import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Future<void> setupFCM(String role) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get device token
  String? token = await messaging.getToken();
  print("📱 FCM Token: $token");

  if (token != null) {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    final url = Uri.parse(
      'https://lms-latest-dsrn.onrender.com/api/device-tokens/register'
    );
    final body = {
      "role": role,
      "platform": "android",
      "deviceToken": token,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(body),
      );
      print('✅ Token registered on backend: ${response.statusCode}');
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  // Subscribe to topics
  await messaging.subscribeToTopic(role);
  await messaging.subscribeToTopic('all_users');
}