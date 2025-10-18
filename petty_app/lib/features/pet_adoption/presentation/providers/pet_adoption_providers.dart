// Alias Riverpod as 'riverpod' to avoid conflict
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:async/async.dart'; // for StreamZip
import '../../data/repositories/supabase_pet_adoption_repository.dart';
import '../../domain/entities/pet_adoption.dart';

// ------------------- Repository Provider -------------------
final petAdoptionRepositoryProvider =
    riverpod.Provider<SupabasePetAdoptionRepository>((ref) {
  return SupabasePetAdoptionRepository(Supabase.instance.client);
});

// ------------------- Pets List Stream -------------------
final petListProvider = riverpod.StreamProvider<List<PetAdoption>>((ref) {
  final repo = ref.watch(petAdoptionRepositoryProvider);
  return repo.watchAllPets();
});

// ------------------- Adoption Requests Stream -------------------
final adoptionRequestsStreamProvider =
    riverpod.StreamProvider<List<AdoptionRequest>>((ref) {
  final repo = ref.watch(petAdoptionRepositoryProvider);
  return repo.watchAdoptionRequests();
});

// ------------------- My Sent Requests (Simple) -------------------
final mySentRequestsProvider =
    riverpod.FutureProvider.autoDispose<List<AdoptionRequest>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final repo = ref.watch(petAdoptionRepositoryProvider);
  return repo.getMyRequests(userId);
});

// ------------------- My Sent Requests WITH DETAILS -------------------
final mySentRequestsWithDetailsProvider =
    riverpod.FutureProvider.autoDispose<List<AdoptionRequest>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  
  final client = Supabase.instance.client;
  
  try {
    // Fetch adoption requests
    final requestsResponse = await client
        .from('adoption_requests')
        .select('*')
        .eq('requester_id', userId)
        .order('created_at', ascending: false);

    final requests = (requestsResponse as List);
    
    if (requests.isEmpty) return [];
    
    // Get unique pet IDs and owner IDs
    final petIds = requests.map((r) => r['pet_id'] as String).toSet().toList();
    final ownerIds = requests
        .map((r) => r['owner_id'] as String?)
        .where((id) => id != null)
        .toSet()
        .toList();
    
    // Fetch pets
    final petsResponse = await client
        .from('pets')
        .select('*')
        .in_('id', petIds);
    
    final petsMap = {
      for (var pet in (petsResponse as List))
        pet['id'] as String: pet
    };
    
    // Fetch owners from auth.users
    Map<String, dynamic> ownersMap = {};
    if (ownerIds.isNotEmpty) {
      try {
        final ownersResponse = await client
            .from('auth.users')
            .select('id, email, raw_user_meta_data')
            .in_('id', ownerIds);
        ownersMap = {
          for (var owner in (ownersResponse as List))
            owner['id'] as String: owner
        };
      } catch (e) {
        // If auth.users query fails, just skip owner data
        print('Could not fetch owner data: $e');
      }
    }
    
    // Combine data
    return requests.map((req) {
      final petId = req['pet_id'] as String;
      final ownerId = req['owner_id'] as String?;
      
      return AdoptionRequest.fromJson({
        ...req,
        'pets': petsMap[petId],
        'owner': ownerId != null ? ownersMap[ownerId] : null,
      });
    }).toList();
  } catch (e) {
    print('Error in mySentRequestsWithDetailsProvider: $e');
    rethrow;
  }
});

// ------------------- My Received Requests WITH DETAILS -------------------
final myReceivedRequestsWithDetailsProvider =
    riverpod.FutureProvider.autoDispose<List<AdoptionRequest>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  
  final client = Supabase.instance.client;
  
  try {
    // Fetch adoption requests for my pets
    final requestsResponse = await client
        .from('adoption_requests')
        .select('*')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);

    final requests = (requestsResponse as List);
    
    if (requests.isEmpty) return [];
    
    // Get unique pet IDs
    final petIds = requests.map((r) => r['pet_id'] as String).toSet().toList();
    
    // Fetch pets
    final petsResponse = await client
        .from('pets')
        .select('*')
        .in_('id', petIds);
    
    final petsMap = {
      for (var pet in (petsResponse as List))
        pet['id'] as String: pet
    };
    
    // For requesters, we'll use the requester_id and create a simple display name
    // You can enhance this later by creating a user_profiles table
    final requestersMap = <String, Map<String, dynamic>>{};
    for (var req in requests) {
      final requesterId = req['requester_id'] as String;
      if (!requestersMap.containsKey(requesterId)) {
        requestersMap[requesterId] = {
          'id': requesterId,
          'email': 'Requester ${requesterId.substring(0, 8)}',
          'raw_user_meta_data': {'name': 'User ${requesterId.substring(0, 8)}'},
        };
      }
    }
    
    // Combine data
    return requests.map((req) {
      final petId = req['pet_id'] as String;
      final requesterId = req['requester_id'] as String;
      
      return AdoptionRequest.fromJson({
        ...req,
        'pets': petsMap[petId],
        'requester': requestersMap[requesterId],
      });
    }).toList();
  } catch (e) {
    print('Error in myReceivedRequestsWithDetailsProvider: $e');
    rethrow;
  }
});

// ------------------- Requests for My Pets (Owner View - Stream) -------------------
final requestsForMyPetsProvider =
    riverpod.StreamProvider.autoDispose<List<AdoptionRequest>>((ref) {
  final repo = ref.watch(petAdoptionRepositoryProvider);

  final petStream = repo.watchAllPets();
  final reqStream = repo.watchAdoptionRequests();

  return StreamZip([petStream, reqStream]).asyncMap((lists) async {
    final pets = lists[0] as List<PetAdoption>;
    final reqs = lists[1] as List<AdoptionRequest>;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return <AdoptionRequest>[];

    final myPetIds = pets.where((p) => p.ownerId == userId).map((p) => p.id).toSet();
    final filtered = reqs.where((r) => myPetIds.contains(r.petId)).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  });
});