import 'package:latlong2/latlong.dart';
import '../entities/pet_ping.dart';

abstract class PetPingRepository {
  /// Add a new pet ping and bind to user
  Future<PetPing> addPetPingForUser(PetPing ping, String userId);
  /// Add a new pet ping
  Future<PetPing> addPetPing(PetPing ping);

  /// Get all pet pings within a radius (in meters) of a location
  Future<List<PetPing>> getNearbyPings(LatLng location, {double radiusMeters = 5000});

  /// Get a specific pet ping by ID
  Future<PetPing?> getPetPingById(String id);

  /// Update a pet ping status
  Future<PetPing> updatePetPing(PetPing ping);

  /// Get all pet pings (with optional limit and offset for pagination)
  Future<List<PetPing>> getAllPetPings({int limit = 10, int offset = 0});
}