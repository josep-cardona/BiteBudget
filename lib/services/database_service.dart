
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


}