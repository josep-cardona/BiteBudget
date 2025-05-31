import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/services/database_service.dart';

class RecipeUploader {
  static Future<void> uploadRecipesFromJson(DatabaseService_Recipe db) async {
    try {
      // 1. Pick JSON file using file_picker (works on web/mobile/desktop)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      // 2. Read file bytes
      final fileBytes = result.files.single.bytes;
      if (fileBytes == null) return;

      // 3. Parse JSON
      final jsonString = utf8.decode(fileBytes);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      final recipes = jsonList.map((json) {
        // Convert ingredients from 2D list to List<String> (ingredient;amount) for upload
        if (json is Map<String, dynamic> && json['ingredients'] is List) {
          json = Map<String, dynamic>.from(json); // Make a copy to avoid mutating original
          json['ingredients'] = (json['ingredients'] as List).map((item) {
            if (item is List && item.length >= 2) {
              return "${item[0]};${item[1]}";
            } else if (item is String) {
              return item;
            } else {
              return item.toString();
            }
          }).toList();
        }
        return Recipe.fromJson(json);
      }).toList();
      
      // 4. Upload to Firestore
      for (final recipe in recipes) {
        await db.addRecipe(recipe);
        print('Uploaded: ${recipe.name}');
      }
      
      print('Successfully uploaded ${recipes.length} recipes!');
    } catch (e) {
      print('Error uploading recipes: $e');
    }
  }
}
