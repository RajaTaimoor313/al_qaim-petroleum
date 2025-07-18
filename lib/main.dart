import 'package:al_qaim/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'auth/password_screen.dart';
import 'auth/activity_service.dart';
import 'auth/auth_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clear authentication state on app start
  await AuthService().clearAuthenticationOnStart();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      // Only for web
      await FirebaseFirestore.instance.enablePersistence(const PersistenceSettings(synchronizeTabs: true));
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        host: null,
        sslEnabled: true,
      );
      // Do NOT call enablePersistence for non-web
    }
  } catch (e) {
    debugPrint('Firebase initialization error:  [0m${e.toString().split('\n')[0]}');
  }
  
  // Set up error handling for Firebase operations
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
  };
  
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
