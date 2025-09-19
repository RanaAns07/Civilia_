import 'package:civilia_app/screens/ai_aid_screen.dart';
import 'package:civilia_app/screens/crisis_detail_screen.dart';
import 'package:civilia_app/screens/crisis_report_screen.dart';
import 'package:civilia_app/screens/edit_profile_screen.dart';
import 'package:civilia_app/screens/home_screen.dart';
import 'package:civilia_app/screens/login_screen.dart';
import 'package:civilia_app/screens/map_picker_screen.dart';
import 'package:civilia_app/screens/signup_screen.dart';
import 'package:civilia_app/screens/splash_screen.dart';
import 'package:civilia_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:civilia_app/providers/bluetooth_provider.dart'; // New provider
import 'package:civilia_app/firebase_options.dart';
import 'package:civilia_app/screens/bluetooth_chat_screen.dart';
import 'package:civilia_app/screens/profile_screen.dart';

const Color neonBlue = Color(0xFF00FFFF);

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()), // Added Bluetooth provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: neonBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: neonBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 96, fontWeight: FontWeight.w300, color: Colors.white),
        displayMedium: GoogleFonts.inter(fontSize: 60, fontWeight: FontWeight.w400, color: Colors.white),
        displaySmall: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w400, color: Colors.white),
        headlineMedium: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w400, color: Colors.white),
        headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white70),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white54),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white54),
      ),
      colorScheme: ColorScheme.dark(
        primary: neonBlue,
        secondary: neonBlue,
        surface: Colors.grey[900]!,
        background: Colors.black,
        onPrimary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        error: Colors.redAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData( // Added for Bluetooth connection chips
        backgroundColor: Colors.grey[800]!,
        labelStyle: GoogleFonts.inter(color: neonBlue, fontWeight: FontWeight.bold),
        secondaryLabelStyle: GoogleFonts.inter(color: Colors.black),
        elevation: 2,
        padding: const EdgeInsets.all(4),
      ),
      // ... rest of your existing dark theme ...
    );
  }

  ThemeData _lightTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: Colors.black),
        bodyMedium: GoogleFonts.inter(color: Colors.black87),
        titleLarge: GoogleFonts.inter(color: neonBlue, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.inter(color: Colors.black),
        titleSmall: GoogleFonts.inter(color: Colors.black54),
        labelLarge: GoogleFonts.inter(color: Colors.white),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black54),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.black54),
      ),
      colorScheme: ColorScheme.light(
        primary: neonBlue,
        secondary: neonBlue,
        surface: Colors.white,
        background: Colors.white,
        onPrimary: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
        error: Colors.redAccent,
      ),
      chipTheme: ChipThemeData( // Added for Bluetooth connection chips
        backgroundColor: Colors.grey[200]!,
        labelStyle: GoogleFonts.inter(color: neonBlue, fontWeight: FontWeight.bold),
        secondaryLabelStyle: GoogleFonts.inter(color: Colors.white),
        elevation: 2,
        padding: const EdgeInsets.all(4),
      ),
      // ... rest of your existing light theme ...
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Civilia',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(context),
      darkTheme: _darkTheme(context),
      themeMode: themeNotifier.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/crisisReport': (context) => const CrisisReportScreen(),
        '/crisisDetail': (context) => CrisisDetailScreen(incident: ModalRoute.of(context)!.settings.arguments as CrisisIncident),
        '/mapPicker': (context) => const MapPickerScreen(),
        '/firstAidCategories': (context) => const AIAidScreen(),
        '/bluetoothChat': (context) => const BluetoothChatScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/editProfile': (context) => const EditProfileScreen(
          initialUsername: 'User',
          initialEmail: 'user@example.com',
          initialUserType: 'CIVILIAN',
        ),
      },
    );
  }
}