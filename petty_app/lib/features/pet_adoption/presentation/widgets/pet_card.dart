import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_adoption.dart';
import '../providers/pet_adoption_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PetCard extends ConsumerWidget {
  final PetAdoption pet;
  final VoidCallback onTap;

  const PetCard({Key? key, required this.pet, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(petAdoptionRepositoryProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMyPet = currentUserId == pet.ownerId;

    // Build image widget
    Widget imageWidget;
    if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.imageUrl!);
        imageWidget = Image.memory(
          bytes,
          height: 120,
          width: 120,
          fit: BoxFit.cover,
        );
      } catch (e) {
        imageWidget = Image.network(
          pet.imageUrl!,
          height: 120,
          width: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              width: 120,
              color: Colors.grey[300],
              child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
            );
          },
        );
      }
    } else if (pet.imagePath != null && pet.imagePath!.isNotEmpty) {
      final imageUrl = repo.getPublicImageUrl(pet.imagePath!);
      imageWidget = Image.network(
        imageUrl,
        height: 120,
        width: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 120,
            width: 120,
            color: Colors.grey[300],
            child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
          );
        },
      );
    } else {
      imageWidget = Container(
        height: 120,
        width: 120,
        color: Colors.grey[300],
        child: Icon(Icons.pets, size: 50, color: Colors.grey[600]),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      shadowColor: Colors.cyan.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.cyan[100]!, Colors.cyan[400]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Image with Hero & Badge
              Stack(
                children: [
                  Hero(
                    tag: pet.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageWidget,
                    ),
                  ),
                  if (isMyPet)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _buildBadge(
                        icon: Icons.person,
                        text: 'MY PET',
                        gradientColors: [Colors.cyan[600]!, Colors.cyan[400]!],
                      ),
                    ),
                  if (pet.adopted)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _buildBadge(
                        text: 'ADOPTED',
                        color: Colors.red[600],
                      ),
                    )
                  else if (!isMyPet)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _buildBadge(
                        icon: Icons.check_circle,
                        text: 'AVAILABLE',
                        gradientColors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Pet Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.pets, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          pet.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.age} ${pet.age == 1 ? 'year' : 'years'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: pet.gender == 'male'
                                ? Colors.blue[50]
                                : pet.gender == 'female'
                                    ? Colors.pink[50]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pet.gender == 'male'
                                    ? Icons.male
                                    : pet.gender == 'female'
                                        ? Icons.female
                                        : Icons.help_outline,
                                size: 14,
                                color: pet.gender == 'male'
                                    ? Colors.blue[700]
                                    : pet.gender == 'female'
                                        ? Colors.pink[700]
                                        : Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pet.gender.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: pet.gender == 'male'
                                      ? Colors.blue[700]
                                      : pet.gender == 'female'
                                          ? Colors.pink[700]
                                          : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pet.location != null && pet.location!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pet.location!,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green[700]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
      {IconData? icon, required String text, List<Color>? gradientColors, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradientColors != null ? LinearGradient(colors: gradientColors) : null,
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (gradientColors != null ? gradientColors.last : color)!.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: Colors.white, size: 14),
          if (icon != null) const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
