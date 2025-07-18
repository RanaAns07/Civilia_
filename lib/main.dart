import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:civilia/firebase_options.dart';
import 'package:civilia/screens/splash_screen.dart';
import 'package:civilia/screens/welcome_screen.dart';
import 'package:civilia/screens/login_screen.dart';
import 'package:civilia/screens/signup_screen.dart';
import 'package:civilia/screens/home_screen.dart';
import 'package:civilia/screens/crisis_connect_screen.dart';
import 'package:civilia/screens/first_aid_categories_screen.dart';
import 'package:civilia/screens/bleeding_control_tutorial_screen.dart';
import 'package:civilia/screens/fractures_tutorial_screen.dart';
import 'package:civilia/screens/cpr_tutorial_screen.dart';
import 'package:civilia/screens/burns_tutorial_screen.dart';
import 'package:civilia/screens/gunshot_wounds_tutorial_screen.dart';
import 'package:civilia/screens/shock_tutorial_screen.dart';
import 'package:civilia/screens/message_list_screen.dart';
import 'package:civilia/screens/messages_screen.dart';
import 'package:civilia/screens/profile_screen.dart';
import 'package:civilia/screens/wifi_direct_connect_screen.dart';
import 'package:civilia/screens/ai_chatbot_screen.dart';
import 'package:civilia/screens/crisis_report_screen.dart';
import 'package:civilia/screens/crisis_detail_screen.dart';
import 'package:civilia/screens/map_picker_screen.dart';
import 'package:provider/provider.dart'; // NEW: Import MapPickerScreen

// Define the custom neon blue color
const Color neonBlue = Color(0xFF00FFFF);

// ThemeNotifier for managing theme state
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// Ensure main is async to allow Firebase.initializeApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase initialization

  // Initialize Firebase using the options generated by FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Dark Theme Definition
  ThemeData _darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: neonBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: neonBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: neonBlue, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white70),
        labelLarge: TextStyle(color: Colors.black), // For Elevated Button text
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blueGrey,
        accentColor: neonBlue,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: neonBlue,
        background: Colors.black,
        onBackground: Colors.white,
        surface: Colors.grey[900], // Cards, dialogs
        onSurface: Colors.white,
        primary: neonBlue,
        onPrimary: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: neonBlue,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: neonBlue),
      ),
      iconTheme: const IconThemeData(
        color: neonBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return neonBlue;
          }
          return Colors.grey[600];
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return neonBlue.withOpacity(0.5);
          }
          return Colors.grey[800];
        }),
      ),
    );
  }

  // Light Theme Definition
  ThemeData _lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1, // Small shadow for contrast
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: neonBlue, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.black),
        titleSmall: TextStyle(color: Colors.black54),
        labelLarge: TextStyle(color: Colors.white), // For Elevated Button text
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
        accentColor: neonBlue,
        brightness: Brightness.light,
      ).copyWith(
        secondary: neonBlue,
        background: Colors.white,
        onBackground: Colors.black,
        surface: Colors.white, // Cards, dialogs
        onSurface: Colors.black,
        primary: neonBlue,
        onPrimary: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[100], // Light grey for cards
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: neonBlue,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonBlue, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.grey),
        labelStyle: const TextStyle(color: neonBlue),
      ),
      iconTheme: const IconThemeData(
        color: neonBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return neonBlue;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return neonBlue.withOpacity(0.5);
          }
          return Colors.grey[400];
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Civilia',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(context), // Default to light theme initially if desired
      darkTheme: _darkTheme(context),
      themeMode: themeNotifier.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/crisisConnect': (context) => const CrisisConnectScreen(),
        '/firstAidCategories': (context) => const FirstAidCategoriesScreen(),
        '/bleedingControlTutorial': (context) => const BleedingControlTutorialScreen(),
        '/fracturesTutorial': (context) => const FracturesTutorialScreen(),
        '/cprTutorial': (context) => const CPRTutorialScreen(),
        '/burnsTutorial': (context) => const BurnsTutorialScreen(),
        '/gunshotWoundsTutorial': (context) => const GunshotWoundsTutorialScreen(),
        '/shockTutorial': (context) => const ShockTutorialScreen(),
        '/messageList': (context) => const MessageListScreen(),
        '/messages': (context) => const MessagesScreen(chatTitle: 'Chat', conversationId: 'default_chat_id'),
        '/profile': (context) => const ProfileScreen(),
        '/wifiDirectConnect': (context) => const WifiDirectConnectScreen(),
        '/aiChatbot': (context) => const AiChatbotScreen(),
        '/reportCrisis': (context) => const CrisisReportScreen(),
        '/mapPicker': (context) => const MapPickerScreen(), // NEW: Add MapPickerScreen route
      },
    );
  }
}
