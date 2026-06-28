import 'dart:math';
import 'package:flutter/material.dart';
import '../models/study_item.dart';
import '../state/app_state.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  bool _showMnemonic = false;
  
  List<StudyItem> _studyCards = [];
  int _currentIndex = 0;
  String _selectedCategory = 'all'; // all, 657_dmk, kik, medical
  
  // XP Parçacık Animasyon Kontrolleri
  late AnimationController _xpController;
  late Animation<double> _xpOpacityAnimation;
  late Animation<double> _xpOffsetAnimation;
  int _gainedXpAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
    
    // 3D Kart Döndürme Animasyonu
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_flipController)
      ..addListener(() {
        setState(() {});
      });

    // Uçan XP Parçacığı Animasyonu
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _xpOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _xpController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _xpOffsetAnimation = Tween<double>(begin: 0.0, end: -80.0).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOut),
    );
  }

  void _loadCards() {
    final allItems = AppState.instance.itemsNotifier.value;
    DateTime now = DateTime.now();
    bool onlyStruggled = AppState.instance.studyOnlyStruggled;
    final selectedDeckId = AppState.instance.selectedDeckId;
    
    // Aralıklı tekrar algoritması veya sadece yanlış yapılanlar (seçili desteye göre)
    List<StudyItem> filtered = allItems.where((item) {
      bool deckMatch = item.deckId == selectedDeckId || onlyStruggled; // Zayıf kartlarda hepsi gelebilir
      if (onlyStruggled) {
        return deckMatch && item.wrongAttempts > 0;
      }
      bool isDue = item.nextDueDate.isBefore(now.add(const Duration(minutes: 5))) || item.repetitions == 0;
      return deckMatch && isDue;
    }).toList();

    // Eğer o desteye ait tekrar edecek kart kalmadıysa, tümünü listele (öğrencinin boş kalmaması için)
    if (filtered.isEmpty && !onlyStruggled) {
      filtered = allItems.where((item) => item.deckId == selectedDeckId).toList();
    }

    // Kartları rastgele karıştır (hiperaktif/ADHD odaklanması için her seferinde farklı sıra)
    filtered.shuffle();

    setState(() {
      _studyCards = filtered;
      _currentIndex = 0;
      _showFront = true;
      _showMnemonic = false;
      _flipController.reset();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _xpController.dispose();
    AppState.instance.studyOnlyStruggled = false; // Reset the flag
    super.dispose();
  }

  // Kartı Çevir
  void _toggleCard() {
    if (_flipController.status == AnimationStatus.dismissed) {
      _flipController.forward().then((_) {
        setState(() {
          _showFront = false;
        });
      });
    } else {
      _flipController.reverse().then((_) {
        setState(() {
          _showFront = true;
        });
      });
    }
  }

  // Cevabı Kaydet ve Sonraki Karta Geç
  void _answerCard(bool wasCorrect, int xpReward) {
    if (_studyCards.isEmpty) return;

    final currentCard = _studyCards[_currentIndex];
    
    // State'i güncelle
    AppState.instance.recordStudyAttempt(currentCard.id, wasCorrect);
    AppState.instance.addXp(xpReward);

    // XP Animasyonunu Başlat
    setState(() {
      _gainedXpAmount = xpReward;
    });
    _xpController.reset();
    _xpController.forward();

    // Kartı kaydırarak değiştirme animasyonu simülasyonu
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _studyCards.length - 1) {
          _currentIndex++;
          _showFront = true;
          _showMnemonic = false;
          _flipController.reset(); // Yeni kart ön yüzüyle başlar
        } else {
          // Kartlar bitti, yeniden yükle veya tebrik ekranı
          _currentIndex = _studyCards.length; // Bitti durumunu tetiklemek için
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AKILLI HAFIZA KARTLARI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F19), Color(0xFF1E1E38)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- KATEGORİ SEÇİM CHIPS ---
              _buildCategoryChips(),
              const SizedBox(height: 16),

              // --- İLERLEME VE KART SAYACI ---
              if (_studyCards.isNotEmpty && _currentIndex < _studyCards.length)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'KART: ${_currentIndex + 1} / ${_studyCards.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      Text(
                        _studyCards[_currentIndex].categoryDisplayName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),

              // --- ANA KART ALANI ---
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Kart Yok veya Bitmişse Tebrik Ekranı
                    if (_studyCards.isEmpty || _currentIndex >= _studyCards.length)
                      _buildCompletedWidget()
                    else
                      // 3D Dönen Kart Widget'ı
                      _buildFlipCardWidget(),

                    // Uçan XP Parçacığı (Doğru butonuna basıldığında yükselir)
                    AnimatedBuilder(
                      animation: _xpController,
                      builder: (context, child) {
                        return Positioned(
                          top: MediaQuery.of(context).size.height * 0.4 + _xpOffsetAnimation.value,
                          child: Opacity(
                            opacity: _xpOpacityAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withOpacity(0.5),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Text(
                                '+$_gainedXpAmount XP 🔥',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- KONTROL BUTONLARI ---
              if (_studyCards.isNotEmpty && _currentIndex < _studyCards.length)
                _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Kategori Filtreleme Butonları
  Widget _buildCategoryChips() {
    final categories = [
      {"id": "all", "label": "Hepsi ⚡"},
      {"id": "657_dmk", "label": "657 DMK 📜"},
      {"id": "kik", "label": "İhale K. 💼"},
      {"id": "medical", "label": "Tıbbi Sek. 🏥"},
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat["id"];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat["label"]!),
              selected: isSelected,
              selectedColor: const Color(0xFFEC4899),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat["id"]!;
                    _loadCards();
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  // 3D Dönen Kart Gövdesi
  Widget _buildFlipCardWidget() {
    final item = _studyCards[_currentIndex];
    
    // Transform ile Y ekseninde 3D Döndürme
    return GestureDetector(
      onTap: _toggleCard,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspektif derinliği
          ..rotateY(_flipAnimation.value * pi),
        alignment: Alignment.center,
        child: _flipAnimation.value < 0.5
            // ÖN YÜZ
            ? _buildCardSide(
                glowColor: const Color(0xFFEC4899),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('SORU', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        item.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Hafıza İpucu Tetikleyici
                    if (!_showMnemonic)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showMnemonic = true;
                          });
                        },
                        icon: const Icon(Icons.psychology, color: Color(0xFF06B6D4)),
                        label: const Text('Hafıza İpucu Al 🧠', style: TextStyle(color: Color(0xFF06B6D4))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF06B6D4)),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4)),
                        ),
                        child: Text(
                          item.mnemonic,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF06B6D4),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cevabı görmek için dokun 🔄',
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                    )
                  ],
                ),
              )
            // ARKA YÜZ (Yazının ters yansımasını engellemek için rotateY(pi) uyguluyoruz)
            : Transform(
                transform: Matrix4.identity()..rotateY(pi),
                alignment: Alignment.center,
                child: _buildCardSide(
                  glowColor: const Color(0xFF06B6D4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('CEVAP', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      Text(
                        item.answer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF22C55E), // Başarılı yeşil
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          item.explanation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Soruyu görmek için dokun 🔄',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Ortak Kart Şablonu (Glow ve Glassmorphism)
  Widget _buildCardSide({required Color glowColor, required Widget child}) {
    return Container(
      width: min(MediaQuery.of(context).size.width * 0.85, 360),
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: glowColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Center(child: child),
    );
  }

  // Değerlendirme Butonları (Kart Çevrilince görünürse daha iyi, ancak Z kuşağı/ADHD için her an butonlar erişilebilir olmalı ya da çevirince butonlar renklenmelidir. Biz sadece çevrildiğinde (Arka Yüzde) butonları tam işlevsel veya renkli gösterelim ya da her an aktif yapalım. Genel olarak, "Cevabı Tahmin Et -> Çevir -> Kendini Değerlendir" mantığı için en doğrusu, kart arkası çevrilince butonların görünmesidir.)
  Widget _buildActionButtons() {
    final showEvalButtons = _flipAnimation.value >= 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AnimatedOpacity(
        opacity: showEvalButtons ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !showEvalButtons, // Çevrilmeden tıklanmasın
          child: Row(
            children: [
              // BİLEMEDİM (Reschedule)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _answerCard(false, 0),
                  icon: const Icon(Icons.close),
                  label: const Text('Bilemedim'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ZORLANDIM
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _answerCard(true, 10),
                  icon: const Icon(Icons.star_half),
                  label: const Text('Zordu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // KOLAYDI
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _answerCard(true, 25),
                  icon: const Icon(Icons.sentiment_very_satisfied),
                  label: const Text('Kolaydı!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tüm Kartlar Tamamlandığında Çıkacak Tebrik Ekranı
  Widget _buildCompletedWidget() {
    return Container(
      width: min(MediaQuery.of(context).size.width * 0.85, 360),
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.15),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 54)),
          const SizedBox(height: 16),
          const Text(
            'TEKRARLAR TAMAMLANDI!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF22C55E)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Şu an için tekrar etmen gereken hiçbir kart kalmadı. Hafızan alev alıyor! 🔥',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Panele Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _loadCards(); // Yeniden başlat
              });
            },
            child: const Text('Kartları Sıfırla ve Yeniden Çalış', style: TextStyle(color: Colors.white30, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
