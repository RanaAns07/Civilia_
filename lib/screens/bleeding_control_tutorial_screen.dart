import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // Corrected import path for main.dart
import 'package:civilia/widgets/bottom_navigation_bar.dart'; // Only one import needed

class BleedingControlTutorialScreen extends StatefulWidget {
  const BleedingControlTutorialScreen({super.key});

  @override
  State<BleedingControlTutorialScreen> createState() => _BleedingControlTutorialScreenState();
}

class _BleedingControlTutorialScreenState extends State<BleedingControlTutorialScreen> {
  int _selectedIndex = 1; // Index for the "First Aid" tab

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate based on the selected index
    switch (index) {
      case 0: // Map
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // First Aid
        break; // Already on this screen
      case 2: // Messages
      // CORRECTED: Navigate to the MessageListScreen
        Navigator.of(context).pushReplacementNamed('/messageList');
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bleeding Control Tutorial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to First Aid categories
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image from PDF
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/bleeding_tutorial.png', // Replace with your actual image
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).cardColor, // Use theme color for fallback
                    child: Center(
                      child: Text(
                        'Bleeding Control Image Placeholder',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Emergency First Aid: Severe Bleeding Control',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 24), // Use theme primary color
            ),
            const SizedBox(height: 10),
            Text(
              'Learn critical steps to manage severe bleeding effectively and safely.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _buildInstructionStep(
              context,
              '1',
              'Ensure Scene Safety',
              'Before approaching, make sure the area is safe for both you and the injured person. Call for professional medical help immediately.',
            ),
            _buildInstructionStep(
              context,
              '2',
              'Apply Direct Pressure',
              'Use a clean cloth or sterile dressing to apply firm, direct pressure directly onto the wound. Maintain constant pressure.',
            ),
            _buildInstructionStep(
              context,
              '3',
              'Elevate the Injured Part',
              'If possible, elevate the injured limb above the level of the heart to help reduce blood flow to the wound.',
            ),
            _buildInstructionStep(
              context,
              '4',
              'Consider a Tourniquet',
              'If bleeding is severe and cannot be controlled by direct pressure, apply a tourniquet high and tight on the limb.',
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

  // Helper function to build instruction steps
  Widget _buildInstructionStep(
      BuildContext context, String stepNumber, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // Use theme primary color
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary, // Text color for primary background
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: 18), // Use theme text color
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium, // Uses theme body medium
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}