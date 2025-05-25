import 'package:al_qaim/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'auth/password_screen.dart';
import 'auth/activity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      host: null,
      sslEnabled: true,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: ${e.toString().split('\n')[0]}');
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
        useMaterial3: true,
      ),
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (child.runtimeType != PasswordScreen) {
              ActivityService().resetTimer(context);
            }
          },
          onPanDown: (_) {
            if (child.runtimeType != PasswordScreen) {
              ActivityService().resetTimer(context);
            }
          },
          child: child!,
        );
      },
      home: const PasswordScreen(destination: HomePage()),
    );
  }
}
