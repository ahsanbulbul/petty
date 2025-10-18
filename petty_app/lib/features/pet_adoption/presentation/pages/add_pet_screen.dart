// lib/features/pet_adoption/presentation/pages/add_pet_screen.dart
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_adoption.dart';
import '../providers/pet_adoption_providers.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  final VoidCallback? onPetAdded;
  const AddPetScreen({super.key, this.onPetAdded});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _ageController = TextEditingController();
  final _descController = TextEditingController();
  String _gender = 'unknown';

  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedXFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(petAdoptionRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet for Adoption'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (dog/cat/bird/other)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Enter type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age (years)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter age';
                  if (int.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Male'),
                      value: 'male',
                      groupValue: _gender,
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                ],
              ),
              RadioListTile<String>(
                title: const Text('Unknown'),
                value: 'unknown',
                groupValue: _gender,
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Pet Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to select image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please log in to add a pet.')));
                            return;
                          }

                          setState(() => _loading = true);

                          try {
                            String? imageBase64;

                            // Convert image to base64 and store in database
                            if (_imageBytes != null) {
                              imageBase64 = base64Encode(_imageBytes!);
                            }

                            final pet = PetAdoption(
                              id: const Uuid().v4(),
                              name: _nameController.text.trim(),
                              type: _typeController.text.trim(),
                              age: int.parse(_ageController.text.trim()),
                              gender: _gender,
                              description: _descController.text.trim(),
                              location: null,
                              imagePath: null,
                              imageUrl: imageBase64, // Store base64 in imageUrl field
                              ownerId: user.id,
                              status: 'available',
                              createdAt: DateTime.now(),
                            );

                            await repo.addPet(pet);

                            if (mounted) {
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pet added successfully!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ));
                              
                              // Call the callback if provided (for tab navigation)
                              widget.onPetAdded?.call();
                              
                              // Wait a bit for the message to show
                              await Future.delayed(const Duration(milliseconds: 500));
                              
                              // Clear form
                              _nameController.clear();
                              _typeController.clear();
                              _ageController.clear();
                              _descController.clear();
                              setState(() {
                                _gender = 'unknown';
                                _pickedXFile = null;
                                _imageBytes = null;
                              });
                            }
                          } catch (e) {
                            print('Error adding pet: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ));
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
                      : const Text('Add Pet', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _ageController.dispose();
    _descController.dispose();
    super.dispose();
  }
}