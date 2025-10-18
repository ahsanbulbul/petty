import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_app/features/pet_adoption/presentation/widgets/pet_card.dart';
import '../providers/pet_adoption_providers.dart';
import 'pet_detail_screen.dart';

class PetAdoptionHomePage extends ConsumerWidget {
  const PetAdoptionHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petListAsync = ref.watch(petListProvider);

    return Scaffold(
     backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: petListAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pets available for adoption.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(petListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return PetCard(
                  pet: pet,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetDetailScreen(pet: pet),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $err',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(petListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
