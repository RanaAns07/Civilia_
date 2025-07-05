import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // Import for neonBlue color

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Data for onboarding pages
  final List<Map<String, String>> _onboardingPages = [
    {
      'image': 'assets/images/onboarding_1.png',
      'title': 'Stay Safe, Stay Connected',
      'description':
      'Real-time location sharing and safety zones keep your loved ones informed during any emergency, ensuring peace of mind.',
    },
    {
      'image': 'assets/images/onboarding_2.png',
      'title': 'Get Real-Time Crisis Alerts',
      'description':
      'Receive immediate notifications and critical updates on emergencies happening near you, keeping you informed and prepared for any situation.',
    },
    {
      'image': 'assets/images/onboarding_3.png',
      'title': 'Access First-Aid Anywhere',
      'description':
      'Ensure you have life-saving medical information readily available, anytime, anywhere - even without an internet connection.',
    },
    {
      'image': 'assets/images/onboarding_3.png',
      'title': 'Offline Messaging, No Internet Needed',
      'description':
      'Stay connected with your loved ones and emergency contacts even when cellular networks are down. Our app uses secure peer-to-peer technology to send vital messages offline.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingPages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                imagePath: _onboardingPages[index]['image']!,
                title: _onboardingPages[index]['title']!,
                description: _onboardingPages[index]['description']!,
                isLastPage: index == _onboardingPages.length - 1,
                onGetStarted: () {
                  // After onboarding, navigate to the login page
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              );
            },
          ),
          // Dot indicators
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15, // Adjusted for better spacing
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingPages.length,
                    (index) => buildDot(index, context),
              ),
            ),
          ),
          // Skip button
          if (_currentPage < _onboardingPages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  // Skip to the login page
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: TextButton.styleFrom(
                  foregroundColor: neonBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: neonBlue.withOpacity(0.5)),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build the dot indicator
  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 10, // Slightly larger dots
      width: _currentPage == index ? 28 : 10, // Wider for active dot
      decoration: BoxDecoration(
        color: _currentPage == index ? neonBlue : Colors.white38,
        borderRadius: BorderRadius.circular(5), // More rounded
        boxShadow: [
          if (_currentPage == index)
            BoxShadow(
              color: neonBlue.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}

// Widget for a single onboarding page
class OnboardingPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final bool isLastPage;
  final VoidCallback onGetStarted;

  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.isLastPage,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.95),
            Colors.black,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Text(
                        'Image Placeholder:\n$title',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40), // Adjusted spacing
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 32, // Larger font size
                color: neonBlue,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: neonBlue.withOpacity(0.5),
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18, // Larger font size
                color: Colors.white70,
                height: 1.5, // Line height for readability
              ),
            ),
            const SizedBox(height: 40),
            // Get Started Button (only on last page)
            if (isLastPage)
              ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55), // Full width, taller button
                  backgroundColor: neonBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // More rounded
                  ),
                  elevation: 8, // Add elevation for depth
                  shadowColor: neonBlue.withOpacity(0.4),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Get Started'),
              ),
            Expanded(flex: isLastPage ? 1 : 2, child: const SizedBox()), // Flexible space for dots
          ],
        ),
      ),
    );
  }
}
