import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitebudget/services/database_service.dart';
import 'dart:math';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  MealPlan? _mealPlan;
  bool _loading = true;
  DateTime _currentMonday = _getMondayOf(DateTime.now());

  static DateTime _getMondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _fetchMealPlanForWeek(_currentMonday);
  }

  Future<void> _fetchMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final service = DatabaseServiceMealPlan();
    final plan = await service.getMealPlanForWeek(user.uid, monday);
    setState(() {
      _mealPlan = plan;
      _loading = false;
    });
  }

  Future<void> _generateMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final recipeService = DatabaseService_Recipe();
    final mealPlanService = DatabaseServiceMealPlan();
    final allRecipes = await recipeService.getAllRecipes();
    if (allRecipes.isEmpty) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes available.')));
      return;
    }
    final random = Random();
    List<DayPlan> days = List.generate(7, (dayIdx) {
      String? pickRandom() => allRecipes[random.nextInt(allRecipes.length)].name;
      return DayPlan(
        breakfast: pickRandom(),
        lunch: pickRandom(),
        snack: pickRandom(),
        dinner: pickRandom(),
      );
    });
    final mealPlan = MealPlan(
      id: '',
      startDate: monday,
      endDate: monday.add(const Duration(days: 6)),
      days: days,
    );
    await mealPlanService.addMealPlan(mealPlan, user.uid);
    await _fetchMealPlanForWeek(monday);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal plan generated!')));
  }

  Future<void> _regenerateMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final recipeService = DatabaseService_Recipe();
    final mealPlanService = DatabaseServiceMealPlan();
    final allRecipes = await recipeService.getAllRecipes();
    if (allRecipes.isEmpty) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes available.')));
      return;
    }
    final random = Random();
    List<DayPlan> days = List.generate(7, (dayIdx) {
      String? pickRandom() => allRecipes[random.nextInt(allRecipes.length)].name;
      return DayPlan(
        breakfast: pickRandom(),
        lunch: pickRandom(),
        snack: pickRandom(),
        dinner: pickRandom(),
      );
    });
    // Find the plan for this week
    final plan = await mealPlanService.getMealPlanForWeek(user.uid, monday);
    if (plan != null) {
      final updatedPlan = MealPlan(
        id: plan.id,
        startDate: monday,
        endDate: monday.add(const Duration(days: 6)),
        days: days,
      );
      await mealPlanService.updateMealPlan(updatedPlan, user.uid);
      await _fetchMealPlanForWeek(monday);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal plan regenerated!')));
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _currentMonday = _currentMonday.add(Duration(days: 7 * offset));
    });
    _fetchMealPlanForWeek(_currentMonday);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final weekStart = _currentMonday;
    final weekEnd = _currentMonday.add(const Duration(days: 6));
    final today = DateTime.now();
    final isCurrentWeek = today.isAfter(weekStart.subtract(const Duration(days: 1))) && today.isBefore(weekEnd.add(const Duration(days: 1)));
    int todayIdx = isCurrentWeek ? today.weekday - 1 : -1;
    final todayPlan = (todayIdx >= 0 && _mealPlan?.days.length == 7) ? _mealPlan!.days[todayIdx] : null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                tooltip: 'Previous week',
                onPressed: () => _changeWeek(-1),
              ),
              Text(
                '${weekStart.day}/${weekStart.month}/${weekStart.year} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                tooltip: 'Next week',
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),
        if (isCurrentWeek && todayPlan != null) ...[
          Card(
            color: Colors.amber[50],
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Breakfast:  \t${todayPlan.breakfast ?? "-"}'),
                  Text('Lunch:      \t${todayPlan.lunch ?? "-"}'),
                  Text('Snack:      \t${todayPlan.snack ?? "-"}'),
                  Text('Dinner:     \t${todayPlan.dinner ?? "-"}'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Full Week Plan'),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
        ],
        if (_mealPlan == null) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _generateMealPlanForWeek(_currentMonday),
              child: const Text('Generate Meal Plan'),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _regenerateMealPlanForWeek(_currentMonday),
              child: const Text('Regenerate Meal Plan'),
            ),
          ),
        ],
        Expanded(
          child: _mealPlan == null
              ? const Center(child: Text('No meal plan found for this week.'))
              : ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = _mealPlan!.days[index];
                    String dayName = [
                      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                    ][index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(dayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Breakfast:  \t${day.breakfast ?? "-"}'),
                            Text('Lunch:      \t${day.lunch ?? "-"}'),
                            Text('Snack:      \t${day.snack ?? "-"}'),
                            Text('Dinner:     \t${day.dinner ?? "-"}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
