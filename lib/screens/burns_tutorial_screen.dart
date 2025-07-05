// lib/screens/burns_tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';

class BurnsTutorialScreen extends StatefulWidget {
  const BurnsTutorialScreen({super.key});

  @override
  State<BurnsTutorialScreen> createState() => _BurnsTutorialScreenState();
}

class _BurnsTutorialScreenState extends State<BurnsTutorialScreen> {
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
        title: const Text('Burns Tutorial'),
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
                'assets/images/burns_tutorial.png', // Placeholder image
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: Text(
                        'Burns Tutorial Image Placeholder',
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
              'Emergency First Aid: Treating Burns',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Learn how to assess and treat different types of burns.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _buildInstructionStep(
              context,
              '1',
              'Cool the Burn',
              'Immediately hold the burned area under cool (not cold) running water for 10-20 minutes. Do not use ice.',
            ),
            _buildInstructionStep(
              context,
              '2',
              'Remove Jewelry/Clothing',
              'Gently remove any jewelry or restrictive clothing near the burned area before swelling begins.',
            ),
            _buildInstructionStep(
              context,
              '3',
              'Cover the Burn',
              'Cover the burn with a sterile, non-adhesive dressing or clean cloth. Do not apply creams, ointments, or butter.',
            ),
            _buildInstructionStep(
              context,
              '4',
              'Seek Medical Attention',
              'For severe burns (large, deep, or on sensitive areas), seek immediate medical attention.',
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
