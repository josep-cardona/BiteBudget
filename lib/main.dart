import 'package:bitebudget/firebase_options.dart';

import 'package:bitebudget/pages/welcome_page.dart';
import 'package:bitebudget/pages/home.dart';
import 'package:bitebudget/pages/test_page.dart';
import 'package:bitebudget/router/router.dart';

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
      theme: ThemeData(fontFamily: 'Inter'),
      
      routerConfig: router,

    );
  }
}

