import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_service.dart';

class PasswordScreen extends StatefulWidget {
  final Widget destination;

  const PasswordScreen({
    super.key,
    required this.destination,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final ActivityService _activityService = ActivityService();
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  String? _correctPassword;
  String? _correctPassword2;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _activityService.stopTimer();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('is_authenticated') ?? false;

      if (isAuthenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => widget.destination),
          );
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('auth')
          .get();

      if (!snapshot.exists) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Authentication configuration not found. Please contact the administrator.';
        });
        return;
      }

      final data = snapshot.data();
      _correctPassword = data?['password'] as String?;
      _correctPassword2 = data?['password2'] as String?;

      if ((_correctPassword == null || _correctPassword!.isEmpty) &&
          (_correctPassword2 == null || _correctPassword2!.isEmpty)) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Passwords not configured. Please contact the administrator.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Failed to connect to the server. Please check your internet connection.';
      });
    }
  }

  Future<void> _verifyPassword() async {
    final enteredPassword = _passwordController.text.trim();
    
    if (enteredPassword.isEmpty) {
      setState(() {
        _isError = true;
        _errorMessage = 'Please enter a password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      if (enteredPassword == _correctPassword || enteredPassword == _correctPassword2) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
        // Store user role
        await prefs.setString('user_role', enteredPassword == _correctPassword ? 'Admin' : 'User');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => widget.destination),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Incorrect password. Please try again.';
          _passwordController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Container(
                    width: isMobile ? double.infinity : 400.0,
                    padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_gas_station,
                                size: 72.0,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(height: 24.0),
                              const Text(
                                'AL QAIM PETROLEUM',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              const Text(
                                'Enter Password',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorText: _isError ? _errorMessage : null,
                                ),
                                onSubmitted: (_) => _verifyPassword(),
                              ),
                              const SizedBox(height: 24.0),
                              SizedBox(
                                width: double.infinity,
                                height: 50.0,
                                child: ElevatedButton(
                                  onPressed: _verifyPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 