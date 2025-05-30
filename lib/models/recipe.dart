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
  String? image_url;
  List<String> steps;


  Recipe({
    required this.name,
    required this.calories,
    required this.protein,
    required this.price,
    required this.time,
    required this.diet,
    required this.ingredients,
    required this.type,
    this.image_url,
    required this.steps,
  });

  // Factory Constructor: From Firestore Map to Dart Object
  // This method is used when you read data from Firestore.
    factory Recipe.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot, 
      SnapshotOptions? options, 
    ) {
      final data = snapshot.data() ?? {};

    return Recipe(
      name: data?['name'] as String,
      calories: (data?['calories'] as num).toDouble(),
      protein: (data?['protein'] as num).toDouble(),
      price: (data?['price'] as num).toDouble(),
      time: (data?['time'] as num).toDouble(),
      diet: data?['diet'] as String,
      // Handling Lists (Arrays):
      // Cast to List<dynamic> first, then map to the desired type.
      ingredients: (data?['ingredients'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      type: (data?['type'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      image_url: data?['image_url'] as String?,
      steps: (data?['steps'] as List<dynamic>?)?.map((item) => item as String).toList() ?? [],
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
      if (image_url != null) 'image_url': image_url,
      'steps': steps,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      time: (json['time'] as num).toDouble(),
      diet: json['diet'] as String,
      ingredients: (json['ingredients'] as List<dynamic>).cast<String>(),
      type: (json['type'] as List<dynamic>).cast<String>(),
      steps: (json['steps'] as List<dynamic>).cast<String>(),
      image_url: json['image_url'] as String?,
    );
  }
}
