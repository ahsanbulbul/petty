import 'dart:convert';
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