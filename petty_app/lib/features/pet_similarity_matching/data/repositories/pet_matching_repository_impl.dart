import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petty_app/core/config/env.dart';
import '../../../lost_pets/domain/entities/pet_ping.dart';
import '../../domain/repositories/pet_matching_repository.dart';
import '../../domain/entities/pet_match.dart';

class PetMatchingRepositoryImpl implements PetMatchingRepository {
  final http.Client _client;

  PetMatchingRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PetMatch.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error submitting lost pet: $e');
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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PetMatch.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error submitting found pet: $e');
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
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking API health: $e');
      return false;
    }
  }
}