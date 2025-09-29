import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CourseService {
  static const String baseUrl = 'http://54.82.53.11:5001/api';

  // Get all courses for the instructor
  static Future<Map<String, dynamic>> getInstructorCourses({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint(
        'Fetching instructor courses from: $baseUrl/instructor/courses?page=$page&limit=$limit',
      );
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/courses?page=$page&limit=$limit',
      );

      debugPrint('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('API response keys: ${data.keys.toList()}');

        if (data['success'] == true) {
          // Extract courses from data.courses as per the API structure
          final courses = _extractCourses(data);
          debugPrint('Extracted ${courses.length} courses');

          // Also get pagination info if available
          Map<String, dynamic>? pagination;
          if (data['data'] != null && data['data']['pagination'] != null) {
            pagination = Map<String, dynamic>.from(data['data']['pagination']);
            debugPrint('Pagination info: $pagination');
          }

          return {
            'success': true,
            'courses': courses,
            'pagination': pagination,
            'message': data['message'] ?? 'Courses retrieved successfully',
          };
        } else {
          debugPrint(
            'API returned success: false with message: ${data['message']}',
          );
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve courses',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve courses. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting instructor courses: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all courses in the system
  static Future<Map<String, dynamic>> getAllCourses({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/instructor/all-courses?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'courses': _extractCourses(data),
            'message': data['message'] ?? 'All courses retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve all courses',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve all courses. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting all courses: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get courses with enrollments
  static Future<Map<String, dynamic>> getCoursesWithEnrollments({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url:
            '$baseUrl/instructor/courses-with-enrollments?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'courses': _extractCourses(data),
            'message':
                data['message'] ??
                'Courses with enrollments retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                data['message'] ??
                'Failed to retrieve courses with enrollments',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve courses with enrollments. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting courses with enrollments: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Helper method to extract courses from different response structures
  static List<Map<String, dynamic>> _extractCourses(Map<String, dynamic> data) {
    List<dynamic> courses = [];

    // Debug print to see the structure of the data
    debugPrint('Data structure keys: ${data.keys.toList()}');

    // Based on the Postman response, the structure is: { success, message, data: { courses: [] } }
    if (data['data'] != null && data['data']['courses'] is List) {
      courses = data['data']['courses'] as List;
      debugPrint('Extracted courses from data.courses: ${courses.length}');
    } else if (data['courses'] is List) {
      courses = data['courses'] as List;
      debugPrint('Extracted courses from courses: ${courses.length}');
    } else if (data['data'] is List) {
      courses = data['data'] as List;
      debugPrint('Extracted courses from data: ${courses.length}');
    }

    return List<Map<String, dynamic>>.from(courses);
  }
}
