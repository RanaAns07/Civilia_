// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import Google Maps
import 'package:geolocator/geolocator.dart'; // Import Geolocation
import 'package:civilia/utils/token_manager.dart'; // For logout functionality (implicitly used in app flow)
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For jsonDecode
import 'dart:math'; // For min/max in LatLngBounds calculation
import 'dart:async'; // For Timer and Future.delayed
import 'package:flutter/services.dart';

import 'crisis_detail_screen.dart';
import 'crisis_report_screen.dart'; // For HapticFeedback

// Define a simple CrisisIncident model for the frontend
class CrisisIncident {
  final int id;
  final String reportedByUsername;
  final String incidentType;
  final String? description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isResolved;
  final String? locationName;

  CrisisIncident({
    required this.id,
    required this.reportedByUsername,
    required this.incidentType,
    this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.timestamp,
    required this.isResolved,
    this.locationName,
  });

  factory CrisisIncident.fromJson(Map<String, dynamic> json) {
    return CrisisIncident(
      id: json['id'],
      reportedByUsername: json['reported_by_username'],
      incidentType: json['incident_type'],
      description: json['description'],
      latitude: double.parse(json['latitude'].toString()), // Ensure parsing to double
      longitude: double.parse(json['longitude'].toString()), // Ensure parsing to double
      imageUrl: json['image'] != null ? json['image'] as String : null,
      timestamp: DateTime.parse(json['timestamp']),
      isResolved: json['is_resolved'],
      locationName: json['location_name'],
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Index for the "Map" tab
  GoogleMapController? _mapController;
  LatLng? _currentLocation; // To store the user's current location
  bool _isLocating = true; // To show loading while getting user location
  bool _isLoadingIncidents = false; // To show loading while fetching incidents
  final Set<Marker> _markers = {}; // Set to store map markers (for incidents and user)

  // Define your Django backend URL
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // UPDATED TO LIVE URL

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndGetLocation();
    // _fetchCrisisIncidents() will be called after location is obtained, or on refresh
  }

  // Check and request location permissions, then get current location
  Future<void> _checkLocationPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled. Please enable them.', isError: true);
      setState(() { _isLocating = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied.', isError: true);
        setState(() { _isLocating = false; });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permissions are permanently denied. We cannot request permissions.', isError: true);
      setState(() { _isLocating = false; });
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
        // Add a marker for the current user's location
        _markers.add(
          Marker(
            markerId: const MarkerId('current_user_location'),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: 'My Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Blue marker for user
          ),
        );
      });
      // After getting current location, fetch incidents
      _fetchCrisisIncidents();

    } catch (e) {
      debugPrint("Error getting location: $e");
      _showSnackBar('Failed to get your location: $e', isError: true);
      setState(() { _isLocating = false; });
      _fetchCrisisIncidents(); // Still try to fetch incidents even if location fails
    }
  }

  // Function to fetch crisis incidents from Django API
  Future<void> _fetchCrisisIncidents() async {
    debugPrint('Attempting to fetch crisis incidents...');
    setState(() {
      _isLoadingIncidents = true;
    });

    final String? accessToken = await TokenManager.getAccessToken();
    if (accessToken == null) {
      debugPrint('Access token is null. User not logged in.');
      _showSnackBar('Please log in to view incidents.', isError: true);
      setState(() { _isLoadingIncidents = false; });
      return;
    } else {
      debugPrint('Access token found: $accessToken');
    }

    try {
      // Fetch only active (unresolved) incidents for display on map
      final Uri incidentsUri = Uri.parse('$_baseUrl/incidents/?is_resolved=false'); // NEW: Filter for unresolved
      debugPrint('Fetching incidents from: $incidentsUri');

      final response = await http.get(
        incidentsUri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> incidentListJson = responseData['results'] as List<dynamic>? ?? [];
        debugPrint('Number of incidents received: ${incidentListJson.length}');

        final List<CrisisIncident> incidents = incidentListJson.map((json) => CrisisIncident.fromJson(json)).toList();

        setState(() {
          // Clear existing incident markers (keep user's marker if it exists)
          _markers.removeWhere((marker) => marker.markerId.value.startsWith('incident_'));

          for (var incident in incidents) {
            debugPrint('Adding incident marker: ID=${incident.id}, Type=${incident.incidentType}, Lat=${incident.latitude}, Lng=${incident.longitude}');
            _markers.add(
              Marker(
                markerId: MarkerId('incident_${incident.id}'),
                position: LatLng(incident.latitude, incident.longitude),
                infoWindow: InfoWindow(
                    title: StringExtension(incident.incidentType.replaceAll('_', ' ')).toCapitalized(),
                    snippet: incident.description ?? 'Tap for details', // Changed snippet text
                    onTap: () async { // Make onTap async to await result from detail screen
                      // Navigate to CrisisDetailScreen on marker info window tap
                      final bool? incidentResolved = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CrisisDetailScreen(incident: incident),
                        ),
                      );
                      // If incident was resolved on detail screen, refresh incidents
                      if (incidentResolved == true) {
                        _fetchCrisisIncidents();
                      }
                    }
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  incident.isResolved ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed, // Green if resolved, Red if active
                ),
              ),
            );
          }
          debugPrint('Total markers on map after adding incidents: ${_markers.length}');
          _isLoadingIncidents = false;
        });
        _showSnackBar('Incidents refreshed!');

        // Adjust map camera to fit all markers
        if (_mapController != null && _markers.isNotEmpty) {
          LatLngBounds bounds;
          if (_markers.length == 1) {
            // If only one marker, just center on it and zoom in
            _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_markers.first.position, 15));
          } else {
            // Calculate bounds for multiple markers
            double minLat = _markers.first.position.latitude;
            double maxLat = _markers.first.position.latitude;
            double minLng = _markers.first.position.longitude;
            double maxLng = _markers.first.position.longitude;

            for (var marker in _markers) {
              minLat = min(minLat, marker.position.latitude);
              maxLat = max(maxLat, marker.position.latitude);
              minLng = min(minLng, marker.position.longitude);
              maxLng = max(maxLng, marker.position.longitude);
            }
            bounds = LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            );
            // Add some padding around the markers
            _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100)); // 100 pixels padding
          }
        }

      } else {
        _showSnackBar('Failed to load incidents: ${response.statusCode}', isError: true);
        setState(() { _isLoadingIncidents = false; });
      }
    } catch (e) {
      debugPrint("Error fetching incidents: $e");
      _showSnackBar('Network error fetching incidents: $e', isError: true);
      setState(() { _isLoadingIncidents = false; });
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate based on the selected index
    switch (index) {
      case 0: // Map
      // If already on map, just re-center or refresh if needed
        if (_currentLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
          );
        }
        _fetchCrisisIncidents(); // Refresh incidents when map tab is tapped
        break;
      case 1: // First Aid
        Navigator.of(context).pushReplacementNamed('/firstAidCategories');
        break;
      case 2: // Messages
        Navigator.of(context).pushReplacementNamed('/messageList'); // Navigate to MessageListScreen
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
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

  // Navigate to CrisisReportScreen
  void _reportCrisis() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CrisisReportScreen(
          initialLocation: _currentLocation, // Pass the current location to the report screen
        ),
      ),
    ).then((result) { // NEW: Use .then to refresh incidents after returning
      if (result == true) { // If a new incident was reported, refresh
        _fetchCrisisIncidents();
      }
    });
  }

  // Function to dispatch an SOS incident
  Future<void> _dispatchSosIncident() async {
    if (_currentLocation == null) {
      _showSnackBar('Cannot send SOS: Current location not available.', isError: true);
      return;
    }

    setState(() {
      _isLoadingIncidents = true; // Use this to show a loading indicator for SOS too
    });

    final String? accessToken = await TokenManager.getAccessToken();
    if (accessToken == null) {
      _showSnackBar('You are not logged in. Please login to send SOS.', isError: true);
      setState(() { _isLoadingIncidents = false; });
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final Uri sosUri = Uri.parse('$_baseUrl/incidents/');

      // Prepare the payload for SOS incident
      final Map<String, dynamic> sosPayload = {
        'incident_type': 'SOS', // Predefined type for SOS
        'description': 'User dispatched an SOS alert.', // Default description
        'latitude': _currentLocation!.latitude.toString(),
        'longitude': _currentLocation!.longitude.toString(),
        'location_name': 'User\'s Current Location', // Default location name
        // No image for SOS, so no multipart/form-data needed.
      };

      final response = await http.post(
        sosUri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(sosPayload),
      );

      if (response.statusCode == 201) {
        _showSnackBar('SOS alert dispatched successfully!');
        _fetchCrisisIncidents(); // Refresh incidents to show the new SOS marker
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to dispatch SOS: ${response.statusCode}';
        if (errorData.isNotEmpty) {
          errorMessage += '\n' + errorData.values.join(', ');
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint("Error dispatching SOS: $e");
      _showSnackBar('Network error dispatching SOS: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingIncidents = false;
      });
    }
  }


  // Function to show SOS confirmation dialog
  void _showSosConfirmationDialog(BuildContext context) {
    int countdown = 5; // Start countdown from 5 seconds
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog content
          builder: (context, setDialogState) {
            if (timer == null) { // Start timer only once
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (countdown > 0) {
                  setDialogState(() {
                    countdown--;
                  });
                } else {
                  t.cancel();
                  Navigator.of(context).pop(); // Close dialog
                  _dispatchSosIncident(); // Dispatch SOS after countdown
                  HapticFeedback.heavyImpact(); // Vibrate on dispatch
                  _showSosSentOverlay(context); // Show thrilling overlay
                }
              });
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                'SOS Alert',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: neonBlue),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.crisis_alert,
                    color: Colors.redAccent, // Red icon for urgency
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your SOS alert will be immediately dispatched to nearby certified responders and community users within a 5-mile radius, along with your precise location.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sending in $countdown seconds...', // Countdown text
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: neonBlue, fontSize: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This action cannot be undone once sent.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    timer?.cancel(); // Cancel the timer if user cancels
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    timer?.cancel(); // Cancel timer immediately
                    Navigator.of(context).pop(); // Close dialog
                    _dispatchSosIncident(); // Dispatch SOS immediately
                    HapticFeedback.heavyImpact(); // Vibrate on dispatch
                    _showSosSentOverlay(context); // Show thrilling overlay
                  },
                  child: const Text('Send Now'), // Changed from "Send SOS" to "Send Now"
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Ensure timer is cancelled if dialog is dismissed by other means (e.g., back button on Android)
      timer?.cancel();
    });
  }

  // Function to show a thrilling "SOS Sent!" overlay
  void _showSosSentOverlay(BuildContext context) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.8), // Dark overlay
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: neonBlue,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                'SOS Sent!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 48, color: neonBlue),
              ),
              const SizedBox(height: 10),
              Text(
                'Help is on its way.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remove the overlay after a short duration
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry?.remove();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Refresh button for incidents
            onPressed: _fetchCrisisIncidents,
            tooltip: 'Refresh Incidents',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              _showSnackBar('Notifications tapped!');
            },
          ),
        ],
      ),
      body: _isLocating || _isLoadingIncidents // Show loading if either is true
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: neonBlue),
            const SizedBox(height: 16),
            Text(
              _isLocating ? 'Getting your location...' : 'Loading incidents...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      )
          : GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(0, 0), // Default to (0,0) if location not yet found
          zoom: _currentLocation != null ? 15 : 2, // Zoom in if location found, otherwise world view
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          if (_currentLocation != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLocation!, 15),
            );
          }
        },
        markers: _markers, // Display markers on the map
        myLocationEnabled: true, // Show blue dot for user's location
        myLocationButtonEnabled: true, // Show button to re-center on user's location
        zoomControlsEnabled: false, // Hide default zoom controls if desired
        compassEnabled: true,
        trafficEnabled: false,
        indoorViewEnabled: false,
        mapToolbarEnabled: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _reportCrisis, // Connect to crisis reporting
            label: const Text('Report Crisis'),
            icon: const Icon(Icons.report_problem_outlined),
            backgroundColor: neonBlue,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              _showSosConfirmationDialog(context);
            },
            label: const Text('SOS'),
            icon: const Icon(Icons.warning_amber_rounded),
            backgroundColor: Colors.redAccent, // Red for SOS
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
