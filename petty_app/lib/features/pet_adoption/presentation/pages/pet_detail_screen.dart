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

  Widget _buildImageWidget(PetAdoption pet, dynamic repo, bool isDark) {
    Widget image;
    if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.imageUrl!);
        image = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        image = Image.network(pet.imageUrl!, fit: BoxFit.cover);
      }
    } else if (pet.imagePath != null && pet.imagePath!.isNotEmpty) {
      final imageUrl = repo.getPublicImageUrl(pet.imagePath!);
      image = Image.network(imageUrl, fit: BoxFit.cover);
    } else {
      image = Container(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        child: const Center(child: Icon(Icons.pets, size: 80, color: Colors.grey)),
      );
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyan.shade200, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: image,
    );
  }

  Widget _cardContainer({required Widget child, bool isDark = false}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(petAdoptionRepositoryProvider);
    final pet = widget.pet;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = userId == pet.ownerId;
    final requestsForMyPetsAsync = ref.watch(requestsForMyPetsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.cyan[50],
      appBar: AppBar(
        title: Text(pet.name),
        backgroundColor: isDark ? Colors.grey[900] : Colors.cyan[400],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageWidget(pet, repo, isDark),

            // Pet Info
            _cardContainer(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.pets, color: Colors.cyan[700], size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${pet.type.toUpperCase()} • ${pet.gender.toUpperCase()} • ${pet.age} years old',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ],
                  ),
                  if (pet.location != null && pet.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.cyan[700], size: 20),
                        const SizedBox(width: 6),
                        Text(pet.location!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                      ],
                    ),
                  ],
                  if (!isOwner && !pet.adopted && pet.contactNumber != null) ...[
                    const SizedBox(height: 12),
                    _infoCard(Icons.phone, 'Contact: ${pet.contactNumber}', Colors.teal, isDark),
                  ],
                  if (pet.adopted) ...[
                    const SizedBox(height: 12),
                    _infoCard(Icons.check_circle, 'This pet has been adopted!', Colors.red, isDark),
                  ],
                  if (pet.description != null && pet.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.teal[200] : Colors.cyan[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(pet.description!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                  ],
                ],
              ),
            ),

            // Adoption Request
            if (!pet.adopted && !isOwner) ...[
              if (_hasRequestedAdoption) _cardContainer(isDark: isDark, child: _requestStatusBanner(isDark)),
              if (!_hasRequestedAdoption)
                _cardContainer(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interested in adopting?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.teal[200] : Colors.cyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Tell the owner why you want to adopt this pet...',
                          hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.teal[400] : Colors.cyan[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _loading ? null : _sendAdoptionRequest,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Send Adoption Request'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Owner view
            if (isOwner) ...[
              const SizedBox(height: 8),
              _cardContainer(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adoption Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.teal[200] : Colors.cyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    requestsForMyPetsAsync.when(
                      data: (requests) {
                        final myRequestsForThisPet = requests.where((r) => r.petId == pet.id).toList();
                        if (myRequestsForThisPet.isEmpty) {
                          return Text('No adoption requests yet.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87));
                        }
                        return Column(
                          children: myRequestsForThisPet.map((req) => _ownerRequestCard(req, pet, isDark)).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String text, MaterialColor color, bool isDark) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color[800], fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  Widget _requestStatusBanner(bool isDark) => Row(
        children: [
          Icon(
            _myRequestStatus == 'pending'
                ? Icons.schedule
                : _myRequestStatus == 'approved'
                    ? Icons.check_circle
                    : Icons.cancel,
            color: _myRequestStatus == 'pending'
                ? Colors.orange
                : _myRequestStatus == 'approved'
                    ? Colors.green
                    : Colors.red,
            size: 30,
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
                          ? Colors.orange
                          : _myRequestStatus == 'approved'
                              ? Colors.green
                              : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _myRequestStatus == 'pending'
                      ? 'Your adoption request is being reviewed.'
                      : _myRequestStatus == 'approved'
                          ? 'Congratulations! Your request is approved.'
                          : 'Your adoption request was rejected.',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _ownerRequestCard(dynamic req, PetAdoption pet, bool isDark) => _cardContainer(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: isDark ? Colors.white70 : Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'From: ${req.requesterName}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
                _buildBadge(req.status.toUpperCase(), req.status == 'pending' ? Colors.orange : req.status == 'approved' ? Colors.green : Colors.red),
              ],
            ),
            if (req.message != null && req.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                ),
                child: Text(req.message!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              ),
            ],
          ],
        ),
      );

  Future<void> _sendAdoptionRequest() async {
    final repo = ref.read(petAdoptionRepositoryProvider);
    final pet = widget.pet;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    setState(() => _loading = true);
    final req = AdoptionRequest(
      id: const Uuid().v4(),
      petId: pet.id,
      requesterId: userId,
      ownerId: pet.ownerId,
      message: messageController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await repo.requestAdoption(req);
      if (mounted) {
        setState(() {
          _hasRequestedAdoption = true;
          _myRequestStatus = 'pending';
          _loading = false;
        });
        messageController.clear();
        ref.invalidate(mySentRequestsWithDetailsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
