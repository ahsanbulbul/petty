// lib/features/pet_adoption/presentation/widgets/pet_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_adoption.dart';
import '../providers/pet_adoption_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PetCard extends ConsumerWidget {
  final PetAdoption pet;
  final VoidCallback onTap;

  const PetCard({Key? key, required this.pet, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(petAdoptionRepositoryProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMyPet = currentUserId == pet.ownerId;
    
    // Check if imageUrl contains base64 data
    Widget imageWidget;
    if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
      try {
        // Try to decode as base64
        final bytes = base64Decode(pet.imageUrl!);
        imageWidget = Image.memory(
          bytes,
          height: 80,
          width: 80,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // If not base64, try as URL
        imageWidget = Image.network(
          pet.imageUrl!,
          height: 80,
          width: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 80,
              width: 80,
              color: Colors.grey[300],
              child: Icon(Icons.pets, size: 40, color: Colors.grey[600]),
            );
          },
        );
      }
    } else if (pet.imagePath != null && pet.imagePath!.isNotEmpty) {
      // Fallback to imagePath if imageUrl is empty
      final imageUrl = repo.getPublicImageUrl(pet.imagePath!);
      imageWidget = Image.network(
        imageUrl,
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 80,
            width: 80,
            color: Colors.grey[300],
            child: Icon(Icons.pets, size: 40, color: Colors.grey[600]),
          );
        },
      );
    } else {
      imageWidget = Container(
        height: 80,
        width: 80,
        color: Colors.grey[300],
        child: Icon(Icons.pets, size: 40, color: Colors.grey[600]),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Pet image with badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
                  ),
                  if (isMyPet)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Pet details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMyPet)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MY PET',
                              style: TextStyle(
                                color: Colors.teal[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.type} • ${pet.gender} • ${pet.age} yrs',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (pet.adopted) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADOPTED',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ] else if (!isMyPet) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, 
                                    size: 12, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'AVAILABLE',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}