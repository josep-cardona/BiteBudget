import 'package:bitebudget/pages/home.dart';
import 'package:bitebudget/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class MealPreferencesForm extends StatefulWidget {
  const MealPreferencesForm({super.key});

  @override
  State<MealPreferencesForm> createState() => _MealPreferencesFormState();
}

class _MealPreferencesFormState extends State<MealPreferencesForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedDiet;
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _budgetController = TextEditingController();
  final List<String> _allergies = [];
  final _allergyController = TextEditingController();
  bool _isLoading = false;

  final List<String> _dietTypes = [
    'Omnivore'
    'Vegetarian',
    'Vegan',
    'Gluten Free'
  ];

  @override
  void dispose() {
    _kcalController.dispose();
    _proteinController.dispose();
    _budgetController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDiet == null) return;
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'dietType': _selectedDiet,
        'caloriesGoal': _kcalController.text.trim(),
        'proteinGoal': _proteinController.text.trim(),
        'weeklyBudget': _budgetController.text.trim(),
        'allergies': _allergies,
        'mealPreferencesCompleted': true,
      }, SetOptions(merge: true));

      // Navigate to home
      if (mounted) {
        GoRouter.of(context).go(Routes.homePage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving meal preferences: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addAllergy() {
    final allergy = _allergyController.text.trim();
    if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
      setState(() {
        _allergies.add(allergy);
        _allergyController.clear();
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('BiteBudget'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diet Type
              const Text('Type of Diet*'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDiet,
                items: _dietTypes
                    .map((diet) => DropdownMenuItem(
                          value: diet,
                          child: Text(diet),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDiet = val),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Choose Diet',
                ),
                validator: (value) =>
                    value == null ? 'Please select a diet type' : null,
              ),
              const SizedBox(height: 24),

              // Calories goal
              const Text('Set the calories goal for each day'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kcalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter kcal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Protein goal
              const Text('Set the protein goal for each day'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter protein g',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Weekly budget
              const Text('Set the maximum weekly budget'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter budget',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Allergies
              const Text('Set allergies'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _allergyController,
                      decoration: const InputDecoration(
                        hintText: 'Add Allergy',
                        prefixIcon: Icon(Icons.add),
                      ),
                      onFieldSubmitted: (_) => _addAllergy(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addAllergy,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _allergies
                    .map((allergy) => Chip(
                          label: Text(allergy),
                          onDeleted: () => _removeAllergy(allergy),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
