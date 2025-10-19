import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet_match.dart';
import '../../domain/repositories/pet_matching_repository.dart';

import 'package:http/http.dart' as http;
import '../../data/repositories/pet_matching_repository_impl.dart';

final petMatchingRepositoryProvider = Provider<PetMatchingRepository>((ref) {
  final client = http.Client();
  return PetMatchingRepositoryImpl(client: client);
});

final petMatchesProvider = FutureProvider<List<PetMatch>>((ref) async {
  try {
    final repository = ref.read(petMatchingRepositoryProvider);
    if (!await repository.checkApiHealth()) {
      throw Exception('Matching service is not available');
    }
    
    print('Checking for matches...');
    
    // Get matches for lost and found pets
    final userMatches = await repository.getCurrentUserMatches();
    print('User matches fetched: ${userMatches.length}');
    
    return userMatches;
  } catch (e) {
    throw Exception('Failed to load matches: $e');
  }
});

final petMatchesStateProvider = StateNotifierProvider<PetMatchesNotifier, List<PetMatch>>((ref) {
  return PetMatchesNotifier();
});

class PetMatchesNotifier extends StateNotifier<List<PetMatch>> {
  PetMatchesNotifier() : super([]);

  void addMatch(PetMatch match) {
    state = [...state, match];
  }

  void removeMatch(String id) {
    state = state.where((match) => match.id != id).toList();
  }

  void updateMatch(PetMatch updatedMatch) {
    state = state.map((match) => 
      match.id == updatedMatch.id ? updatedMatch : match
    ).toList();
  }

  void markAsResolved(String id) {
    state = state.map((match) => 
      match.id == id ? match.copyWith(isResolved: true) : match
    ).toList();
  }
}