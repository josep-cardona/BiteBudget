import 'dart:math';

import 'package:bitebudget/models/recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String RECIPE_COLLECTION_REF = "recipes";

class DatabaseService_Recipe {

  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference _recipesRef;

  DatabaseService_Recipe(){
    _recipesRef = _firestore.collection(RECIPE_COLLECTION_REF).withConverter<Recipe>(
      fromFirestore: Recipe.fromFirestore, 
      toFirestore: (Recipe recipe,_) => recipe.toFirestore());
  }

  Future<Recipe?> getRecipeById(String id) async {
    try {
      final docSnapshot = await _recipesRef.doc(id).get();
      if (docSnapshot.exists) {
        return docSnapshot.data() as Recipe; // Converter handles mapping to Recipe object
      } else {
        return null; // Document not found
      }
    } catch (e) {
      print('Error getting document with ID $id: $e');
      return null;
    }
  }

  Future<List<Recipe>> getRecipesById(List<String> ids) async { // (1) 'async' marks the function as asynchronous
    try {
      // (2) 'await' pauses the execution of this function until _recipesRef.get() completes
      final querySnapshot = await _recipesRef.where(FieldPath.documentId, whereIn: ids).get(); 
      // (3) Once it completes, 'querySnapshot' will contain the actual data.
      return querySnapshot.docs.map((doc) => doc.data() as Recipe).toList();
    } catch (e) {
      print('Error getting recipes: $e');
      return []; // Return an empty list on error
    }
  }

  Future<List<Recipe>> getAllRecipes() async { // (1) 'async' marks the function as asynchronous
    try {
      // (2) 'await' pauses the execution of this function until _recipesRef.get() completes
      final querySnapshot = await _recipesRef.get(); 
      // (3) Once it completes, 'querySnapshot' will contain the actual data.
      return querySnapshot.docs.map((doc) => doc.data() as Recipe).toList();
    } catch (e) {
      print('Error getting recipes: $e');
      return []; // Return an empty list on error
    }
  }

  Stream<QuerySnapshot> getRecipes(){
    return _recipesRef.snapshots();
  }

Future<void> addRecipe(Recipe recipe) async {
  await _recipesRef.add(recipe);
}

  Future<List<Recipe>> getRandomRecipes(int count) async {
    try {
      final querySnapshot = await _recipesRef.get();
      final allRecipes = querySnapshot.docs.map((doc) => doc.data() as Recipe).toList();

      if (allRecipes.isEmpty) {
        return []; // No recipes available
      }

      // If the requested count is greater than or equal to the total number of recipes,
      // just shuffle and return all of them.
      if (count >= allRecipes.length) {
        allRecipes.shuffle(Random()); // Shuffle with a new Random instance for better randomness
        return allRecipes;
      }

      // Otherwise, select a random subset.
      final random = Random();
      final List<Recipe> randomRecipes = [];
      final List<int> selectedIndices = []; // To keep track of already selected indices

      while (randomRecipes.length < count) {
        int randomIndex = random.nextInt(allRecipes.length);
        if (!selectedIndices.contains(randomIndex)) {
          randomRecipes.add(allRecipes[randomIndex]);
          selectedIndices.add(randomIndex);
        }
      }
      return randomRecipes;
    } on FirebaseException catch (e) {
      print("Error fetching random recipes: ${e.message}");
      // You might want to throw the error or return an empty list based on your error handling strategy
      return [];
    } catch (e) {
      print("An unexpected error occurred: $e");
      return [];
    }
  }

  Future<List<Recipe>> getFilteredRecipes({
    List<String>? ids, // Optional list of document IDs
    String? diet, // Optional diet filter
    double? minCalories, // Optional minimum calories filter
    double? maxCalories, // Optional maximum calories filter
    List<String>? types, // Optional list of recipe types to filter by
    // Add other optional filters as needed (e.g., minPrice, maxTime, ingredients)
  }) async {
    try {
      Query query = _recipesRef; 

      if (diet != null && diet.isNotEmpty) {
        query = query.where('diet', isEqualTo: diet);
      }

      if (minCalories != null) {
        query = query.where('calories', isGreaterThanOrEqualTo: minCalories);
      }

      
      if (maxCalories != null) {
        // Make sure maxCalories is not less than minCalories if both are provided
        if (minCalories != null && maxCalories < minCalories) {
          print('Warning: maxCalories is less than minCalories. This query will likely return no results.');
        }
        query = query.where('calories', isLessThanOrEqualTo: maxCalories);
      }

      if (types != null && types.isNotEmpty) {
        // Firestore allows array-contains-any for up to 10 items.
        if (types.length <= 10) {
            query = query.where('type', arrayContainsAny: types);
        } else {
            print('Warning: Filtering by more than 10 types is not supported in a single arrayContainsAny query.');
            // You'd need to do multiple queries or reconsider the filtering approach.
            return [];
        }
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) => doc.data() as Recipe).toList();
    } catch (e) {
      print('Error getting recipes: $e');
      return []; // Return an empty list on error
    }

  }
  
  Future<Map<String, Recipe>> getRecipesByNames(List<String> names) async {
    final querySnapshot = await _recipesRef.where('name', whereIn: names).get();
    final recipes = <String, Recipe>{};
    for (var doc in querySnapshot.docs) {
      final recipe = doc.data() as Recipe;
      recipes[recipe.name] = recipe;
    }
    return recipes;
  }
}