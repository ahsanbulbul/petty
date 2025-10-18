import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _client;
  final _picker = ImagePicker();

  StorageService(this._client);

  Future<String?> pickAndUploadImage() async {
    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Reasonable size for pet images
        maxHeight: 1024,
        imageQuality: 85, // Good quality while keeping file size reasonable
      );

      if (pickedFile == null) return null;

      // Generate unique filename
      final String filename = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      
      // Upload to Supabase storage
      final bytes = await pickedFile.readAsBytes();
      final String storageResponse = await uploadImage(bytes, filename);
      
      return storageResponse;
    } catch (e) {
      print('Error picking/uploading image: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(Uint8List fileBytes, String filename) async {
    try {
      // Upload directly to the bucket
      final String path = await _client.storage
          .from('pet-images')
          .uploadBinary(
            filename, 
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true // Allow overwriting if file exists
            )
          );

      // Get public URL
      final String publicUrl = _client.storage
          .from('pet-images')
          .getPublicUrl(filename);

      return publicUrl;
    } catch (e) {
      print('Error uploading to Supabase storage: $e');
      rethrow;
    }
  }
}