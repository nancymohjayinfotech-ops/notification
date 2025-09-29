import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = "http://54.82.53.11:5001/api";

  /// ✅ Get all notifications
  static Future<List<dynamic>> getNotifications() async {
    final response = await InstructorAuthService.authenticatedRequest(
      method: 'GET',
      url: "$baseUrl/notifications/",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // backend: { success, data: [ ... ], pagination, unreadCount }
      if (data is Map && data.containsKey("data")) {
        return data["data"];
      }
      return [];
    } else {
      throw Exception("Failed to load notifications: ${response.statusCode}");
    }
  }

  /// ✅ Get unread count
  static Future<int> getUnreadCount() async {
    final response = await InstructorAuthService.authenticatedRequest(
      method: 'GET',
      url: "$baseUrl/notifications/unread-count",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["unreadCount"] ?? 0;
    }
    return 0;
  }

  /// ✅ Mark single notification as read
  static Future<void> markAsRead(String notificationId) async {
    await InstructorAuthService.authenticatedRequest(
      method: 'PATCH',
      url: "$baseUrl/notifications/$notificationId/read",
    );
  }

  /// ✅ Mark multiple notifications as read
  static Future<void> markMultipleAsRead(List<String> ids) async {
    await InstructorAuthService.authenticatedRequest(
      method: 'PATCH',
      url: "$baseUrl/notifications/mark-multiple-read",
      body: jsonEncode({"notificationIds": ids}),
    );
  }

  /// ✅ Mark all notifications as read
  static Future<void> markAllAsRead() async {
    await InstructorAuthService.authenticatedRequest(
      method: 'PATCH',
      url: "$baseUrl/notifications/mark-all-read",
    );
  }

  /// ✅ Delete notification
  static Future<void> deleteNotification(String id) async {
    await InstructorAuthService.authenticatedRequest(
      method: 'DELETE',
      url: "$baseUrl/notifications/$id",
    );
  }

  /// ✅ Add device token
  static Future<void> addDeviceToken(String token) async {
    await InstructorAuthService.authenticatedRequest(
      method: 'POST',
      url: "$baseUrl/device-tokens/",
      body: jsonEncode({"deviceId": token}),
    );
  }

  /// ✅ Delete device token
  static Future<void> deleteDeviceToken(String token) async {
    await InstructorAuthService.authenticatedRequest(
      method: 'DELETE',
      url: "$baseUrl/device-tokens/",
      body: jsonEncode({"deviceId": token}),
    );
  }

  /// ✅ Test push notification
  static Future<void> testPush(String deviceId) async {
    await InstructorAuthService.authenticatedRequest(
      method: 'POST',
      url: "$baseUrl/device-tokens/test",
      body: jsonEncode({
        "deviceId": deviceId,
        "title": "Test Notification",
        "message": "This is a test notification",
      }),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:fluttertest/instructor/services/auth_service.dart';
// import 'package:http/http.dart' as http;

// class NotificationService {
//   static const String baseUrl = 'http://54.82.53.11:5001/api';

//   /// Get all notifications
//   static Future<List<dynamic>> getNotifications() async {
//     try {
//       final response = await InstructorAuthService.authenticatedRequest(
//         method: 'GET',
//         url: '$baseUrl/notifications/',
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data is List) {
//           return data; // API returns an array
//         }
//         return data['data'] ?? [];
//       } else {
//         throw Exception('Failed to fetch notifications: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint("❌ getNotifications error: $e");
//       rethrow;
//     }
//   }

//   /// Get unread notification count
//   static Future<int> getUnreadCount() async {
//     try {
//       final response = await InstructorAuthService.authenticatedRequest(
//         method: 'GET',
//         url: '$baseUrl/notifications/unread-count',
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['unreadCount'] ?? 0;
//       } else {
//         throw Exception('Failed to fetch unread count');
//       }
//     } catch (e) {
//       debugPrint("❌ getUnreadCount error: $e");
//       rethrow;
//     }
//   }

//   /// Mark single notification as read
//   static Future<void> markAsRead(String notificationId) async {
//     try {
//       final response = await InstructorAuthService.authenticatedRequest(
//         method: 'PATCH',
//         url: '$baseUrl/notifications/$notificationId/read',
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Failed to mark as read');
//       }
//     } catch (e) {
//       debugPrint("❌ markAsRead error: $e");
//       rethrow;
//     }
//   }

//   /// Mark all notifications as read
//   static Future<void> markAllAsRead() async {
//     try {
//       final response = await InstructorAuthService.authenticatedRequest(
//         method: 'PATCH',
//         url: '$baseUrl/notifications/mark-all-read',
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Failed to mark all as read');
//       }
//     } catch (e) {
//       debugPrint("❌ markAllAsRead error: $e");
//       rethrow;
//     }
//   }

//   /// Delete a notification
//   static Future<void> deleteNotification(String notificationId) async {
//     try {
//       final response = await InstructorAuthService.authenticatedRequest(
//         method: 'DELETE',
//         url: '$baseUrl/notifications/$notificationId',
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Failed to delete notification');
//       }
//     } catch (e) {
//       debugPrint("❌ deleteNotification error: $e");
//       rethrow;
//     }
//   }

//   /// Add device token (for push notifications)
//   static Future<void> addDeviceToken(String deviceToken) async {
//     try {
//       final response = await InstructorAuthService.authenticatedRequest(
//         method: 'POST',
//         url: '$baseUrl/device-tokens/',
//         body: jsonEncode({'deviceId': deviceToken}),
//       );

//       if (response.statusCode != 200 && response.statusCode != 201) {
//         throw Exception('Failed to add device token');
//       }
//     } catch (e) {
//       debugPrint("❌ addDeviceToken error: $e");
//       rethrow;
//     }
//   }
// }
