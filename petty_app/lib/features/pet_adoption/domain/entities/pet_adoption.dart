// lib/features/pet_adoption/domain/entities/pet_adoption.dart
//import 'package:flutter/foundation.dart';

// lib/features/pet_adoption/domain/entities/pet_adoption.dart
// REPLACE your PetAdoption class with this updated version:

class PetAdoption {
  final String id;
  final String name;
  final String type;
  final int age;
  final String gender;
  final String? description;
  final String? location;
  final String? contactNumber; // ADD THIS FIELD
  final String? imagePath;
  final String? imageUrl;
  final String ownerId;
  final String? status;
  final DateTime createdAt;

  PetAdoption({
    required this.id,
    required this.name,
    required this.type,
    required this.age,
    required this.gender,
    this.description,
    this.location,
    this.contactNumber, // ADD THIS
    this.imagePath,
    this.imageUrl,
    required this.ownerId,
    this.status,
    required this.createdAt,
  });

  factory PetAdoption.fromJson(Map<String, dynamic> json) => PetAdoption(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        age: (json['age'] is int) 
            ? json['age'] as int 
            : int.tryParse((json['age'] ?? '0').toString()) ?? 0,
        gender: json['gender'] as String? ?? 'unknown',
        description: json['description'] as String?,
        location: json['location'] as String?,
        contactNumber: json['contact_number'] as String?, // ADD THIS
        imagePath: json['image_path'] as String?,
        imageUrl: json['image_url'] as String?,
        ownerId: json['owner_id'] as String,
        status: json['status'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'age': age,
        'gender': gender,
        'description': description,
        'location': location,
        'contact_number': contactNumber, // ADD THIS
        'image_path': imagePath,
        'image_url': imageUrl,
        'owner_id': ownerId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  bool get adopted => status == 'adopted';
}
// lib/features/pet_adoption/domain/entities/pet_adoption.dart
// REPLACE your existing AdoptionRequest class with this updated version:

class AdoptionRequest {
  final String id;
  final String petId;
  final String requesterId;
  final String? ownerId; // ADD THIS FIELD
  final String? message;
  final String status;
  final DateTime createdAt;
  
  // ADD THESE JOINED DATA FIELDS
  final Map<String, dynamic>? pet;
  final Map<String, dynamic>? owner;
  final Map<String, dynamic>? requester;

  AdoptionRequest({
    required this.id,
    required this.petId,
    required this.requesterId,
    this.ownerId, // ADD THIS
    this.message,
    required this.status,
    required this.createdAt,
    this.pet, // ADD THIS
    this.owner, // ADD THIS
    this.requester, // ADD THIS
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    return AdoptionRequest(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      requesterId: json['requester_id'] as String,
      ownerId: json['owner_id'] as String?, // ADD THIS
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      pet: json['pets'] as Map<String, dynamic>?, // ADD THIS
      owner: json['owner'] as Map<String, dynamic>?, // ADD THIS
      requester: json['requester'] as Map<String, dynamic>?, // ADD THIS
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'requester_id': requesterId,
        'owner_id': ownerId, // ADD THIS
        'message': message,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  // ADD THESE HELPER GETTERS
  String get petName => pet?['name'] as String? ?? 'Unknown Pet';
  String? get petImageUrl => pet?['image_url'] as String?;
  String? get petImagePath => pet?['image_path'] as String?;
  String? get petType => pet?['type'] as String?;
  int? get petAge => pet?['age'] as int?;
  String? get petGender => pet?['gender'] as String?;
  
  String get ownerName => _extractUserName(owner);
  String get requesterName => _extractUserName(requester);
  String get ownerEmail => owner?['email'] as String? ?? 'Unknown';
  String get requesterEmail => requester?['email'] as String? ?? 'Unknown';

  String _extractUserName(Map<String, dynamic>? user) {
    if (user == null) return 'Unknown User';
    
    // Try to get name from metadata
    final metadata = user['raw_user_meta_data'] as Map<String, dynamic>?;
    if (metadata != null) {
      final name = metadata['name'] ?? metadata['full_name'];
      if (name != null) return name as String;
    }
    
    // Fall back to email username
    final email = user['email'] as String?;
    if (email != null) {
      return email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
    }
    
    return 'Unknown User';
  }
}
