// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:notify/data/local_notification/notification_service.dart';
import 'package:notify/core/services/logger.dart';
import 'package:notify/config/firebase_options.dart';
import 'dart:async';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/presentation/main/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase Cloud Function URL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('FlutterError', error: details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  // Zone-level error handling for uncaught async errors
  await runZonedGuarded<Future<void>>(() async {
    try {
      AppLogger.info('Initializing Firebase...');
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      AppLogger.info('Firebase initialized');

      AppLogger.info('Initializing notification service...');
      await NotificationService.init();
      AppLogger.info('Notification service initialized');

      AppLogger.info('Initializing shared preferences...');
      await SharedPrefs().init();
      AppLogger.info('Shared preferences initialized');

      AppLogger.info('Setting up Firebase Messaging...');
      final messaging = FirebaseMessaging.instance;
    
    // Request notification permissions first
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    AppLogger.info('Notification permission status: ${settings.authorizationStatus}');

    // Get the token
    final token = await messaging.getToken();
    AppLogger.debug('Firebase Messaging token: $token');

    if (token != null) {
      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mainTokenId', token);
      AppLogger.info('Token saved to SharedPreferences');
    } else {
      AppLogger.warn('Firebase token is null');
    }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.debug('Received foreground message');
        NotificationService.showForegroundNotification(message);
      });

      runApp(const ProviderScope(child: NotifyApp()));
    } catch (e, stackTrace) {
      AppLogger.error('Error during initialization', error: e, stackTrace: stackTrace);
      // Still run the app even if there's an error
      runApp(const ProviderScope(child: NotifyApp()));
    }
  }, (error, stack) {
    AppLogger.error('Uncaught zone error', error: error, stackTrace: stack);
  });
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
      AppLogger.info('Notification permission status: ${settings.authorizationStatus}');

      final token = await messaging.getToken();

      if (token != null) {
        // Update both SharedPreferences and provider
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mainTokenId', token);
        ref.read(setMainTokenIdProvider(tokenId: token));
        AppLogger.info('Token updated in both SharedPreferences and provider');
      } else {
        AppLogger.warn('Firebase token is null during reinitialization');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing Firebase Messaging', error: e, stackTrace: stackTrace);
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
