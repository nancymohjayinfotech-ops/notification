import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/course.dart';
import '../models/dashboard_stats.dart';
import '../models/course_progress.dart';
import 'api_client.dart';

class CourseService extends ChangeNotifier {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final ApiClient _apiClient = ApiClient();
  
  List<Course> _enrolledCourses = [];
  bool _isLoadingEnrolled = false;
  String? _error;

  List<Course> get enrolledCourses => List.unmodifiable(_enrolledCourses);
  bool get isLoadingEnrolled => _isLoadingEnrolled;
  String? get error => _error;

  /// Get all courses from the API
  Future<List<Course>> getAllCourses({
    String? category,
    String? level,
    String? search,
    bool? published,
    String? instructor,
  }) async {
    try {
      debugPrint('🔍 Fetching all courses from API...');
      
      // Build query parameters
      Map<String, dynamic> queryParams = {};
      if (category != null) queryParams['category'] = category;
      if (level != null) queryParams['level'] = level;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
      if (published != null) queryParams['published'] = published.toString();
      if (instructor != null) queryParams['instructor'] = instructor;

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.allCourses,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        // Backend returns { success, message, data: { courses: [...] } }
        final wrapper = data['data'] as Map<String, dynamic>?;
        final list = wrapper != null ? wrapper['courses'] : data['courses'];
        
        if (list != null) {
          final coursesJson = list as List<dynamic>;
          final courses = coursesJson
              .map((courseJson) => Course.fromJson(courseJson))
              .toList();
          
          debugPrint('✅ Successfully fetched ${courses.length} courses');
          return courses;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to fetch courses');
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        throw Exception(response.error?.message ?? 'Failed to fetch courses');
      }
    } catch (e) {
      debugPrint('❌ Error in getAllCourses: $e');
      rethrow;
    }
  }

  /// Get a specific course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      debugPrint('🔍 Fetching course by ID: $courseId');
      
      final endpoint = '${ApiConfig.courseById}/$courseId';
      final response = await _apiClient.get<Map<String, dynamic>>(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (data['success'] == true && data['course'] != null) {
          final course = Course.fromJson(data['course']);
          debugPrint('✅ Successfully fetched course: ${course.title}');
          return course;
        } else if (data['course'] != null) {
          // Fallback for different response structure
          final course = Course.fromJson(data['course']);
          debugPrint('✅ Successfully fetched course: ${course.title}');
          return course;
        } else {
          debugPrint('❌ Course not found: ${data['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in getCourseById: $e');
      return null;
    }
  }

  /// Get a specific course by slug
  Future<Course?> getCourseBySlug(String slug) async {
    try {
      debugPrint('🔍 Fetching course by slug: $slug');

      final endpoint = '${ApiConfig.courseBySlug}/$slug';
      final response = await _apiClient.get<Map<String, dynamic>>(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true && data['data'] != null && data['data']['course'] != null) {
          final course = Course.fromJson(data['data']['course']);
          debugPrint('✅ Successfully fetched course: ${course.title}');
          return course;
        } else if (data['success'] == true && data['course'] != null) {
          // Fallback for direct course response
          final course = Course.fromJson(data['course']);
          debugPrint('✅ Successfully fetched course: ${course.title}');
          return course;
        } else if (data['course'] != null) {
          // Another fallback for different response structure
          final course = Course.fromJson(data['course']);
          debugPrint('✅ Successfully fetched course: ${course.title}');
          return course;
        } else {
          debugPrint('❌ Course not found: ${data['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in getCourseBySlug: $e');
      return null;
    }
  }

  /// Get courses by category
  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    try {
      debugPrint('🔍 Fetching courses by category: $categoryId');
      
      return await getAllCourses(category: categoryId);
    } catch (e) {
      debugPrint('❌ Error in getCoursesByCategory: $e');
      rethrow;
    }
  }

  /// Get courses by subcategory
  Future<List<Course>> getCoursesBySubcategory(String subcategoryId) async {
    try {
      debugPrint('🔍 Fetching courses by subcategory: $subcategoryId');

      final endpoint = '/courses/subcategory/$subcategoryId';
      final response = await _apiClient.get<Map<String, dynamic>>(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        // { success, message, data: { courses: [...], ... } }
        final wrapper = data['data'] as Map<String, dynamic>?;
        final list = wrapper != null ? wrapper['courses'] : data['courses'];

        if (list != null) {
          final coursesJson = list as List<dynamic>;
          final courses = coursesJson
              .map((courseJson) => Course.fromJson(courseJson))
              .toList();

          debugPrint('✅ Successfully fetched ${courses.length} courses for subcategory');
          return courses;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error in getCoursesBySubcategory: $e');
      return [];
    }
  }

  /// Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      debugPrint('🔍 Searching courses with query: $query');
      
      if (query.trim().isEmpty) {
        return await getAllCourses();
      }
      
      return await getAllCourses(search: query);
    } catch (e) {
      debugPrint('❌ Error in searchCourses: $e');
      rethrow;
    }
  }

  /// Enroll in a course
  Future<bool> enrollInCourse(String courseId) async {
    try {
      debugPrint('📝 Enrolling in course: $courseId');
      
      final endpoint = ApiConfig.enrollCourse.replaceAll('{id}', courseId);
      final response = await _apiClient.post<Map<String, dynamic>>(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (data['success'] == true) {
          debugPrint('✅ Successfully enrolled in course');
          return true;
        } else {
          debugPrint('❌ Enrollment failed: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('❌ Enrollment API request failed: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in enrollInCourse: $e');
      return false;
    }
  }

  /// Add rating to a course
  Future<bool> addRating(String courseId, int rating, {String? review}) async {
    try {
      debugPrint('⭐ Adding rating to course: $courseId');
      
      final endpoint = '${ApiConfig.coursesEndpoint}/$courseId/ratings';
      final response = await _apiClient.post<Map<String, dynamic>>(
        endpoint,
        data: {
          'rating': rating,
          if (review != null) 'review': review,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (data['success'] == true) {
          debugPrint('✅ Successfully added rating');
          return true;
        } else {
          debugPrint('❌ Rating failed: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('❌ Rating API request failed: ${response.error?.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in addRating: $e');
      return false;
    }
  }

  /// Get featured courses from API
  Future<List<Course>> getFeaturedCourses({int page = 1, int limit = 10}) async {
    try {
      debugPrint('🔄 Fetching featured courses from: ${ApiConfig.featuredCourses}');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.featuredCourses,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('✅ Featured courses API response: $data');
        
        if (data['success'] == true && data['data'] != null && data['data']['courses'] != null) {
          final List<dynamic> coursesJson = data['data']['courses'];
          final courses = coursesJson.map((json) => Course.fromJson(json)).toList();
          debugPrint('✅ Successfully fetched ${courses.length} featured courses');
          return courses;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error in getFeaturedCourses: $e');
      return [];
    }
  }


  /// Get enrolled courses for the current user with progress data
  Future<List<Course>> getEnrolledCourses() async {
    try {
      _isLoadingEnrolled = true;
      _error = null;
      notifyListeners();

      debugPrint('📚 Fetching enrolled courses from: ${ApiConfig.baseUrl}${ApiConfig.enrolledCourses}');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.enrolledCourses,
        options: Options(
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('📚 ========== ENROLLED COURSES API RESPONSE ==========');
        debugPrint('📚 Full response: $data');
        debugPrint('📚 Response keys: ${data.keys.toList()}');
        debugPrint('📚 Response type: ${data.runtimeType}');
        debugPrint('📚 Is success field present: ${data.containsKey('success')}');
        debugPrint('📚 Success value: ${data['success']}');
        debugPrint('📚 Data field present: ${data.containsKey('data')}');
        debugPrint('📚 Data field value: ${data['data']}');
        debugPrint('📚 Courses field present: ${data.containsKey('courses')}');
        debugPrint('📚 Courses field value: ${data['courses']}');
        
        // Handle multiple possible response structures
        List<dynamic> coursesJson = [];
        
        if (data['success'] == true) {
          if (data['data'] != null && data['data']['courses'] != null) {
            coursesJson = data['data']['courses'] as List<dynamic>;
          } else if (data['data'] != null && data['data'] is List) {
            coursesJson = data['data'] as List<dynamic>;
          } else if (data['courses'] != null) {
            coursesJson = data['courses'] as List<dynamic>;
          }
        } else if (data['courses'] != null) {
          coursesJson = data['courses'] as List<dynamic>;
        } else if (data is List) {
          coursesJson = data as List<dynamic>;
        }
        
        debugPrint('📚 Parsed courses JSON length: ${coursesJson.length}');
        debugPrint('📚 Courses JSON: $coursesJson');
        
        if (coursesJson.isNotEmpty) {
          debugPrint('📚 Processing ${coursesJson.length} enrolled courses...');
          _enrolledCourses = coursesJson.map((courseJson) {
            try {
              debugPrint('📚 Processing course: $courseJson');
              // Extract progress data from the enrolled course JSON
              final progressData = courseJson['progress'] ?? {};
              double progressValue = 0.0;
              String progressText = '0% completed';
              
              if (progressData is Map<String, dynamic>) {
                final progress = CourseProgress.fromJson(progressData);
                progressValue = progress.percentage / 100; // Convert to 0-1 range
                progressText = progress.formattedProgress;
              } else if (courseJson['progressPercentage'] != null) {
                progressValue = (courseJson['progressPercentage'] as num).toDouble() / 100;
                progressText = '${(progressValue * 100).round()}% completed';
              }
              
              // Create Course object with progress information
              final course = Course.fromJson(courseJson);
              return Course(
                id: course.id,
                title: course.title,
                slug: course.slug,
                description: course.description,
                price: course.price,
                instructor: course.instructor,
                thumbnail: course.thumbnail,
                category: course.category,
                subcategory: course.subcategory,
                level: course.level,
                published: course.published,
                enrolledStudents: course.enrolledStudents,
                averageRating: course.averageRating,
                introVideo: course.introVideo,
                sections: course.sections,
                totalVideos: course.totalVideos,
                totalDuration: course.totalDuration,
                createdAt: course.createdAt,
                updatedAt: course.updatedAt,
                // Legacy fields with progress data
                author: course.author,
                imageAsset: course.imageAsset,
                progress: progressValue,
                progressText: progressText,
                students: course.students,
                duration: course.duration,
                videoIds: course.videoIds,
                hasVideo: course.hasVideo,
                language: course.language,
              );
            } catch (e) {
              debugPrint('⚠️ Error parsing course: $e, courseJson: $courseJson');
              // Return basic course without progress if parsing fails
              return Course.fromJson(courseJson);
            }
          }).toList();
          
          debugPrint('✅ Successfully fetched ${_enrolledCourses.length} enrolled courses with progress');
        } else {
          debugPrint('📚 ❌ No enrolled courses found in response - coursesJson is empty');
          debugPrint('📚 ❌ This means the API response structure doesn\'t match expected format');
          _enrolledCourses = [];
        }
        
        debugPrint('📚 ========== FINAL RESULT ==========');
        debugPrint('📚 Total enrolled courses loaded: ${_enrolledCourses.length}');
        debugPrint('📚 Enrolled courses: ${_enrolledCourses.map((c) => c.title).toList()}');
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        _error = response.error?.message ?? 'Failed to load enrolled courses';
        _enrolledCourses = [];
      }
    } catch (e) {
      debugPrint('❌ Error in getEnrolledCourses: $e');
      _error = 'Error loading enrolled courses: $e';
      _enrolledCourses = [];
    } finally {
      _isLoadingEnrolled = false;
      notifyListeners();
    }

    return _enrolledCourses;
  }


  /// Get favorite courses for the current user
  Future<List<Course>> getFavoriteCourses() async {
    try {
      debugPrint('❤️ Fetching favorite courses');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.favoriteCourses,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (data['success'] == true && data['courses'] != null) {
          final coursesJson = data['courses'] as List<dynamic>;
          final courses = coursesJson
              .map((courseJson) => Course.fromJson(courseJson))
              .toList();
          
          debugPrint('✅ Successfully fetched ${courses.length} favorite courses');
          return courses;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      return [];
    }
  }


  /// Get dashboard statistics for the current user
  Future<DashboardStats?> getDashboardStats() async {
    try {
      debugPrint('📊 Fetching dashboard stats from: ${ApiConfig.baseUrl}${ApiConfig.dashboardStats}');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.dashboardStats,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('📊 Dashboard stats response: $data');
        
        // Handle different response structures
        Map<String, dynamic>? statsData;
        
        if (data['success'] == true && data['data'] != null) {
          statsData = data['data'];
        } else if (data['data'] != null) {
          statsData = data['data'];
        } else if (data.containsKey('totalCourses') || data.containsKey('learningHours')) {
          // Direct data structure
          statsData = data;
        }
        
        if (statsData != null) {
          final stats = DashboardStats.fromJson(statsData);
          debugPrint('✅ Successfully parsed dashboard stats: ${stats.totalCourses} courses, ${stats.formattedLearningHours}, ${stats.formattedRating} rating');
          return stats;
        } else {
          debugPrint('❌ No valid stats data found in response');
          debugPrint('📄 Full response structure: $data');
          // Return default stats to avoid showing static values
          return DashboardStats(
            totalCourses: 0,
            learningHours: 0.0,
            averageRating: 0.0,
            completionRate: 0.0,
            enrolledCoursesCount: 0,
          );
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        // Return default stats instead of null
        return DashboardStats(
          totalCourses: 0,
          learningHours: 0.0,
          averageRating: 0.0,
          completionRate: 0.0,
          enrolledCoursesCount: 0,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in getDashboardStats: $e');
      // Return default stats instead of null
      return DashboardStats(
        totalCourses: 0,
        learningHours: 0.0,
        averageRating: 0.0,
        completionRate: 0.0,
        enrolledCoursesCount: 0,
      );
    }
  }

  /// Get popular courses from the API
  Future<List<Course>> getPopularCourses({int page = 1, int limit = 10}) async {
    try {
      debugPrint('🔥 Fetching popular courses from: ${ApiConfig.popularCourses}');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.popularCourses,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('✅ Popular courses API response: $data');
        
        if (data['success'] == true && data['data'] != null && data['data']['courses'] != null) {
          final List<dynamic> coursesJson = data['data']['courses'];
          final courses = coursesJson.map((json) => Course.fromJson(json)).toList();
          debugPrint('✅ Successfully fetched ${courses.length} popular courses');
          return courses;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error in getPopularCourses: $e');
      return [];
    }
  }

  /// Get recommended courses from the API
  Future<List<Course>> getRecommendedCourses({int page = 1, int limit = 10}) async {
    try {
      debugPrint('🎯 Fetching recommended courses from: ${ApiConfig.recommendedCourses}');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.recommendedCourses,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('✅ Recommended courses API response: $data');
        
        if (data['success'] == true && data['data'] != null && data['data']['courses'] != null) {
          final List<dynamic> coursesJson = data['data']['courses'];
          final courses = coursesJson.map((json) => Course.fromJson(json)).toList();
          debugPrint('✅ Successfully fetched ${courses.length} recommended courses');
          return courses;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error in getRecommendedCourses: $e');
      return [];
    }
  }

  /// Get course count by category ID
  Future<int> getCourseCountByCategory(String categoryId) async {
    try {
      debugPrint('📊 Fetching course count for category: $categoryId');
      
      final courses = await getCoursesByCategory(categoryId);
      final count = courses.length;
      
      debugPrint('✅ Found $count courses for category: $categoryId');
      return count;
    } catch (e) {
      debugPrint('❌ Error in getCourseCountByCategory: $e');
      return 0;
    }
  }

  /// Get course counts for multiple categories
  Future<Map<String, int>> getCourseCountsForCategories(List<String> categoryIds) async {
    try {
      debugPrint('📊 Fetching course counts for ${categoryIds.length} categories');
      
      final Map<String, int> counts = {};
      
      // Use Future.wait to fetch counts in parallel for better performance
      final futures = categoryIds.map((categoryId) async {
        final count = await getCourseCountByCategory(categoryId);
        return MapEntry(categoryId, count);
      });
      
      final results = await Future.wait(futures);
      
      for (final entry in results) {
        counts[entry.key] = entry.value;
      }
      
      debugPrint('✅ Successfully fetched course counts for all categories');
      return counts;
    } catch (e) {
      debugPrint('❌ Error in getCourseCountsForCategories: $e');
      return {};
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh enrolled courses
  Future<void> refreshEnrolledCourses() async {
    await getEnrolledCourses();
  }
}
