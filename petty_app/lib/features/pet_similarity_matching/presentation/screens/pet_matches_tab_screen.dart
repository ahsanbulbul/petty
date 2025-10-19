import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_matches_provider.dart';
import '../widgets/match_card.dart';

class PetMatchesTabScreen extends ConsumerWidget {
  const PetMatchesTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(petMatchesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pet Matches'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lost Pet Matches'),
              Tab(text: 'Found Pet Matches'),
            ],
          ),
        ),
        body: matches.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error loading matches: $error'),
          ),
          data: (data) {
            // Show best_match for each ping as the post card
            final lostMatches = data.where((m) => !m.isResolved && m.isMatch).toList();
            final foundMatches = data.where((m) => !m.isResolved && !m.isMatch).toList();

            return TabBarView(
              children: [
                // Lost Pet Matches (best_match only)
                lostMatches.isEmpty
                    ? const Center(child: Text('No matches found for lost pets'))
                    : ListView.builder(
                        itemCount: lostMatches.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MatchCard(match: lostMatches[index]),
                        ),
                      ),

                // Found Pet Matches (best_match only)
                foundMatches.isEmpty
                    ? const Center(child: Text('No matches found for found pets'))
                    : ListView.builder(
                        itemCount: foundMatches.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MatchCard(match: foundMatches[index]),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}