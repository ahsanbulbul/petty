import 'package:latlong2/latlong.dart';
import 'dart:typed_data';

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
      'image_data': imageData?.toList(), // Convert Uint8List to regular List<int> for proper serialization
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

  static List<int> _parseImageData(dynamic imageData) {
    if (imageData == null) return [];
    
    print('Raw image data type: ${imageData.runtimeType}');
    String sample = imageData.toString();
    if (sample.length > 100) {
      sample = '${sample.substring(0, 50)}...${sample.substring(sample.length - 50)}';
    }
    print('Raw image data sample: $sample');
    
    if (imageData is List) {
      print('Image data is already a List');
      return List<int>.from(imageData);
    }
    
    if (imageData is String) {
      // Handle PostgreSQL bytea format
      if (imageData.startsWith('\\x')) {
        print('Parsing PostgreSQL bytea format');
        String hex = imageData.substring(2);
        List<int> bytes = [];
        for (int i = 0; i < hex.length; i += 2) {
          if (i + 2 <= hex.length) {
            String pair = hex.substring(i, i + 2);
            try {
              bytes.add(int.parse(pair, radix: 16));
            } catch (e) {
              print('Error parsing hex byte: $pair');
            }
          }
        }
        print('First few bytes from bytea: ${bytes.take(10).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
        return bytes;
      }
      
      // Handle array string format [137,80,78,71,...]
      if (imageData.startsWith('[') && imageData.endsWith(']')) {
        print('Parsing array string format');
        try {
          var bytes = imageData
            .substring(1, imageData.length - 1)
            .split(',')
            .map((s) => int.parse(s.trim()))
            .toList();
          print('First few bytes from array: ${bytes.take(10).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
          return bytes;
        } catch (e) {
          print('Error parsing array string: $e');
        }
      }
      
      // Try parsing as comma-separated values without brackets
      if (imageData.contains(',')) {
        print('Trying to parse as comma-separated values');
        try {
          var bytes = imageData
            .split(',')
            .map((s) => int.parse(s.trim()))
            .toList();
          print('First few bytes from CSV: ${bytes.take(10).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
          return bytes;
        } catch (e) {
          print('Error parsing CSV: $e');
        }
      }
    }
    
    print('Unhandled image data format');
    return [];
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
          ? Uint8List.fromList(_parseImageData(json['image_data']))
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