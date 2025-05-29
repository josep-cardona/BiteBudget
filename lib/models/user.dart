import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? dietType;
  final double? calorieGoal;
  final double? proteinGoal;
  final double? weeklyBudget;
  final List<String>? allergies;
  final String? preferredStore;
  final double? cookingTime;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.dietType,
    this.calorieGoal,
    this.proteinGoal,
    this.weeklyBudget,
    this.allergies,
    this.preferredStore,
    this.cookingTime,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      dietType: data['dietType'],
      calorieGoal: (data['calorieGoal'] as num?)?.toDouble(),
      proteinGoal: (data['proteinGoal'] as num?)?.toDouble(),
      weeklyBudget: (data['weeklyBudget'] as num?)?.toDouble(),
      allergies: (data['allergies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      preferredStore: data['preferredStore'],
      cookingTime: (data['cookingTime'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'dietType': dietType,
    'calorieGoal': calorieGoal,
    'proteinGoal': proteinGoal,
    'weeklyBudget': weeklyBudget,
    'allergies': allergies,
    'preferredStore': preferredStore,
    'cookingTime': cookingTime,
  };
}
