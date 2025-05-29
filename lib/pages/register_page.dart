import 'package:flutter/material.dart';
import 'package:bitebudget/services/auth_service.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'user_info_form.dart'; // Create this file next
import 'package:bitebudget/services/user_service.dart';
import 'package:bitebudget/models/user.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        // Create user document in Firestore
        final appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
        );
        await _userService.createUser(appUser);
        _navigateToUserInfo();
      }
    } catch (e) {
      _showError('Registration failed: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _navigateToUserInfo();
      }
    } catch (e) {
      _showError('Google sign-in failed: $e');
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final user = await _authService.signInWithApple();
      if (user != null) {
        _navigateToUserInfo();
      }
    } catch (e) {
      _showError('Apple sign-in failed: $e');
    }
  }

  void _navigateToUserInfo() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserInfoForm()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter email';
                  if (!value.contains('@')) return 'Please enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password too short (min 6 chars)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (value) {
                  if (value != _passwordController.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Register Button
              ElevatedButton(
                onPressed: _registerWithEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 24),

              // Divider
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 24),

              // Social Buttons
              FlutterSocialButton(
                onTap: _signInWithGoogle,
                buttonType: ButtonType.google,
                mini: false,
              ),
              const SizedBox(height: 12),
              FlutterSocialButton(
                onTap: _signInWithApple,
                buttonType: ButtonType.apple,
                mini: false,
              ),
              const SizedBox(height: 24),

              // Login Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
