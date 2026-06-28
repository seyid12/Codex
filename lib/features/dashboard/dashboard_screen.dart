import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../study_modes/data/deck_repository.dart';
import '../study_modes/domain/deck_model.dart';

final availableDecksProvider = FutureProvider<List<DeckModel>>((ref) async {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.getAvailableDecks();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(availableDecksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CODEX'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                const SizedBox(width: 4),
                Text(
                  '12', // Mock streak
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günün Hedefi 🎯',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.secondary),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('50 Kart Tekrarı', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 0.6,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Destelerim 📚',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: decksAsync.when(
                data: (decks) => ListView.separated(
                  itemCount: decks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Kategori: ${deck.category}'),
                        trailing: Icon(Icons.play_circle_fill, color: Theme.of(context).primaryColor, size: 36),
                        onTap: () {
                          context.push('/study/${deck.id}');
                        },
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Hata: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/teacher-panel'),
        backgroundColor: const Color(0xFF00F0FF),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}
