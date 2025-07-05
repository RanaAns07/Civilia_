// lib/screens/gunshot_wounds_tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';

class GunshotWoundsTutorialScreen extends StatefulWidget {
  const GunshotWoundsTutorialScreen({super.key});

  @override
  State<GunshotWoundsTutorialScreen> createState() => _GunshotWoundsTutorialScreenState();
}

class _GunshotWoundsTutorialScreenState extends State<GunshotWoundsTutorialScreen> {
  int _selectedIndex = 1; // Index for the "First Aid" tab

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/messageList');
        break;
      case 3:
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
        title: const Text('Gunshot Wounds Tutorial'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/gunshot_wound_tutorial.png', // Placeholder image
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: Text(
                        'Gunshot Wound Tutorial Image Placeholder',
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
              'Emergency First Aid: Gunshot Wounds',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Immediate actions for severe bleeding from gunshot wounds.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _buildInstructionStep(
              context,
              '1',
              'Ensure Safety',
              'Move to a safe location if possible. Call for medical help immediately.',
            ),
            _buildInstructionStep(
              context,
              '2',
              'Apply Direct Pressure',
              'Apply firm, direct pressure to the wound with a clean cloth or dressing. Pack the wound if necessary.',
            ),
            _buildInstructionStep(
              context,
              '3',
              'Control Bleeding',
              'If direct pressure is insufficient, apply a tourniquet above the wound on a limb, or pack the wound with gauze and apply pressure.',
            ),
            _buildInstructionStep(
              context,
              '4',
              'Monitor and Reassure',
              'Keep the person warm, monitor their breathing, and reassure them until professional help arrives.',
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
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
