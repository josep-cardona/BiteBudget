import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/services/database_service.dart';

class Recipe_Uploader {

  static final newRecipe = Recipe(
      name: 'App-Added Delicious Meal',
      calories: 500.0,
      protein: 25.0,
      price: 15.00,
      time: 45.0,
      diet: 'Omnivore',
      ingredients: ['Pasta', 'Tomato Sauce', 'Ground Beef', 'Cheese'],
      type: ['Dinner', 'Italian', 'Comfort Food'],
      steps: ['Step 1'],
      image_url: 'image'
    );

  static void addNewRecipes(DatabaseService_Recipe db){
    db.addRecipe(newRecipe);

  }

}
