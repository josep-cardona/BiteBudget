import 'package:cloud_firestore/cloud_firestore.dart';

class DayPlan {
  final String? breakfast;
  final String? lunch;
  final String? snack;
  final String? dinner;

  DayPlan({this.breakfast, this.lunch, this.snack, this.dinner});

  Map<String, dynamic> toMap() => {
    'breakfast': breakfast,
    'lunch': lunch,
    'snack': snack,
    'dinner': dinner,
  };

  factory DayPlan.fromMap(Map<String, dynamic> map) => DayPlan(
    breakfast: map['breakfast'],
    lunch: map['lunch'],
    snack: map['snack'],
    dinner: map['dinner'],
  );
}

class MealPlan {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<DayPlan> days;

  MealPlan({required this.id, required this.startDate, required this.endDate, required this.days});

  Map<String, dynamic> toFirestore() => {
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'days': days.map((d) => d.toMap()).toList(),
  };

  factory MealPlan.fromFirestore(String id, Map<String, dynamic> data) => MealPlan(
    id: id,
    startDate: (data['startDate'] as Timestamp).toDate(),
    endDate: (data['endDate'] as Timestamp).toDate(),
    days: (data['days'] as List).map((d) => DayPlan.fromMap(Map<String, dynamic>.from(d))).toList(),
  );
}