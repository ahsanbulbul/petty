import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_ping.dart';
import '../../domain/repositories/pet_ping_repository.dart';

class SupabasePetPingRepository implements PetPingRepository {

  // Get all pings posted by a specific user using the join table
  Future<List<PetPing>> getPingsByUser(String userId) async {
  final response = await _client
    .from('user_pet_pings')
    .select('pet_pings(*)')
    .eq('user_id', userId);
  print('user_pet_pings response: $response');
  // Only map rows where pet_pings is not null, then sort by timestamp descending
  final List<PetPing> pings = response
    .where((row) => row['pet_pings'] != null)
    .map<PetPing>((row) => PetPing.fromJson(row['pet_pings']))
    .toList();
  pings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return pings;
  }

  // Delete a ping by id for a user (removes from pet_pings and associated user_pet_pings entries)
  Future<void> deletePing(String pingId, {String? userId}) async {
    try {
      print('Starting deletion process for pingId: $pingId, userId: $userId');

      if (userId == null) {
        throw Exception('userId is required for deletion');
      }

      // First verify the ping exists and belongs to the user
      final verify = await _client
          .from('user_pet_pings')
          .select()
          .eq('user_id', userId)
          .eq('pet_ping_id', pingId)
          .single();
      
      if (verify == null) {
        throw Exception('Ping not found or does not belong to the user');
      }

      print('Verified ping ownership, proceeding with deletion');

      // Delete from user_pet_pings first
      final userPingResponse = await _client
          .from('user_pet_pings')
          .delete()
          .eq('user_id', userId)
          .eq('pet_ping_id', pingId)
          .select();  // Add .select() to get response data
      
      if (userPingResponse == null || userPingResponse.isEmpty) {
        throw Exception('Failed to delete from user_pet_pings');
      }
      print('Successfully deleted from user_pet_pings: $userPingResponse');

      // Then delete from pet_pings with explicit error handling
      try {
        print('Attempting to delete ping with direct SQL via RPC...');
        await _client.rpc(
          'delete_pet_ping',
          params: {'ping_id': pingId}
        );
        
        // Verify deletion
        final verifyDeleted = await _client
            .from('pet_pings')
            .select()
            .eq('id', pingId)
            .maybeSingle();
            
        if (verifyDeleted != null) {
          print('Verification failed - ping still exists after deletion');
          throw Exception('Ping still exists after deletion attempt');
        }
        
        print('Successfully verified deletion from pet_pings');
      } catch (e) {
        print('Error in pet_pings deletion: $e');
        throw Exception('Failed to delete from pet_pings: $e');
      }

    } catch (e, stackTrace) {
      print('Error during deletion: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to delete ping: $e');
    }
  }

  // Add a new pet ping and bind to user
  Future<PetPing> addPetPingForUser(PetPing ping, String userId) async {
    final newPing = await addPetPing(ping);
    await _client.from('user_pet_pings').insert({
      'user_id': userId,
      'pet_ping_id': newPing.id,
    });
    return newPing;
  }
  final SupabaseClient _client;
  
  SupabasePetPingRepository(this._client);

  @override
  Future<PetPing> addPetPing(PetPing ping) async {
    try {
      // Prepare data for insertion
      final data = {
  'title': ping.title,
  'pet_type': ping.petType,
  'gender': ping.gender,
        'description': ping.description,
        'location': 'SRID=4326;POINT(${ping.location.longitude} ${ping.location.latitude})',
        'is_lost': ping.isLost,
        'images': ping.images?.map((img) => base64Encode(img)).toList(),
        'contact_info': ping.contactInfo,
        'timestamp': ping.timestamp.toIso8601String(),
      };

      print('Inserting data: $data');

      if (data['images'] != null) {
        print('Images present: ${(data['images'] as List).length} images');
      }
      
      final List<dynamic> response = await _client
          .from('pet_pings')
          .insert(data)
          .select();
          
      print('Response from insert: ${response.first}');
      print('Response from insert: $response');

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

      return response.map((json) {
        // Convert response to Map<String, dynamic>
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);
        
        // Handle the transition period where we might get either images or image_data
        if (data['image_data'] != null && !data.containsKey('images')) {
          data['images'] = [data['image_data']];
          data.remove('image_data');
        }
        
        return PetPing.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting lost pets: $e');
      if (e.toString().contains('column p.image_data does not exist')) {
        // If the error is about the missing column, try to fetch with a simpler query
        try {
          final response = await _client
              .from('pet_pings')
              .select()
              .eq('is_lost', true)
              .order('timestamp', ascending: false);
          
          return response.map((json) => PetPing.fromJson(json)).toList();
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }
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

      return response.map((json) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(json);
        
        // Handle the transition period where we might get either images or image_data
        if (data['image_data'] != null && !data.containsKey('images')) {
          data['images'] = [data['image_data']];
          data.remove('image_data');
        }
        
        return PetPing.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting nearby pings: $e');
      if (e.toString().contains('column p.image_data does not exist')) {
        // If the error is about the missing column, try to fetch with a simpler query
        try {
          final response = await _client
              .from('pet_pings')
              .select()
              .not('location', 'is', null) // Ensure location exists
              .order('created_at', ascending: false)
              .order('timestamp', ascending: false);
          
          return response.map((json) => PetPing.fromJson(json)).toList();
        } catch (fallbackError) {
          print('Fallback query also failed: $fallbackError');
          return [];
        }
      }
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
          'title': ping.title,
          'pet_type': ping.petType,
          'gender': ping.gender,
          'description': ping.description,
          'location': 'SRID=4326;POINT(${ping.location.longitude} ${ping.location.latitude})',
          'is_lost': ping.isLost,
          'images': ping.images?.map((img) => base64Encode(img)).toList(),
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