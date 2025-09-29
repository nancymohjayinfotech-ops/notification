// api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  static const String baseUrl = 'http://54.82.53.11:5001/api';

  // Fetch instructor groups with automatic token refresh
  static Future<List<dynamic>> fetchInstructorGroups() async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/groups',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['groups'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to load groups');
        }
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        debugPrint('Authentication needed: $e');
      }
      rethrow;
    }
  }

  // Create a new group with automatic token refresh
  static Future<Map<String, dynamic>> createGroup(
    String name,
    String description,
  ) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'POST',
        url: '$baseUrl/instructor/groups',
        body: jsonEncode({'name': name, 'description': description}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        debugPrint('Authentication needed: $e');
      }
      rethrow;
    }
  }

  // Fetch user profile with automatic token refresh
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // 1. Get the access token
      final token = await InstructorAuthService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception("No access token found. Please login.");
      }

      // 2. Make GET request
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 3. Parse response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        print(">>>>>>>>>>>>>>>><<<<<<<<<<<<");
        if (data['success'] == true && data['user'] != null) {
          // return Map<String, dynamic>.from(data['user']); // always a Map
          print(">>>>>>>>>>>>>>>><<<<<<<<<<<<");
          return Map<String, dynamic>.from(data); // return entire data
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch profile');
        }
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Get Profile Error: $e');
      rethrow;
    }
  }

  // Update user profile with automatic token refresh
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'PUT',
        url: '$baseUrl/instructor/profile',
        body: jsonEncode(data),
      );

      print("REQUEST BODY: ${jsonEncode(data)}");
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Agar backend success field bhej raha hai
        if (responseData.containsKey('success')) {
          if (responseData['success'] == true) {
            return responseData['data'] ?? responseData;
          } else {
            throw Exception(
              responseData['message'] ?? 'Failed to update profile',
            );
          }
        }

        // Agar backend sirf updated object bhej raha hai (no success flag)
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ??
              'Failed to update profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("ccccccccccccccccccccccccc $e");
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        debugPrint('Authentication needed: $e');
      }
      rethrow;
    }
  }

  // Upload profile image with automatic token refresh
  static Future<Map<String, dynamic>> uploadProfileImage(
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final url = '$baseUrl/uploads/profile';
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header using token from InstructorAuthService
      final token = await InstructorAuthService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }
      request.headers['Authorization'] = 'Bearer $token';

      // Detect MIME type based on file name
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          fileBytes,
          filename: fileName,
          contentType: mimeType.contains('image')
              ? MediaType.parse(mimeType)
              : MediaType.parse('application/octet-stream'),
        ),
      );

      final response = await request.send();
      final httpResponse = await http.Response.fromStream(response);

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        print(
          ";??????????>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<",
        );
        print(fileBytes);
        final Map<String, dynamic> responseData = jsonDecode(httpResponse.body);
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to upload profile image',
          );
        }
      } else {
        final errorData = jsonDecode(httpResponse.body);
        throw Exception(
          errorData['message'] ??
              'Failed to upload profile image: ${httpResponse.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        debugPrint('Authentication needed: $e');
      }
      rethrow;
    }
  }
}
