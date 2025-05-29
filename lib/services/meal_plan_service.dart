import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_plan.dart';

const String MEAL_PLAN_COLLECTION = "mealPlans";

class DatabaseServiceMealPlan {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference getMealPlanCollectionForUser(String uid) {
    return _firestore.collection('users').doc(uid).collection(MEAL_PLAN_COLLECTION);
  }

  Future<void> addMealPlan(MealPlan mealPlan, String uid) async {
    final mealPlanCollection = getMealPlanCollectionForUser(uid);
    await mealPlanCollection.add(mealPlan.toFirestore());
  }

  Future<List<MealPlan>> getMealPlansForUser(String uid) async {
    final mealPlanCollection = getMealPlanCollectionForUser(uid);
    final snapshot = await mealPlanCollection.get();
    return snapshot.docs.map((doc) => MealPlan.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<MealPlan?> getMealPlanById(String uid, String mealPlanId) async {
    final mealPlanCollection = getMealPlanCollectionForUser(uid);
    final doc = await mealPlanCollection.doc(mealPlanId).get();
    if (doc.exists) {
      return MealPlan.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<MealPlan?> getMealPlanForWeek(String uid, DateTime weekMonday) async {
    final mealPlanCollection = getMealPlanCollectionForUser(uid);
    final monday = DateTime(weekMonday.year, weekMonday.month, weekMonday.day);
    final snapshot = await mealPlanCollection
        .where('startDate', isEqualTo: Timestamp.fromDate(monday))
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return MealPlan.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateMealPlan(MealPlan mealPlan, String uid) async {
    final mealPlanCollection = getMealPlanCollectionForUser(uid);
    await mealPlanCollection.doc(mealPlan.id).set(mealPlan.toFirestore());
  }
}
