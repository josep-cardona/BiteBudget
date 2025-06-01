import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final _usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> createUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toFirestore());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    // Ensure double fields are stored as double
    if (data.containsKey('caloriesGoal')) {
      final val = data['caloriesGoal'];
      data['caloriesGoal'] = val is String ? double.tryParse(val) : (val is num ? val.toDouble() : null);
    }
    if (data.containsKey('proteinGoal')) {
      final val = data['proteinGoal'];
      data['proteinGoal'] = val is String ? double.tryParse(val) : (val is num ? val.toDouble() : null);
    }
    if (data.containsKey('weeklyBudget')) {
      final val = data['weeklyBudget'];
      data['weeklyBudget'] = val is String ? double.tryParse(val) : (val is num ? val.toDouble() : null);
    }
    await _usersRef.doc(uid).update(data);
  }
}
