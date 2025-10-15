import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_app/core/services/supabase_service.dart';
import 'package:petty_app/core/services/storage_service.dart';
import '../../data/repositories/supabase_pet_ping_repository.dart';
import '../../domain/repositories/pet_ping_repository.dart';

final petPingRepositoryProvider = Provider<PetPingRepository>((ref) {
  return SupabasePetPingRepository(SupabaseService.client);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(SupabaseService.client);
});