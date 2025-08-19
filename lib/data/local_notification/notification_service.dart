import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:notify/config/const_variables.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:notify/core/services/logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Set your local timezone

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        AppLogger.debug('Notification tapped: ${response.payload}');
      },
    );

    // Request FCM permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title;
    final body = message.notification?.body;
    final imageUrl = message.data['image'];

    BigPictureStyleInformation? bigPictureStyleInformation;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final byteArray = response.bodyBytes;
          bigPictureStyleInformation = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(byteArray),
            largeIcon: ByteArrayAndroidBitmap(byteArray),
            contentTitle: title,
            summaryText: body,
          );
        }
      } catch (e, s) {
        AppLogger.warn('Failed to fetch notification image', error: e, stackTrace: s);
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      styleInformation: bigPictureStyleInformation,
    );

    final iosDetails = const DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required DateTime scheduledTime,
    String? description,
    required List<String> tokens,
  }) async {
    if (tokens.isEmpty) {
      AppLogger.warn('No tokens provided for notification');
      return;
    }

    // Convert to UTC for consistent timezone handling
    final utcScheduledTime = scheduledTime.toUtc();
    
    // Validate scheduled time is in the future
    if (utcScheduledTime.isBefore(DateTime.now().toUtc())) {
      AppLogger.warn('Cannot schedule notification in the past');
      return;
    }

    // Send scheduled notification request for each token
    for (final token in tokens) {
      if (token.isEmpty) {
        AppLogger.warn('Skipping empty token');
        continue;
      }

      try {
        AppLogger.info('Scheduling notification for time: ${utcScheduledTime.toIso8601String()}');
        
        final requestBody = {
          'token': token,
          'title': title,
          'body': description ?? 'Time to complete your task!',
          'scheduledTime': utcScheduledTime.toIso8601String(),
          'taskId': taskId,
          'image': '',
        };
        
        AppLogger.debug('Request body: ${json.encode(requestBody)}');
        
        final response = await http.post(
          Uri.parse('https://schedulenotification-pjkmgzabia-uc.a.run.app'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(requestBody),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );
        
        AppLogger.debug('Response status: ${response.statusCode}');
        AppLogger.debug('Response body: ${response.body}');
        
        if (response.statusCode != 200) {
          AppLogger.warn('Failed to schedule notification: ${response.body}');
          throw Exception('Failed to schedule notification: ${response.body}');
        } else {
          AppLogger.info('Successfully scheduled notification for ${utcScheduledTime.toIso8601String()}');
        }
      } on TimeoutException {
        AppLogger.warn('Request timed out while scheduling notification');
      } catch (e, s) {
        AppLogger.error('Failed to schedule notification', error: e, stackTrace: s);
        rethrow; // Rethrow to handle in the UI if needed
      }
    }
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
  }

  static Future<void> showTaskReminder({
    required String title,
    String? description,
    required List<String> userId,
  }) async {
    // Show local notification
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.high,
      icon: 'ic_notification',
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      'Task Reminder: $title',
      description ?? 'Time to complete your task!',
      notificationDetails,
    );

    // Get all device tokens for the user
    final prefs = await SharedPreferences.getInstance();
    final deviceTokens = prefs.getStringList('device_tokens_$userId') ?? [];

    // Send FCM notification to all user's devices
    for (final token in deviceTokens) {
      if (token != await _firebaseMessaging.getToken()) {
        // Don't send to current device as we already showed local notification
        try {
          await http.post(
            Uri.parse(notificaiotnApiUrl), // Replace with your cloud function URL
            headers: {
              'Content-Type': 'application/json',
            },
            body: {
              'token': token,
              'title': 'Task Reminder: $title',
              'body': description ?? 'Time to complete your task!',
              'data': {
                'type': 'immediate_reminder',
              },
            },
          );
        } catch (e, s) {
          AppLogger.error('Failed to send FCM notification', error: e, stackTrace: s);
        }
      }
    }
  }

  // Call this method when a user logs in on a new device
  static Future<void> registerDeviceToken(String userId) async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final deviceTokens = prefs.getStringList('device_tokens_$userId') ?? [];
      if (!deviceTokens.contains(token)) {
        deviceTokens.add(token);
        await prefs.setStringList('device_tokens_$userId', deviceTokens);
      }
    }
  }
}
