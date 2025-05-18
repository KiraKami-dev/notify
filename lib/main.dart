import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:notify/data/local_notification/notification_service.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/presentation/lifecycle/app_life_cycle.dart';
import 'package:notify/presentation/main/home_page.dart';

// Firebase Cloud Function URL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await NotificationService.init();

  // Initialize SharedPreferences
  await SharedPrefs().init();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService.showForegroundNotification(message);
  });
  runApp(const ProviderScope(child: NotifyApp()));
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

  @override
  Widget build(BuildContext context) {
    return AppLifecycleHandler(
      child: MaterialApp(
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
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purpleAccent,
            secondary: Colors.deepPurpleAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),
        themeMode: ThemeMode.system,
        home: const MessageSenderPage(),
      ),
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();

    if (token != null) {
      ref.read(setMainTokenIdProvider(tokenId: token));
    }
  }
}
