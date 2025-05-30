import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:bitebudget/router/routes.dart';
import 'package:bitebudget/services/user_service.dart';

class MealPreferencesForm extends StatefulWidget {
  final Map<String, dynamic>? userInfo;
  final VoidCallback? onSaved;
  const MealPreferencesForm({Key? key, this.userInfo, this.onSaved}) : super(key: key);

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
    'Omnivore',
    'Vegetarian',
    'Vegan',
    'Gluten Free'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize fields with userInfo if available
    if (widget.userInfo != null) {
      setState(() {
        _selectedDiet = widget.userInfo!['dietType'];
        _kcalController.text = widget.userInfo!['caloriesGoal'] ?? '';
        _proteinController.text = widget.userInfo!['proteinGoal'] ?? '';
        _budgetController.text = widget.userInfo!['weeklyBudget'] ?? '';
        _allergies.addAll(List<String>.from(widget.userInfo!['allergies'] ?? []));
      });
    }
  }

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
      // Merge info from user_info_form (if any) with meal preferences
      final Map<String, dynamic> allUserData = {
        ...?widget.userInfo,
        'uid': user.uid,
        'email': user.email ?? '',
        'dietType': _selectedDiet,
        'caloriesGoal': _kcalController.text.trim(),
        'proteinGoal': _proteinController.text.trim(),
        'weeklyBudget': _budgetController.text.trim(),
        'allergies': _allergies,
        'mealPreferencesCompleted': true,
      };
      await UserService().updateUser(user.uid, allUserData);
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else if (mounted) {
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

  InputDecoration _formFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Name
                  const Text(
                    'BiteBudget',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Diet Type
                  const Text('Type of Diet*', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedDiet,
                    items: _dietTypes
                        .map((diet) => DropdownMenuItem(
                              value: diet,
                              child: Text(
                                diet,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDiet = val),
                    decoration: InputDecoration(
                      hintText: 'Choose Diet',
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    dropdownColor: const Color(0xFFF8F8F8), // Menu background color
                    borderRadius: BorderRadius.circular(16), // Rounded corners for the menu
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Calories goal
                  const Text('Set the calories goal for each day', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _kcalController,
                    keyboardType: TextInputType.number,
                    decoration: _formFieldDecoration('Enter kcal'),
                  ),
                  const SizedBox(height: 18),

                  // Protein goal
                  const Text('Set the protein goal for each day', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: _formFieldDecoration('Enter protein g'),
                  ),
                  const SizedBox(height: 18),

                  // Weekly budget
                  const Text('Set the maximum weekly budget', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: _formFieldDecoration('Enter budget'),
                  ),
                  const SizedBox(height: 18),

                  // Allergies
                  const Text('Set allergies', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined, size: 20),
                        onPressed: _addAllergy,
                        splashRadius: 18,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _addAllergy,
                          child: TextFormField(
                            controller: _allergyController,
                            decoration: const InputDecoration(
                              hintText: 'Add Allergy',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                            ),
                            onFieldSubmitted: (_) => _addAllergy(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_allergies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _allergies
                            .map((allergy) => Chip(
                                  label: Text(allergy),
                                  onDeleted: () => _removeAllergy(allergy),
                                  backgroundColor: Colors.grey[300], // Set chip color to gray
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}