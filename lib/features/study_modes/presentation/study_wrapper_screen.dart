import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/deck_repository.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

final deckCardsProvider = FutureProvider.family<List<dynamic>, String>((ref, deckId) async {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.getCardsForDeck(deckId);
});

class StudyWrapperScreen extends ConsumerStatefulWidget {
  final String deckId;
  const StudyWrapperScreen({super.key, required this.deckId});

  @override
  ConsumerState<StudyWrapperScreen> createState() => _StudyWrapperScreenState();
}

class _StudyWrapperScreenState extends ConsumerState<StudyWrapperScreen> {
  int _currentIndex = 0;

  void _nextCard() {
    setState(() {
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(deckCardsProvider(widget.deckId));

    return Scaffold(
      appBar: AppBar(title: const Text('Çalışma Modu')),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('Bu destede hiç kart yok.'));
          }
          if (_currentIndex >= cards.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tebrikler! Desteyi tamamladınız. 🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Dashboard\'a Dön'),
                  )
                ],
              ),
            );
          }

          final currentCard = cards[_currentIndex];
          
          if (currentCard.cardType == 'quiz') {
            return QuizScreen(card: currentCard, onNext: _nextCard);
          } else {
            return FlashcardScreen(card: currentCard, onNext: _nextCard);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
      ),
    );
  }
}
