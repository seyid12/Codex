class StudyItem {
  final String id;
  final String deckId; // Hangi derse/desteye bağlı olduğu
  final String category; // '657_dmk', 'kik', 'medical'
  final String categoryDisplayName;
  final String question;
  final String answer;
  final String mnemonic; // Hafıza İpucu (Gen Z / ADHD)
  final List<String> options; // Çoktan seçmeli test için şıklar
  final int correctOptionIndex;
  final String clozeText; // Boşluk doldurma metni
  final String clozeAnswer; // Boşluk doldurma cevabı
  final String explanation; // Soru açıklama / Detaylı bilgi

  // İlerleme durum parametreleri (SuperMemo-2 Algoritması ve Hata Analizi için)
  double easeFactor;
  int repetitions;
  int intervalDays;
  int wrongAttempts;
  DateTime nextDueDate;

  StudyItem({
    required this.id,
    required this.deckId,
    required this.category,
    required this.categoryDisplayName,
    required this.question,
    required this.answer,
    required this.mnemonic,
    required this.options,
    required this.correctOptionIndex,
    required this.clozeText,
    required this.clozeAnswer,
    required this.explanation,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.wrongAttempts = 0,
    DateTime? nextDueDate,
  }) : this.nextDueDate = nextDueDate ?? DateTime.now();

  // Json'a ve Json'dan dönüştürme (Gelecekte .NET API'ye hazır olması için)
  factory StudyItem.fromJson(Map<String, dynamic> json) {
    return StudyItem(
      id: json['id'] as String,
      deckId: json['deckId'] as String? ?? 'deck_dmk',
      category: json['category'] as String,
      categoryDisplayName: json['categoryDisplayName'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      mnemonic: json['mnemonic'] as String,
      options: List<String>.from(json['options'] as List),
      correctOptionIndex: json['correctOptionIndex'] as int,
      clozeText: json['clozeText'] as String,
      clozeAnswer: json['clozeAnswer'] as String,
      explanation: json['explanation'] as String,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      repetitions: json['repetitions'] as int? ?? 0,
      intervalDays: json['intervalDays'] as int? ?? 0,
      wrongAttempts: json['wrongAttempts'] as int? ?? 0,
      nextDueDate: json['nextDueDate'] != null 
          ? DateTime.parse(json['nextDueDate'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'category': category,
      'categoryDisplayName': categoryDisplayName,
      'question': question,
      'answer': answer,
      'mnemonic': mnemonic,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'clozeText': clozeText,
      'clozeAnswer': clozeAnswer,
      'explanation': explanation,
      'easeFactor': easeFactor,
      'repetitions': repetitions,
      'intervalDays': intervalDays,
      'wrongAttempts': wrongAttempts,
      'nextDueDate': nextDueDate.toIso8601String(),
    };
  }

  // Varsayılan Hazır Kart Verileri (Placeholder içermeyen gerçek örnekler)
  static List<StudyItem> get defaultItems => [
    // --- 657 SAYILI DEVLET MEMURLARI KANUNU (DMK) ---
    StudyItem(
      id: "dmk_001",
      deckId: "deck_dmk",
      category: "657_dmk",
      categoryDisplayName: "657 Sayılı DMK",
      question: "Aday memurluk süresi en çok ne kadar olabilir?",
      answer: "2 yıl",
      mnemonic: "Aday memur = 2 yıla kadar gözetim altındasın! Sabret! 👀",
      options: ["6 ay", "1 yıl", "2 yıl", "3 yıl"],
      correctOptionIndex: 2,
      clozeText: "Adaylık süresi en az 1 yıl, en çok [2] yıldır.",
      clozeAnswer: "2",
      explanation: "657 sayılı DMK Madde 54'e göre; aday memurluk süresi 1 yıldan az, 2 yıldan çok olamaz.",
    ),
    StudyItem(
      id: "dmk_002",
      deckId: "deck_dmk",
      category: "657_dmk",
      categoryDisplayName: "657 Sayılı DMK",
      question: "Devlet memurunun haftalık çalışma süresi genel olarak kaç saattir?",
      answer: "40 saat",
      mnemonic: "Memur hayatı = Günde 8 saat x 5 Gün = 40 Saat! Haftasonu tatil! 🕒",
      options: ["35 saat", "40 saat", "45 saat", "48 saat"],
      correctOptionIndex: 1,
      clozeText: "Devlet memurlarının haftalık çalışma süresi genel olarak [40] saattir.",
      clozeAnswer: "40",
      explanation: "657 sayılı DMK Madde 99'a göre memurların haftalık çalışma süresi genel olarak 40 saattir ve Cumartesi-Pazar günleri tatildir.",
    ),
    StudyItem(
      id: "dmk_003",
      deckId: "deck_dmk",
      category: "657_dmk",
      categoryDisplayName: "657 Sayılı DMK",
      question: "Memura verilen aylıktan kesme cezasında kesinti oranı en fazla ne kadar olabilir?",
      answer: "1/8",
      mnemonic: "Aylıktan kesme = Maaşın 8 dilimli pizzadır, en çok 1 dilimi (1/8) uçar! 🍕💸",
      options: ["1/30", "1/10", "1/8", "1/4"],
      correctOptionIndex: 2,
      clozeText: "Aylıktan kesme cezası, brüt aylığından [1/30] - [1/8] arasında kesinti yapılarak verilir.",
      clozeAnswer: "1/8",
      explanation: "657 sayılı DMK Madde 125/C'ye göre; Aylıktan kesme cezası, brüt aylığın 1/30'u ile 1/8'i arasında kesinti yapılmasıdır.",
    ),
    StudyItem(
      id: "dmk_004",
      deckId: "deck_dmk",
      category: "657_dmk",
      categoryDisplayName: "657 Sayılı DMK",
      question: "Devlet memurluğundan çıkarma cezasını vermeye yetkili makam hangisidir?",
      answer: "Yüksek Disiplin Kurulu",
      mnemonic: "Son Karar = YDK (Yüksek Disiplin Kurulu) = Yetki Dehşet Büyük! 💀",
      options: ["Disiplin Amiri", "Atamaya Yetkili Amir", "Yüksek Disiplin Kurulu", "Bakan"],
      correctOptionIndex: 2,
      clozeText: "Devlet memurluğundan çıkarma cezası [Yüksek Disiplin Kurulu] kararı ile verilir.",
      clozeAnswer: "Yüksek Disiplin Kurulu",
      explanation: "657 sayılı DMK Madde 126'ya göre memurluktan çıkarma cezası amirlerin isteği üzerine Yüksek Disiplin Kurulu kararı ile verilir.",
    ),

    // --- KAMU İHALE KANUNU (KİK) ---
    StudyItem(
      id: "kik_001",
      deckId: "deck_kik",
      category: "kik",
      categoryDisplayName: "Kamu İhale Kanunu",
      question: "Doğrudan temin yöntemiyle yapılan alımlarda ihale komisyonu kurulması zorunlu mudur?",
      answer: "Zorunlu değildir",
      mnemonic: "Doğrudan Temin = Komisyonsuz hızlı alışveriş! Kestirmeden git! 🛒💨",
      options: ["Zorunludur", "Zorunlu değildir", "Bakan onayına bağlıdır", "En az 3 kişiyle kurulur"],
      correctOptionIndex: 1,
      clozeText: "Doğrudan temin yönteminde ihale komisyonu kurulması [zorunlu değildir].",
      clozeAnswer: "zorunlu değildir",
      explanation: "4734 sayılı Kamu İhale Kanunu Madde 22 kapsamında doğrudan temin alımlarında ihale komisyonu kurulması ve teminat alınması zorunlu değildir.",
    ),
    StudyItem(
      id: "kik_002",
      deckId: "deck_kik",
      category: "kik",
      categoryDisplayName: "Kamu İhale Kanunu",
      question: "Açık ihale usulünde tekliflerin sunulması için verilecek ilan süresi en az kaç gündür?",
      answer: "40 gün",
      mnemonic: "Her şey açık ihale ediliyorsa, 40 gün 40 gece bekle! 🗓️👑",
      options: ["15 gün", "22 gün", "30 gün", "40 gün"],
      correctOptionIndex: 3,
      clozeText: "Açık ihale usulünde ilan süresi en az [40] gündür.",
      clozeAnswer: "40",
      explanation: "4734 sayılı KİK Madde 13'e göre; açık ihale usulünde ilanlar, ihale tarihinden en az 40 gün önce yayınlanmalıdır.",
    ),
    StudyItem(
      id: "kik_003",
      deckId: "deck_kik",
      category: "kik",
      categoryDisplayName: "Kamu İhale Kanunu",
      question: "İhale dokümanına karşı şikayet başvurusu ihale tarihinden en az kaç gün önce yapılmalıdır?",
      answer: "3 gün",
      mnemonic: "İtirazın mı var? Son 3 güne kalma, hakkın yanar! ⏰🛑",
      options: ["3 gün", "5 gün", "7 gün", "10 gün"],
      correctOptionIndex: 0,
      clozeText: "İhale dokümanına karşı şikayet ihale tarihinden en az [3] gün önce yapılmalıdır.",
      clozeAnswer: "3",
      explanation: "İhale dokümanına karşı şikayet başvurusu ihale tarihinden en az 3 iş günü öncesine kadar idareye ulaştırılmalıdır.",
    ),

    // --- TIBBİ SEKRETERLİK ---
    StudyItem(
      id: "med_001",
      deckId: "deck_med",
      category: "medical",
      categoryDisplayName: "Tıbbi Sekreterlik",
      question: "Gastroenteroloji tıbbi birimi hangi organ sisteminin hastalıklarıyla ilgilenir?",
      answer: "Sindirim Sistemi",
      mnemonic: "Gastro (Mide) + Enter (Bağırsak) = Kısaca Komple Sindirim Sistemi! 🍔➡️💩",
      options: ["Solunum Sistemi", "Dolaşım Sistemi", "Sindirim Sistemi", "Üriner Sistem"],
      correctOptionIndex: 2,
      clozeText: "Gastroenteroloji, [sindirim] sistemi hastalıkları ile ilgilenir.",
      clozeAnswer: "sindirim",
      explanation: "Gastroenteroloji yemek borusu, mide, ince bağırsak, kalın bağırsak, karaciğer, safra kesesi ve pankreas organlarını içeren sindirim sistemi bilimidir.",
    ),
    StudyItem(
      id: "med_002",
      deckId: "deck_med",
      category: "medical",
      categoryDisplayName: "Tıbbi Sekreterlik",
      question: "Subkutan enjeksiyon kelime anlamı olarak neyi ifade eder?",
      answer: "Deri altı enjeksiyon",
      mnemonic: "Sub (Altında) + Kutan (Deri/Cutis) = Derinin tam altı! 💉",
      options: ["Kas içi enjeksiyon", "Deri altı enjeksiyon", "Damar içi enjeksiyon", "Eklem içi enjeksiyon"],
      correctOptionIndex: 1,
      clozeText: "Subkutan enjeksiyon, ilacın [deri altı] dokusuna verilmesidir.",
      clozeAnswer: "deri altı",
      explanation: "Subkutan enjeksiyon, dermis tabakasının altındaki yağlı subkutan dokuya (hypodermis) yapılan ilaç uygulamasıdır.",
    ),
    StudyItem(
      id: "med_003",
      deckId: "deck_med",
      category: "medical",
      categoryDisplayName: "Tıbbi Sekreterlik",
      question: "Uluslararası Hastalık Sınıflandırması kodlama sisteminin kısaltması nedir?",
      answer: "ICD",
      mnemonic: "ICD = Hastalıkların dünya çapındaki barkod numarası! 🏷️🏥",
      options: ["ICD", "MRG", "BT", "HBYS"],
      correctOptionIndex: 0,
      clozeText: "Hastalıkların sınıflandırılmasında [ICD] kodları kullanılır.",
      clozeAnswer: "ICD",
      explanation: "ICD (International Classification of Diseases), hastalıkların ve sağlık sorunlarının uluslararası standart kodlarla sınıflandırılması sistemidir.",
    ),
  ];
}
