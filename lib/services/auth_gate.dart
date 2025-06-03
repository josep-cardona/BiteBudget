import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A simple ChangeNotifier that notifies listeners when the auth state changes.
class AuthGate extends ChangeNotifier {
  AuthGate._internal() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
  static final AuthGate instance = AuthGate._internal();
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
}
