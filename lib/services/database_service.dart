
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

  void addRecipe(Recipe recipe) async{
    _recipesRef.add(recipe);
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


}