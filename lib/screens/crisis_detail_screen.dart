// lib/screens/crisis_detail_screen.dart (UPDATED with Resolve Button & Pop Result)
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/screens/home_screen.dart'; // Import CrisisIncident model
import 'package:civilia/utils/token_manager.dart'; // Import TokenManager
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For jsonDecode

class CrisisDetailScreen extends StatefulWidget {
  final CrisisIncident incident;

  const CrisisDetailScreen({super.key, required this.incident});

  @override
  State<CrisisDetailScreen> createState() => _CrisisDetailScreenState();
}

class _CrisisDetailScreenState extends State<CrisisDetailScreen> {
  late CrisisIncident _currentIncident;
  bool _isLoadingAction = false;

  // Define your Django backend URL
  final String _baseUrl = 'https://web-production-15734.up.railway.app/api'; // UPDATED TO LIVE URL

  @override
  void initState() {
    super.initState();
    _currentIncident = widget.incident;
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

  Future<void> _markAsResolved() async {
    setState(() {
      _isLoadingAction = true;
    });

    final String? accessToken = await TokenManager.getAccessToken();
    if (accessToken == null) {
      _showSnackBar('You are not logged in. Please login.', isError: true);
      setState(() { _isLoadingAction = false; });
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final Uri updateUri = Uri.parse('$_baseUrl/incidents/${_currentIncident.id}/');
      final response = await http.patch(
        updateUri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, bool>{
          'is_resolved': true,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Incident marked as resolved successfully!');
        setState(() {
          _currentIncident = CrisisIncident.fromJson(jsonDecode(response.body));
        });
        // NEW: Pop back to previous screen and pass a result to indicate update
        Navigator.of(context).pop(true); // Pass 'true' to indicate resolution
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to mark incident as resolved: ${response.statusCode}';
        if (errorData.isNotEmpty) {
          errorMessage += '\n' + errorData.values.join(', ');
        }
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint("Error marking as resolved: $e");
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingAction = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIncident.incidentType.replaceAll('_', ' ').toCapitalized()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingAction
          ? const Center(child: CircularProgressIndicator(color: neonBlue))
          : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Incident Image (if available)
          if (_currentIncident.imageUrl != null && _currentIncident.imageUrl!.isNotEmpty)
          ClipRRect(
          borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _currentIncident.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 250,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            color: Theme.of(context).cardColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 50, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'Image not available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    )
    else
    Container(
    height: 150,
    width: double.infinity,
    decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(Icons.image_not_supported_outlined, size: 50, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
    const SizedBox(height: 10),
    Text(
    'No image provided for this incident.',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
    ),
    ],
    ),
    ),
    ),
    const SizedBox(height: 20),

    // Incident Type
    _buildDetailRow(context, 'Incident Type', _currentIncident.incidentType.replaceAll('_', ' ').toCapitalized(), Icons.warning_amber_rounded),

    // Description
    if (_currentIncident.description != null && _currentIncident.description!.isNotEmpty)
    _buildDetailRow(context, 'Description', _currentIncident.description!, Icons.description_outlined),

    // Location Name
    if (_currentIncident.locationName?.isNotEmpty ?? false)
                  _buildDetailRow(
                    context,
                    'Location',
                    _currentIncident.locationName!,
                    Icons.location_on_outlined,
                  )
                else
                  _buildDetailRow(
                    context,
                    'Coordinates',
                    'Lat: ${_currentIncident.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_currentIncident.longitude.toStringAsFixed(6)}',
                    Icons.location_on_outlined,
                  ),

    // Reported By
    _buildDetailRow(context, 'Reported By', _currentIncident.reportedByUsername, Icons.person_outline),

    // Timestamp
    _buildDetailRow(context, 'Time', _formatTimestamp(_currentIncident.timestamp), Icons.access_time),

    // Status
    _buildDetailRow(
    context,
    'Status',
    _currentIncident.isResolved ? 'Resolved' : 'Active',
    _currentIncident.isResolved ? Icons.check_circle_outline : Icons.error_outline,
    valueColor: _currentIncident.isResolved ? Colors.greenAccent : Colors.redAccent,
    ),
    const SizedBox(height: 20),

    // Action Buttons (e.g., "Mark as Resolved")
    if (!_currentIncident.isResolved) // Only show if not already resolved
    Center(
    child: ElevatedButton.icon(
    onPressed: _markAsResolved,
    icon: const Icon(Icons.check_circle_outline),
    label: const Text('Mark as Resolved'),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    ),
    ),
    const SizedBox(height: 20),
    ],
    ),
    ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: neonBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${_getMonthName(timestamp.month)} ${timestamp.day}, ${timestamp.year} at ${timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour < 12 ? 'AM' : 'PM'}';
  }

  String _getMonthName(int month) {
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month];
  }
}
