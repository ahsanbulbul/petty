import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petty_app/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../lost_pets/domain/entities/pet_ping.dart';
import '../../domain/repositories/pet_matching_repository.dart';
import '../../domain/entities/pet_match.dart';

Map<String, double?> parseLocation(dynamic loc) {
  if (loc is String && loc.length >= 50) {
    try {
      final endianFlag = loc.substring(0, 2);
      final littleEndian = endianFlag == '01';
      final lonHex = loc.substring(18, 34);
      final latHex = loc.substring(34, 50);

      final lon = _hexToDouble(lonHex, littleEndian: littleEndian);
      final lat = _hexToDouble(latHex, littleEndian: littleEndian);

      return {'latitude': lat, 'longitude': lon};
    } catch (e) {
      print('WKB parse error: $e');
      return {'latitude': null, 'longitude': null};
    }
  }
  return {'latitude': null, 'longitude': null};
}


double? _hexToDouble(String hex, {bool littleEndian = true}) {
  final bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
  return byteData.getFloat64(0, littleEndian ? Endian.little : Endian.big);
}


class PetMatchingRepositoryImpl implements PetMatchingRepository {
  final http.Client _client;
  final SupabaseClient _supabase;

  PetMatchingRepositoryImpl({http.Client? client}) 
    : _client = client ?? http.Client(),
      _supabase = Supabase.instance.client;

  @override
  Future<PetMatch?> submitLostPet(PetPing ping) async {
    try {
      // Convert first image to base64 if available
      final imageData = ping.images?.isNotEmpty == true 
          ? base64Encode(ping.images!.first)
          : null;
      
      final response = await _client.post(
        Uri.parse('${Env.matchServiceUrl}/lost'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': Env.matchServiceApiKey,
        },
        body: jsonEncode({
          'id': ping.id,
          'imageData': imageData,
          'location': {
            'latitude': ping.location.latitude,
            'longitude': ping.location.longitude,
          },
          'timestamp': ping.timestamp.toIso8601String(),
          'description': ping.description,
          'petType': ping.petType,
          'title': ping.title,
        }),
      );

      print('Lost pet submission response status: ${response.statusCode}');
      print('Lost pet submission response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Lost pet parsed data: $data');
        return PetMatch.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      print('Error submitting lost pet: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<PetMatch?> submitFoundPet(PetPing ping) async {
    try {
      // Convert first image to base64 if available
      final imageData = ping.images?.isNotEmpty == true 
          ? base64Encode(ping.images!.first)
          : null;
          
      final response = await _client.post(
        Uri.parse('${Env.matchServiceUrl}/found'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': Env.matchServiceApiKey,
        },
        body: jsonEncode({
          'id': ping.id,
          'imageData': imageData,
          'location': {
            'latitude': ping.location.latitude,
            'longitude': ping.location.longitude,
          },
          'timestamp': ping.timestamp.toIso8601String(),
          'description': ping.description,
          'petType': ping.petType,
          'title': ping.title,
        }),
      );

      print('Found pet submission response status: ${response.statusCode}');
      print('Found pet submission response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Found pet parsed data: $data');
        return PetMatch.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      print('Error submitting found pet: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<bool> markLostPetAsSolved(String id) async {
    try {
      final response = await _client.post(
        Uri.parse('${Env.matchServiceUrl}/solvedlost/$id'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': Env.matchServiceApiKey,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking lost pet as solved: $e');
      return false;
    }
  }

  @override
  Future<bool> markFoundPetAsSolved(String id) async {
    try {
      final response = await _client.post(
        Uri.parse('${Env.matchServiceUrl}/solvedfound/$id'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': Env.matchServiceApiKey,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking found pet as solved: $e');
      return false;
    }
  }

  @override
  Future<bool> checkApiHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('${Env.matchServiceUrl}/health'),
        headers: {
          'X-API-Key': Env.matchServiceApiKey,
        },
      );
      print('Health check response status: ${response.statusCode}');
      print('Health check response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      print('Error checking API health: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<List<PetMatch>> getCurrentUserMatches() async {
    try {
      // Get current user's info
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

    // Step 1: Get user's pet_ping_ids from user_pet_pings
    final userPosts = await _supabase
      .from('user_pet_pings')
      .select()
      .eq('user_id', user.id);

    // Step 2: Get all pet_pings that match those ids
    final petPingIds = userPosts.map((row) => row['pet_ping_id']).toList();
    final userPings = await _supabase
      .from('pet_pings')
      .select()
      .in_('id', petPingIds)
      .order('created_at', ascending: false);

      print('Found ${userPings.length} pings for current user');
      List<PetMatch> allMatches = [];

      // Process each ping
      for (final ping in userPings) {
  print('Raw location value for ping ${ping['id']}: ${ping['location']}');
        final endpoint = ping['is_lost'] == true ? '/lost' : '/found';
        print('Processing ${ping['is_lost'] ? 'lost' : 'found'} pet ping: ${ping['id']}');

        // Convert image to base64 if available
        final imageBase64 = ping['images'] != null && (ping['images'] as List).isNotEmpty
            ? ping['images'][0].toString()
            : null;

        // Use robust location parsing utility
        final locParsed = parseLocation(ping['location']);
        final latitude = locParsed['latitude'];
        final longitude = locParsed['longitude'];

        try {
          final response = await _client.post(
            Uri.parse('${Env.matchServiceUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': Env.matchServiceApiKey,
            },
            body: jsonEncode({
              'id': ping['id'],
              'pet_type': ping['pet_type'],
              'latitude': latitude,
              'longitude': longitude,
              'timestamp': ping['created_at'],
              'imageData': imageBase64,
              'gender': ping['gender'] ?? 'unknown',
              'description': ping['description'],
              'title': ping['title'],
            }),
          );

          print('Match response for ${ping['id']} status: ${response.statusCode}');
          print('Match response body: ${response.body}');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data != null) {
              if (data is List) {
                allMatches.addAll(
                  data.map((item) => PetMatch.fromJson(Map<String, dynamic>.from(item))).toList()
                );
              } else if (data is Map<String, dynamic>) {
                allMatches.add(PetMatch.fromJson(data));
              }
            }
          }
        } catch (e) {
          print('Error processing ping ${ping['id']}: $e');
          // Continue with next ping
          continue;
        }
      }

      print('Found ${allMatches.length} total matches');
      return allMatches;
    } catch (e, stackTrace) {
      print('Error getting matches: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}