import 'package:flutter/material.dart';
import 'package:civilia_app/main.dart'; // For neonBlue
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:mime/mime.dart'; // For lookupMimeType
import 'package:civilia_app/utils/token_manager.dart'; // For access token
import 'dart:convert'; // For jsonDecode
import 'package:civilia_app/utils/string_extensions.dart'; // For toCapitalized extension

class EditProfileScreen extends StatefulWidget {
  final String initialUsername;
  final String initialEmail;
  final String initialUserType;
  final String? initialProfilePictureUrl;
  // You can add initialPhoneNumber here if your UserProfile model has it

  const EditProfileScreen({
    super.key,
    required this.initialUsername,
    required this.initialEmail,
    required this.initialUserType,
    this.initialProfilePictureUrl,
    // Add initialPhoneNumber
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  // Add TextEditingController for phone number if needed
  String? _selectedUserType;
  XFile? _newProfileImage; // To store the newly picked image
  bool _isLoading = false;

  final List<String> _userTypeOptions = [
    'CIVILIAN',
    'RESPONDER',
    'AID_WORKER',
    'MEDIC',
    'JOURNALIST',
  ];

  // Define your Django backend URL
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // Placeholder URL

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
    _selectedUserType = widget.initialUserType;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme
            .of(context)
            .colorScheme
            .onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _newProfileImage = image;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String? accessToken = await TokenManager.getAccessToken();
    if (accessToken == null) {
      _showSnackBar('You are not logged in. Please login.', isError: true);
      setState(() {
        _isLoading = false;
      });
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      var request = http.MultipartRequest(
        'PATCH', // Use PATCH for partial updates
        Uri.parse(
            '$_baseUrl/users/me/profile/'), // Endpoint to update current user's profile
      );
      request.headers['Authorization'] = 'Bearer $accessToken';

      request.fields['username'] = _usernameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['user_type'] = _selectedUserType!;
      // Add phone_number field if you have it
      // request.fields['phone_number'] = _phoneNumberController.text;

      if (_newProfileImage != null) {
        String? mimeType = lookupMimeType(_newProfileImage!.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture', // Field name in Django serializer/model
            _newProfileImage!.path,
            contentType: MediaType.parse(
                mimeType ?? 'image/jpeg'), // Default to jpeg if lookup fails
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _showSnackBar('Profile updated successfully!');
        if (mounted) Navigator.of(context).pop(
            true); // Pop with true to indicate success
      } else {
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        String errorMessage = 'Failed to update profile: ${response
            .statusCode}';
        if (errorData.isNotEmpty) {
          errorMessage += '\n' + errorData.values.join(', ');
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Network error updating profile: $e');
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () =>
              Navigator.of(context).pop(false), // Pop with false on cancel
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Theme
                          .of(context)
                          .brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      backgroundImage: _newProfileImage != null
                          ? FileImage(
                          File(_newProfileImage!.path)) as ImageProvider<
                          Object>?
                          : (widget.initialProfilePictureUrl != null &&
                          widget.initialProfilePictureUrl!.isNotEmpty
                          ? NetworkImage(
                          widget.initialProfilePictureUrl!) as ImageProvider<
                          Object>?
                          : const AssetImage(
                          'assets/images/profile_avatar.png')),
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint(
                            'Error loading initial profile image: $exception');
                      },
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        backgroundColor: neonBlue,
                        radius: 20,
                        child: Icon(
                            Icons.camera_alt, color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
                style: TextStyle(color: Theme
                    .of(context)
                    .textTheme
                    .bodyLarge
                    ?.color),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                style: TextStyle(color: Theme
                    .of(context)
                    .textTheme
                    .bodyLarge
                    ?.color),
              ),
              const SizedBox(height: 20),
              // Add TextFormField for phone number if needed
              // TextFormField(
              //   controller: _phoneNumberController,
              //   keyboardType: TextInputType.phone,
              //   decoration: InputDecoration(
              //     labelText: 'Phone Number (Optional)',
              //     prefixIcon: const Icon(Icons.phone_outlined),
              //   ),
              //   style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              // ),
              // const SizedBox(height: 20),
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
                  fillColor: Theme
                      .of(context)
                      .inputDecorationTheme
                      .fillColor,
                ),
                items: _userTypeOptions.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toCapitalized(),
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyMedium),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUserType = newValue!;
                  });
                },
                dropdownColor: Theme
                    .of(context)
                    .cardColor,
                // Dropdown background color
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium, // Text style for selected item
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: neonBlue)
                  : ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: neonBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  elevation: 5,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}