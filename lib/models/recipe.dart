import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {

  String name;
  double calories;
  double protein;
  double price;
  double time;
  String diet;
  List<String> ingredients;
  List<String> type;
  String imageUrl;

  Recipe({
    required this.name,
    required this.calories,
    required this.protein,
    required this.price,
    required this.time,
    required this.diet,
    required this.ingredients,
    required this.type,
    required this.imageUrl,
  });

  // Factory Constructor: From Firestore Map to Dart Object
  // This method is used when you read data from Firestore.
    factory Recipe.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, 
      SnapshotOptions? options, 
    ) {
      final data = snapshot.data() ?? {};

    return Recipe(
      name: data['name'] as String? ?? 'Unnamed Recipe',
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      time: (data['time'] as num?)?.toDouble() ?? 0.0,
      diet: data['diet'] as String? ?? '',
      ingredients: (data['ingredients'] as List<dynamic>? ?? []).cast<String>(),
      type: (data['type'] as List<dynamic>? ?? []).cast<String>(),
      imageUrl: data['image_url'] as String? ?? '',

    );
  }

  // Method: To Dart Object to Firestore Map
  // This method is used when you write data to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'price': price,
      'time': time,
      'diet': diet,
      'ingredients': ingredients,
      'type': type,
      'image_url': imageUrl,
    };
  }
}
