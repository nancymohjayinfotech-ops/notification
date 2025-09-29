import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InstructorAuthService {
  // Base URL for authentication
  static const String baseUrl = 'http://54.82.53.11:5001/api/auth';

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userPhoneKey = 'user_phone';
  static const String user_Id = 'user_Id';

  // Send OTP to the provided phone number
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'role': 'instructor'}),
      );

      // Print the response for debugging
      debugPrint('Send OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'data': data['data'] ?? {},
        };
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Verify OTP for the provided phone number
  static Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
      );

      // Print the response for debugging
      debugPrint('Verify OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        // Safely parse the response
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          debugPrint('Error decoding JSON: $e');
          return {'success': false, 'message': 'Invalid response format'};
        }

        // Store tokens in SharedPreferences
        if (data['success'] == true && data['data'] != null) {
          print("fxfgxghfcsgfcsghxchjgcgjh");
          final accessToken = data['data']['accessToken'];
          final refreshToken = data['data']['refreshToken'];
          final user = data['data']['user'];
          final userId = user != null ? user['_id'] : '';

          debugPrint('🔵 INSTRUCTOR OTP VERIFICATION - Tokens from API:');
          debugPrint(
            '🔵 Access Token: ${accessToken?.toString().substring(0, 20) ?? 'null'}...',
          );
          debugPrint(
            '🔵 Refresh Token: ${refreshToken?.toString().substring(0, 20) ?? 'null'}...',
          );
          debugPrint('🔵 User ID: $userId');

          await _saveTokens(
            accessToken,
            refreshToken,
            userId,
            'instructor',
            phoneNumber,
          );

          // Verify tokens were saved
          final prefs = await SharedPreferences.getInstance();
          final savedToken = prefs.getString(accessTokenKey);
          debugPrint(
            '🔵 INSTRUCTOR - Token saved verification: ${savedToken?.substring(0, 20) ?? 'null'}...',
          );
        }

        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified successfully',
          'data': data['data'] ?? {},
        };
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');

      // Provide more specific error message for type errors
      String errorMessage;
      if (e.toString().contains(
        "type 'Null' is not a subtype of type 'String'",
      )) {
        errorMessage = 'Invalid response from server. Please try again.';
      } else {
        errorMessage =
            'Network error. Please check your connection and try again.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Refresh access token using refresh token
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        return {'success': false, 'message': 'No refresh token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Update access token in SharedPreferences
        if (data['success'] == true && data['data'] != null) {
          final newAccessToken = data['data']['accessToken'];
          await prefs.setString(accessTokenKey, newAccessToken);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Token refreshed successfully',
          'data': data['data'] ?? {},
        };
      } else {
        final Map<String, dynamic> error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to refresh token',
        };
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Save tokens to SharedPreferences
  static Future<void> _saveTokens(
    dynamic accessToken,
    dynamic refreshToken,
    dynamic userId,
    String role,
    String phoneNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Safely store tokens, ensuring we don't try to store null values
    if (accessToken != null && accessToken is String) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(accessTokenKey, accessToken);
    }

    if (refreshToken != null && refreshToken is String) {
      await prefs.setString(refreshTokenKey, refreshToken);
    }

    if (userId != null && userId is String) {
      await prefs.setString(userIdKey, userId);
    }

    await prefs.setString(userRoleKey, role);
    await prefs.setString(userPhoneKey, phoneNumber);

    debugPrint(
      'Tokens saved successfully: Access token exists: ${accessToken != null}',
    );
  }

  // Get access token from SharedPreferences
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey) ?? prefs.getString("auth_token");
  }

  // Get refresh token from SharedPreferences
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userIdKey);
    await prefs.remove(userRoleKey);
    await prefs.remove(userPhoneKey);
  }

  // Get a valid access token (refreshes if needed)
  static Future<String?> getValidAccessToken() async {
    // First, try to get the existing token
    String? token = await getAccessToken();

    // If no token found, return null (user needs to login)
    if (token == null || token.isEmpty) {
      return null;
    }

    // Check if token is expired by parsing JWT
    if (isTokenExpired(token)) {
      debugPrint('Access token expired. Attempting to refresh...');
      // Try to refresh the token
      final refreshResult = await refreshToken();

      if (refreshResult['success'] == true) {
        // Get the new token
        token = await getAccessToken();
        debugPrint('Token refreshed successfully');
      } else {
        debugPrint('Failed to refresh token: ${refreshResult['message']}');
        // If refresh fails, return null to trigger login
        return null;
      }
    }

    return token;
  }

  // Check if a JWT token is expired
  static bool isTokenExpired(String token) {
    try {
      // Split the token
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Invalid token format
      }

      // Get the payload part (second part)
      final payload = parts[1];

      // Add padding if needed
      String normalizedPayload = payload;
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }

      // Decode the base64 payload
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decoded);

      // Check the expiration time
      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'];
        final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expiryDateTime);
      }

      return true; // No expiration found, consider expired to be safe
    } catch (e) {
      debugPrint('Error checking token expiration: $e');
      return true; // Consider expired on error
    }
  }

  // Helper method to make authenticated HTTP requests with auto token refresh
  static Future<http.Response> authenticatedRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
  }) async {
    // Get a valid token (refreshes if needed)
    final token = await getValidAccessToken();

    if (token == null) {
      // Token refresh failed or no token available
      throw Exception('Authentication required. Please login again.');
    }

    // Get the user role and ID
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString(userRoleKey) ?? 'instructor';
    final userId = prefs.getString(userIdKey);

    // Make sure userId isn't null
    final String safeUserId = userId ?? '';

    // Print debug info
    debugPrint(
      'Making authenticated request with role: $userRole, userId: $safeUserId',
    );
    debugPrint('Request to URL: $url');
    debugPrint('Request method: $method');

    // Create headers with authentication and role information
    // Try all possible combinations of headers the backend might be expecting
    final Map<String, String> authHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      // Role headers
      'X-User-Role': userRole,
      'role': userRole,
      'X-Role': userRole,
      'userRole': userRole,
      // User ID headers
      'userId': safeUserId,
      'X-User-ID': safeUserId,
      'user-id': safeUserId,
      'X-userId': safeUserId,
      // Custom header
      'isAdmin': 'false', // Explicitly indicate we're not admin
      'isInstructor': 'true', // Explicitly indicate we are instructor
      ...?headers,
    };

    debugPrint('Request headers: $authHeaders');

    // Make the HTTP request based on method
    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: authHeaders);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: authHeaders,
          body: body,
        );
        break;
      case 'PUT':
        response = await http.put(
          Uri.parse(url),
          headers: authHeaders,
          body: body,
        );
        break;

      case 'PATCH':
        response = await http.patch(
          Uri.parse(url),

          headers: authHeaders,

          body: body,
        );

        break;

      case 'DELETE':
        // Print debug info
        debugPrint('DELETE request headers: $authHeaders');

        // Try more advanced handling for DELETE with body
        if (body != null) {
          debugPrint('DELETE request with body: $body');

          // Create a custom request for DELETE with body, as http package doesn't support this directly
          final request = http.Request('DELETE', Uri.parse(url));
          request.headers.addAll(authHeaders);

          // Make sure body is properly encoded as JSON if it's not already a string
          if (body is! String) {
            request.body = jsonEncode(body);
          } else {
            request.body = body;
          }

          final streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else {
          debugPrint('DELETE request without body');
          response = await http.delete(Uri.parse(url), headers: authHeaders);
        }
        break;
      case 'PATCH':
        // Handle PATCH requests using http.Request for custom method support
        debugPrint('PATCH request headers: $authHeaders');

        final request = http.Request('PATCH', Uri.parse(url));
        request.headers.addAll(authHeaders);

        if (body != null) {
          if (body is! String) {
            request.body = jsonEncode(body);
          } else {
            request.body = body;
          }
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // Check if we got a 401 Unauthorized, which might mean the token was rejected despite our refresh
    if (response.statusCode == 401) {
      debugPrint(
        'Still got 401 after token refresh. User needs to re-authenticate.',
      );
      // Clear tokens as they're no longer valid
      await logout();
      throw Exception('Session expired. Please login again.');
    }

    return response;
  }
}
