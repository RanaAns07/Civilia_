// lib/screens/profile_screen.dart (UPDATED for Modernized UI & Edit Profile Navigation)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civilia/main.dart'; // For neonBlue and ThemeNotifier
import 'package:civilia/widgets/bottom_navigation_bar.dart';
import 'package:civilia/utils/token_manager.dart'; // For fetching access token
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For jsonDecode
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase user ID
import 'package:civilia/utils/string_extensions.dart'; // Import the string extension utility
import 'package:civilia/screens/edit_profile_screen.dart'; // NEW: Import the EditProfileScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3; // Index for the "Profile" tab
  String _username = 'Loading...';
  String _email = 'Loading...';
  String _userType = 'Loading...';
  String? _profilePictureUrl;
  bool _isLoadingProfile = true;

  final String _baseUrl = 'https://web-production-15734.up.railway.app/api';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch user profile data from Django backend
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final String? accessToken = await TokenManager.getAccessToken();
    if (accessToken == null) {
      debugPrint('Access token is null. User not logged in.');
      _showSnackBar('Please log in to view your profile.', isError: true);
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final Uri profileUri = Uri.parse('$_baseUrl/users/me/profile/');
      final response = await http.get(
        profileUri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint('Profile response status: ${response.statusCode}');
      debugPrint('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _username = responseData['username'] ?? 'N/A';
          _email = responseData['email'] ?? 'N/A';
          _userType = (responseData['user_type'] as String?)?.replaceAll('_', ' ').toCapitalized() ?? 'Civilian';
          _profilePictureUrl = responseData['profile_picture'];
          _isLoadingProfile = false;
        });
      } else {
        _showSnackBar('Failed to load profile: ${response.statusCode}', isError: true);
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      _showSnackBar('Network error fetching profile: $e', isError: true);
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      case 3:
        break;
      default:
        break;
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
      _isLoadingProfile = true;
    });
    try {
      await TokenManager.clearTokens(); // Clear Django tokens
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase

      _showSnackBar('Logged out successfully!');
      Navigator.of(context).pushReplacementNamed('/login'); // Go back to login screen
    } catch (e) {
      debugPrint("Error during logout: $e");
      _showSnackBar('Error during logout: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'), // Updated title
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoadingProfile
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: neonBlue),
            const SizedBox(height: 16),
            Text(
              'Loading profile...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: neonBlue.withOpacity(0.7), // Neon border around avatar
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonBlue.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                      backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                          ? NetworkImage(_profilePictureUrl!) as ImageProvider<Object>?
                          : const AssetImage('assets/images/profile_avatar.png'), // Fallback to asset
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint('Error loading profile image: $exception');
                      },
                      child: _profilePictureUrl == null || _profilePictureUrl!.isEmpty
                          ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary)
                          : null, // Show icon only if no image URL
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _username,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userType,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navigate to EditProfileScreen and await result
                      final bool? didUpdate = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            initialUsername: _username,
                            initialEmail: _email,
                            initialUserType: _userType,
                            initialProfilePictureUrl: _profilePictureUrl,
                            // You might want to pass phone number here if you add it to UserProfile
                          ),
                        ),
                      );
                      if (didUpdate == true) {
                        _fetchUserProfile(); // Refresh profile data if updated
                        _showSnackBar('Profile updated successfully!');
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, color: Colors.black),
                    label: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonBlue.withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Settings Options
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // Added vertical margin
              color: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // More rounded card
              elevation: 8, // Increased elevation for a floating effect
              child: Column(
                children: [
                  _buildSettingsTile(context, 'General', Icons.settings_outlined),
                  _buildSettingsTile(context, 'Language', Icons.language_outlined),
                  _buildSettingsTile(
                    context,
                    'Dark Mode',
                    Icons.dark_mode_outlined,
                    isToggle: true,
                    onToggle: (value) {
                      themeNotifier.toggleTheme();
                    },
                  ),
                  _buildSettingsTile(context, 'Notifications', Icons.notifications_none_outlined),
                  _buildSettingsTile(context, 'Tools & Support', Icons.build_circle_outlined),
                  _buildSettingsTile(context, 'Moderator Tools', Icons.admin_panel_settings_outlined),
                  _buildSettingsTile(context, 'Help & Feedback', Icons.help_outline),
                  _buildSettingsTile(
                    context,
                    'Connect via Wi-Fi Direct',
                    Icons.wifi_outlined,
                    onTap: () {
                      Navigator.of(context).pushNamed('/wifiDirectConnect');
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    'Chat with AI Assistant',
                    Icons.smart_toy_outlined,
                    onTap: () {
                      Navigator.of(context).pushNamed('/aiChatbot');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Logout Button
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Helper function to build settings tiles
  Widget _buildSettingsTile(BuildContext context, String title, IconData icon, {bool isToggle = false, ValueChanged<bool>? onToggle, VoidCallback? onTap}) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Theme.of(context).iconTheme.color),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: isToggle
              ? Switch(
            value: themeNotifier.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              onToggle?.call(value);
            },
            activeColor: neonBlue,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[400],
          )
              : Icon(Icons.arrow_forward_ios, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), size: 16),
          onTap: isToggle
              ? null
              : () {
            onTap?.call();
            if (onTap == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$title tapped! (Placeholder)',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  backgroundColor: neonBlue,
                  duration: const Duration(milliseconds: 500),
                ),
              );
            }
          },
        ),
        Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), height: 1),
      ],
    );
  }
}
