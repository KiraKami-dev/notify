import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:notify/config/const_variables.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

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

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
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
      } catch (e) {
        print('Failed to fetch image: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
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
    // Schedule local notification
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.high,
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

    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print('Scheduled time is in the past, notification will not be scheduled');
      return;
    }

    // Schedule local notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      taskId.hashCode,
      'Task Reminder: $title',
      description ?? 'Time to complete your task!',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: taskId,
    );

    
    for (final token in tokens) {
      try {
        await http.post(
          Uri.parse(notificaiotnApiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: {
            'token': token,
            'title': 'Task Reminder: $title',
            'body': description ?? 'Time to complete your task!',
            'data': {
              'taskId': taskId,
              'scheduledTime': scheduledTime.toIso8601String(),
            },
          },
        );
      } catch (e) {
        print('Failed to send FCM notification: $e');
      }
    }
  }

  static Future<void> cancelTaskNotification(String taskId) async {
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
  }

  static Future<void> showTaskReminder({
    required String title,
    String? description,
    required String userId,
  }) async {
    // Show local notification
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.high,
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
        } catch (e) {
          print('Failed to send FCM notification: $e');
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
