import 'package:flutter/material.dart';
import 'package:civilia/main.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io'; // For File
import 'dart:convert'; // For jsonDecode
import 'package:civilia/utils/token_manager.dart'; // To get authentication token
import 'package:civilia/screens/map_picker_screen.dart'; // NEW: Import MapPickerScreen

class CrisisReportScreen extends StatefulWidget {
  final LatLng? initialLocation; // Pass current location from Home Screen

  const CrisisReportScreen({super.key, this.initialLocation});

  @override
  State<CrisisReportScreen> createState() => _CrisisReportScreenState();
}

class _CrisisReportScreenState extends State<CrisisReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedIncidentType;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  LatLng? _selectedLocation;
  XFile? _imageFile; // To store the picked image
  bool _isLoading = false;

  // Define your Django backend URL
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // UPDATED TO LIVE URL

  final List<String> _incidentTypes = [
    'BOMBING',
    'SHOOTING',
    'MEDICAL_EMERGENCY',
    'FOOD_SHORTAGE',
    'WATER_SHORTAGE',
    'SHELTER_NEEDED',
    'MISSING_PERSON',
    'INFRASTRUCTURE_DAMAGE',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize location with current location from HomeScreen if provided
    _selectedLocation = widget.initialLocation;
    // Optionally, reverse geocode the initial location to get a name
    if (_selectedLocation != null) {
      _reverseGeocodeLocation(_selectedLocation!);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  // Helper for showing snackbars
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source', style: Theme.of(context).textTheme.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: neonBlue),
                title: Text('Photo Gallery', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: neonBlue),
                title: Text('Camera', style: Theme.of(context).textTheme.bodyMedium),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }

  // Get current location (useful if initialLocation is null or user wants to update)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _showSnackBar('Location updated!');
      _reverseGeocodeLocation(_selectedLocation!); // Get name for new location
    } catch (e) {
      _showSnackBar('Failed to get current location: $e', isError: true);
      setState(() {
        _isLoading = false;
      });
    }
  }

  // NEW: Navigate to MapPickerScreen to choose location
  Future<void> _pickLocationOnMap() async {
    final LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
      _reverseGeocodeLocation(pickedLocation); // Get name for the picked location
      _showSnackBar('Location picked from map!');
    }
  }


  // Reverse geocode to get a human-readable location name
  Future<void> _reverseGeocodeLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) address += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty) address += '${place.locality}';
        if (address.isEmpty && place.name != null) address = place.name!; // Fallback
        _locationNameController.text = address.trim();
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
      _locationNameController.text = 'Unknown Location';
    }
  }

  // Submit incident to Django backend
  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      _showSnackBar('Please select or get a location for the incident.', isError: true);
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
      Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login
      return;
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/incidents/'));
      request.headers['Authorization'] = 'Bearer $accessToken';

      request.fields['incident_type'] = _selectedIncidentType!;
      request.fields['description'] = _descriptionController.text;
      // NEW: Format latitude and longitude to limit decimal places
      request.fields['latitude'] = _selectedLocation!.latitude.toStringAsFixed(8); // Limit to 8 decimal places
      request.fields['longitude'] = _selectedLocation!.longitude.toStringAsFixed(8); // Limit to 8 decimal places
      request.fields['location_name'] = _locationNameController.text;

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // Field name in Django serializer/model
            _imageFile!.path,
            contentType: MediaType('image', _imageFile!.path.split('.').last), // e.g., 'image/jpeg' or 'image/png'
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        _showSnackBar('Crisis incident reported successfully!');
        Navigator.of(context).pop(true); // Go back to Home Screen, pass true for refresh
      } else {
        final Map<String, dynamic> errorData = jsonDecode(responseBody);
        String errorMessage = 'Failed to report incident: ${response.statusCode}';
        if (errorData.isNotEmpty) {
          errorMessage += '\n' + errorData.values.join(', ');
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
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
        title: const Text('Report Crisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report a new crisis incident to alert responders and the community.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Incident Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedIncidentType,
                decoration: InputDecoration(
                  labelText: 'Incident Type',
                  prefixIcon: const Icon(Icons.warning_amber_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _incidentTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toCapitalized(), style: Theme.of(context).textTheme.bodyMedium), // Display nicely formatted
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedIncidentType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select an incident type' : null,
                dropdownColor: Theme.of(context).scaffoldBackgroundColor, // Background of dropdown menu
                style: Theme.of(context).textTheme.bodyMedium, // Text style in dropdown button
                iconEnabledColor: neonBlue,
              ),
              const SizedBox(height: 20),

              // Description TextField
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  hintText: 'e.g., collapsed building, injured people, fire...',
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 20),

              // Image Upload
              Card(
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image_outlined, color: neonBlue),
                          const SizedBox(width: 8),
                          Text('Attach Image (Optional)', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _imageFile == null
                          ? Center(
                        child: OutlinedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: Icon(Icons.add_a_photo, color: neonBlue),
                          label: Text('Pick Image', style: TextStyle(color: neonBlue)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: neonBlue, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      )
                          : Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imageFile!.path),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 28),
                            onPressed: () {
                              setState(() {
                                _imageFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Section
              Card(
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: neonBlue),
                          const SizedBox(width: 8),
                          Text('Incident Location', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _locationNameController,
                        decoration: InputDecoration(
                          labelText: 'Location Name (e.g., Street, Landmark)',
                          prefixIcon: const Icon(Icons.add_location_alt_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a location name' : null,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedLocation != null
                            ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                            : 'No location selected.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.gps_fixed),
                              label: const Text('Get My Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: neonBlue,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickLocationOnMap, // NEW: Call map picker
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Pick on Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                foregroundColor: neonBlue,
                                side: const BorderSide(color: neonBlue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitIncident,
                  icon: const Icon(Icons.send),
                  label: const Text('Report Incident Now'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: neonBlue,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of each word in a string
extension StringExtension on String {
  String toCapitalized() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
