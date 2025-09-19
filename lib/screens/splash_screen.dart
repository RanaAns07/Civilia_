import 'package:flutter/material.dart';
import 'package:civilia_app/main.dart'; // For neonBlue
import 'package:shared_preferences/shared_preferences.dart'; // For first-time launch check
import 'package:civilia_app/utils/token_manager.dart'; // To check login status

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate some loading time for a better user experience
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final bool? isFirstLaunch = prefs.getBool('isFirstLaunch');

    if (isFirstLaunch == null || isFirstLaunch == true) {
      // If it's the first launch, show WelcomeScreen
      await prefs.setBool('isFirstLaunch', false); // Set to false after first launch
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } else {
      // Not the first launch, check if user is logged in
      final String? accessToken = await TokenManager.getAccessToken();
      if (mounted) {
        if (accessToken != null) {
          // User is logged in, go to Home Screen
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // User is not logged in, go to Login Screen
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined, // A relevant icon for safety/protection
              size: 100,
              color: neonBlue,
            ),
            const SizedBox(height: 20),
            Text(
              'Civilia',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 48, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            Text(
              'Your Safety, Our Priority',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(neonBlue),
            ),
          ],
        ),
      ),
    );
  }
}
