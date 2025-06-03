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

  // Create a FlatMealPlan from a MealPlan and a list of all recipes
  static FlatMealPlan fromMealPlan(MealPlan mealPlan, List<Recipe> allRecipes) {
    final recipeMap = { for (var r in allRecipes) r.name : r };
    final List<Recipe> genes = [];
    for (final day in mealPlan.days) {
      for (final name in [day.breakfast, day.lunch, day.snack, day.dinner]) {
        if (name != null && recipeMap.containsKey(name)) {
          genes.add(recipeMap[name]!);
        } else {
          throw Exception('Recipe "$name" not found in allRecipes');
        }
      }
    }
    return FlatMealPlan(genes);
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

List<FlatMealPlan> generateInitialPopulation({
  required int populationSize,
  required List<Recipe> allRecipes,
}) {
  final List<FlatMealPlan> population = [];
  final buckets = bucketizeByMealType(allRecipes);

  for (int i = 0; i < populationSize; i++) {
    population.add(generateRandomMealPlan(buckets));
  }

  return population;
}

double evaluateFitness(
  FlatMealPlan plan, {
  double? dailyCaloriesGoal,
  double? dailyProteinGoal,
  double? weeklyBudget,
  double? dailyTimeLimit,
  FlatMealPlan? previousWeekPlan,
  double weightCalories = 1.0,
  double weightProtein = 4.0,
}) {
  final List<Recipe> genes = plan.genes;
  final int totalDays = 7;

  double totalPrice = 0;
  double totalTime = 0;
  final Map<String, int> recipeCount = {};
  double totalCalorieError = 0;
  double totalProteinError = 0;

  final Set<String> lastWeekRecipes = previousWeekPlan != null
      ? previousWeekPlan.genes.map((r) => r.name).toSet()
      : {};

  int previousWeekRepeats = 0;
  double lunchDinnerPenalty = 0; // NEW

  for (int day = 0; day < totalDays; day++) {
    double dayCalories = 0;
    double dayProtein = 0;
    double dayTime = 0;

    for (int i = 0; i < 4; i++) {
      Recipe recipe = genes[day * 4 + i];
      dayCalories += recipe.calories;
      dayProtein += recipe.protein;
      dayTime += recipe.time;
      totalPrice += recipe.price;
      totalTime += recipe.time;

      recipeCount[recipe.name] = (recipeCount[recipe.name] ?? 0) + 1;

      if (lastWeekRecipes.contains(recipe.name)) {
        previousWeekRepeats++;
      }
    }

    if (dailyCaloriesGoal != null) {
      totalCalorieError += (dayCalories - dailyCaloriesGoal).abs() / dailyCaloriesGoal;
    }

    if (dailyProteinGoal != null) {
      totalProteinError += (dayProtein - dailyProteinGoal).abs() / dailyProteinGoal;
    }

    if (dailyTimeLimit != null && dayTime > dailyTimeLimit) {
      totalTime += (dayTime - dailyTimeLimit);
    }

    // NEW: Penalize if dinner is more caloric than lunch
    Recipe lunch = genes[day * 4 + 1];
    Recipe dinner = genes[day * 4 + 2];
    if (dinner.calories > lunch.calories) {
      lunchDinnerPenalty += (dinner.calories - lunch.calories) / 1000.0;
    }
  }

  // Repetition penalty (same week)
  int repeatPenalty = recipeCount.values.where((count) => count > 1).fold(0, (sum, count) => sum + (count - 1));

  // Budget penalty
  double penalty = 0;
  if (weeklyBudget != null && totalPrice > weeklyBudget) {
    penalty += (totalPrice - weeklyBudget) / weeklyBudget;
  }

  if (dailyTimeLimit != null) {
    final double weeklyTimeLimit = dailyTimeLimit * totalDays;
    if (totalTime > weeklyTimeLimit) {
      penalty += (totalTime - weeklyTimeLimit) / weeklyTimeLimit;
    }
  }

  // Weighted errors
  double calorieError = dailyCaloriesGoal != null ? totalCalorieError / totalDays : 0;
  double proteinError = dailyProteinGoal != null ? totalProteinError / totalDays : 0;
  double weightedError = (weightCalories * calorieError) + (weightProtein * proteinError);

  // Repetition penalties
  double sameWeekRepetitionPenalty = repeatPenalty * 0.2;
  double previousWeekPenalty = previousWeekRepeats * 0.05;

  // Final fitness
  double fitness = 1 / (1 + weightedError + penalty + sameWeekRepetitionPenalty + previousWeekPenalty + lunchDinnerPenalty);

  return fitness;
}



FlatMealPlan tournamentSelection(List<FlatMealPlan> population, Map<FlatMealPlan, double> fitnessScores, {int tournamentSize = 3}) {
  final random = Random();
  List<FlatMealPlan> tournament = [];

  // Randomly pick k individuals
  for (int i = 0; i < tournamentSize; i++) {
    final candidate = population[random.nextInt(population.length)];
    tournament.add(candidate);
  }

  // Pick the one with the best fitness
  tournament.sort((a, b) => fitnessScores[b]!.compareTo(fitnessScores[a]!));
  return tournament.first;
}


FlatMealPlan crossoverByDay(FlatMealPlan parent1, FlatMealPlan parent2) {
  final random = Random();
  int dayIndex = random.nextInt(6) + 1; // pick between 1 and 6
  int crossoverPoint = dayIndex * 4;

  List<Recipe> childGenes = [
    ...parent1.genes.sublist(0, crossoverPoint),
    ...parent2.genes.sublist(crossoverPoint)
  ];

  return FlatMealPlan(childGenes);
}

void mutate(
  FlatMealPlan plan,
  Map<String, List<Recipe>> mealTypeBuckets, {
  double mutationRate = 0.05, // 5% chance per gene
}) {
  final random = Random();

  for (int i = 0; i < plan.genes.length; i++) {
    if (random.nextDouble() < mutationRate) {
      // Identify which meal type this gene is (0 = breakfast, 1 = lunch, ...)
      int mealIndex = i % 4;
      String mealType;

      switch (mealIndex) {
        case 0:
          mealType = 'breakfast';
          break;
        case 1:
          mealType = 'lunch';
          break;
        case 2:
          mealType = 'snack';
          break;
        case 3:
          mealType = 'dinner';
          break;
        default:
          mealType = 'lunch'; // fallback
      }

      List<Recipe> options = mealTypeBuckets[mealType]!;
      Recipe current = plan.genes[i];

      // Avoid picking the same recipe again
      Recipe replacement;
      do {
        replacement = options[random.nextInt(options.length)];
      } while (replacement.name == current.name && options.length > 1);

      plan.genes[i] = replacement;
    }
  }
}

Future<MealPlan> evolveMealPlan({
  required List<Recipe> allRecipes,
  required DateTime monday,
  int populationSize = 50,
  int generations = 100,
  double mutationRate = 0.05,
  double? calorieGoal,
  double? proteinGoal,
  double? weeklyBudget,
  double? weeklyTime,
  FlatMealPlan? previousWeek,
  int earlyStoppingRounds = 25,
}) async {
  final random = Random();
  final mealBuckets = bucketizeByMealType(allRecipes);

  // Step 1: Generate initial population
  List<FlatMealPlan> population = List.generate(
    populationSize,
    (_) => generateRandomMealPlan(mealBuckets),
  );

  FlatMealPlan bestIndividual = population.first;
  double bestFitness = -double.infinity;

  int roundsWithoutImprovement = 0;

  for (int gen = 0; gen < generations; gen++) {
    // Step 2: Evaluate fitness
    final fitnessScores = {
      for (var individual in population)
        individual: evaluateFitness(
          individual,
          dailyCaloriesGoal: calorieGoal,
          dailyProteinGoal: proteinGoal,
          weeklyBudget: weeklyBudget,
          dailyTimeLimit: weeklyTime,
          previousWeekPlan: previousWeek,
        )
    };

    // Track the best individual
    for (var entry in fitnessScores.entries) {
      if (entry.value > bestFitness) {
        bestFitness = entry.value;
        bestIndividual = entry.key;
        roundsWithoutImprovement = 0; // reset on improvement

      }
    }

    print('Generation $gen best fitness: ${bestFitness.toStringAsFixed(4)}');

    // Early stopping condition
    roundsWithoutImprovement++;
    if (roundsWithoutImprovement >= earlyStoppingRounds) {
      print('Early stopping triggered at generation $gen');
      break;
    }

    // Step 3: Create new generation
    List<FlatMealPlan> newGeneration = [];

    while (newGeneration.length < populationSize) {
      FlatMealPlan parent1 = tournamentSelection(population, fitnessScores);
      FlatMealPlan parent2 = tournamentSelection(population, fitnessScores);

      FlatMealPlan child = crossoverByDay(parent1, parent2);
      mutate(child, mealBuckets, mutationRate: mutationRate);

      newGeneration.add(child);
    }

    population = newGeneration;
  }

  print("GA finished");
  // Return the best plan converted into structured format
  return bestIndividual.toMealPlan(monday);
}





Future<MealPlan> generateMealPlan({
  required DateTime monday,
  required List<Recipe> allRecipes,
  required AppUser user,
  MealPlan? pastWeek
  
}) async {
  //Random smart planning
  //final buckets = bucketizeByMealType(allRecipes);
  //final plan = generateRandomMealPlan(buckets);

  //GA:

  FlatMealPlan? previousWeek;
  if (pastWeek != null) {
    previousWeek = FlatMealPlan.fromMealPlan(pastWeek, allRecipes);
  }
  return await evolveMealPlan(
    allRecipes: allRecipes,
    monday: monday,
    calorieGoal: user.caloriesGoal,
    proteinGoal: user.proteinGoal,
    weeklyBudget: user.weeklyBudget,
    // Optionally: pass previousWeek if needed
    previousWeek: previousWeek
  );
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