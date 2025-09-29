import 'dart:convert';
import '../services/api_client.dart'; // ✅ ApiClient import kiya
import 'package:flutter/foundation.dart';

class StudentNotificationService {
  static const String baseUrl = "http://54.82.53.11:5001/api";

  /// ✅ Get all notifications
  static Future<List<dynamic>> getNotifications() async {
    final response = await ApiClient().authenticatedRequest(
      (dio) => dio.get("$baseUrl/notifications/"),
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data;
      if (data is Map && data.containsKey("data")) {
        return data["data"];
      }
      return [];
    } else {
      throw Exception("❌ Failed to load notifications");
    }
  }

  /// ✅ Get unread count
  static Future<int> getUnreadCount() async {
    final response = await ApiClient().authenticatedRequest(
      (dio) => dio.get("$baseUrl/notifications/unread-count"),
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data;
      return (data as Map)["unreadCount"] ?? 0;
    }
    return 0;
  }

  /// ✅ Mark single notification as read
  static Future<void> markAsRead(String notificationId) async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.patch("$baseUrl/notifications/$notificationId/read"),
    );
  }

  /// ✅ Mark multiple notifications as read
  static Future<void> markMultipleAsRead(List<String> ids) async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.patch(
        "$baseUrl/notifications/mark-multiple-read",
        data: jsonEncode({"notificationIds": ids}),
      ),
    );
  }

  /// ✅ Mark all notifications as read
  static Future<void> markAllAsRead() async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.patch("$baseUrl/notifications/mark-all-read"),
    );
  }

  /// ✅ Delete notification
  static Future<void> deleteNotification(String id) async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.delete("$baseUrl/notifications/$id"),
    );
  }

  /// ✅ Add device token
  static Future<void> addDeviceToken(String token) async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.post(
        "$baseUrl/device-tokens/",
        data: jsonEncode({"deviceId": token}),
      ),
    );
  }

  /// ✅ Delete device token
  static Future<void> deleteDeviceToken(String token) async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.delete(
        "$baseUrl/device-tokens/",
        data: jsonEncode({"deviceId": token}),
      ),
    );
  }

  /// ✅ Test push notification
  static Future<void> testPush(String deviceId) async {
    await ApiClient().authenticatedRequest(
      (dio) => dio.post(
        "$baseUrl/device-tokens/test",
        data: jsonEncode({
          "deviceId": deviceId,
          "title": "Test Notification",
          "message": "This is a test notification",
        }),
      ),
    );
  }
}
