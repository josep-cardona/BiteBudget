import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:BiteBudget/models/recipe.dart';
import 'package:BiteBudget/services/database_service.dart';

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
        // Convert ingredients from 3D list to List<String> (ingredient;amount;imageUrl) for upload
        if (json is Map<String, dynamic> && json['ingredients'] is List) {
          json = Map<String, dynamic>.from(json); // Make a copy to avoid mutating original
          json['ingredients'] = (json['ingredients'] as List).map((item) {
            if (item is String && item.contains(';')) {
              final parts = item.split(';');
              // Always return [name, amount, imageUrl] (pad with empty strings if missing)
              if (parts.length >= 3) {
                return [parts[0].trim(), parts[1].trim(), parts[2].trim()];
              } else if (parts.length == 2) {
                return [parts[0].trim(), parts[1].trim(), ''];
              } else {
                return [parts[0].trim(), '', ''];
              }
            } else if (item is List) {
              // Already a list
              return item.map((e) => e.toString().trim()).toList();
            } else {
              return [item.toString().trim(), '', ''];
            }
          }).toList();
          // Debug print to verify structure
          print('Uploading recipe: \\${json['name']} ingredients: \\${json['ingredients']}');
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