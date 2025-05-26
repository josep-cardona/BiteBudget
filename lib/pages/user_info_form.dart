import 'package:flutter/material.dart';

class UserInfoForm extends StatelessWidget {
  const UserInfoForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: const Center(
        child: Text('Add your user info form here'),
      ),
    );
  }
}
