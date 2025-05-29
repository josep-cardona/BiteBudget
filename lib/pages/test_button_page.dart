import 'package:bitebudget/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestButtonPage extends StatefulWidget {
  const TestButtonPage({super.key});

  @override
  State<TestButtonPage> createState() => _TestButtonPageState();
}

class _TestButtonPageState extends State<TestButtonPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Button Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Add your logic here
            GoRouter.of(context).go(Routes.homePage);
          },
          child: const Text('Press Me'),
        ),
      ),
    );
  }
}

