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