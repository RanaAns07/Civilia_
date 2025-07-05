import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For encoding/decoding JSON
import 'package:civilia/utils/token_manager.dart'; // Import the new TokenManager
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  // Define your Django backend URL
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // IMPORTANT: Adjust this if needed!

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/'), // Your Django login endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String accessToken = responseData['access'];
        final String refreshToken = responseData['refresh'];
        final String? firebaseCustomToken = responseData['firebase_custom_token']; // NEW: Get Firebase custom token

        // Save tokens using the TokenManager (for Django API calls)
        await TokenManager.saveTokens(accessToken, refreshToken);

        // NEW: Sign in to Firebase Authentication with the custom token
        if (firebaseCustomToken != null) {
          try {
            await _auth.signInWithCustomToken(firebaseCustomToken);
            debugPrint('Successfully signed into Firebase with custom token.');
            // Optionally update Firebase user's display name if needed
            if (_auth.currentUser != null && _auth.currentUser!.displayName == null) {
              await _auth.currentUser!.updateDisplayName(_usernameController.text);
            }
          } on FirebaseAuthException catch (e) {
            debugPrint('Firebase Auth Error during custom token sign-in: ${e.code} - ${e.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firebase login failed: ${e.message}', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                backgroundColor: Colors.orangeAccent, // Use a warning color
              ),
            );
            // Even if Firebase login fails, proceed if Django login was successful
            // This might mean Firebase services won't work, but the app can still use Django APIs.
          }
        } else {
          debugPrint('No Firebase custom token received from Django.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful, but Firebase features may be limited (no Firebase token).', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Successful!', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: neonBlue,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String errorMessage = 'Login failed. Please check your credentials.';
        if (responseData.containsKey('detail')) {
          errorMessage = responseData['detail'];
        } else if (responseData.values.isNotEmpty) {
          errorMessage = responseData.values.join(', ');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('Network error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: neonBlue,
              ),
              const SizedBox(height: 16),
              Text(
                'Civilia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 36, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onBackground),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: 'Enter your username',
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Enter your password',
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: neonBlue)
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/signup');
                },
                child: Text('Don\'t have an account? Sign Up', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
