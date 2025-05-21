import 'package:al_qaim/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase initialized successfully for platform: $defaultTargetPlatform');
    
    // Explicitly set Firestore settings to ensure we're using the live instance
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      // Ensure we're not accidentally connecting to the emulator
      host: null,
      sslEnabled: true,
    );
    print('Firestore settings configured');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Optionally, you can show an error to the user or exit the app
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Qaim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const HomePage(),
    );
  }
}