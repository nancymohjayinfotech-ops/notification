import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_service.dart';

class ApiService {
  static const String baseUrl = 'http://54.82.53.11:5001';

  // Authentication endpoints
  static const String registerAdminEndpoint = '/api/auth/register-admin';
  static const String adminLoginEndpoint = '/api/auth/admin-login';
  static const String dashboardStatsEndpoint = '/api/admin/dashboard/stats';
  static const String updatePasswordEndpoint = '/api/admin/profile/password';
  static const String logoutEndpoint = '/api/admin/logout';
  static const String profileEndpoint = '/api/admin/profile';
  static const String uploadProfileImageEndpoint = '/api/uploads/profile';
  static const String studentsEndpoint = '/api/admin/students';
  static const String instructorsEndpoint = '/api/admin/instructors';
  static const String instructorStatsEndpoint = '/api/admin/instructors/stats';
  static const String eventsStatsEndpoint = '/api/admin/events/stats';
  static const String eventsEndpoint = '/api/admin/events';
  static const String uploadEventImagesEndpoint = '/api/uploads/event/images';
  static const String uploadEventVideosEndpoint = '/api/uploads/event/videos';
  static const String coursesStatsEndpoint = '/api/admin/courses/stats';
  static const String coursesEndpoint = '/api/admin/courses';
  static const String uploadCourseImageEndpoint = '/api/uploads/course/image';
  static const String uploadCourseVideoEndpoint = '/api/uploads/course/video';

  // Groups endpoints
  static const String groupsEndpoint = '/api/admin/groups';

  // Register Admin
  static Future<Map<String, dynamic>> registerAdmin({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$registerAdminEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin Login
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$adminLoginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      // Store access token if login successful
      if (responseData['success'] == true && responseData['data'] != null) {
        await _storeAccessToken(responseData['data']['accessToken']);
        await _storeUserData(responseData['data']['user']);
      }

      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        dashboardStatsEndpoint,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update Password
  static Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'PATCH',
        updatePasswordEndpoint,
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get Admin Profile
  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final response = await _makeAuthenticatedRequest('GET', profileEndpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update Admin Profile
  static Future<Map<String, dynamic>> updateAdminProfile({
    required String name,
    required String email,
    String? bio,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {'name': name, 'email': email};

      if (bio != null && bio.isNotEmpty) {
        requestBody['bio'] = bio;
      }

      final response = await _makeAuthenticatedRequest(
        'PATCH',
        profileEndpoint,
        body: requestBody,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Upload Profile Image
  static Future<Map<String, dynamic>> uploadProfileImage(
    String imagePath, {
    Uint8List? imageBytes,
  }) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Starting profile image upload...');
        print('DEBUG: Image path: $imagePath');
        print('DEBUG: Upload endpoint: $baseUrl$uploadProfileImageEndpoint');
      }

      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadProfileImageEndpoint'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      if (kIsWeb && imageBytes != null) {
        String filename = imagePath.split('/').last.toLowerCase();
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            imageBytes,
            filename: filename.isEmpty ? 'avatar.jpg' : filename,
            contentType: _getImageMimeType(filename),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            imagePath,
            contentType: _getImageMimeType(imagePath),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        if (kDebugMode) {
          print('DEBUG: Upload successful, response: $responseData');
        }
        return responseData;
      } else {
        if (kDebugMode) {
          print('DEBUG: Upload failed with status: ${response.statusCode}');
          print('DEBUG: Error response: ${response.body}');
        }
        return {
          'success': false,
          'message':
              'Failed to upload image: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout - clear all stored data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }

  // Simple authenticated API call
  static Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    String? token = await getAccessToken();

    if (token == null) {
      throw Exception('No access token found');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    http.Response response;
    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
        break;
      case 'POST':
        response = await http
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 20));
        break;
      case 'PUT':
        response = await http
            .put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 20));
        break;
      case 'PATCH':
        response = await http
            .patch(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 20));
        break;
      case 'DELETE':
        response = await http
            .delete(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 20));
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If token expired, logout user and redirect
    if (response.statusCode == 401) {
      await _handleUnauthorized();
    }

    return response;
  }

  static Future<void> _handleUnauthorized() async {
    await logout();
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: 401 detected, clearing token and redirecting to /login');
    }
    NavigationService.redirectToLogin();
  }

  // Student Management API
  static Future<Map<String, dynamic>> getAllStudents({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? sortOrder,
  }) async {
    try {
      String endpoint = '/api/admin/students?page=$page&limit=$limit';

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      if (status != null && status.isNotEmpty) {
        endpoint += '&status=${Uri.encodeComponent(status)}';
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        endpoint += '&sortOrder=${Uri.encodeComponent(sortOrder)}';
      }

      final response = await _makeAuthenticatedRequest('GET', endpoint);
      final responseData = jsonDecode(response.body);

      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch students: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStudent(
    String studentId,
    Map<String, dynamic> studentData,
  ) async {
    try {
      // Clean the data - remove empty strings and null values
      final cleanData = <String, dynamic>{};
      studentData.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          cleanData[key] = value.toString().trim();
        }
      });

      final response = await _makeAuthenticatedRequest(
        'PATCH',
        '/api/admin/students/$studentId',
        body: cleanData,
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Failed to update student: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'DELETE',
        '/api/admin/students/$studentId',
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete student: $e'};
    }
  }

  // Create Student
  static Future<Map<String, dynamic>> createStudent({
    required String name,
    required String phoneNumber,
    required String email,
    required String address,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        '/api/admin/students',
        body: {
          'name': name,
          'phoneNumber': phoneNumber,
          'email': email,
          'address': address,
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create student: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStudentStats() async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '/api/admin/students/stats',
      );
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch student stats: $e'};
    }
  }

  // Event Management API
  static Future<Map<String, dynamic>> getEventStats() async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        eventsStatsEndpoint,
      );
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch event stats: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllEvents({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      String endpoint = '$eventsEndpoint?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      final response = await _makeAuthenticatedRequest('GET', endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch events: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '$eventsEndpoint/$eventId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch event details: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'DELETE',
        '$eventsEndpoint/$eventId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete event: $e'};
    }
  }

  // Token Management
  static Future<void> _storeAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // User Data Management
  static Future<void> _storeUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userData['_id']);
    await prefs.setString('user_role', userData['role']);
    await prefs.setString('avatarUrl', jsonEncode(userData['avatar']));
    await prefs.setString('name', jsonEncode(userData['name']));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Admin Logout
  static Future<Map<String, dynamic>> adminLogout() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl$logoutEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      // Clear local storage regardless of API response
      await logout();

      return responseData;
    } catch (e) {
      // Clear local storage even if API call fails
      await logout();
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Instructor Management API
  static Future<Map<String, dynamic>> getAllInstructors({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? sortOrder,
  }) async {
    try {
      String endpoint = '$instructorsEndpoint?page=$page&limit=$limit';

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      if (status != null && status.isNotEmpty) {
        endpoint += '&status=${Uri.encodeComponent(status)}';
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        endpoint += '&sortOrder=${Uri.encodeComponent(sortOrder)}';
      }

      final response = await _makeAuthenticatedRequest('GET', endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch instructors: $e'};
    }
  }

  static Future<Map<String, dynamic>> getInstructorById(
    String instructorId,
  ) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '$instructorsEndpoint/$instructorId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch instructor details: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getInstructorStats() async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        instructorStatsEndpoint,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch instructor stats: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateInstructor(
    String instructorId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Clean the data - remove empty strings and null values
      final cleanData = <String, dynamic>{};
      data.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          cleanData[key] = value.toString().trim();
        }
      });

      final response = await _makeAuthenticatedRequest(
        'PATCH',
        '$instructorsEndpoint/$instructorId',
        body: cleanData,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update instructor: $e'};
    }
  }

  static Future<Map<String, dynamic>> addInstructor(
    Map<String, dynamic> instructorData,
  ) async {
    try {
      // Clean the data - remove empty strings and null values
      final cleanData = <String, dynamic>{};
      instructorData.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          cleanData[key] = value.toString().trim();
        }
      });

      final response = await _makeAuthenticatedRequest(
        'POST',
        instructorsEndpoint,
        body: cleanData,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to add instructor: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteInstructor(
    String instructorId,
  ) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'DELETE',
        '$instructorsEndpoint/$instructorId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete instructor: $e'};
    }
  }

  // Debug method to check token status
  static Future<Map<String, dynamic>> checkTokenStatus() async {
    final accessToken = await getAccessToken();
    final userData = await getUserData();

    return {
      'hasAccessToken': accessToken != null,
      'hasUserData': userData != null,
      'accessTokenLength': accessToken?.length ?? 0,
      'tokenPreview': accessToken != null
          ? '${accessToken.substring(0, 10)}...'
          : null,
    };
  }

  // Test token validity by making a simple authenticated request
  static Future<Map<String, dynamic>> testTokenValidity() async {
    try {
      final result = await getAdminProfile();
      return {
        'valid': result['success'] == true,
        'message': result['message'] ?? 'Token test completed',
      };
    } catch (e) {
      return {'valid': false, 'message': 'Token test failed: $e'};
    }
  }

  // Upload Single Event Image
  static Future<Map<String, dynamic>> uploadEventImage(
    String imagePath, {
    Uint8List? imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadEventImagesEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found. Please login again.',
        };
      }
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file with proper MIME type detection
      if (kIsWeb && imageBytes != null) {
        // For web, use bytes with proper MIME type detection
        String filename = imagePath.split('/').last.toLowerCase();
        MediaType contentType;

        if (filename.endsWith('.png')) {
          contentType = MediaType('image', 'png');
        } else if (filename.endsWith('.gif')) {
          contentType = MediaType('image', 'gif');
        } else if (filename.endsWith('.webp')) {
          contentType = MediaType('image', 'webp');
        } else if (filename.endsWith('.svg')) {
          contentType = MediaType('image', 'svg+xml');
        } else {
          // Default to jpeg for jpg, jpeg, and unknown types
          contentType = MediaType('image', 'jpeg');
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            imageBytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      } else {
        // For mobile, use file path with MIME type detection
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imagePath,
            contentType: _getImageMimeType(imagePath),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle unauthorized response
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message':
              'Failed to upload image: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload image: $e'};
    }
  }

  // Helper method to extract proper filename
  static String _extractFilename(String imagePath) {
    String filename;

    // Handle blob URLs (web)
    if (imagePath.startsWith('blob:')) {
      filename = 'avatar.jpg'; // Default for blob URLs
    } else {
      // Extract filename from path
      filename = imagePath.split('/').last.toLowerCase();

      // Ensure we have a valid filename with extension
      if (filename.isEmpty || !filename.contains('.')) {
        filename = 'avatar.jpg';
      }
    }

    // Ensure the filename has a supported image extension
    List<String> supportedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.svg',
    ];
    bool hasValidExtension = supportedExtensions.any(
      (ext) => filename.endsWith(ext),
    );

    if (!hasValidExtension) {
      // Default to .jpg if no valid extension found
      String baseName = filename.split('.').first;
      filename = '$baseName.jpg';
    }

    return filename;
  }

  // Helper method to get MIME type for images
  static MediaType _getImageMimeType(String filename) {
    String lowerFilename = filename.toLowerCase();
    if (lowerFilename.endsWith('.png')) {
      return MediaType('image', 'png');
    } else if (lowerFilename.endsWith('.gif')) {
      return MediaType('image', 'gif');
    } else if (lowerFilename.endsWith('.webp')) {
      return MediaType('image', 'webp');
    } else if (lowerFilename.endsWith('.svg')) {
      return MediaType('image', 'svg+xml');
    } else if (lowerFilename.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else {
      // Default to jpeg for jpg and unknown types
      return MediaType('image', 'jpeg');
    }
  }

  // Helper method to get MIME type for videos
  static MediaType _getVideoMimeType(String filePath) {
    String filename = filePath.toLowerCase();
    if (filename.endsWith('.avi')) {
      return MediaType('video', 'avi');
    } else if (filename.endsWith('.mov')) {
      return MediaType('video', 'quicktime');
    } else if (filename.endsWith('.wmv')) {
      return MediaType('video', 'x-ms-wmv');
    } else if (filename.endsWith('.webm')) {
      return MediaType('video', 'webm');
    } else {
      // Default to mp4
      return MediaType('video', 'mp4');
    }
  }

  // Upload Event Images
  static Future<Map<String, dynamic>> uploadEventImages(
    List<String> imagePaths, {
    List<Uint8List>? imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadEventImagesEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image files
      if (kIsWeb && imageBytes != null) {
        // For web, use bytes
        for (int i = 0; i < imageBytes.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              imageBytes[i],
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      } else {
        // For mobile, use file paths with proper MIME type detection
        for (String imagePath in imagePaths) {
          print('DEBUG: Adding image file: $imagePath');
          String filename = imagePath.split('/').last.toLowerCase();
          print('DEBUG: Filename: $filename');
          MediaType contentType = _getImageMimeType(filename);
          print('DEBUG: Content type: $contentType');

          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              imagePath,
              filename: filename,
              contentType: contentType,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: Upload response status: ${response.statusCode}');
      print('DEBUG: Upload response body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload images: $e'};
    }
  }

  // Upload Single Event Video
  static Future<Map<String, dynamic>> uploadEventVideo(
    String videoPath, {
    Uint8List? videoBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadEventVideosEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No access token found. Please login again.',
        };
      }
      request.headers['Authorization'] = 'Bearer $token';

      // Add video file with proper MIME type detection
      if (kIsWeb && videoBytes != null) {
        // For web, use bytes with proper MIME type detection
        String filename = videoPath.split('/').last.toLowerCase();
        MediaType contentType = _getVideoMimeType(filename);

        request.files.add(
          http.MultipartFile.fromBytes(
            'videos',
            videoBytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      } else {
        // For mobile, use file path with MIME type detection
        request.files.add(
          await http.MultipartFile.fromPath(
            'videos',
            videoPath,
            contentType: _getVideoMimeType(videoPath),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle unauthorized response
      if (response.statusCode == 401) {
        await _handleUnauthorized();
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message':
              'Failed to upload video: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload video: $e'};
    }
  }

  // Upload Event Videos
  static Future<Map<String, dynamic>> uploadEventVideos(
    List<String> videoPaths,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadEventVideosEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add video files
      for (String videoPath in videoPaths) {
        request.files.add(
          await http.MultipartFile.fromPath('videos', videoPath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload videos: $e'};
    }
  }

  // Create Event
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String location,
    required String category,
    required String eventType,
    required String startDate,
    required String endDate,
    required String registrationDeadline,
    required int maxParticipants,
    required List<String> tags,
    required String startTime,
    required String endTime,
    String? contactEmail,
    String? contactPhone,
    double? price,
    List<String>? images,
    List<String>? videos,
  }) async {
    try {
      // Only send the fields you specified - no extra fields like createdAt, updatedAt, etc.
      final Map<String, dynamic> requestBody = {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'eventType': eventType,
        'startDate': startDate,
        'endDate': endDate,
        'registrationDeadline': registrationDeadline,
        'maxParticipants': maxParticipants.toString(),
        'tags': tags,
        'startTime': startTime,
        'endTime': endTime,
      };

      // Only add optional fields if they have values
      if (contactEmail != null && contactEmail.isNotEmpty) {
        requestBody['contact_email'] = contactEmail;
      }
      if (contactPhone != null && contactPhone.isNotEmpty) {
        requestBody['contact_phone'] = contactPhone;
      }
      if (price != null && price > 0) {
        requestBody['price'] = price;
      }
      if (images != null && images.isNotEmpty) {
        requestBody['images'] = images;
      }
      if (videos != null && videos.isNotEmpty) {
        requestBody['videos'] = videos;
      }

      final response = await _makeAuthenticatedRequest(
        'POST',
        eventsEndpoint,
        body: requestBody,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create event: $e'};
    }
  }

  // Update Event
  static Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required String category,
    required String eventType,
    required String startDate,
    required String endDate,
    required String registrationDeadline,
    required int maxParticipants,
    required List<String> tags,
    required String startTime,
    required String endTime,
    String? contactEmail,
    String? contactPhone,
    double? price,
    List<String>? images,
    List<String>? videos,
  }) async {
    try {
      // Only send the fields you specified - no extra fields like updatedAt, createdAt, etc.
      final Map<String, dynamic> requestBody = {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'eventType': eventType,
        'startDate': startDate,
        'endDate': endDate,
        'registrationDeadline': registrationDeadline,
        'maxParticipants': maxParticipants.toString(),
        'tags': tags,
        'startTime': startTime,
        'endTime': endTime,
      };

      // Only add optional fields if they have values
      if (contactEmail != null && contactEmail.isNotEmpty) {
        requestBody['contact_email'] = contactEmail;
      }
      if (contactPhone != null && contactPhone.isNotEmpty) {
        requestBody['contact_phone'] = contactPhone;
      }
      if (price != null && price > 0) {
        requestBody['price'] = price;
      }
      if (images != null && images.isNotEmpty) {
        requestBody['images'] = images;
      }
      if (videos != null && videos.isNotEmpty) {
        requestBody['videos'] = videos;
      }

      final response = await _makeAuthenticatedRequest(
        'PATCH',
        '$eventsEndpoint/$eventId',
        body: requestBody,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update event: $e'};
    }
  }

  // Categories API
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '/api/admin/categories',
      );
      final result = jsonDecode(response.body);

      // Handle different response structures
      if (result['success'] == true && result['data'] != null) {
        // If the response has nested structure, extract the categories array
        if (result['data'] is Map && result['data']['categories'] != null) {
          return {'success': true, 'data': result['data']['categories']};
        } else if (result['data'] is List) {
          return {'success': true, 'data': result['data']};
        } else {
          return result;
        }
      } else {
        return result;
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch categories: $e'};
    }
  }

  // Subcategories API
  static Future<Map<String, dynamic>> getSubcategories(
    String categoryId,
  ) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '/api/admin/categories/$categoryId/subcategories',
      );
      final result = jsonDecode(response.body);

      // Handle different response structures
      if (result['success'] == true && result['data'] != null) {
        // If the response has nested structure, extract the subcategories array
        if (result['data'] is Map && result['data']['subcategories'] != null) {
          return {'success': true, 'data': result['data']['subcategories']};
        } else if (result['data'] is List) {
          return {'success': true, 'data': result['data']};
        } else {
          return result;
        }
      } else {
        return result;
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch subcategories: $e'};
    }
  }

  // Instructors API
  static Future<Map<String, dynamic>> getInstructors({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '$instructorsEndpoint?page=$page&limit=$limit',
      );
      final result = jsonDecode(response.body);

      // Handle different response structures
      if (result['success'] == true && result['data'] != null) {
        // If the response has nested structure, extract the instructors array
        if (result['data'] is Map && result['data']['instructors'] != null) {
          return {'success': true, 'data': result['data']['instructors']};
        } else if (result['data'] is List) {
          return {'success': true, 'data': result['data']};
        } else {
          return result;
        }
      } else {
        return result;
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch instructors: $e'};
    }
  }

  // Group Management API
  static Future<Map<String, dynamic>> getAllGroups({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      String endpoint = '$groupsEndpoint?page=$page&limit=$limit';

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }

      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG: Groups API endpoint: $baseUrl$endpoint');
      }
      final response = await _makeAuthenticatedRequest('GET', endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch groups: $e'};
    }
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required String category,
    required String description,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        groupsEndpoint,
        body: {'name': name, 'category': category, 'description': description},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create group: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateGroup({
    required String groupId,
    required String name,
    required String description,
    String? category,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'description': description,
      };

      if (category != null && category.isNotEmpty) {
        requestBody['category'] = category;
      }

      final response = await _makeAuthenticatedRequest(
        'PATCH',
        '$groupsEndpoint/$groupId',
        body: requestBody,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update group: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'DELETE',
        '$groupsEndpoint/$groupId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete group: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAvailableUsers({
    String? role,
    String? search,
    String? groupId,
  }) async {
    try {
      String endpoint = '$groupsEndpoint/users/available';
      List<String> queryParams = [];

      if (role != null && role.isNotEmpty) {
        queryParams.add('role=${Uri.encodeComponent(role)}');
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }
      if (groupId != null && groupId.isNotEmpty) {
        queryParams.add('groupId=${Uri.encodeComponent(groupId)}');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await _makeAuthenticatedRequest('GET', endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch available users: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addMembersToGroup({
    required String groupId,
    required List<Map<String, dynamic>> members,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        '$groupsEndpoint/$groupId/members',
        body: {'members': members},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add members to group: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '$groupsEndpoint/$groupId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch group details: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeMemberFromGroup({
    required String groupId,
    required String memberId,
    String? role,
  }) async {
    try {
      final endpoint = '$groupsEndpoint/$groupId/members/$memberId';
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG API: Making DELETE request to: $baseUrl$endpoint');
        // ignore: avoid_print
        print('DEBUG API: GroupId: $groupId, MemberId: $memberId, Role: $role');
      }

      // Send role in request body as the server expects it
      final requestBody = {
        'role': role ?? 'student', // Default to student if role not provided
      };

      final response = await _makeAuthenticatedRequest(
        'DELETE',
        endpoint,
        body: requestBody,
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG API: Response status: ${response.statusCode}');
        // ignore: avoid_print
        print('DEBUG API: Response body: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG API: Parsed response: $responseData');
      }

      return responseData;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DEBUG API: Exception in removeMemberFromGroup: $e');
      }
      return {
        'success': false,
        'message': 'Failed to remove member from group: $e',
      };
    }
  }

  // Course Management API
  static Future<Map<String, dynamic>> getCourseStats() async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        coursesStatsEndpoint,
      );
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch course stats: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllCourses({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      String endpoint = '$coursesEndpoint?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }
      final response = await _makeAuthenticatedRequest('GET', endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch courses: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCourseById(String courseId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'GET',
        '$coursesEndpoint/$courseId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch course details: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'DELETE',
        '$coursesEndpoint/$courseId',
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete course: $e'};
    }
  }

  // Upload Course Image
  static Future<Map<String, dynamic>> uploadCourseImage(
    String imagePath, {
    Uint8List? imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadCourseImageEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image file
      if (kIsWeb && imageBytes != null) {
        // For web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'course_image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        // For mobile, use file path
        request.files.add(
          await http.MultipartFile.fromPath('images', imagePath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload image: $e'};
    }
  }

  // Upload Course Video
  static Future<Map<String, dynamic>> uploadCourseVideo(
    String videoPath, {
    Uint8List? videoBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadCourseVideoEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add video file
      if (kIsWeb && videoBytes != null) {
        // For web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'video',
            videoBytes,
            filename: 'course_video.mp4',
            contentType: MediaType('video', 'mp4'),
          ),
        );
      } else {
        // For mobile, use file path
        request.files.add(
          await http.MultipartFile.fromPath('video', videoPath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload video: $e'};
    }
  }

  // Upload Multiple Course Images
  static Future<Map<String, dynamic>> uploadCourseImages(
    List<String> imagePaths, {
    List<Uint8List>? imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadCourseImageEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image files
      if (kIsWeb && imageBytes != null) {
        // For web, use bytes
        for (int i = 0; i < imageBytes.length; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes[i],
              filename: 'course_image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      } else {
        // For mobile, use file paths
        for (String imagePath in imagePaths) {
          request.files.add(
            await http.MultipartFile.fromPath('images', imagePath),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload images: $e'};
    }
  }

  // Upload Multiple Course Videos
  static Future<Map<String, dynamic>> uploadCourseVideos(
    List<String> videoPaths,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadCourseVideoEndpoint'),
      );

      // Add authorization header
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add video files
      for (String videoPath in videoPaths) {
        request.files.add(
          await http.MultipartFile.fromPath('video', videoPath),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload videos: $e'};
    }
  }

  // Create Course
  static Future<Map<String, dynamic>> createCourse({
    required String category,
    required String subcategory,
    required String title,
    required String description,
    required String price,
    required String thumbnail,
    required String level,
    required String instructor,
    required int published,
    Map<String, dynamic>? introVideo,
    required List<Map<String, dynamic>> sections,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        coursesEndpoint,
        body: {
          'category': category,
          'subcategory': subcategory,
          'title': title,
          'description': description,
          'price': price,
          'thumbnail': thumbnail,
          'level': level,
          'instructor': instructor,
          'published': published,
          if (introVideo != null) 'introVideo': introVideo,
          'sections': sections,
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create course: $e'};
    }
  }

  // Verify User (Instructor)
  static Future<Map<String, dynamic>> verifyUser(String userId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        '/api/user/verify',
        body: {'userId': userId},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify user: $e'};
    }
  }

  // Update Course
  static Future<Map<String, dynamic>> updateCourse({
    required String courseId,
    required String category,
    required String subcategory,
    required String title,
    required String description,
    required String price,
    required String thumbnail,
    required String level,
    required String instructor,
    required int published,
    Map<String, dynamic>? introVideo,
    required List<Map<String, dynamic>> sections,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'PATCH',
        '$coursesEndpoint/$courseId',
        body: {
          'category': category,
          'subcategory': subcategory,
          'title': title,
          'description': description,
          'price': price,
          'thumbnail': thumbnail,
          'level': level,
          'instructor': instructor,
          'published': published,
          if (introVideo != null) 'introVideo': introVideo,
          'sections': sections,
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update course: $e'};
    }
  }

  // Event Accounts API
  static Future<Map<String, dynamic>> getEventAccounts({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      String endpoint = '/api/admin/events/accounts?page=$page&limit=$limit';

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await _makeAuthenticatedRequest('GET', endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch event accounts: $e',
      };
    }
  }

  // Verify Event Account API
  static Future<Map<String, dynamic>> verifyEventAccount(String userId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        '/api/user/verify',
        body: {'userId': userId},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify event account: $e',
      };
    }
  }

  // Reject Event Account API
  static Future<Map<String, dynamic>> rejectEventAccount(String userId) async {
    try {
      final response = await _makeAuthenticatedRequest(
        'POST',
        '/api/user/reject',
        body: {'userId': userId},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reject event account: $e',
      };
    }
  }
}
