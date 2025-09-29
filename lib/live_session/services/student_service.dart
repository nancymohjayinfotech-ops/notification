import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentService {
  static const String apiUrl =
      'http://54.82.53.11:5001/api/instructor/students?page=1&limit=10';

  static Future<bool> _refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        print('[StudentService] No refresh token found');
        return false;
      }

      const refreshUrl = 'http://54.82.53.11:5001/api/auth/refresh-token';

      final response = await http.post(
        Uri.parse(refreshUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);

        print('[StudentService] Token refreshed successfully');
        return true;
      } else {
        print('[StudentService] Failed to refresh token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[StudentService] Token refresh error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      print('[StudentService] No access token found');
      return [];
    }
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('[StudentService] API response status: ${response.statusCode}');
      print('[StudentService] API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[StudentService] Parsed data: $data');

        // Try to match the structure in student_page.dart
        if (data['data'] != null && data['data']['students'] != null) {
          try {
            final students = List<Map<String, dynamic>>.from(
              data['data']['students'],
            );
            print('[StudentService] Found ${students.length} students');
            if (students.isNotEmpty) return students;
          } catch (e) {
            print('[StudentService] Could not parse students as List<Map>: $e');
          }
        } else {
          print(
            '[StudentService] Data structure mismatch - data: ${data['data']}',
          );
        }
      } else if (response.statusCode == 401) {
        print('[StudentService] Unauthorized - attempting token refresh');
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with the new token
          return fetchStudents();
        } else {
          print('[StudentService] Token refresh failed');
        }
      } else {
        print(
          '[StudentService] HTTP ${response.statusCode} when fetching students',
        );
      }
    } catch (e) {
      // Common on Flutter web if CORS not allowed by remote API
      print('[StudentService] fetchStudents error: $e');
    }
    return [];
  }
}
