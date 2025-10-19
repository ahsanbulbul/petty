import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_matches_provider.dart';
import '../widgets/match_card.dart';

class PetMatchesTabScreen extends ConsumerWidget {
  const PetMatchesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final matches = ref.watch(petMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Matches',
            onPressed: () {
              ref.invalidate(petMatchesProvider);
            },
          ),
        ],
      ),
      body: matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading matches: $error'),
        ),
        data: (data) {
          final visibleMatches = data.where((m) => !m.isResolved).toList();
          return visibleMatches.isEmpty
              ? const Center(child: Text('No matches found'))
              : ListView.builder(
                  itemCount: visibleMatches.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MatchCard(match: visibleMatches[index]),
                  ),
                );
        },
      ),
    );
  }
}