import 'dart:math';
import 'package:bitebudget/models/meal_plan.dart';
import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/models/user.dart';


class FlatMealPlan {
  List<Recipe> genes; // 28 recipes: 7 days * 4 meals

  FlatMealPlan(this.genes);

  /// Converts the flat list of recipes into a structured MealPlan
  MealPlan toMealPlan(DateTime monday) {
    List<DayPlan> days = [];

    for (int i = 0; i < 7; i++) {
      Recipe breakfast = genes[i * 4];
      Recipe lunch = genes[i * 4 + 1];
      Recipe snack = genes[i * 4 + 2];
      Recipe dinner = genes[i * 4 + 3];

      days.add(DayPlan(
        breakfast: breakfast.name,
        lunch: lunch.name,
        snack: snack.name,
        dinner: dinner.name,
      ));
    }

    return MealPlan(
      id: '', // You can generate this later
      startDate: monday,
      endDate: monday.add(const Duration(days: 6)),
      days: days,
    );
  }
}


Map<String, List<Recipe>> bucketizeByMealType(List<Recipe> allRecipes) {
  final Map<String, List<Recipe>> buckets = {
    'breakfast': [],
    'lunch': [],
    'snack': [],
    'dinner': [],
  };

  for (var recipe in allRecipes) {
    for (var type in recipe.type) {
      final normalized = type.toLowerCase();
      if (buckets.containsKey(normalized)) {
        buckets[normalized]!.add(recipe);
      }
    }
  }


  return buckets;
}

FlatMealPlan generateRandomMealPlan(Map<String, List<Recipe>> buckets) {
  final random = Random();
  final List<Recipe> genes = [];

  for (int day = 0; day < 7; day++) {
    genes.add(_pickRandom(buckets['breakfast']!, random));
    genes.add(_pickRandom(buckets['lunch']!, random));
    genes.add(_pickRandom(buckets['snack']!, random));
    genes.add(_pickRandom(buckets['dinner']!, random));
  }

  return FlatMealPlan(genes);
}

Recipe _pickRandom(List<Recipe> list, Random random) {
  return list[random.nextInt(list.length)];
}

MealPlan generateMealPlan({
  required DateTime monday,
  required List<Recipe> allRecipes,
  required AppUser user
}){
  final buckets = bucketizeByMealType(allRecipes);
  final plan = generateRandomMealPlan(buckets);
  print(user.name);

  return plan.toMealPlan(monday);
}


/*
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
*/
