import 'package:flutter/material.dart';
import '../../domain/entities/pet_ping.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';

class PetDetailScreen extends StatelessWidget {
  final PetPing pet;

  const PetDetailScreen({super.key, required this.pet});

  Widget _buildImage() {
    // Debug image data
    if (pet.images != null) {
      print('PetDetailScreen - Number of images: ${pet.images!.length}');
      for (var i = 0; i < pet.images!.length; i++) {
        print('PetDetailScreen - Image $i Length: ${pet.images![i].length}');
        print('PetDetailScreen - Image $i First few bytes: ${pet.images![i].take(10).toList()}');
      }
    }

    if (pet.images != null && pet.images!.isNotEmpty) {
      return PageView.builder(
        itemCount: pet.images!.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Image.memory(
                pet.images![index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
                errorBuilder: (context, error, stackTrace) {
                  print('Error displaying image $index: $error');
                  print('Stack trace: $stackTrace');
                  return Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                  );
                },
              ),
              if (pet.images!.length > 1)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${index + 1}/${pet.images!.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey[300],
        child: const Icon(Icons.pets, size: 100, color: Colors.grey),
      );
    }
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
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.title),
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
              child: _buildImage(),
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
                  if (pet.gender != null && pet.gender!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      context,
                      'Gender',
                      pet.gender![0].toUpperCase() + pet.gender!.substring(1),
                      Icons.transgender,
                    ),
                  ],
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
}