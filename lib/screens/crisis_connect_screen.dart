import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';

class CrisisConnectScreen extends StatefulWidget {
  const CrisisConnectScreen({super.key});

  @override
  State<CrisisConnectScreen> createState() => _CrisisConnectScreenState();
}

class _CrisisConnectScreenState extends State<CrisisConnectScreen> {
  int _selectedIndex = 0; // Keep track of current tab (dummy for now)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation logic similar to HomeScreen, but this screen is likely reached via a button
    // For now, we'll just navigate back to home if "Map" is tapped, or to other main screens.
    switch (index) {
      case 0: // Map
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // First Aid
        Navigator.of(context).pushReplacementNamed('/firstAidCategories');
        break;
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
        title: const Text('Crisis Connect'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to previous screen
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Services Hub section
            Card(
              color: Theme.of(context).cardTheme.color, // Use theme color for card
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hub, color: Theme.of(context).iconTheme.color, size: 30), // Use theme color
                        const SizedBox(width: 10),
                        Text(
                          'Emergency Services Hub',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary), // Use theme primary color
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Quick access to essential crisis response and community support resources.',
                      style: Theme.of(context).textTheme.bodyMedium, // Uses theme body medium
                    ),
                    const SizedBox(height: 20),
                    _buildCrisisConnectOption(context, 'Manage Emergency Contacts', Icons.people_alt_outlined),
                    _buildCrisisConnectOption(context, 'Volunteer Opportunities', Icons.volunteer_activism_outlined),
                    _buildCrisisConnectOption(context, 'Find Nearby Safe Zones', Icons.location_on_outlined),
                    _buildCrisisConnectOption(context, 'Explore Full Services', Icons.explore_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // SOS Alert section (as seen on Page 6 of PDF)
            Card(
              color: Theme.of(context).cardTheme.color, // Use theme color for card
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
                        const SizedBox(width: 10),
                        Text(
                          'SOS Alert',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your SOS alert will be immediately dispatched to nearby certified responders and community users within a 5-mile radius, along with your precise location.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This action cannot be undone once sent.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement SOS dispatch logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'SOS alert dispatched! (Placeholder)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                              backgroundColor: neonBlue,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Send SOS Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonBlue, // Use neon blue for the button
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // You can add more sections here if needed, like "Nearby Safe Zones"
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex, // Dummy selected index for this screen
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildCrisisConnectOption(BuildContext context, String title, IconData icon) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Theme.of(context).iconTheme.color), // Use theme color
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium, // Uses theme text style
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), size: 16), // Use theme color
          onTap: () {
            // TODO: Implement navigation for each option
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$title tapped! (Placeholder)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                ),
                backgroundColor: neonBlue,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), height: 1), // Use theme divider color
      ],
    );
  }
}
