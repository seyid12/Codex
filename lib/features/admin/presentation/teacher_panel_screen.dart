import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../study_modes/data/deck_repository.dart';
import '../../study_modes/domain/card_model.dart';
import '../../study_modes/domain/deck_model.dart';

class TeacherPanelScreen extends ConsumerStatefulWidget {
  const TeacherPanelScreen({super.key});

  @override
  ConsumerState<TeacherPanelScreen> createState() => _TeacherPanelScreenState();
}

class _TeacherPanelScreenState extends ConsumerState<TeacherPanelScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isCreatingNewDeck = false;
  String? _selectedDeckId;

  // Yeni deste için
  final _deckTitleController = TextEditingController();
  final _deckCategoryController = TextEditingController();

  // Soru için
  String _selectedCardType = 'flashcard'; // 'flashcard' or 'quiz'
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _mnemonicController = TextEditingController();

  // Quiz için
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctOptionIndex = 0;

  bool _isLoading = false;

  @override
  void dispose() {
    _deckTitleController.dispose();
    _deckCategoryController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _mnemonicController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Quiz validasyonu
    if (_selectedCardType == 'quiz') {
      for (var c in _optionControllers) {
        if (c.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tüm şıkları doldurmalısınız!')),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(deckRepositoryProvider);
      final user = ref.read(authRepositoryProvider).currentUser;
      final creatorId = user?.uid ?? 'admin';

      String targetDeckId = _selectedDeckId ?? '';

      // Eğer yeni deste oluşturuluyorsa
      if (_isCreatingNewDeck) {
        final newDeck = DeckModel(
          id: '', // Firestore oluşturacak
          title: _deckTitleController.text.trim(),
          category: _deckCategoryController.text.trim(),
          creatorId: creatorId,
          createdAt: DateTime.now(),
        );
        targetDeckId = await repo.createDeck(newDeck);
        _selectedDeckId = targetDeckId;
      }

      if (targetDeckId.isEmpty) {
        throw Exception('Lütfen bir deste seçin veya oluşturun');
      }

      // Soru oluşturma
      final newCard = CardModel(
        id: '', // Firestore oluşturacak
        cardType: _selectedCardType,
        question: _questionController.text.trim(),
        answer: _selectedCardType == 'quiz' ? _optionControllers[_correctOptionIndex].text.trim() : _answerController.text.trim(),
        mnemonic: _mnemonicController.text.trim(),
        options: _selectedCardType == 'quiz' ? _optionControllers.map((c) => c.text.trim()).toList() : [],
        correctOptionIndex: _selectedCardType == 'quiz' ? _correctOptionIndex : 0,
      );

      await repo.addCardToDeck(targetDeckId, newCard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soru başarıyla eklendi! 🎉'), backgroundColor: Colors.green),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _questionController.clear();
    _answerController.clear();
    _mnemonicController.clear();
    for (var c in _optionControllers) {
      c.clear();
    }
    _correctOptionIndex = 0;
    // Deste seçimi aynı kalır ki öğretmen aynı desteye hızlıca soru eklemeye devam etsin.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen / Yönetici Paneli'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDeckSection(),
                    const Divider(height: 48, color: Colors.white24),
                    _buildCardTypeSection(),
                    const SizedBox(height: 24),
                    _buildQuestionSection(),
                    const SizedBox(height: 24),
                    if (_selectedCardType == 'flashcard') _buildFlashcardSection() else _buildQuizSection(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _mnemonicController,
                      decoration: const InputDecoration(
                        labelText: 'Hafıza İpucu / Mnemonic (İsteğe Bağlı)',
                        prefixIcon: Icon(Icons.lightbulb_outline),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _saveData,
                      icon: const Icon(Icons.save),
                      label: const Text('Soruyu Kaydet'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDeckSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Deste Seçimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Row(
                  children: [
                    const Text('Yeni Deste'),
                    Switch(
                      value: _isCreatingNewDeck,
                      onChanged: (val) {
                        setState(() {
                          _isCreatingNewDeck = val;
                          if (val) _selectedDeckId = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            Text(_isCreatingNewDeck ? 'Yeni Deste Oluştur' : 'Var Olan Desteyi Seç', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            if (_isCreatingNewDeck) ...[
              TextFormField(
                controller: _deckTitleController,
                decoration: const InputDecoration(labelText: 'Deste Başlığı (Örn: Ceza Hukuku)'),
                validator: (val) => val != null && val.isEmpty ? 'Başlık boş olamaz' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deckCategoryController,
                decoration: const InputDecoration(labelText: 'Kategori (Örn: hukuk)'),
                validator: (val) => val != null && val.isEmpty ? 'Kategori boş olamaz' : null,
              ),
            ] else ...[
              FutureBuilder<List<DeckModel>>(
                future: ref.read(deckRepositoryProvider).getAvailableDecks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Kayıtlı deste bulunamadı. Lütfen "Yeni Deste" oluşturun.', style: TextStyle(color: Colors.redAccent));
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Desteler'),
                    value: _selectedDeckId,
                    items: snapshot.data!.map((deck) {
                      return DropdownMenuItem(value: deck.id, child: Text(deck.title));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDeckId = val),
                    validator: (val) => val == null ? 'Lütfen bir deste seçin' : null,
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeSection() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'flashcard', label: Text('Flashcard'), icon: Icon(Icons.flip)),
        ButtonSegment(value: 'quiz', label: Text('Quiz'), icon: Icon(Icons.quiz)),
      ],
      selected: {_selectedCardType},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() => _selectedCardType = newSelection.first);
      },
    );
  }

  Widget _buildQuestionSection() {
    return TextFormField(
      controller: _questionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Soru Metni',
        alignLabelWithHint: true,
      ),
      validator: (val) => val != null && val.isEmpty ? 'Soru boş olamaz' : null,
    );
  }

  Widget _buildFlashcardSection() {
    return TextFormField(
      controller: _answerController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Cevap',
        alignLabelWithHint: true,
      ),
      validator: (val) => val != null && val.isEmpty ? 'Cevap boş olamaz' : null,
    );
  }

  Widget _buildQuizSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Şıklar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctOptionIndex,
                      onChanged: (val) => setState(() => _correctOptionIndex = val!),
                      activeColor: Colors.greenAccent,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Şık ${i + 1}',
                          filled: true,
                          fillColor: _correctOptionIndex == i ? Colors.green.withOpacity(0.1) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Text('Doğru olan şıkkın yanındaki yuvarlağı seçin.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
