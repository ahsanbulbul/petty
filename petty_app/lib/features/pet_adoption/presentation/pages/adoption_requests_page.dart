// lib/features/pet_adoption/presentation/pages/adoption_requests_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pet_adoption_providers.dart';

class AdoptionRequestsPage extends ConsumerWidget {
  const AdoptionRequestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySentAsync = ref.watch(mySentRequestsProvider);
    return Scaffold(
     //backgroundColor: const Color.fromARGB(255, 232, 246, 249),
      body: mySentAsync.when(
        data: (reqs) {
          if (reqs.isEmpty) return const Center(child: Text('No adoption requests yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reqs.length,
            itemBuilder: (context, index) {
              final req = reqs[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text('Pet ID: ${req.petId}'),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (req.message != null && req.message!.isNotEmpty) Text('Message: ${req.message}'),
                    Text('Status: ${req.status}', style: TextStyle(color: req.status == 'approved' ? Colors.green : req.status == 'rejected' ? Colors.red : Colors.orange)),
                  ]),
                  trailing: Text(req.createdAt.toLocal().toString().split('.')[0], style: const TextStyle(fontSize: 12)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
