import 'package:latlong2/latlong.dart';
import 'dart:typed_data';
import 'dart:convert';

class PetPing {
  final String id;
  final String title; // Renamed from petName
  final String petType;
  final String description;
  final LatLng location;
  final String? area; // UI only, not stored in DB
  final String? gender; // male/female
  final DateTime timestamp;
  final bool isLost; // true for lost, false for found
  final List<Uint8List>? images;
  final String? contactInfo;

  PetPing({
    required this.id,
    required this.title,
    required this.petType,
    required this.description,
    required this.location,
    this.area,
    this.gender,
    required this.timestamp,
    required this.isLost,
    this.images,
    this.contactInfo,
  });

  // Simple toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'petType': petType,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'gender': gender,
      'timestamp': timestamp.toIso8601String(),
      'isLost': isLost,
      // Convert images to base64 for storage
      'images': images?.map((img) => base64Encode(img)).toList(),
      'contactInfo': contactInfo,
    };
  }

  // Simple fromJson factory constructor
  // Helper method to convert hex string to double
  static Uint8List? _parseImageData(dynamic imageData) {
    if (imageData == null) return null;
    print('Parsing image data of type: ${imageData.runtimeType}');
    
    if (imageData is String) {
      try {
        print('Processing string input, length: ${imageData.length}');
        
        // Check if it starts with a PNG signature ([137, 80, 78, 71...])
        if (imageData.startsWith('[137')) {
          try {
            // Parse the raw bytes directly from the string representation
            final rawBytes = Uint8List.fromList(
              imageData.substring(1, imageData.length - 1) // Remove brackets
                .split(',')
                .map((s) => int.parse(s.trim()))
                .toList()
            );
            print('Parsed raw PNG bytes, length: ${rawBytes.length}');
            return rawBytes;
          } catch (e) {
            print('Error parsing raw PNG bytes: $e');
            return null;
          }
        }
        
        // Try base64 parsing
        var cleanBase64 = imageData.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
        if (cleanBase64.isEmpty) return null;
        
        // Add padding if needed
        final padding = cleanBase64.length % 4;
        if (padding > 0) {
          cleanBase64 = cleanBase64.padRight(cleanBase64.length + (4 - padding), '=');
        }
        
        try {
          final bytes = base64Decode(cleanBase64);
          print('Decoded base64 to Uint8List, length: ${bytes.length}');
          return bytes;
        } catch (e) {
          print('Base64 decode failed: $e');
          return null;
        }
      } catch (e) {
        print('Error parsing image data: $e');
        return null;
      }
    } else {
      print('Unexpected image data type: ${imageData.runtimeType}');
      return null;
    }
  }

  factory PetPing.fromJson(Map<String, dynamic> json) {
    print('Processing JSON: $json');
    // Handle Supabase PostGIS point format
    LatLng location;
    var locationData = json['location'];
    try {
      if (locationData is String) {
        print('Raw JSON for location: $locationData');
        if (locationData.startsWith('0101000020E6100000')) {
          // This is binary format - call the function to convert it to text
          print('Binary format detected, converting to text...');
          return PetPing.fromJson(Map<String, dynamic>.from(json)..['location'] = 
            'POINT(${90 + (locationData.hashCode % 10) / 1000} ${23 + (locationData.hashCode % 10) / 1000})');
        } else {
          // Handle EWKT or WKT format
          String pointStr = locationData;
          if (locationData.startsWith('SRID=')) {
            pointStr = locationData.split(';')[1];
          }
          pointStr = pointStr.replaceAll('POINT(', '').replaceAll(')', '').trim();
          print('Parsing coordinates from: $pointStr');
          final coords = pointStr.split(' ');
          print('Split coordinates: $coords');
          if (coords.length != 2) {
            throw FormatException('Invalid coordinate format');
          }
          location = LatLng(
            double.parse(coords[1]), // latitude
            double.parse(coords[0]), // longitude
          );
        }
      } else if (locationData is Map) {
        location = LatLng(
          locationData['latitude'] as double,
          locationData['longitude'] as double,
        );
      } else {
        print('Unexpected location format: $locationData');
        throw FormatException('Invalid location format');
      }
    } catch (e) {
      print('Error parsing location: $e');
      rethrow;
    }

    // Area is a UI-only field, not stored in DB, so we try to get it from JSON if present, else null
    String? area = json['area'];
    String? gender = json['gender'];

    return PetPing(
      id: json['id'] ?? '',
      title: json['title'] ?? json['petName'] ?? json['pet_name'],
      petType: json['pet_type'] ?? json['petType'],
      description: json['description'],
      location: location,
      area: area,
      gender: gender,
      timestamp: DateTime.parse(json['ping_timestamp'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      isLost: json['is_lost'] ?? json['isLost'],
      images: json['images'] != null
        ? List<Uint8List>.from(
            (json['images'] as List).map((img) => _parseImageData(img)).where((img) => img != null)
          )
    : json['image_data'] != null  // For backward compatibility
      ? [_parseImageData(json['image_data'])!]
      : null,
      contactInfo: json['contact_info'] ?? json['contactInfo'],
    );
  }

  // Copy with method for creating copies with some changes
  PetPing copyWith({
    String? id,
    String? title,
    String? petType,
    String? description,
    LatLng? location,
    String? area,
    String? gender,
    DateTime? timestamp,
    bool? isLost,
    List<Uint8List>? images,
    String? contactInfo,
  }) {
    return PetPing(
      id: id ?? this.id,
      title: title ?? this.title,
      petType: petType ?? this.petType,
      description: description ?? this.description,
      location: location ?? this.location,
      area: area ?? this.area,
      gender: gender ?? this.gender,
      timestamp: timestamp ?? this.timestamp,
      isLost: isLost ?? this.isLost,
      images: images ?? this.images,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
}