import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/study_item.dart';
import '../state/app_state.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({Key? key}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  List<StudyItem> _allItems = [];
  List<StudyItem> _currentPool = [];
  
  List<String> _leftTerms = [];
  List<String> _rightDefinitions = [];
  
  String? _selectedLeft;
  String? _selectedRight;
  
  List<String> _matchedLefts = [];
  List<String> _matchedRights = [];
  
  int _score = 0;
  int _xpEarned = 0;
  bool _gameFinished = false;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  void _loadGameData() {
    final all = AppState.instance.itemsNotifier.value;
    setState(() {
      _allItems = all;
      _gameFinished = false;
      _score = 0;
      _xpEarned = 0;
      _matchedLefts.clear();
      _matchedRights.clear();
      _selectedLeft = null;
      _selectedRight = null;
    });
    _setupNextRound();
  }

  void _setupNextRound() {
    final selectedDeckId = AppState.instance.selectedDeckId;
    // Seçili desteye ait kartları alıp karıştırıyoruz
    List<StudyItem> pool = _allItems.where((item) => item.deckId == selectedDeckId).toList();
    pool.shuffle();
    
    // Her turda 4 çift eşleştirelim
    final count = pool.length >= 4 ? 4 : pool.length;
    _currentPool = pool.take(count).toList();
    
    // Sol liste terimler
    _leftTerms = _currentPool.map((item) => item.question).toList();
    _leftTerms.shuffle();

    // Sağ liste tanımlar / cevaplar
    _rightDefinitions = _currentPool.map((item) => item.answer).toList();
    _rightDefinitions.shuffle();
    
    setState(() {
      _selectedLeft = null;
      _selectedRight = null;
    });
  }

  void _onLeftSelected(String term) {
    if (_matchedLefts.contains(term)) return;
    setState(() {
      _selectedLeft = term;
    });
    _checkMatch();
  }

  void _onRightSelected(String definition) {
    if (_matchedRights.contains(definition)) return;
    setState(() {
      _selectedRight = definition;
    });
    _checkMatch();
  }

  void _checkMatch() {
    if (_selectedLeft == null || _selectedRight == null) return;

    // Eşleşen çifti bul
    bool isMatch = false;
    StudyItem? matchedItem;

    for (var item in _currentPool) {
      if (item.question == _selectedLeft && item.answer == _selectedRight) {
        isMatch = true;
        matchedItem = item;
        break;
      }
    }

    if (isMatch && matchedItem != null) {
      // Doğru Eşleşme
      HapticFeedback.lightImpact();
      setState(() {
        _matchedLefts.add(_selectedLeft!);
        _matchedRights.add(_selectedRight!);
        _selectedLeft = null;
        _selectedRight = null;
        _score += 100;
        _xpEarned += 10;
      });
      
      AppState.instance.addXp(10);
      AppState.instance.recordStudyAttempt(matchedItem.id, true);

      // Tur bitti mi kontrolü
      if (_matchedLefts.length == _currentPool.length) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _gameFinished = true;
          });
        });
      }
    } else {
      // Yanlış Eşleşme
      HapticFeedback.vibrate();
      
      // Hatalı eşleşen kartların ilerlemesini düşür
      final wrongItem = _currentPool.firstWhere((element) => element.question == _selectedLeft);
      AppState.instance.recordStudyAttempt(wrongItem.id, false);

      // Ekranda kırmızılık hissetmesi için hafif bekletip temizliyoruz
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _selectedLeft = null;
          _selectedRight = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TERİM EŞLEŞTİRME OYUNU'),
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
          child: _gameFinished ? _buildResultsScreen() : _buildGamePlayScreen(),
        ),
      ),
    );
  }

  // Oyun Oynama Ekranı
  Widget _buildGamePlayScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Üst Bilgi Barı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Eşleşen: ${_matchedLefts.length} / ${_currentPool.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              Text(
                'Puan: $_score',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEAB308)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Sol taraftan bir terim seç, ardından sağ taraftan anlamını bul! 🧬',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Çift Sütunlu Kartlar
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sol Sütun: Tıbbi Terimler
                Expanded(
                  child: ListView.builder(
                    itemCount: _leftTerms.length,
                    itemBuilder: (context, index) {
                      final term = _leftTerms[index];
                      final isMatched = _matchedLefts.contains(term);
                      final isSelected = _selectedLeft == term;

                      return _buildItemCard(
                        text: term,
                        isSelected: isSelected,
                        isMatched: isMatched,
                        glowColor: const Color(0xFFEC4899), // Neon Pembe
                        onTap: () => _onLeftSelected(term),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sağ Sütun: Tanımlar
                Expanded(
                  child: ListView.builder(
                    itemCount: _rightDefinitions.length,
                    itemBuilder: (context, index) {
                      final definition = _rightDefinitions[index];
                      final isMatched = _matchedRights.contains(definition);
                      final isSelected = _selectedRight == definition;

                      return _buildItemCard(
                        text: definition,
                        isSelected: isSelected,
                        isMatched: isMatched,
                        glowColor: const Color(0xFF06B6D4), // Neon Cyan
                        onTap: () => _onRightSelected(definition),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Eşleştirme Kartı Widget Tasarımı
  Widget _buildItemCard({
    required String text,
    required bool isSelected,
    required bool isMatched,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    Color cardBorderColor = const Color(0xFF334155);
    Color cardBgColor = const Color(0xFF1E293B).withOpacity(0.5);
    double opacity = 1.0;

    if (isMatched) {
      // Eşleşmişse yeşil ve silikleşir
      cardBorderColor = const Color(0xFF22C55E).withOpacity(0.3);
      cardBgColor = const Color(0xFF22C55E).withOpacity(0.05);
      opacity = 0.3;
    } else if (isSelected) {
      // Seçilmişse kendi neon rengiyle parlar
      cardBorderColor = glowColor;
      cardBgColor = glowColor.withOpacity(0.15);
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: isMatched ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorderColor, width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: glowColor.withOpacity(0.2),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sonuç Ekranı
  Widget _buildResultsScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔬🔥', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 16),
              const Text(
                'TUR TAMAMLANDI!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFEC4899)),
              ),
              const SizedBox(height: 12),
              Text(
                'Terimler hafızaya yazıldı! Toplam +$_xpEarned XP kazandın! 🧠🚀',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Dashboard\'a Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadGameData(),
                child: const Text('Yeni Tur Başlat 🔄', style: TextStyle(color: Colors.white30, fontSize: 11)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
