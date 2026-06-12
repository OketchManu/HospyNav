import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:hospy_nav/firebase_options.dart';
import 'package:hospy_nav/screens/home_screen.dart';
import 'package:hospy_nav/screens/login_screen.dart';
import 'package:hospy_nav/screens/register_screen.dart';
import 'package:hospy_nav/screens/settings_screen.dart';
import 'package:hospy_nav/screens/profile_screen.dart' as profile;
import 'package:hospy_nav/screens/feedback_screen.dart' as feedback;
import 'package:hospy_nav/screens/emergency_contacts_screen.dart';
import 'package:hospy_nav/screens/help_screen.dart';
import 'package:hospy_nav/screens/notifications_screen.dart';
import 'package:hospy_nav/screens/first_aid_videos_screen.dart';
import 'package:hospy_nav/screens/hospital_finder_screen.dart';
import 'package:hospy_nav/services/authentication_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = Logger('HospyNav');

Future<void> initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env');
      _logger.info('Environment variables loaded from .env');
    } catch (e) {
      _logger.warning(
        'Could not load .env file. Copy .env.example to .env and add your API keys.',
      );
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.info('Firebase initialized successfully');
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
    _logger.info('App initialization completed successfully');
  } catch (e, stackTrace) {
    _logger.severe('Error in initializeApp', e, stackTrace);
    rethrow;
  }
}

void main() async {
  try {
    await initializeApp();
    runApp(const HospyNavApp());
  } catch (e, stackTrace) {
    _logger.severe('Error initializing app', e, stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

class HospyNavApp extends StatefulWidget {
  const HospyNavApp({super.key});

  @override
  HospyNavAppState createState() => HospyNavAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<HospyNavAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, bool isDarkMode) {
    final state = context.findAncestorStateOfType<HospyNavAppState>();
    state?.setThemeMode(isDarkMode);
  }
}

class HospyNavAppState extends State<HospyNavApp> {
  Locale? _locale;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _logger.info('HospyNavAppState initialized');
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
      _logger.info('Locale set to: $locale');
    });
  }

  void setThemeMode(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
      _saveThemePreference(isDarkMode);
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HospyNav',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        hintColor: const Color(0xFF43A047),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF212121)),
          bodyMedium: TextStyle(color: Color(0xFF212121)),
        ),
        buttonTheme: const ButtonThemeData(buttonColor: Color(0xFF1976D2)),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF1E88E5),
        hintColor: const Color(0xFF43A047),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        buttonTheme: const ButtonThemeData(buttonColor: Color(0xFF1976D2)),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('sw', 'KE'),
        Locale('luo', 'KE'),
        Locale('kik', 'KE'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: const AuthenticationWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const profile.ProfileScreen(),
        '/emergency_contacts': (context) => const EmergencyContactsScreen(),
        '/feedback': (context) => const feedback.FeedbackScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/help': (context) => const HelpScreen(),
        '/first_aid': (context) => const FirstAidVideosScreen(),
        '/hospitals': (context) => const HospitalFinderScreen(),
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'An error occurred during initialization',
                style: TextStyle(fontSize: 16),
              ),
              if (!const bool.fromEnvironment('dart.vm.product'))
                Text(
                  error,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => main(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
