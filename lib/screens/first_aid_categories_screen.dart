// lib/screens/first_aid_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For medical icons
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';

class FirstAidCategoriesScreen extends StatefulWidget {
  const FirstAidCategoriesScreen({super.key});

  @override
  State<FirstAidCategoriesScreen> createState() => _FirstAidCategoriesScreenState();
}

class _FirstAidCategoriesScreenState extends State<FirstAidCategoriesScreen> {
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
        Navigator.of(context).pushReplacementNamed('/messageList'); // Navigate to MessageListScreen
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      default:
        break;
    }
  }

  // Data for First Aid categories
  final List<Map<String, dynamic>> _firstAidCategories = [
    {'name': 'Bleeding', 'icon': FontAwesomeIcons.droplet, 'route': '/bleedingControlTutorial'},
    {'name': 'Fractures', 'icon': FontAwesomeIcons.bone, 'route': '/fracturesTutorial'}, // NEW ROUTE
    {'name': 'CPR', 'icon': FontAwesomeIcons.heartPulse, 'route': '/cprTutorial'}, // NEW ROUTE
    {'name': 'Burns', 'icon': FontAwesomeIcons.fireFlameSimple, 'route': '/burnsTutorial'}, // NEW ROUTE
    {'name': 'Gunshot Wounds', 'icon': FontAwesomeIcons.crosshairs, 'route': '/gunshotWoundsTutorial'}, // NEW ROUTE
    {'name': 'Shock', 'icon': FontAwesomeIcons.brain, 'route': '/shockTutorial'}, // NEW ROUTE
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Go back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns as per PDF
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0, // Make items square
          ),
          itemCount: _firstAidCategories.length,
          itemBuilder: (context, index) {
            final category = _firstAidCategories[index];
            return FirstAidCategoryCard(
              title: category['name'],
              icon: category['icon'],
              onTap: () {
                // Navigate to the specific tutorial or placeholder
                if (category['route'] != '/') {
                  Navigator.of(context).pushNamed(category['route']);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${category['name']} tutorial coming soon!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      ),
                      backgroundColor: neonBlue,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Widget for a single First Aid category card
class FirstAidCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FirstAidCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900], // Dark background for cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: neonBlue, width: 1.0), // Neon blue border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: neonBlue.withOpacity(0.3),
        highlightColor: neonBlue.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 48,
              color: neonBlue,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
