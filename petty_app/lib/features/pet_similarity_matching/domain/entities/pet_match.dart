class PetMatch {
  final String id;
  final String queryId;
  final String matchedId;
  final double confidence;
  final bool isMatch;
  final String matchCategory;
  final String petType;
  final MatchDetails details;
  final DateTime timestamp;
  final bool isResolved;

  PetMatch({
    required this.id,
    required this.queryId,
    required this.matchedId,
    required this.confidence,
    required this.isMatch,
    required this.matchCategory,
    required this.petType,
    required this.details,
    required this.timestamp,
    this.isResolved = false,
  });

  factory PetMatch.fromJson(Map<String, dynamic> json) {
    return PetMatch(
      id: json['post_id'] ?? json['query_id'], // Fallback to query_id if post_id not available
      queryId: json['query_id'],
      matchedId: json['matched_id'],
      confidence: (json['confidence'] as num).toDouble(),
      isMatch: json['is_match'],
      matchCategory: json['match_category'],
      petType: json['pet_type'],
      details: MatchDetails.fromJson(json['details']),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isResolved: json['is_resolved'] ?? false,
    );
  }

  String get matchCategoryColor {
    switch (matchCategory.toLowerCase()) {
      case 'high':
        return '#4CAF50'; // Green
      case 'medium':
        return '#FFA726'; // Orange
      case 'low':
        return '#EF5350'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  PetMatch copyWith({
    String? id,
    String? queryId,
    String? matchedId,
    double? confidence,
    bool? isMatch,
    String? matchCategory,
    String? petType,
    MatchDetails? details,
    DateTime? timestamp,
    bool? isResolved,
  }) {
    return PetMatch(
      id: id ?? this.id,
      queryId: queryId ?? this.queryId,
      matchedId: matchedId ?? this.matchedId,
      confidence: confidence ?? this.confidence,
      isMatch: isMatch ?? this.isMatch,
      matchCategory: matchCategory ?? this.matchCategory,
      petType: petType ?? this.petType,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': id,
      'query_id': queryId,
      'matched_id': matchedId,
      'confidence': confidence,
      'is_match': isMatch,
      'match_category': matchCategory,
      'pet_type': petType,
      'details': details.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class MatchDetails {
  final double visualSimilarity;
  final double locationScore;
  final double timeScore;
  final double metadataScore;
  final double distanceKm;
  final double timeDiffHours;

  MatchDetails({
    required this.visualSimilarity,
    required this.locationScore,
    required this.timeScore,
    required this.metadataScore,
    required this.distanceKm,
    required this.timeDiffHours,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    return MatchDetails(
      visualSimilarity: (json['visual_similarity'] as num).toDouble(),
      locationScore: (json['location_score'] as num).toDouble(),
      timeScore: (json['time_score'] as num).toDouble(),
      metadataScore: (json['metadata_score'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      timeDiffHours: (json['time_diff_hours'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visual_similarity': visualSimilarity,
      'location_score': locationScore,
      'time_score': timeScore,
      'metadata_score': metadataScore,
      'distance_km': distanceKm,
      'time_diff_hours': timeDiffHours,
    };
  }
}