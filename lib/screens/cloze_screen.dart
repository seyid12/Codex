import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_item.dart';
import '../state/app_state.dart';

class ClozeScreen extends StatefulWidget {
  const ClozeScreen({Key? key}) : super(key: key);

  @override
  State<ClozeScreen> createState() => _ClozeScreenState();
}

class _ClozeScreenState extends State<ClozeScreen> {
  late List<StudyItem> _clozeItems;
  int _currentIndex = 0;
  final TextEditingController _inputController = TextEditingController();
  bool _answered = false;
  bool _isCorrect = false;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadClozeItems();
  }

  void _loadClozeItems() {
    final allItems = AppState.instance.itemsNotifier.value;
    final selectedDeckId = AppState.instance.selectedDeckId;
    // Boşluk doldurması olan ve seçili desteye ait soruları filtrele
    List<StudyItem> filtered = allItems.where((item) => 
        item.deckId == selectedDeckId &&
        item.clozeText.contains('[') && 
        item.clozeText.contains(']')
    ).toList();
    filtered.shuffle();
    setState(() {
      _clozeItems = filtered;
      _currentIndex = 0;
      _answered = false;
      _inputController.clear();
    });
  }

  void _checkAnswer() {
    if (_inputController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    final item = _clozeItems[_currentIndex];
    // Cevap kontrolü (küçük/büyük harf duyarsız ve Türkçe karakter uyumlu)
    final studentAnswer = _inputController.text.trim().toLowerCase()
        .replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u')
        .replaceAll('ş', 's').replaceAll('ç', 'c').replaceAll('ğ', 'g');

    final correctAnswer = item.clozeAnswer.toLowerCase()
        .replaceAll('ı', 'i').replaceAll('ö', 'o').replaceAll('ü', 'u')
        .replaceAll('ş', 's').replaceAll('ç', 'c').replaceAll('ğ', 'g');

    final correct = studentAnswer == correctAnswer;

    setState(() {
      _isCorrect = correct;
      _answered = true;
    });

    if (correct) {
      HapticFeedback.lightImpact();
      setState(() {
        _xpEarned += 20;
      });
      AppState.instance.addXp(20);
      AppState.instance.recordStudyAttempt(item.id, true);
    } else {
      HapticFeedback.vibrate();
      AppState.instance.recordStudyAttempt(item.id, false);
    }
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _clozeItems.length - 1) {
        _currentIndex++;
        _answered = false;
        _inputController.clear();
      } else {
        _currentIndex = _clozeItems.length; // Bitti durumu
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAYI VE SÜRE AVCISI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F19), Color(0xFF1E1E38)],
          ),
        ),
        child: SafeArea(
          child: _clozeItems.isEmpty
              ? _buildNoItemsWidget()
              : (_currentIndex >= _clozeItems.length
                  ? _buildCompletedWidget()
                  : _buildClozePlayWidget()),
        ),
      ),
    );
  }

  // Boşluk Doldurma Oyun Alanı
  Widget _buildClozePlayWidget() {
    final item = _clozeItems[_currentIndex];
    
    // Metindeki [boşluk] kısmını gizleyerek "______" haline getirme
    final clozeTemplate = item.clozeText.replaceAll(RegExp(r'\[.*?\]'), '___________');

    Color outlineColor = const Color(0xFF334155);
    if (_answered) {
      outlineColor = _isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kategori Rozeti
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
              ),
              child: Text(
                item.categoryDisplayName.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Soru/Metin Kartı
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: outlineColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _answered
                      ? (_isCorrect ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1))
                      : Colors.transparent,
                  blurRadius: 15,
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book, color: Colors.grey, size: 28),
                const SizedBox(height: 16),
                Text(
                  clozeTemplate,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Cevap Giriş Alanı
          TextField(
            controller: _inputController,
            enabled: !_answered,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Gizlenen Değeri Buraya Yaz',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF1E293B).withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _checkAnswer(),
          ),
          const SizedBox(height: 20),

          // Kontrol Et / Sonraki Butonu
          if (!_answered)
            ElevatedButton.icon(
              onPressed: _checkAnswer,
              icon: const Icon(Icons.search),
              label: const Text('Cevabı Kontrol Et', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Doğru/Yanlış Mesajı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isCorrect ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isCorrect ? 'HARİKA! DOĞRU CEVAP 🎉' : 'YANLIŞ CEVAP! ❌',
                        style: TextStyle(
                          color: _isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Doğru Cevap: "${item.clozeAnswer}"',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Yanlış Yaparsa İpucu/Açıklama Göster
                if (!_isCorrect)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.2)),
                    ),
                    child: Text(
                      '💡 İpucu: ${item.mnemonic}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF06B6D4), fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Sonraki Soruya Geç', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Sorulacak Boşluklu Soru Kalmadığında
  Widget _buildNoItemsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'UYGUN KART BULUNAMADI',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'Boşluk doldurma modunda çalışmak için öğretmen panelinden uygun formatta (köşeli parantez [ ] içeren) mevzuat eklemelisiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Panele Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  // Tebrikler Ekranı
  Widget _buildCompletedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              const Text(
                'TÜM SÜRELER EZBERLENDİ!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF22C55E)),
              ),
              const SizedBox(height: 12),
              Text(
                'Mevzuattaki tüm önemli sayı ve süreleri avladın. Toplam +$_xpEarned XP cepte! 🔥',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Dashboard\'a Dön'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadClozeItems(),
                child: const Text('Yeniden Oyna 🔄', style: TextStyle(color: Colors.white30, fontSize: 11)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
