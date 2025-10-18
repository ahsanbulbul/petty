import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet_match.dart';
import '../providers/pet_matches_provider.dart';

class MatchCard extends ConsumerWidget {
  final PetMatch match;

  const MatchCard({
    super.key,
    required this.match,
  });

  Color _getConfidenceColor(String category) {
    switch (category.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidenceCategory = match.matchCategory;
    final confidenceColor = _getConfidenceColor(match.matchCategory);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with confidence level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$confidenceCategory Match',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
                Text(
                  '${(match.confidence * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Match details
            _buildDetailRow(
              'Visual Similarity',
              match.details.visualSimilarity,
              Icons.image,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Location Proximity',
              match.details.locationScore,
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Time Proximity',
              match.details.timeScore,
              Icons.access_time,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to detail screen when implemented
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Match Details'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pet Type: ${match.petType}'),
                            Text('Distance: ${match.details.distanceKm.toStringAsFixed(1)} km'),
                            Text('Time Difference: ${match.details.timeDiffHours.toStringAsFixed(1)} hours'),
                            Text('Metadata Score: ${(match.details.metadataScore * 100).toInt()}%'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(petMatchesStateProvider.notifier).markAsResolved(match.id);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Resolved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double score, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(
            _getConfidenceColor(score >= 0.8 ? 'high' : score >= 0.5 ? 'medium' : 'low'),
          ),
          minHeight: 8,
        ),
        const SizedBox(width: 8),
        Text('${(score * 100).toInt()}%'),
      ],
    );
  }
}