// lib/features/pet_adoption/presentation/pages/add_pet_screen.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _ageController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  String _gender = 'unknown';
  String? _selectedLocation;
  String? _selectedType;

  XFile? _pickedXFile;
  Uint8List? _imageBytes;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _petTypes = [
    'Dog', 'Cat', 'Bird', 'Rabbit', 'Hamster', 'Fish', 'Turtle', 'Other',
  ];

  final List<String> _locations = [
    'Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna',
    'Barisal', 'Rangpur', 'Mymensingh', 'Comilla', 'Gazipur',
    'Narayanganj', 'Cox\'s Bazar', 'Jessore', 'Bogra', 'Dinajpur', 'Other',
  ];

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
    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ allows scroll when keyboard is open
      
      body: GestureDetector(
        // ✅ tap outside to dismiss keyboard
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 📸 Pet Photo
                  const Text(
                    'Pet Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 60, color: Colors.teal[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to select pet image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🐶 Basic Information
                  _sectionTitle('Basic Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Pet Name *', Icons.pets),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter pet name' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration:
                              _inputDecoration('Pet Type *', Icons.category),
                          items: _petTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedType = v),
                          validator: (v) => v == null ? 'Select type' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration:
                              _inputDecoration('Age (years) *', Icons.cake),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter age';
                            if (int.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🚻 Gender
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            _genderRadio('Male', 'male'),
                            _genderRadio('Female', 'female'),
                            _genderRadio('Unknown', 'unknown'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 📍 Contact & Location
                  _sectionTitle('Contact & Location'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    decoration:
                        _inputDecoration('Contact Number *', Icons.phone),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter contact number';
                      if (v.length < 11) return 'Enter valid 11-digit number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration:
                        _inputDecoration('Location *', Icons.location_on),
                    items: _locations
                        .map((loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(loc),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLocation = v),
                    validator: (v) =>
                        v == null ? 'Please select a location' : null,
                  ),
                  const SizedBox(height: 24),

                  // 📝 Description
                  _sectionTitle('Additional Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration:
                        _inputDecoration('Description (Optional)', Icons.edit),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // 🚀 Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _loading ? null : _handleSubmit,
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Add Pet for Adoption',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.teal,
      ),
    );
  }

  Widget _genderRadio(String title, String value) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(title),
        value: value,
        groupValue: _gender,
        onChanged: (val) => setState(() => _gender = val!),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a pet image')));
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(petAdoptionRepositoryProvider);
      final imageBase64 = base64Encode(_imageBytes!);

      final pet = PetAdoption(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _selectedType!.toLowerCase(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        location: _selectedLocation,
        contactNumber: _contactController.text.trim(),
        imageUrl: imageBase64,
        imagePath: null,
        ownerId: user.id,
        status: 'available',
        createdAt: DateTime.now(),
      );

      await repo.addPet(pet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Pet added successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
        widget.onPetAdded?.call();

        _formKey.currentState!.reset();
        setState(() {
          _gender = 'unknown';
          _selectedLocation = null;
          _selectedType = null;
          _pickedXFile = null;
          _imageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
