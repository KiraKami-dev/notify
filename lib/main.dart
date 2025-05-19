// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:notify/data/local_notification/notification_service.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/presentation/lifecycle/app_life_cycle.dart';
import 'package:notify/presentation/main/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase Cloud Function URL

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Initializing Firebase...');
    await Firebase.initializeApp();
    print('Firebase initialized');

    print('Initializing notification service...');
    await NotificationService.init();
    print('Notification service initialized');

    print('Initializing shared preferences...');
    await SharedPrefs().init();
    print('Shared preferences initialized');

    print('Setting up Firebase Messaging...');
    final messaging = FirebaseMessaging.instance;
    
    // Request notification permissions first
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('Notification permission status: ${settings.authorizationStatus}');

    // Get the token
    final token = await messaging.getToken();
    print('Firebase Messaging token: $token');

    if (token != null) {
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mainTokenId', token);
      print('Token saved to SharedPreferences');
    } else {
      print('Warning: Firebase token is null');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message');
      NotificationService.showForegroundNotification(message);
    });

    runApp(const ProviderScope(child: NotifyApp()));
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
    // Still run the app even if there's an error
    runApp(const ProviderScope(child: NotifyApp()));
  }
}

class NotifyApp extends ConsumerStatefulWidget {
  const NotifyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NotifyAppState();
}

class _NotifyAppState extends ConsumerState<NotifyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      print('Notification permission status: ${settings.authorizationStatus}');

      final token = await messaging.getToken();
      print('Reinitializing Firebase Messaging token: $token');

      if (token != null) {
        // Update both SharedPreferences and provider
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mainTokenId', token);
        ref.read(setMainTokenIdProvider(tokenId: token));
        print('Token updated in both SharedPreferences and provider');
      } else {
        print('Warning: Firebase token is null during reinitialization');
      }
    } catch (e, stackTrace) {
      print('Error initializing Firebase Messaging: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          secondary: Colors.deepPurpleAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      // darkTheme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(
      //     seedColor: Colors.purpleAccent,
      //     secondary: Colors.deepPurpleAccent,
      //     brightness: Brightness.dark,
      //   ),
      //   useMaterial3: true,
      //   fontFamily: 'Poppins',
      // ),
      // themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
