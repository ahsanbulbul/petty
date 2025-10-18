// lib/features/pet_adoption/presentation/pages/pet_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_adoption.dart';
import '../providers/pet_adoption_providers.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final PetAdoption pet;
  const PetDetailScreen({Key? key, required this.pet}) : super(key: key);

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  final TextEditingController messageController = TextEditingController();
  bool _loading = false;
  bool _hasRequestedAdoption = false;
  String? _myRequestStatus;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('adoption_requests')
          .select('status')
          .eq('pet_id', widget.pet.id)
          .eq('requester_id', userId);

      if (response.isNotEmpty && mounted) {
        setState(() {
          _hasRequestedAdoption = true;
          _myRequestStatus = response.first['status'] as String;
        });
      }
    } catch (e) {
      print('Error checking existing request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(petAdoptionRepositoryProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final pet = widget.pet;

    // Build image widget with base64 support
    Widget imageWidget;
    if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
      try {
        // Try to decode as base64
        final bytes = base64Decode(pet.imageUrl!);
        imageWidget = Image.memory(
          bytes,
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // If not base64, try as URL
        imageWidget = Image.network(
          pet.imageUrl!,
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: Colors.grey[300],
              child: const Icon(Icons.pets, size: 100, color: Colors.grey),
            );
          },
        );
      }
    } else if (pet.imagePath != null && pet.imagePath!.isNotEmpty) {
      final imageUrl = repo.getPublicImageUrl(pet.imagePath!);
      imageWidget = Image.network(
        imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey[300],
            child: const Icon(Icons.pets, size: 100, color: Colors.grey),
          );
        },
      );
    } else {
      imageWidget = Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: const Icon(Icons.pets, size: 100, color: Colors.grey),
      );
    }

    final requestsForMyPetsAsync = ref.watch(requestsForMyPetsProvider);
    final isOwner = userId == pet.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        backgroundColor: Colors.teal,
        actions: [
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text(
                  'Your Pet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.teal[700],
                avatar: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image
            imageWidget,
            
            // Pet Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.pets, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${pet.type.toUpperCase()} • ${pet.gender.toUpperCase()} • ${pet.age} years old',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (pet.adopted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'This pet has been adopted!',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (pet.description != null && pet.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                  
                  // Show "This is your pet" message for owner
                  if (isOwner && !pet.adopted) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.teal[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is your pet. You will see adoption requests below.',
                              style: TextStyle(
                                color: Colors.teal[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Show request status if user already requested
                  if (!pet.adopted && !isOwner && _hasRequestedAdoption) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _myRequestStatus == 'pending'
                            ? Colors.orange[50]
                            : _myRequestStatus == 'approved'
                                ? Colors.green[50]
                                : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _myRequestStatus == 'pending'
                              ? Colors.orange[200]!
                              : _myRequestStatus == 'approved'
                                  ? Colors.green[200]!
                                  : Colors.red[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _myRequestStatus == 'pending'
                                ? Icons.schedule
                                : _myRequestStatus == 'approved'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                            color: _myRequestStatus == 'pending'
                                ? Colors.orange[700]
                                : _myRequestStatus == 'approved'
                                    ? Colors.green[700]
                                    : Colors.red[700],
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _myRequestStatus == 'pending'
                                      ? 'Request Pending'
                                      : _myRequestStatus == 'approved'
                                          ? 'Request Approved!'
                                          : 'Request Rejected',
                                  style: TextStyle(
                                    color: _myRequestStatus == 'pending'
                                        ? Colors.orange[700]
                                        : _myRequestStatus == 'approved'
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _myRequestStatus == 'pending'
                                      ? 'Your adoption request is being reviewed by the owner.'
                                      : _myRequestStatus == 'approved'
                                          ? 'Congratulations! Your adoption request has been approved.'
                                          : 'Your adoption request was not approved.',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Adoption request section for non-owners who haven't requested
                  if (!pet.adopted && !isOwner && !_hasRequestedAdoption) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Interested in adopting?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Send a message to the owner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Your message',
                        hintText: 'Tell the owner why you want to adopt this pet...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                if (userId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please log in to request adoption')),
                                  );
                                  return;
                                }
                                if (messageController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a message')),
                                  );
                                  return;
                                }
                                setState(() => _loading = true);
                                final req = AdoptionRequest(
                                  id: const Uuid().v4(),
                                  petId: pet.id,
                                  requesterId: userId,
                                  message: messageController.text.trim(),
                                  status: 'pending',
                                  createdAt: DateTime.now(),
                                );
                                try {
                                  await repo.requestAdoption(req);
                                  if (mounted) {
                                    // Update state to show request was sent
                                    setState(() {
                                      _hasRequestedAdoption = true;
                                      _myRequestStatus = 'pending';
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Adoption request sent!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    messageController.clear();
                                    
                                    // Refresh the lists
                                    ref.invalidate(mySentRequestsWithDetailsProvider);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final errorMessage = e.toString().contains('already have a pending')
                                        ? 'You already have a pending request for this pet'
                                        : 'Error: $e';
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _loading = false);
                                  }
                                }
                              },
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send Adoption Request',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],

                  // Adoption requests section for owner
                  if (isOwner) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Adoption Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    requestsForMyPetsAsync.when(
                      data: (requests) {
                        final myRequestsForThisPet =
                            requests.where((r) => r.petId == pet.id).toList();
                        if (myRequestsForThisPet.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'No adoption requests yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: myRequestsForThisPet.map((req) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Requester ID: ${req.requesterId.substring(0, 8)}...',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: req.status == 'pending'
                                                ? Colors.orange[100]
                                                : req.status == 'approved'
                                                    ? Colors.green[100]
                                                    : Colors.red[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            req.status.toUpperCase(),
                                            style: TextStyle(
                                              color: req.status == 'pending'
                                                  ? Colors.orange[700]
                                                  : req.status == 'approved'
                                                      ? Colors.green[700]
                                                      : Colors.red[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (req.message != null && req.message!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        req.message!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                    if (req.status == 'pending') ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.check),
                                              label: const Text('Approve'),
                                              onPressed: () async {
                                                await repo.updateRequestStatus(req.id, 'approved');
                                                await repo.markPetAdopted(pet.id);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Request approved!'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.close),
                                              label: const Text('Reject'),
                                              onPressed: () async {
                                                await repo.updateRequestStatus(req.id, 'rejected');
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Request rejected'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading requests: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
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
  
  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}