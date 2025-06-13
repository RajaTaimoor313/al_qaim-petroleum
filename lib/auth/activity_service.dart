import 'dart:async';
import 'package:al_qaim/home_page.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'password_screen.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  
  factory ActivityService() {
    return _instance;
  }
  
  ActivityService._internal();
  
  void startActivityTimer(BuildContext context) {
    // Timer functionality removed
  }
  
  void resetTimer(BuildContext context) {
    // Timer functionality removed
  }
  
  void stopTimer() {
    // Timer functionality removed
  }
} 