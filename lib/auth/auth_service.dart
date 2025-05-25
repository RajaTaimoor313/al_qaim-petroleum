import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  // Sign out the user by clearing the authentication state
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', false);
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_authenticated') ?? false;
  }
} 