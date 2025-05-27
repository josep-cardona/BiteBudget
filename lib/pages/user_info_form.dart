import 'dart:io';
import 'package:bitebudget/pages/home.dart';
import 'package:bitebudget/pages/meal_preferences_form.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserInfoForm extends StatefulWidget {
  const UserInfoForm({super.key});

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  File? _profileImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_profileImage == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/$userId.jpg');
      
      await storageRef.putFile(_profileImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Upload image first
      final imageUrl = await _uploadImage(user.uid);

      // Prepare user data
      final userData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'profileImageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields
      _addIfValid(_ageController.text.trim(), (v) => int.tryParse(v), 'age', userData);
      _addIfValid(_weightController.text.trim(), (v) => double.tryParse(v), 'weight', userData);
      _addIfValid(_heightController.text.trim(), (v) => double.tryParse(v), 'height', userData);

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MealPreferencesForm()),
);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addIfValid(
    String value,
    dynamic Function(String) parser,
    String fieldName,
    Map<String, dynamic> data,
  ) {
    if (value.isEmpty) return;
    final parsed = parser(value);
    if (parsed != null) data[fieldName] = parsed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImage != null 
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt, 
                          size: 40, 
                          color: Colors.grey[600])
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Name (Required)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'First Name*',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.trim().isEmpty 
                    ? 'Required field' 
                    : null,
              ),
              const SizedBox(height: 16),

              // Surname (Required)
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'Surname*',
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (v) => v!.trim().isEmpty 
                    ? 'Required field' 
                    : null,
              ),
              const SizedBox(height: 24),

              // Age (Optional)
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age (optional)',
                  prefixIcon: Icon(Icons.cake),
                ),
              ),
              const SizedBox(height: 16),

              // Weight (Optional)
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight in kg (optional)',
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 16),

              // Height (Optional)
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height in cm (optional)',
                  prefixIcon: Icon(Icons.height),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Saving...' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
