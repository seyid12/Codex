import 'package:flutter/foundation.dart';
import '../models/study_item.dart';
import '../models/deck_model.dart';

class AppState {
  // Singleton pattern
  static final AppState instance = AppState._internal();
  AppState._internal();

  final ValueNotifier<int> xpNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> levelNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> streakNotifier = ValueNotifier<int>(3); // Varsayılan 3 günlük streak verelim (boş durmasın)
  final ValueNotifier<List<StudyItem>> itemsNotifier = ValueNotifier<List<StudyItem>>(StudyItem.defaultItems);
  final ValueNotifier<List<StudyDeck>> decksNotifier = ValueNotifier<List<StudyDeck>>(StudyDeck.defaultDecks);
  final ValueNotifier<List<String>> badgesNotifier = ValueNotifier<List<String>>(["Çırak"]);
  
  // Seçilen ders/deste ve çalışma modu bayrakları
  String? selectedDeckId;
  bool studyOnlyStruggled = false;

  // XP Ekle ve Level Up hesapla
  void addXp(int amount) {
    xpNotifier.value += amount;
    
    // Basit seviye atlama eşiği: Her seviye için (Seviye * 100) XP gerekir.
    int nextLevelThreshold = levelNotifier.value * 150;
    if (xpNotifier.value >= nextLevelThreshold) {
      xpNotifier.value -= nextLevelThreshold;
      levelNotifier.value += 1;
      
      // Seviyeye göre yeni rozetler kazanılması
      _checkNewBadges();
    }
  }

  // Seri (Streak) Artır
  void incrementStreak() {
    streakNotifier.value += 1;
  }

  // Öğrenci İlerlemesini Güncelle (Zayıf Noktalar & Aralıklı Tekrar)
  void recordStudyAttempt(String itemId, bool wasCorrect) {
    final updatedList = List<StudyItem>.from(itemsNotifier.value);
    final index = updatedList.indexWhere((element) => element.id == itemId);

    if (index != -1) {
      final item = updatedList[index];

      if (wasCorrect) {
        item.repetitions += 1;
        // SuperMemo-2 basitleştirilmiş aralık hesabı
        if (item.repetitions == 1) {
          item.intervalDays = 1;
        } else if (item.repetitions == 2) {
          item.intervalDays = 3;
        } else {
          item.intervalDays = (item.intervalDays * item.easeFactor).round();
        }
        // Kolay bildiği için zorluk katsayısını hafifçe artır (aralık uzasın)
        item.easeFactor = (item.easeFactor + 0.15).clamp(1.3, 3.0);
      } else {
        // Hata yaptı
        item.repetitions = 0;
        item.intervalDays = 0;
        item.wrongAttempts += 1; // Toplam hata sayısı arttı!
        // Zorlandığı için katsayıyı düşür (daha sık karşına çıksın)
        item.easeFactor = (item.easeFactor - 0.25).clamp(1.3, 3.0);
      }

      item.nextDueDate = DateTime.now().add(Duration(days: item.intervalDays));
      itemsNotifier.value = updatedList; // Listenin referansını güncelleyip notify ediyoruz
    }
  }

  // Yeni Kart Ekleme (Öğretmen Modülü)
  void addNewCard(StudyItem newItem) {
    final updatedList = List<StudyItem>.from(itemsNotifier.value);
    updatedList.add(newItem);
    itemsNotifier.value = updatedList;
  }

  // Yeni Ders / Deste Ekleme (Öğretmen Modülü)
  void addNewDeck(StudyDeck newDeck) {
    final updatedList = List<StudyDeck>.from(decksNotifier.value);
    updatedList.add(newDeck);
    decksNotifier.value = updatedList;
  }

  // Zayıf Konular İstatistiği Hesapla
  Map<String, double> getCategorySuccessRates() {
    final items = itemsNotifier.value;
    final Map<String, int> totalAttempts = {};
    final Map<String, int> wrongAttempts = {};

    // Her kategorinin toplam sorusunu ve toplam hata sayısını hesapla
    for (var item in items) {
      totalAttempts[item.categoryDisplayName] = (totalAttempts[item.categoryDisplayName] ?? 0) + 1;
      wrongAttempts[item.categoryDisplayName] = (wrongAttempts[item.categoryDisplayName] ?? 0) + item.wrongAttempts;
    }

    final Map<String, double> successRates = {};
    totalAttempts.forEach((categoryName, totalCount) {
      // Bir öğrenci o kategoriye ait soruları çözdükçe wrongAttempts artar.
      // Basit bir başarı oranı formülü: (Toplam Soru) / (Toplam Soru + Toplam Hata) * 100
      int wrongs = wrongAttempts[categoryName] ?? 0;
      double rate = (totalCount / (totalCount + wrongs)) * 100;
      successRates[categoryName] = double.parse(rate.toStringAsFixed(1));
    });

    return successRates;
  }

  // Seviyeye göre rozet kontrolü
  void _checkNewBadges() {
    final currentBadges = List<String>.from(badgesNotifier.value);
    int lvl = levelNotifier.value;

    if (lvl >= 2 && !currentBadges.contains("Hızlı Öğrenen")) {
      currentBadges.add("Hızlı Öğrenen");
    }
    if (lvl >= 3 && !currentBadges.contains("Mevzuat Bükücü")) {
      currentBadges.add("Mevzuat Bükücü");
    }
    if (lvl >= 5 && !currentBadges.contains("Codex Hâkimi")) {
      currentBadges.add("Codex Hâkimi");
    }

    badgesNotifier.value = currentBadges;
  }
}
