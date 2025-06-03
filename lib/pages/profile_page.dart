import 'package:bitebudget/services/auth_service.dart';
import 'package:bitebudget/services/user_service.dart';
import 'package:bitebudget/models/user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:bitebudget/pages/meal_preferences_form.dart';
import 'package:bitebudget/pages/home.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitebudget/models/recipe_uploader.dart';
import 'package:bitebudget/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bitebudget_button_style.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUser? _user;
  bool _loading = true;
  File? _profileImage; // <-- Add this line

  @override
  void initState() {
    super.initState();
    _loadProfileImage(); // <-- Add this line
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() => _loading = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final user = await UserService().getUser(firebaseUser.uid);
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _navigateAndRefresh(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
    // Refetch user info and reload image after returning
    await _fetchUser();
    await _loadProfileImage(); 
  }

  void _logout() async {
    await AuthService().signOut();
    if (mounted) {
      GoRouter.of(context).go('/welcome');
    }
  }

  void _editProfile() {
    _navigateAndRefresh(EditProfilePage(user: _user));
  }

  Future<void> _uploadRecipes() async {
    try {
      await RecipeUploader.uploadRecipesFromJson(DatabaseService_Recipe());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipes uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  void _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.delete_forever, color: Colors.red, size: 40),
              const SizedBox(height: 16),
              const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
              const SizedBox(height: 12),
              const Text('Are you sure you want to delete your account? This action cannot be undone.',
                style: TextStyle(fontSize: 16, color: Colors.black87), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFFE6E6E6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFF7F7F7),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      // Delete Firebase Auth user
      await user.delete();
      if (mounted) {
        GoRouter.of(context).go('/welcome');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted.')),);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text('Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : null,
              child: _profileImage == null
                  ? const Icon(Icons.person, size: 48, color: Colors.white)
                  : null,
            ),
              const SizedBox(height: 16),
              Text(
                (_user?.name ?? '') +
                (_user?.surname != null && _user!.surname!.isNotEmpty ? ' ${_user!.surname!}' : ''),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_user?.email ?? '', style: const TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _editProfile,
                style: biteBudgetBlackButtonStyle.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
                child: const Text('Edit Profile', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Divider(thickness: 1, color: Colors.grey),
              _profileMenuItem(Icons.settings, 'Settings'),
              _profileMenuItem(Icons.help_outline, 'Help'),
              _profileMenuItem(Icons.remove_red_eye_outlined, 'Appearance'),
              _profileMenuItem(Icons.flash_on, 'Future Features'),
              _profileMenuItem(Icons.menu_book_outlined, 'About us'),
              _profileMenuItem(Icons.logout, 'Log out', onTap: _logout),
              _profileMenuItem(Icons.delete_forever, 'Delete Account', onTap: _deleteAccount),
              if (_user?.email == 'admin@bitebudget.com')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text('Upload JSON', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: _uploadRecipes,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final AppUser? user;
  const EditProfilePage({Key? key, this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  void _loadUserData() {
    final user = widget.user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _surnameController.text = user.surname ?? '';
      _emailController.text = user.email;
      _ageController.text = user.age?.toString() ?? '';
      _weightController.text = user.weight?.toString() ?? '';
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImage = File(path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await UserService().updateUser(user.uid, {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'weight': double.tryParse(_weightController.text.trim()),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        HomePage.userUpdateNotifier.value++;
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _pickAndSaveImageLocally() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final localImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
      setState(() => _profileImage = localImage);

      // Save the path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', localImage.path);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person, size: 48, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndSaveImageLocally,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, color: Colors.grey[700]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _surnameController,
              decoration: InputDecoration(labelText: 'Surname', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Weight', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final appUser = await UserService().getUser(user.uid);
                  if (mounted) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MealPreferencesForm(
                          userInfo: appUser?.toFirestore(),
                          onSaved: () async {
                            HomePage.userUpdateNotifier.value++;
                            Navigator.of(context).pop(); // Pop meal preferences
                            Navigator.of(context).pop(); // Pop edit profile
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Edit Meal Plan Preferences',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: biteBudgetBlackButtonStyle.copyWith(
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}