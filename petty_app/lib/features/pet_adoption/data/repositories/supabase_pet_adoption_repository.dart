// lib/features/pet_adoption/data/repositories/supabase_pet_adoption_repository.dart
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_adoption.dart';

class SupabasePetAdoptionRepository {
  final SupabaseClient client;
  final String bucket = 'pet_images';

  SupabasePetAdoptionRepository(this.client);

  // Uploads an image file (File on mobile or Uint8List / XFile bytes on web)
  Future<String> uploadPetImage(String petId, dynamic imageFile, {String ext = 'jpg'}) async {
    final path = 'pet_images/$petId.$ext';

    Uint8List bytes;
    if (imageFile is File) {
      bytes = await imageFile.readAsBytes();
    } else if (imageFile is Uint8List) {
      bytes = imageFile;
    } else {
      // XFile from image_picker (web/mobile)
      bytes = await imageFile.readAsBytes();
    }

    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return path;
  }

  // Returns public URL for a path
  String getPublicImageUrl(String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  Future<PetAdoption> addPet(PetAdoption pet, {dynamic imageFile}) async {
    String? imagePath;
    String? imageUrl;
    
    if (imageFile != null) {
      imagePath = await uploadPetImage(pet.id, imageFile);
      imageUrl = getPublicImageUrl(imagePath);
    }

    final toInsert = pet.toJson();
    // Update with uploaded image data
    toInsert['image_path'] = imagePath ?? pet.imagePath;
    toInsert['image_url'] = imageUrl ?? pet.imageUrl;

    final response = await client
        .from('pets')
        .insert([toInsert])
        .select()
        .single();
    return PetAdoption.fromJson(response);
  }

  Future<List<PetAdoption>> getAllPets() async {
    final response = await client
        .from('pets')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => PetAdoption.fromJson(e)).toList();
  }

  Stream<List<PetAdoption>> watchAllPets() {
    final stream = client
        .from('pets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
    return stream.map((event) => 
        (event as List).map((e) => PetAdoption.fromJson(e)).toList());
  }

  Future<AdoptionRequest> requestAdoption(AdoptionRequest req) async {
    final response = await client
        .from('adoption_requests')
        .insert([req.toJson()])
        .select()
        .single();
    return AdoptionRequest.fromJson(response);
  }

  Stream<List<AdoptionRequest>> watchAdoptionRequests() {
    final stream = client
        .from('adoption_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
    return stream.map((event) => 
        (event as List).map((e) => AdoptionRequest.fromJson(e)).toList());
  }

  Future<List<AdoptionRequest>> getRequestsForPet(String petId) async {
    final response = await client
        .from('adoption_requests')
        .select()
        .eq('pet_id', petId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => AdoptionRequest.fromJson(e)).toList();
  }

  Future<List<AdoptionRequest>> getMyRequests(String userId) async {
    final response = await client
        .from('adoption_requests')
        .select()
        .eq('requester_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => AdoptionRequest.fromJson(e)).toList();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await client
        .from('adoption_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  Future<void> markPetAdopted(String petId) async {
    await client
        .from('pets')
        .update({'status': 'adopted'})
        .eq('id', petId);
  }

  Future<List<AdoptionRequest>> getRequestsForPets(List<String> petIds) async {
    if (petIds.isEmpty) return [];
    final response = await client
        .from('adoption_requests')
        .select()
        .in_('pet_id', petIds);
    return (response as List).map((e) => AdoptionRequest.fromJson(e)).toList();
  }

  /// Get adoption requests sent by current user WITH joined pet and owner details
  Future<List<AdoptionRequest>> getMySentRequestsWithDetails() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final response = await client
          .from('adoption_requests')
          .select('''
            *,
            pets:pet_id (
              id,
              name,
              image_url,
              image_path,
              type,
              age,
              gender,
              description
            ),
            owner:owner_id (
              id,
              email,
              raw_user_meta_data
            )
          ''')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdoptionRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching sent requests with details: $e');
      rethrow;
    }
  }

  /// Get adoption requests received by current user (as pet owner) WITH joined requester details
  Future<List<AdoptionRequest>> getMyReceivedRequestsWithDetails() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final response = await client
          .from('adoption_requests')
          .select('''
            *,
            pets:pet_id (
              id,
              name,
              image_url,
              image_path,
              type,
              age,
              gender,
              description
            ),
            requester:requester_id (
              id,
              email,
              raw_user_meta_data
            )
          ''')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AdoptionRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching received requests with details: $e');
      rethrow;
    }
  }
}