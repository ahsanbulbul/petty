import 'package:flutter/material.dart';
import '../../domain/entities/pet_ping.dart';
import 'package:intl/intl.dart';

class PetDetailScreen extends StatelessWidget {
  final PetPing pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    print('PetDetailScreen - Image Data Length: ${pet.imageData?.length}');
    print('PetDetailScreen - Has Image: ${pet.imageData != null}');
    if (pet.imageData != null) {
      print('First few bytes: ${pet.imageData!.take(10).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.petName),
        backgroundColor: pet.isLost ? Colors.red.shade100 : Colors.green.shade100,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: pet.imageData != null
                ? Hero(
                    tag: 'pet_image_${pet.id}',
                    child: Image.memory(
                      pet.imageData!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        print('Stack trace: $stackTrace');
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 50,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: pet.isLost ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pet.isLost ? 'Lost Pet' : 'Found Pet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, y \'at\' h:mm a').format(pet.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    context,
                    'Pet Type',
                    pet.petType,
                    Icons.pets,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    context,
                    'Description',
                    pet.description,
                    Icons.description,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    context,
                    'Location',
                    'Lat: ${pet.location.latitude.toStringAsFixed(6)}\nLng: ${pet.location.longitude.toStringAsFixed(6)}',
                    Icons.location_on,
                  ),
                  if (pet.contactInfo != null && pet.contactInfo!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      context,
                      'Contact Information',
                      pet.contactInfo!,
                      Icons.contact_phone,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}