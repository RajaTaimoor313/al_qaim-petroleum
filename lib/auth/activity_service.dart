import 'package:flutter/material.dart';

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