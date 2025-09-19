import 'package:flutter/material.dart';
import 'package:civilia_app/main.dart'; // For neonBlue
import 'package:http/http.dart' as http; // Import the http package for Django API
import 'dart:convert'; // For encoding/decoding JSON
import 'package:flutter/services.dart'; // For SystemNavigator.pop
import 'package:civilia_app/utils/string_extensions.dart'; // Import the string extension utility
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  String _selectedUserType = 'CIVILIAN'; // Default user type
  final List<String> _userTypeOptions = [
    'CIVILIAN',
    'RESPONDER',
    'AID_WORKER',
    'MEDIC',
    'JOURNALIST',
  ];

  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  // Define your Django backend URL.
  // IMPORTANT: Replace this with your actual Django backend URL.
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // Placeholder URL

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _signup() async {
    setState(() {
      _isLoading = true;
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match.', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register/'), // Your Django registration endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'password2': _confirmPasswordController.text,
          'user_type': _selectedUserType,
          'phone_number': _phoneNumberController.text,
        }),
      );

      if (response.statusCode == 201) {
        // Successfully registered with Django. Now attempt Firebase registration.
        try {
          // Create user in Firebase Auth
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          // Update Firebase user's display name
          await userCredential.user?.updateDisplayName(_usernameController.text);
          debugPrint('Successfully registered with Firebase Auth.');

          _showSnackBar('Signup Successful! Please login.');
          Navigator.of(context).pushReplacementNamed('/login'); // Go to login after signup
        } on FirebaseAuthException catch (e) {
          debugPrint('Firebase Auth Error during signup: ${e.code} - ${e.message}');
          _showSnackBar('Signup successful with Civilia, but Firebase registration failed: ${e.message}. Please try logging in.', isError: true);
          Navigator.of(context).pushReplacementNamed('/login'); // Still go to login
        }
      } else {
        // Registration failed, parse error message from Django
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String errorMessage = 'Registration failed. Please try again.';
        if (responseData.containsKey('username') && responseData['username'] is List) {
          errorMessage = 'Username: ${responseData['username'][0]}';
        } else if (responseData.containsKey('email') && responseData['email'] is List) {
          errorMessage = 'Email: ${responseData['email'][0]}';
        } else if (responseData.containsKey('password') && responseData['password'] is List) {
          errorMessage = 'Password: ${responseData['password'][0]}';
        } else if (responseData.containsKey('phone_number') && responseData['phone_number'] is List) {
          errorMessage = 'Phone Number: ${responseData['phone_number'][0]}';
        } else if (responseData.containsKey('user_type') && responseData['user_type'] is List) {
          errorMessage = 'User Type: ${responseData['user_type'][0]}';
        } else if (responseData.containsKey('non_field_errors') && responseData['non_field_errors'] is List) {
          errorMessage = responseData['non_field_errors'][0];
        } else {
          errorMessage = responseData.values.join(', '); // Fallback to join all error messages
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Network error during signup: $e');
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent going back with system back button
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }
        SystemNavigator.pop(); // Exit app if back button pressed on this screen
      },
      child: Scaffold(
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
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 36, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create Your Account',
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    hintText: 'Enter your email',
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
                    hintText: 'Enter your password (min 6 characters)',
                  ),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    hintText: 'Re-enter your password',
                  ),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: 'e.g., +1234567890',
                  ),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: InputDecoration(
                    labelText: 'User Type',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  items: _userTypeOptions.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type.replaceAll('_', ' ').toCapitalized(), style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUserType = newValue!;
                    });
                  },
                  dropdownColor: Theme.of(context).cardColor,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator(color: neonBlue)
                    : ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text('Already have an account? Login', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
