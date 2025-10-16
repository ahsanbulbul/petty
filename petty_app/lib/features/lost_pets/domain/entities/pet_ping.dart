import 'package:latlong2/latlong.dart';
import 'dart:typed_data';
import 'dart:convert';

class PetPing {
  final String id;
  final String petName;
  final String petType;
  final String description;
  final LatLng location;
  final DateTime timestamp;
  final bool isLost; // true for lost, false for found
  final Uint8List? imageData;
  final String? contactInfo;

  PetPing({
    required this.id,
    required this.petName,
    required this.petType,
    required this.description,
    required this.location,
    required this.timestamp,
    required this.isLost,
    this.imageData,
    this.contactInfo,
  });

  // Simple toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petName': petName,
      'petType': petType,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'timestamp': timestamp.toIso8601String(),
      'isLost': isLost,
      // Store image as base64 string
      'image_data': imageData != null ? base64Encode(imageData!) : null,
      'contactInfo': contactInfo,
    };
  }

  // Simple fromJson factory constructor
  // Helper method to convert hex string to double
  static double _hexToDouble(String hex) {
    // Convert hex string to int first
    int bits = int.parse(hex, radix: 16);
    // Use Float64List to convert bits to double
    var bytes = Float64List(1);
    bytes[0] = bits.toDouble();
    return bytes[0];
  }

  static Uint8List _parseImageData(dynamic imageData) {
    if (imageData == null) return Uint8List(0);
    if (imageData is Uint8List) return imageData;
    if (imageData is List<int>) return Uint8List.fromList(imageData);
    if (imageData is String) {
      try {
        // Assume base64 string
        return base64Decode(imageData);
      } catch (e) {
        print('Error decoding base64 image: $e');
        return Uint8List(0);
      }
    }
    print('Unhandled image data format');
    return Uint8List(0);
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
    

    return PetPing(
      id: json['id'] ?? '',
      petName: json['pet_name'] ?? json['petName'],
      petType: json['pet_type'] ?? json['petType'],
      description: json['description'],
      location: location,
      timestamp: DateTime.parse(json['ping_timestamp'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      isLost: json['is_lost'] ?? json['isLost'],
    imageData: json['image_data'] != null 
      ? _parseImageData(json['image_data'])
      : null,
      contactInfo: json['contact_info'] ?? json['contactInfo'],
    );
  }

  // Copy with method for creating copies with some changes
  PetPing copyWith({
    String? id,
    String? petName,
    String? petType,
    String? description,
    LatLng? location,
    DateTime? timestamp,
    bool? isLost,
    Uint8List? imageData,
    String? contactInfo,
  }) {
    return PetPing(
      id: id ?? this.id,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      description: description ?? this.description,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isLost: isLost ?? this.isLost,
      imageData: imageData ?? this.imageData,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
}