import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';

import 'package:fluttertest/student/services/token_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Local notifications plugin
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM + Local notifications
  static Future<void> init({required String role}) async {
    // 1️⃣ Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // 2️⃣ Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: null,
      macOS: null,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationClick(details.payload);
      },
    );

    // 3️⃣ Get device token
    String? token = await _messaging.getToken(
      vapidKey: kIsWeb
          ? "BH45PeaUONwe4MhotY4U-sjrEm1TXW8QYz_uOzOG5qVW0Ngi8WV0N8HDkQCDv1il5l-pICsF3AzMYkjX8j-AHrw"
          : null,
    );

    if (token != null) {
      debugPrint("FCM Token: $token");

      // Send token + role to backend
      await _sendTokenToBackend(token, role);
    }

    // 4️⃣ Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Foreground message: ${message.notification?.title} - ${message.notification?.body}',
      );
      _showLocalNotification(message);
    });

    // 5️⃣ When user taps a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'Notification clicked: ${message.notification?.title} - ${message.notification?.body}',
      );
      _handleNotificationClick(jsonEncode(message.data));
    });
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformDetails,
      payload: jsonEncode(message.data), // send data to payload
    );
  }

  // Handle click
  static void _handleNotificationClick(String? payload) {
    if (payload == null) return;

    final data = jsonDecode(payload);

    // Example: navigate based on role or type
    final role = data['role'] ?? '';
    final type = data['type'] ?? '';

    debugPrint('Notification payload: $data');

    // TODO: Implement navigation based on role/type
    // Example:
    // if (role == 'student') Navigator.pushNamed(context, '/studentPage');
    // if (role == 'instructor') Navigator.pushNamed(context, '/instructorPage');
       if (type == 'course_created') {

      navigatorKey.currentState?.pushNamed('/all-courses');

    } else if (type == 'quiz_pending') {

      navigatorKey.currentState?.pushNamed('/dashboard');

    } else if (type == 'payment_success') {

      navigatorKey.currentState?.pushNamed('/cart');

    } else if (type == 'verify_instructor') {

      navigatorKey.currentState?.pushNamed('/instructordashboard');

    }
  }

  // Send token to backend
  static Future<void> _sendTokenToBackend(String token, String role) async {
    final url = Uri.parse(
      'http://54.82.53.11:5001/api/device-tokens/register/',
    );

    final accessToken = await TokenService().getAccessToken();

    final body = {"role": role, "deviceToken": token};

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null) "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(body),
      );

      debugPrint('Device token registered: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
    } catch (e) {
      debugPrint('Error sending token to backend: $e');
    }
  }
}
