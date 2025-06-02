import 'package:flutter/material.dart';
import 'package:bitebudget/models/meal_plan.dart';
import 'package:bitebudget/services/database_service.dart';
import 'package:bitebudget/services/meal_plan_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/pages/recipe_page.dart';

class DayMealPlanPage extends StatefulWidget {
  final DayPlan dayPlan;
  final int dayIndex;
  final String weekPlanId;
  final DateTime weekMonday;
  final List<DayPlan> weekDays;

  const DayMealPlanPage({
    Key? key,
    required this.dayPlan,
    required this.dayIndex,
    required this.weekPlanId,
    required this.weekMonday,
    required this.weekDays,
  }) : super(key: key);

  @override
  State<DayMealPlanPage> createState() => _DayMealPlanPageState();
}

class _DayMealPlanPageState extends State<DayMealPlanPage> {
  late DayPlan _dayPlan;
  bool _updating = false;
  bool _loadingRecipes = true;
  Map<String, Recipe> _recipeMap = {};

  @override
  void initState() {
    super.initState();
    _dayPlan = widget.dayPlan;
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final service = DatabaseService_Recipe();
    final names = [
      _dayPlan.breakfast,
      _dayPlan.lunch,
      _dayPlan.snack,
      _dayPlan.dinner
    ].whereType<String>().toList();
    final map = await service.getRecipesByNames(names);
    setState(() {
      _recipeMap = map;
      _loadingRecipes = false;
    });
  }

  Future<void> _editRecipe(String mealType) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => RecipePickerDialog(mealType: mealType),
    );
    if (selected != null) {
      setState(() { _updating = true; });
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final mealPlanService = DatabaseServiceMealPlan();
      final updatedDay = DayPlan(
        breakfast: mealType == 'breakfast' ? selected : _dayPlan.breakfast,
        lunch: mealType == 'lunch' ? selected : _dayPlan.lunch,
        snack: mealType == 'snack' ? selected : _dayPlan.snack,
        dinner: mealType == 'dinner' ? selected : _dayPlan.dinner,
      );
      final updatedWeek = List<DayPlan>.from(widget.weekDays);
      updatedWeek[widget.dayIndex] = updatedDay;
      await mealPlanService.updateMealPlan(
        MealPlan(
          id: widget.weekPlanId,
          startDate: widget.weekMonday,
          endDate: widget.weekMonday.add(const Duration(days: 6)),
          days: updatedWeek,
        ),
        user.uid,
      );
      setState(() {
        _dayPlan = updatedDay;
      });
      await _fetchRecipes(); // Refetch recipes to update images and UI
      setState(() {
        _updating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe updated!')));
      // Do NOT pop here. Let user go back manually.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day Meal Plan')),
      body: _updating || _loadingRecipes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _centeredMealCard(_mealCard('Breakfast', _dayPlan.breakfast, 'breakfast')),
                  _centeredMealCard(_mealCard('Lunch', _dayPlan.lunch, 'lunch')),
                  _centeredMealCard(_mealCard('Snack', _dayPlan.snack, 'snack')),
                  _centeredMealCard(_mealCard('Dinner', _dayPlan.dinner, 'dinner')),
                ],
              ),
            ),
    );
  }

  Widget _centeredMealCard(Widget card) {
    return Center(
      child: SizedBox(
        width: 380, // or MediaQuery.of(context).size.width * 0.92 for responsive
        child: card,
      ),
    );
  }

  Widget _mealCard(String label, String? recipeName, String mealType) {
    final recipe = recipeName != null ? _recipeMap[recipeName] : null;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: recipe != null
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RecipePage(recipe: recipe),
                  ),
                );
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recipe?.image_url != null && recipe!.image_url!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  recipe.image_url!,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey[700]),
                        tooltip: 'Edit $label',
                        onPressed: () => _editRecipe(mealType),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(recipeName ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  if (recipe != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _propertyChip(Icons.local_fire_department, '${recipe.calories.toStringAsFixed(0)} kcal', Colors.orange),
                        _propertyChip(Icons.fitness_center, '${recipe.protein.toStringAsFixed(0)}g protein', Colors.blue),
                        _propertyChip(Icons.access_time, '${recipe.time.toStringAsFixed(0)} min', Colors.green),
                        _propertyChip(Icons.euro, '${recipe.price.toStringAsFixed(2)} €', Colors.purple),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class RecipePickerDialog extends StatefulWidget {
  final String mealType;
  const RecipePickerDialog({Key? key, required this.mealType}) : super(key: key);

  @override
  State<RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<RecipePickerDialog> {
  List<String> _recipes = [];
  List<String> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final service = DatabaseService_Recipe();
    final all = await service.getAllRecipes();
    setState(() {
      _recipes = all.map((r) => r.name).toList();
      _filtered = _recipes;
      _loading = false;
    });
  }

  void _search(String q) {
    setState(() {
      _filtered = _recipes.where((r) => r.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Recipe for ${widget.mealType}'),
      content: _loading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Search recipes...'),
                  onChanged: _search,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  width: 300,
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, idx) => ListTile(
                      title: Text(_filtered[idx]),
                      onTap: () => Navigator.of(context).pop(_filtered[idx]),
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
