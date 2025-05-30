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
    await _usersRef.doc(uid).update(data);
  }
}
