import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet_match.dart';
import '../providers/pet_matches_provider.dart';
import '../../../lost_pets/presentation/providers/pet_ping_providers.dart';
import '../../../lost_pets/presentation/screens/pet_detail_screen.dart';

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
  final confidenceCategory = match.matchCategory[0].toUpperCase() + match.matchCategory.substring(1).toLowerCase();
  final confidenceColor = _getConfidenceColor(match.matchCategory);

  return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // Fetch the user's own post (queryId) and navigate
                    final petAsync = await ref.read(petPingByIdProvider(match.queryId).future);
                    if (petAsync != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PetDetailScreen(pet: petAsync),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.pets),
                  label: const Text('Post'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Fetch the best match post (matchedId) and navigate
                    final petAsync = await ref.read(petPingByIdProvider(match.matchedId).future);
                    if (petAsync != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PetDetailScreen(pet: petAsync),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Best Match'),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
                  '${match.confidence.toStringAsFixed(2)}%',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double score, IconData icon) {
    String valueText;
    double displayValue;
    if (label == 'Visual Similarity') {
      displayValue = score * 100;
      valueText = '${displayValue.toStringAsFixed(1)}%';
    } else {
      displayValue = score;
      valueText = '${displayValue.round()}%';
    }
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: label == 'Visual Similarity' ? score / 1.0 : score / 100.0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(
              _getConfidenceColor((label == 'Visual Similarity' ? score : score / 100.0) >= 0.8 ? 'high' : (label == 'Visual Similarity' ? score : score / 100.0) >= 0.5 ? 'medium' : 'low'),
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 8),
        Text(valueText),
      ],
    );
  }
}