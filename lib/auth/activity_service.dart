import 'dart:async';
import 'package:al_qaim/home_page.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'password_screen.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  Timer? _activityTimer;
  final int _timeoutDuration = 30; // 30 seconds timeout
  
  factory ActivityService() {
    return _instance;
  }
  
  ActivityService._internal();
  
  void startActivityTimer(BuildContext context) {
    _activityTimer?.cancel(); // Cancel any existing timer
    
    _activityTimer = Timer(Duration(seconds: _timeoutDuration), () {
      _handleTimeout(context);
    });
  }
  
  void resetTimer(BuildContext context) {
    startActivityTimer(context);
  }
  
  void stopTimer() {
    _activityTimer?.cancel();
    _activityTimer = null;
  }
  
  Future<void> _handleTimeout(BuildContext context) async {
    // Stop the timer first
    stopTimer();
    
    // Sign out the user
    await AuthService().signOut();
    
    // Navigate to password screen if the context is still valid
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const PasswordScreen(
            destination: HomePage(),
          ),
        ),
        (route) => false,
      );
    }
  }
} 