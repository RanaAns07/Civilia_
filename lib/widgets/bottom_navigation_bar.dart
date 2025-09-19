import 'package:flutter/material.dart';
import 'package:civilia_app/main.dart'; // For neonBlue

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Use surface color for the bar
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5), // Shadow at the top
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              label: 'First Aid',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: neonBlue, // Selected icon and label color
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color, // Unselected icon and label color
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensures all items are visible
          backgroundColor: Theme.of(context).colorScheme.surface, // Ensure background matches container
          elevation: 0, // No default elevation, handled by container's boxShadow
          selectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: neonBlue, fontWeight: FontWeight.bold),
          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
