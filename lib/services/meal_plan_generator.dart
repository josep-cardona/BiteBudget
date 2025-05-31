import 'dart:math';
import 'package:bitebudget/models/meal_plan.dart';
import 'package:bitebudget/models/recipe.dart';

/// Generates a meal plan for a week given a list of all recipes.
/// Returns a [MealPlan] object.
MealPlan generateMealPlan({
  required DateTime monday,
  required List<Recipe> allRecipes,
}) {
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
  return MealPlan(
    id: '',
    startDate: monday,
    endDate: monday.add(const Duration(days: 6)),
    days: days,
  );
}
