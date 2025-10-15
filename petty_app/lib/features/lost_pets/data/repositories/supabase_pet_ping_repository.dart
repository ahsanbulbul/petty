import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_ping.dart';
import '../../domain/repositories/pet_ping_repository.dart';

class SupabasePetPingRepository implements PetPingRepository {
  final SupabaseClient _client;
  
  SupabasePetPingRepository(this._client);

  @override
  Future<PetPing> addPetPing(PetPing ping) async {
    try {
      // Prepare data for insertion
      final data = {
        'pet_name': ping.petName,
        'pet_type': ping.petType,
        'description': ping.description,
        'location': 'SRID=4326;POINT(${ping.location.longitude} ${ping.location.latitude})',
        'is_lost': ping.isLost,
        'image_data': ping.imageData?.toList(), // Convert to List<int> for proper serialization
        'contact_info': ping.contactInfo,
        'timestamp': ping.timestamp.toIso8601String(),
      };

      print('Inserting data: $data');

      final List<dynamic> response = await _client
          .from('pet_pings')
          .insert(data)
          .select();

      print('Insert response: $response');

      if (response.isEmpty) {
        throw Exception('No data returned after insert');
      }

      final Map<String, dynamic> insertedData = Map<String, dynamic>.from(response[0]);
      return PetPing.fromJson(insertedData);
    } catch (e) {
      print('Error in addPetPing: $e');
      throw Exception('Failed to add pet ping: $e');
    }
  }

  Future<List<PetPing>> getAllLostPets() async {
    try {
      print('Fetching all lost pets...');
      final List<dynamic> response = await _client.rpc(
        'find_nearby_pings',
        params: {
          'search_lat': 23.8103, // Dhaka center
          'search_lng': 90.4125,
          'search_radius': 50000 // 50km radius to get all pets
        });

      print('Got response from getAllLostPets: $response');

      return response
          .map((json) => PetPing.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error getting lost pets: $e');
      return [];
    }
  }

  @override
  Future<List<PetPing>> getNearbyPings(LatLng location, {double radiusMeters = 5000}) async {
    try {
      final List<dynamic> response = await _client
          .rpc('find_nearby_pings', 
          params: {
            'search_lat': location.latitude,
            'search_lng': location.longitude,
            'search_radius': radiusMeters
          });

      return response
          .map((json) => PetPing.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error getting nearby pings: $e');
      return [];
    }
  }

  @override
  Future<PetPing?> getPetPingById(String id) async {
    final response = await _client
        .from('pet_pings')
        .select()
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return PetPing.fromJson(response);
  }

  @override
  Future<PetPing> updatePetPing(PetPing ping) async {
    final response = await _client
        .from('pet_pings')
        .update({
          'pet_name': ping.petName,
          'pet_type': ping.petType,
          'description': ping.description,
          'location': 'SRID=4326;POINT(${ping.location.longitude} ${ping.location.latitude})',
          'is_lost': ping.isLost,
          'image_data': ping.imageData,
          'contact_info': ping.contactInfo,
        })
        .eq('id', ping.id)
        .select()
        .single();

    return PetPing.fromJson(response);
  }

  @override
  Future<List<PetPing>> getAllPetPings({int limit = 10, int offset = 0}) async {
    final response = await _client
        .from('pet_pings')
        .select()
        .range(offset, offset + limit - 1)
        .order('timestamp', ascending: false);

    return response.map((json) => PetPing.fromJson(json)).toList();
  }
}