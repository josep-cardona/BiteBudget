import 'package:BiteBudget/firebase_options.dart';
import 'package:BiteBudget/router/router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  //Enable fetching info from cache (more cost efficient)
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(0, 0, 0, 0)), // Black border when focused
            borderRadius: BorderRadius.circular(12),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: const Color.fromARGB(0, 0, 0, 0)), // Black border by default
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: TextStyle(color: Colors.black), // Black label
          floatingLabelStyle: TextStyle(color: Colors.black), // Black label when focused
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black, // Black typing bar/cursor
          selectionColor: Colors.black12, // Light black highlight
          selectionHandleColor: Colors.black, // Black handle
        ),
      ),
      routerConfig: router,

    );
  }
}
