import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? name;
  final String? surname;
  final int? age;
  final double? height;
  final double? weight;
  final DateTime? createdAt;
  final String? dietType;
  final String? caloriesGoal;
  final String? proteinGoal;
  final String? weeklyBudget;
  final List<String>? allergies;
  final bool? mealPreferencesCompleted;

  AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.surname,
    this.age,
    this.height,
    this.weight,
    this.createdAt,
    this.dietType,
    this.caloriesGoal,
    this.proteinGoal,
    this.weeklyBudget,
    this.allergies,
    this.mealPreferencesCompleted,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      surname: data['surname'],
      age: data['age'],
      height: (data['height'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      dietType: data['dietType'],
      caloriesGoal: data['caloriesGoal'],
      proteinGoal: data['proteinGoal'],
      weeklyBudget: data['weeklyBudget'],
      allergies: (data['allergies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      mealPreferencesCompleted: data['mealPreferencesCompleted'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'name': name,
    'surname': surname,
    'age': age,
    'height': height,
    'weight': weight,
    'createdAt': createdAt,
    'dietType': dietType,
    'caloriesGoal': caloriesGoal,
    'proteinGoal': proteinGoal,
    'weeklyBudget': weeklyBudget,
    'allergies': allergies,
    'mealPreferencesCompleted': mealPreferencesCompleted,
  };
}
