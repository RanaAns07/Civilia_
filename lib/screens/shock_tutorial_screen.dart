// lib/screens/shock_tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';

class ShockTutorialScreen extends StatefulWidget {
  const ShockTutorialScreen({super.key});

  @override
  State<ShockTutorialScreen> createState() => _ShockTutorialScreenState();
}

class _ShockTutorialScreenState extends State<ShockTutorialScreen> {
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
        title: const Text('Shock Tutorial'),
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
                'assets/images/shock_tutorial.png', // Placeholder image
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: Text(
                        'Shock Tutorial Image Placeholder',
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
              'Emergency First Aid: Recognizing and Treating Shock',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Learn how to identify and manage symptoms of shock in an emergency.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _buildInstructionStep(
              context,
              '1',
              'Call for Help',
              'Immediately call emergency services. Shock is a life-threatening condition.',
            ),
            _buildInstructionStep(
              context,
              '2',
              'Lay Person Down',
              'Have the person lie on their back. Elevate their feet about 12 inches if injuries permit.',
            ),
            _buildInstructionStep(
              context,
              '3',
              'Keep Warm',
              'Cover the person with a blanket or coat to prevent loss of body heat.',
            ),
            _buildInstructionStep(
              context,
              '4',
              'Monitor and Reassure',
              'Check for signs of breathing and consciousness. Reassure the person until medical help arrives. Do not give food or drink.',
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
