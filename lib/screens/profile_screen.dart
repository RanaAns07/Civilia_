import 'package:flutter/material.dart';
import 'package:civilia_app/main.dart'; // For neonBlue and ThemeNotifier
import 'package:civilia_app/utils/token_manager.dart'; // For logout
import 'package:http/http.dart' as http; // For fetching profile data
import 'dart:convert'; // For jsonDecode
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase logout
import 'package:provider/provider.dart'; // For accessing ThemeNotifier
import 'package:civilia_app/utils/string_extensions.dart'; // For toCapitalized extension

// Import the EditProfileScreen (which we will create next)
import 'package:civilia_app/screens/edit_profile_screen.dart';

import '../widgets/bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Loading...';
  String _email = 'Loading...';
  String _userType = 'Loading...';
  String? _profilePictureUrl;
  bool _isLoading = true;
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // Your Django backend URL

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final String? accessToken = await TokenManager.getAccessToken();
    if (accessToken == null) {
      _showSnackBar('You are not logged in. Please login.', isError: true);
      setState(() { _isLoading = false; });
      // Use pushReplacementNamed to prevent going back to a logged-out profile screen
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/profile/'), // Endpoint to get current user's profile
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = jsonDecode(response.body);
        setState(() {
          _username = profileData['username'] ?? 'N/A';
          _email = profileData['email'] ?? 'N/A';
          _userType = (profileData['user_type'] as String?)?.replaceAll('_', ' ').toCapitalized() ?? 'N/A';
          _profilePictureUrl = profileData['profile_picture'];
          _isLoading = false;
        });
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to load profile: ${response.statusCode}';
        if (errorData.isNotEmpty) {
          errorMessage += '\n' + errorData.values.join(', ');
        }
        _showSnackBar(errorMessage, isError: true);
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Network error fetching profile: $e');
      _showSnackBar('Network error: $e', isError: true);
      setState(() { _isLoading = false; });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Clear Django tokens
      await TokenManager.clearTokens();
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      _showSnackBar('Logged out successfully!');
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      _showSnackBar('Error logging out: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context); // Access ThemeNotifier via Provider
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(themeNotifier.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Using Provider to toggle theme
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              // Navigate to EditProfileScreen and await result
              final bool? profileUpdated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    initialUsername: _username,
                    initialEmail: _email,
                    initialUserType: _userType.toUpperCase().replaceAll(' ', '_'), // Pass in Django format
                    initialProfilePictureUrl: _profilePictureUrl,
                  ),
                ),
              );
              if (profileUpdated == true) {
                _fetchUserProfile(); // Refresh profile data if updated
              }
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                  ? NetworkImage(_profilePictureUrl!) as ImageProvider<Object>?
                  : const AssetImage('assets/images/profile_avatar.png'), // Placeholder image
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Error loading profile image: $exception');
              },
            ),
            const SizedBox(height: 20),
            Text(
              _username,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: neonBlue),
            ),
            const SizedBox(height: 10),
            Text(
              _email,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 5),
            Text(
              _userType,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.white54),
            ),
            const SizedBox(height: 40),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person_outline, color: neonBlue),
                      title: Text('Username', style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Text(_username, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: neonBlue),
                      title: Text('Email', style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Text(_email, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.badge_outlined, color: neonBlue),
                      title: Text('User Type', style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Text(_userType, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    // Add other profile details here (e.g., phone number)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 3, // Profile tab is at index 3
        onItemTapped: (index) {
          // Handle navigation from bottom bar
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/firstAidCategories');
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/messageList');
              break;
            case 3: // Stay on profile screen
              break;
          }
        },
      ),
    );
  }
}
