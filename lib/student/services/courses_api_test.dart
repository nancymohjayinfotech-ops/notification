import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'course_service.dart';

class CoursesApiTest {
  static final ApiClient _apiClient = ApiClient();
  static final CourseService _courseService = CourseService();

  /// Test all courses API endpoints
  static Future<Map<String, dynamic>> runAllCoursesTests() async {
    debugPrint('🚀 Starting comprehensive courses API tests...');
    
    final results = <String, dynamic>{
      'getAllCoursesTest': await testGetAllCourses(),
      'getCourseByIdTest': await testGetCourseById(),
      'searchCoursesTest': await testSearchCourses(),
      'filterCoursesTest': await testFilterCourses(),
      'summary': {},
    };

    final allTestsResults = [
      results['getAllCoursesTest']['success'] as bool,
      results['getCourseByIdTest']['success'] as bool,
      results['searchCoursesTest']['success'] as bool,
      results['filterCoursesTest']['success'] as bool,
    ];

    final passedTests = allTestsResults.where((test) => test).length;
    final totalTests = allTestsResults.length;

    results['summary'] = {
      'allTestsPassed': passedTests == totalTests,
      'passedTests': passedTests,
      'totalTests': totalTests,
      'successRate': '${(passedTests / totalTests * 100).toStringAsFixed(1)}%',
      'recommendations': _getRecommendations(results),
    };

    debugPrint('🏁 Courses API tests completed: $passedTests/$totalTests passed');
    return results;
  }

  /// Test GET /api/courses (get all courses)
  static Future<Map<String, dynamic>> testGetAllCourses() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing GET /api/courses...');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.allCourses,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (data['success'] == true) {
          final courses = data['courses'] as List<dynamic>?;
          result['success'] = true;
          result['message'] = 'Successfully fetched ${courses?.length ?? 0} courses';
          result['details'] = {
            'coursesCount': courses?.length ?? 0,
            'responseStructure': data.keys.toList(),
            'sampleCourse': courses?.isNotEmpty == true ? courses!.first : null,
          };
          debugPrint('✅ Get all courses test passed');
        } else {
          result['message'] = 'API returned success=false: ${data['message']}';
          result['details'] = data;
          debugPrint('❌ Get all courses test failed: API returned success=false');
        }
      } else {
        result['message'] = 'API request failed: ${response.error?.message}';
        result['details'] = {
          'error': response.error?.message,
          'errorType': response.error?.type.toString(),
        };
        debugPrint('❌ Get all courses test failed: API request failed');
      }
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Get all courses test failed: Exception - $e');
    }

    return result;
  }

  /// Test GET /api/courses/:id (get course by ID)
  static Future<Map<String, dynamic>> testGetCourseById() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing GET /api/courses/:id...');
      
      // First get all courses to find a valid ID
      final allCoursesResult = await testGetAllCourses();
      if (!allCoursesResult['success']) {
        result['message'] = 'Cannot test course by ID: getAllCourses failed';
        result['details'] = allCoursesResult;
        return result;
      }

      final courses = allCoursesResult['details']['sampleCourse'];
      if (courses == null) {
        result['message'] = 'No courses available to test course by ID';
        result['details'] = {'note': 'Database might be empty'};
        return result;
      }

      // Try to get course by ID using the service
      final courseId = courses['_id'] ?? courses['id'];
      if (courseId == null) {
        result['message'] = 'No valid course ID found in sample course';
        result['details'] = {'sampleCourse': courses};
        return result;
      }

      final course = await _courseService.getCourseById(courseId.toString());
      
      if (course != null) {
        result['success'] = true;
        result['message'] = 'Successfully fetched course by ID';
        result['details'] = {
          'courseId': courseId,
          'courseTitle': course.title,
          'courseInstructor': course.instructor?.name,
        };
        debugPrint('✅ Get course by ID test passed');
      } else {
        result['message'] = 'Course by ID returned null';
        result['details'] = {'courseId': courseId};
        debugPrint('❌ Get course by ID test failed: returned null');
      }
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Get course by ID test failed: Exception - $e');
    }

    return result;
  }

  /// Test search functionality
  static Future<Map<String, dynamic>> testSearchCourses() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing course search...');
      
      final searchResults = await _courseService.searchCourses('flutter');
      
      result['success'] = true;
      result['message'] = 'Search completed successfully';
      result['details'] = {
        'searchTerm': 'flutter',
        'resultsCount': searchResults.length,
        'sampleResults': searchResults.take(2).map((c) => c.title).toList(),
      };
      debugPrint('✅ Search courses test passed');
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Search courses test failed: Exception - $e');
    }

    return result;
  }

  /// Test filtering functionality
  static Future<Map<String, dynamic>> testFilterCourses() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing course filtering...');
      
      final filteredResults = await _courseService.getAllCourses(
        level: 'beginner',
        published: true,
      );
      
      result['success'] = true;
      result['message'] = 'Filtering completed successfully';
      result['details'] = {
        'filters': {'level': 'beginner', 'published': true},
        'resultsCount': filteredResults.length,
        'sampleResults': filteredResults.take(2).map((c) => {
          'title': c.title,
          'level': c.level,
        }).toList(),
      };
      debugPrint('✅ Filter courses test passed');
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Filter courses test failed: Exception - $e');
    }

    return result;
  }

  static List<String> _getRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    final getAllSuccess = results['getAllCoursesTest']['success'] as bool;
    final getByIdSuccess = results['getCourseByIdTest']['success'] as bool;
    final searchSuccess = results['searchCoursesTest']['success'] as bool;
    final filterSuccess = results['filterCoursesTest']['success'] as bool;

    if (!getAllSuccess) {
      recommendations.addAll([
        'Check if backend server is running on port 5000',
        'Verify courses route is configured in backend',
        'Check if MongoDB has course data',
        'Verify API base URL is correct for your platform',
      ]);
    }

    if (getAllSuccess && !getByIdSuccess) {
      recommendations.addAll([
        'Check course ID format in database',
        'Verify getCourseById route is working',
      ]);
    }

    if (getAllSuccess && (!searchSuccess || !filterSuccess)) {
      recommendations.addAll([
        'Check search/filter query parameters in backend',
        'Verify MongoDB query syntax in course controller',
      ]);
    }

    if (getAllSuccess && getByIdSuccess && searchSuccess && filterSuccess) {
      recommendations.add('All courses API tests passed! The courses API is working correctly.');
    }

    return recommendations;
  }
}
