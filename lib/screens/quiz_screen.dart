import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_item.dart';
import '../state/app_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late List<StudyItem> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _xpEarned = 0;
  bool _quizFinished = false;

  // Seçenek durum kontrolü
  int? _selectedOptionIndex;
  bool _answered = false;

  // Süre Sayacı
  Timer? _timer;
  double _timeRemaining = 1.0; // 1.0 ile 0.0 arası (oran)
  final int _secondsPerQuestion = 10;
  int _secondsPassed = 0;

  // Ekran Sallama (Shake) Animasyon Kontrolcüsü
  late AnimationController _shakeController;
  // Konfeti (Particles) Animasyon Kontrolcüsü
  late AnimationController _confettiController;
  List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();

    // Sallama Animasyonu
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Konfeti Animasyonu
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
        _updateParticles();
        setState(() {});
      });

    _startTimer();
  }

  void _loadQuestions() {
    final selectedDeckId = AppState.instance.selectedDeckId;
    final allItems = List<StudyItem>.from(AppState.instance.itemsNotifier.value)
        .where((item) => item.deckId == selectedDeckId)
        .toList();
    allItems.shuffle();
    // Test için en fazla 5 soru seçelim (ADHD için sıkılmadan bitebilecek kısa süreli odak seansı)
    _questions = allItems.take(5).toList();
  }

  void _startTimer() {
    _secondsPassed = 0;
    _timeRemaining = 1.0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_answered || _quizFinished) return;

      setState(() {
        _secondsPassed += 100;
        _timeRemaining = (1.0 - (_secondsPassed / (_secondsPerQuestion * 1000))).clamp(0.0, 1.0);
      });

      if (_secondsPassed >= _secondsPerQuestion * 1000) {
        _timer?.cancel();
        _handleTimeOut();
      }
    });
  }

  // Süre Bittiğinde
  void _handleTimeOut() {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0.0);
    setState(() {
      _answered = true;
      _combo = 0;
      _wrongCount++;
      // Yanlış cevabı kaydet
      AppState.instance.recordStudyAttempt(_questions[_currentIndex].id, false);
    });

    _showNextQuestionAfterDelay();
  }

  // Konfeti Üretici
  void _triggerConfetti() {
    _particles = List.generate(40, (index) {
      return ConfettiParticle(
        x: Random().nextDouble() * 400,
        y: -10,
        color: [
          const Color(0xFFEC4899), // Neon Pembe
          const Color(0xFF06B6D4), // Neon Cyan
          const Color(0xFF22C55E), // Yeşil
          const Color(0xFFEAB308), // Sarı
          Colors.blueAccent,
        ][Random().nextInt(5)],
        speedX: Random().nextDouble() * 4 - 2,
        speedY: Random().nextDouble() * 5 + 3,
        size: Random().nextDouble() * 8 + 6,
        rotation: Random().nextDouble() * pi,
      );
    });
    _confettiController.forward(from: 0.0);
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.y += p.speedY;
      p.x += p.speedX;
      p.rotation += 0.05;
    }
  }

  // Seçeneğe Tıklandığında
  void _selectOption(int optionIndex) {
    if (_answered) return;
    _timer?.cancel();

    final item = _questions[_currentIndex];
    final isCorrect = optionIndex == item.correctOptionIndex;

    setState(() {
      _selectedOptionIndex = optionIndex;
      _answered = true;
    });

    if (isCorrect) {
      // Doğru Cevap
      HapticFeedback.lightImpact();
      _triggerConfetti();
      
      setState(() {
        _correctCount++;
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        
        int baseReward = 15;
        int comboReward = (_combo - 1) * 5; // Combo çarpanı
        int totalReward = baseReward + comboReward;
        
        _xpEarned += totalReward;
        AppState.instance.addXp(totalReward);
        _score += 100 * _combo;
      });

      // İlerlemeyi kaydet
      AppState.instance.recordStudyAttempt(item.id, true);
    } else {
      // Yanlış Cevap
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0.0);
      
      setState(() {
        _wrongCount++;
        _combo = 0; // Combo sıfırlandı
      });

      // İlerlemeyi kaydet
      AppState.instance.recordStudyAttempt(item.id, false);
    }

    _showNextQuestionAfterDelay();
  }

  void _showNextQuestionAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _shakeController.reset();
      _confettiController.reset();

      setState(() {
        if (_currentIndex < _questions.length - 1) {
          _currentIndex++;
          _selectedOptionIndex = null;
          _answered = false;
          _startTimer();
        } else {
          _quizFinished = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      return _buildResultsScreen();
    }

    final item = _questions[_currentIndex];
    
    // Süre barının rengi (Son 3 saniyede kırmızıya döner)
    final isUrgent = _timeRemaining <= 0.3;
    final timerBarColor = isUrgent ? const Color(0xFFEF4444) : const Color(0xFF06B6D4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZAMANA KARŞI HIZ TESTİ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'SKOR: $_score',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEAB308)),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Ana İçerik
          SafeArea(
            child: Column(
              children: [
                // --- SÜRE BAR (Neon) ---
                Container(
                  height: 6,
                  width: double.infinity,
                  color: const Color(0xFF0F172A),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _timeRemaining,
                      child: Container(
                        decoration: BoxDecoration(
                          color: timerBarColor,
                          boxShadow: [
                            BoxShadow(
                              color: timerBarColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // --- COMBO BÖLÜMÜ ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SORU: ${_currentIndex + 1} / ${_questions.length}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      // Combo Göstergesi
                      if (_combo > 1)
                        AnimatedScale(
                          scale: 1.1,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withOpacity(0.4),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: Text(
                              'COMBO x$_combo! 🔥',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 26),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // --- SORU KARTI (Sallanabilir) ---
                Expanded(
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // Sine dalgasıyla ekran sallama
                      double offset = 0;
                      if (_shakeController.isAnimating) {
                        offset = sin(_shakeController.value * 4 * pi) * 12;
                      }
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.categoryDisplayName.toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.question,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // --- CEVAP ŞIKKARI (A, B, C, D) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: List.generate(item.options.length, (index) {
                      return _buildOptionButton(index, item);
                    }),
                  ),
                ),

                // --- BİLGİ / HAFIZA İPUCU (Yanlış bildiyse veya süre bittiyse altta fırlar) ---
                _buildFeedbackSection(item),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Konfeti Yağmuru Çizimi
          if (_confettiController.isAnimating)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: ConfettiPainter(particles: _particles),
              ),
            ),
        ],
      ),
    );
  }

  // Şık Butonu Oluşturucu
  Widget _buildOptionButton(int index, StudyItem item) {
    Color btnBorderColor = const Color(0xFF334155);
    Color btnBgColor = const Color(0xFF1E293B).withOpacity(0.6);
    Widget? rightIcon;

    if (_answered) {
      final isCorrect = index == item.correctOptionIndex;
      final isSelected = index == _selectedOptionIndex;

      if (isCorrect) {
        // Doğru şık yeşil yanar
        btnBorderColor = const Color(0xFF22C55E);
        btnBgColor = const Color(0xFF22C55E).withOpacity(0.15);
        rightIcon = const Icon(Icons.check_circle, color: Color(0xFF22C55E));
      } else if (isSelected) {
        // Yanlış seçilen şık kırmızı yanar
        btnBorderColor = const Color(0xFFEF4444);
        btnBgColor = const Color(0xFFEF4444).withOpacity(0.15);
        rightIcon = const Icon(Icons.cancel, color: Color(0xFFEF4444));
      } else {
        // Diğer şıklar silikleşir
        btnBgColor = btnBgColor.withOpacity(0.2);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () => _selectOption(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: btnBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: btnBorderColor, width: 1.5),
            boxShadow: _answered && index == item.correctOptionIndex
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.2),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Şık Harfi ve Metni
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _answered && index == item.correctOptionIndex
                            ? const Color(0xFF22C55E)
                            : (_answered && index == _selectedOptionIndex
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0F172A)),
                      ),
                      child: Center(
                        child: Text(
                          ['A', 'B', 'C', 'D'][index],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.options[index],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              if (rightIcon != null) rightIcon,
            ],
          ),
        ),
      ),
    );
  }

  // Cevap Verildiğinde Mnemonic/Açıklama Göstergesi
  Widget _buildFeedbackSection(StudyItem item) {
    if (!_answered) return const SizedBox(height: 60);

    final wasCorrect = _selectedOptionIndex == item.correctOptionIndex;

    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: SingleChildScrollView(
          child: wasCorrect
              ? const Text(
                  'BRAVO! HIZLI CEVAP VE KOMBO PUANI CAPILDI! ⚡🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w900, fontSize: 13),
                )
              : Text(
                  '💡 İpucu: ${item.mnemonic}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF06B6D4), fontStyle: FontStyle.italic, fontSize: 13),
                ),
        ),
      ),
    );
  }

  // Sonuç Ekranı
  Widget _buildResultsScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F19), Color(0xFF1E1E38)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'TEST TAMAMLANDI! 🏁',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEC4899),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sonuç Paneli
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      _buildResultRow('Kazanılan Puan:', '$_score Puan', const Color(0xFFEAB308)),
                      const Divider(color: Colors.white12, height: 20),
                      _buildResultRow('Kazanılan XP:', '+$_xpEarned XP 🔥', const Color(0xFF22C55E)),
                      const Divider(color: Colors.white12, height: 20),
                      _buildResultRow('En Yüksek Kombo:', '$_maxCombo x', const Color(0xFFEC4899)),
                      const Divider(color: Colors.white12, height: 20),
                      _buildResultRow('Doğru / Yanlış:', '$_correctCount Doğru - $_wrongCount Yanlış', Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Dashboard\'a Dön', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _score = 0;
                      _combo = 0;
                      _maxCombo = 0;
                      _correctCount = 0;
                      _wrongCount = 0;
                      _xpEarned = 0;
                      _quizFinished = false;
                      _selectedOptionIndex = null;
                      _answered = false;
                      _loadQuestions();
                      _startTimer();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF06B6D4)),
                  ),
                  child: const Text('Yeniden Oyna 🔄', style: TextStyle(color: Color(0xFF06B6D4))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}

// Konfeti Parçacık Modeli
class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double speedX;
  final double speedY;
  final double size;
  double rotation;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.rotation,
  });
}

// Konfeti Çizici
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
