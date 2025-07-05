// lib/screens/edit_profile_screen.dart (NEW FILE)
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:mime/mime.dart'; // For lookupMimeType
import 'package:civilia/utils/token_manager.dart'; // For access token
import 'dart:convert'; // For jsonDecode

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
  late TextEditingController _phoneNumberController; // Assuming you'll add this
  late String _selectedUserType;
  File? _pickedImage;
  bool _isLoading = false;

  final List<String> _userTypeOptions = [
    'Civilian',
    'Crisis Responder',
    'Aid Worker',
    'Medic',
    'Journalist',
  ];

  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // IMPORTANT: Adjust this if needed!

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneNumberController = TextEditingController(text: ''); // Initialize with empty or actual value
    _selectedUserType = widget.initialUserType;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
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
      setState(() { _isLoading = false; });
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final Uri updateUri = Uri.parse('$_baseUrl/users/me/profile/');
      var request = http.MultipartRequest('PATCH', updateUri);
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add fields
      // Only include fields if they have changed or are being submitted
      if (_usernameController.text != widget.initialUsername) {
        request.fields['username'] = _usernameController.text;
      }
      if (_emailController.text != widget.initialEmail) {
        request.fields['email'] = _emailController.text;
      }
      // Convert user type back to Django's format (e.g., "Aid Worker" -> "AID_WORKER")
      final String djangoUserType = _selectedUserType.toUpperCase().replaceAll(' ', '_');
      if (djangoUserType != widget.initialUserType.toUpperCase().replaceAll(' ', '_')) {
        request.fields['user_type'] = djangoUserType;
      }
      // Add phone number if it's being managed
      // request.fields['phone_number'] = _phoneNumberController.text; // Uncomment when phone_number is fully integrated

      // Add image file if picked
      if (_pickedImage != null) {
        final mimeTypeData = lookupMimeType(_pickedImage!.path)?.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture', // This must match the field name in your Django serializer
          _pickedImage!.path,
          contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Update Profile Response Status: ${response.statusCode}');
      debugPrint('Update Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('Profile updated successfully!');
        Navigator.of(context).pop(true); // Pop back and indicate success
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to update profile: ${response.statusCode}';
        if (errorData.isNotEmpty) {
          errorMessage += '\n' + errorData.values.join(', ');
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      _showSnackBar('Network error updating profile: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider<Object>?
                          : (widget.initialProfilePictureUrl != null && widget.initialProfilePictureUrl!.isNotEmpty
                          ? NetworkImage(widget.initialProfilePictureUrl!) as ImageProvider<Object>?
                          : const AssetImage('assets/images/profile_avatar.png')),
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint('Error loading profile image: $exception');
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: neonBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.camera_alt, color: Colors.black, size: 24),
                        ),
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
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Optional: Phone Number field
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                // No validator for now, as it might be optional
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
                    child: Text(type, style: Theme.of(context).textTheme.bodyMedium),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUserType = newValue!;
                  });
                },
                dropdownColor: Theme.of(context).cardColor, // Dropdown background color
                style: Theme.of(context).textTheme.bodyMedium, // Text style for selected item
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
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
