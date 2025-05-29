// welcome_page.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: Colors.grey[100],
  body: LayoutBuilder(
    builder: (context, constraints) {
      final screenHeight = constraints.maxHeight;
      final int bottomBoxHeight = 287;

      return Stack(
        children: [
          // Background image (extends slightly below the screen to peek under box)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomBoxHeight - 30, // allows image to go *under* the box a bit
            child: Image.asset(
              'assets/icons/welcome.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Centered text
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'Eat Healthier\nEat Cheaper\nEat BiteBudget',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 1.5,
                  letterSpacing: -2.40,
                  fontVariations: [FontVariation('wght', 800)],
                ),
              ),
            ),
          ),

          // Bottom box
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomBoxHeight.toDouble(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: const Text('Log In', style: TextStyle(fontSize: 16),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('or'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                      child: const Text('Sign Up',style: TextStyle(fontSize: 16),),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFE0E0E0), // Light gray border
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Color(0xFFF3F3F3), // Optional: light background
                        foregroundColor: Colors.black, // Text color
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Flexible(
                    child: Text(
                      'By clicking continue, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF828282)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  ),
);

  }
}
