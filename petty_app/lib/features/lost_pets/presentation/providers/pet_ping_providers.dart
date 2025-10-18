import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_app/core/services/supabase_service.dart';
import 'package:petty_app/core/services/storage_service.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/supabase_pet_ping_repository.dart';
import '../../domain/repositories/pet_ping_repository.dart';
import '../../domain/entities/pet_filter.dart';
import '../../domain/entities/pet_ping.dart';
import 'pet_filter_provider.dart';

final petPingRepositoryProvider = Provider<PetPingRepository>((ref) {
  return SupabasePetPingRepository(SupabaseService.client);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(SupabaseService.client);
});

final filteredPetPingsProvider = FutureProvider<List<PetPing>>((ref) async {
  final repository = ref.read(petPingRepositoryProvider);
  final filter = ref.watch(petFilterProvider);

  final pings = await repository.getAllPetPings();

  return pings.where((ping) {
    // Apply status filter
    if (filter.isLost != null && ping.isLost != filter.isLost) {
      return false;
    }

    // Apply gender filter
    if (filter.gender != null && ping.gender != filter.gender) {
      return false;
    }

    // Apply pet type filter
    if (filter.petType != null && ping.petType != filter.petType) {
      return false;
    }

    // Apply time range filter
    if (filter.startTime != null && ping.timestamp.isBefore(filter.startTime!)) {
      return false;
    }
    if (filter.endTime != null && ping.timestamp.isAfter(filter.endTime!)) {
      return false;
    }

    return true;
  }).toList();
});