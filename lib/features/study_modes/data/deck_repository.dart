import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/card_model.dart';
import '../domain/deck_model.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(FirebaseFirestore.instance);
});

class DeckRepository {
  final FirebaseFirestore _firestore;

  DeckRepository(this._firestore);

  Future<List<DeckModel>> getAvailableDecks() async {
    try {
      final snapshot = await _firestore.collection('decks').get();
      return snapshot.docs.map((doc) => DeckModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      // Return mock data if Firebase is not configured yet
      return [
        DeckModel(
          id: 'mock_deck_1',
          title: '657 Sayılı DMK Temel İlkeler',
          category: '657_dmk',
          creatorId: 'admin',
          createdAt: DateTime.now(),
        ),
        DeckModel(
          id: 'mock_deck_2',
          title: 'Kamu İhale Kanunu Kavramları',
          category: 'kik',
          creatorId: 'admin',
          createdAt: DateTime.now(),
        ),
        DeckModel(
          id: 'mock_deck_3',
          title: 'Tıbbi Sekreterlik Anatomi',
          category: 'medical',
          creatorId: 'admin',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  Future<List<CardModel>> getCardsForDeck(String deckId) async {
    try {
      final snapshot = await _firestore
          .collection('decks')
          .doc(deckId)
          .collection('cards')
          .get();
      return snapshot.docs.map((doc) => CardModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      // Return mock data if Firebase is not configured yet
      if (deckId == 'mock_deck_1') {
        return [
          CardModel(
            id: 'card_1',
            cardType: 'flashcard',
            question: 'Devlet memurlarının sadakat yükümlülüğü hangi kanun maddesinde geçer?',
            answer: 'Madde 6',
            mnemonic: 'Sadakat => 6 harfli (Altı)',
          ),
          CardModel(
            id: 'card_2',
            cardType: 'quiz',
            question: 'Aşağıdakilerden hangisi memurluk mesleğinin temel ilkelerinden biridir?',
            answer: 'Liyakat',
            options: ['Kıdem', 'Liyakat', 'Yaş', 'Zenginlik'],
            correctOptionIndex: 1,
          ),
        ];
      }
      return [];
    }
  }
}
