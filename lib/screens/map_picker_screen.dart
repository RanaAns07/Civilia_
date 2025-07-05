import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:civilia/main.dart'; // For neonBlue

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    if (_pickedLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('picked_location'),
          position: _pickedLocation!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet), // Distinct color
        ),
      );
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
      _markers.clear(); // Clear previous marker
      _markers.add(
        Marker(
          markerId: const MarkerId('picked_location'),
          position: _pickedLocation!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location on Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Go back without selecting
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_pickedLocation != null) {
                Navigator.of(context).pop(_pickedLocation); // Return selected location
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please tap on the map to select a location.', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            tooltip: 'Confirm Location',
          ),
        ],
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: _pickedLocation ?? const LatLng(30.3753, 69.3451), // Default to Pakistan center or initial location
          zoom: _pickedLocation != null ? 15 : 5,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onTap: _onMapTap, // Handle map taps
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: _pickedLocation != null
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pop(_pickedLocation); // Confirm and return
        },
        label: const Text('Confirm Location'),
        icon: const Icon(Icons.check),
        backgroundColor: neonBlue,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
