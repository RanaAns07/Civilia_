import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:civilia_app/main.dart'; // For neonBlue
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:civilia_app/widgets/bottom_navigation_bar.dart'; // Import CustomBottomNavigationBar

class AIAidScreen extends StatefulWidget {
  const AIAidScreen({super.key});

  @override
  State<AIAidScreen> createState() => _AIAidScreenState();
}

class _AIAidScreenState extends State<AIAidScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _aiResponse = '';
  bool _isLoadingAI = false;
  String _selectedLanguage = 'English'; // Default language
  int _selectedIndex = 1; // First Aid tab is at index 1 in the bottom navigation bar

  // IMPORTANT: Replace with your actual Gemini API Key
  // Note: For security, consider fetching this from a secure backend or environment variable in a real app.
  final String _geminiApiKey = "AIzaSyD8aVV85uSoFq7TilD2lQcxHKtVhi99574"; // Placeholder
  final String _geminiApiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  final List<String> _suggestedInjuries = [
    'Bleeding wound',
    'Burns',
    'Broken bone',
    'Choking',
    'Unconsciousness',
    'Heart attack',
    'Seizure',
    'Shock',
    'Snake bite',
    'Sprain',
    'Dehydration',
    'Hypothermia'
  ];

  final List<String> _supportedLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Arabic',
    'Urdu', // Added Urdu as an example
    // Add more languages as needed and supported by Gemini API
  ];

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black, Colors.black, Colors.black],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // Handles tapping on suggested injury chips
  void _onInjuryChipTapped(String injury) {
    setState(() {
      _promptController.text = injury;
      _aiResponse = ''; // Clear previous AI response
    });
    _getFirstAidAdvice(); // Automatically get advice for the selected chip
  }

  // Fetches first aid advice from the Gemini AI model
  Future<void> _getFirstAidAdvice() async {
    final String promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      _showSnackBar('Please describe symptoms or select an injury.', isError: true);
      return;
    }

    setState(() {
      _isLoadingAI = true;
      _aiResponse = ''; // Clear previous response
    });

    try {
      String aiPrompt =
          "Provide step-by-step first aid instructions for: \"$promptText\". "
          "Make the steps clear, concise, easy to understand, and human-friendly. "
          "Respond in $_selectedLanguage. Format the response using Markdown (e.g., bold for headings, numbered lists, bullet points).";

      // IMPORTANT: If you want to use models other than gemini-2.0-flash,
      // you would need to provide an API key here. Otherwise, leave it as-is.
      final String apiKey = _geminiApiKey; // Canvas will automatically provide the API key at runtime if empty

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {"role": "user", "parts": [{"text": aiPrompt}]}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        setState(() {
          _aiResponse = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
              "Sorry, I couldn't understand the query or provide relevant advice.";
        });
      } else {
        debugPrint('AI API Error: ${response.statusCode} - ${response.body}');
        _aiResponse = "Error connecting to AI. Please try again later. Status: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint('AI API Network Error: $e');
      _aiResponse = "Network error. Please check your connection and try again.";
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  // Displays a snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Handles navigation for the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0: // Map
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // First Aid (stay on this screen)
        break;
      case 2: // Messages
        Navigator.of(context).pushReplacementNamed('/messageList');
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      default:
        break;
    }
  }

  // Builds the input section for symptoms and language selection
  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
      children: [
        TextField(
          controller: _promptController,
          onChanged: (text) {
            // ALWAYS call setState here to rebuild the UI and re-evaluate button state
            setState(() {
              if (_aiResponse.isNotEmpty) {
                _aiResponse = ''; // Clear previous AI response if user starts typing again
              }
              // No need to do anything else here, just rebuild to update button state
            });
          },
          decoration: InputDecoration(
            hintText: 'Describe symptoms or injury (e.g., "severe cut on arm")',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neonBlue.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neonBlue.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neonBlue, width: 2),
            ),
            prefixIcon: Icon(Icons.text_fields, color: neonBlue),
          ),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _promptController.text.trim().isEmpty || _isLoadingAI
              ? null
              : _getFirstAidAdvice,
          icon: const Icon(Icons.medical_services_outlined),
          label: const Text('Get First Aid Advice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonBlue,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Show suggested injuries only if there's no AI response
        if (_aiResponse.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Injuries:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: neonBlue),
                ),
                const SizedBox(height: 10),
                Center( // Centered the Wrap for suggestions
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _suggestedInjuries.map((injury) {
                      return ActionChip(
                        label: Text(injury, style: Theme.of(context).textTheme.bodyMedium),
                        backgroundColor: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: neonBlue.withOpacity(0.5)),
                        ),
                        onPressed: () => _onInjuryChipTapped(injury),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Re-introducing AppBar for title and language selection
        title: const Text('AI First Aid Assistant'),
        centerTitle: true,
        actions: [
          // Language Dropdown moved to AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                icon: Icon(Icons.language, color: neonBlue),
                dropdownColor: Theme.of(context).cardColor,
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                },
                items: _supportedLanguages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(gradient: backgroundGradient),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children horizontally
              children: [
                _buildInputSection(),
                const SizedBox(height: 30),
                if (_isLoadingAI)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: neonBlue),
                        const SizedBox(height: 20),
                        Text('Analyzing symptoms...',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                if (_aiResponse.isNotEmpty)
                  MarkdownBody(
                    data: _aiResponse,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      h1: Theme.of(context).textTheme.headlineSmall?.copyWith(color: neonBlue, fontWeight: FontWeight.bold),
                      h2: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      h3: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      strong: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: neonBlue),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
