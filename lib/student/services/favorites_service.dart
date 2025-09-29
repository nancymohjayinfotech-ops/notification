import 'package:flutter/foundation.dart';
import '../models/course.dart';
import 'api_client.dart';
import 'token_service.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal() {
    _loadFavorites();
  }

  final ApiClient _apiClient = ApiClient();
  final TokenService _tokenService = TokenService();

  List<Course> _favoritesCourses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get favoritesCourses => List.unmodifiable(_favoritesCourses);
  int get favoritesCount => _favoritesCourses.length;
  bool get hasFavorites => _favoritesCourses.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load favorites from backend API
  Future<void> _loadFavorites() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('❤️ Loading favorites from backend...');
      debugPrint('🔑 Token valid: ${_tokenService.hasValidToken}');

      if (!_tokenService.hasValidToken) {
        debugPrint('❌ No valid token, using empty favorites list');
        _favoritesCourses = [];
        return;
      }

      // Use the correct endpoint format
      final response = await _apiClient.get<Map<String, dynamic>>(
        'user/favorites',  // GET /api/user/favorites
      );

      debugPrint('📥 Favorites response: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true) {
          // Handle both response formats:
          // 1. { success: true, courses: [...] }
          // 2. { success: true, data: { courses: [...] } }
          final coursesJson = data['courses'] ?? (data['data']?['courses']);

          if (coursesJson != null && coursesJson is List) {
            _favoritesCourses = coursesJson
                .map((courseJson) => Course.fromJson(courseJson))
                .toList();
            debugPrint(
              '✅ Successfully loaded ${_favoritesCourses.length} favorite courses',
            );
          } else {
            debugPrint('⚠️ No courses found in the response');
            _favoritesCourses = [];
          }
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          _error = data['message'] ?? 'Failed to load favorites';

          // If access denied, try the course favorites endpoint as fallback
          if (data['message']?.toString().toLowerCase().contains(
                'access denied',
              ) ==
              true) {
            debugPrint(
              '⚠️ Access denied to user favorites, trying course favorites endpoint...',
            );
            await _loadCourseFavorites();
            return;
          }
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        _error = response.error?.message ?? 'Failed to load favorites';

        // If 403 Forbidden, try the course favorites endpoint as fallback
        if (response.error?.code == 403) {
          debugPrint('⚠️ 403 Forbidden, trying course favorites endpoint...');
          await _loadCourseFavorites();
          return;
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
      _error = 'Error loading favorites: $e';
      _favoritesCourses = []; // Ensure we have an empty list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh favorites from backend
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }

  // Add course to favorites via backend API
  Future<bool> addToFavorites(Course course) async {
    if (course.id == null) {
      debugPrint('❌ Cannot add course to favorites: course ID is null');
      _error = 'Course ID is missing';
      return false;
    }

    if (!_tokenService.hasValidToken) {
      debugPrint('❌ No valid token, cannot add to favorites');
      _error = 'Authentication required';
      return false;
    }

    try {
      debugPrint('❤️ Adding course ${course.id} to favorites...');

      // Use the user favorites endpoint with POST method
      final endpoint = 'user/favorites/${course.id}';  // POST /api/user/favorites/{courseId}
      
      debugPrint('🔗 POST endpoint: $endpoint');
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        endpoint,
        data: {'courseId': course.id},
      );

      debugPrint('📥 Response: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true || data['message']?.toString().toLowerCase().contains('added') == true) {
          // Add to local list if not already present
          if (!isFavorite(course.id!)) {
            _favoritesCourses.add(course);
            notifyListeners();
          }
          debugPrint('✅ Course added to favorites successfully');
          _error = null;
          return true;
        } else {
          debugPrint('❌ Failed to add to favorites: ${data['message']}');
          _error = data['message'] ?? 'Failed to add to favorites';
          return false;
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        _error = response.error?.message ?? 'Failed to add to favorites';
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error adding to favorites: $e');
      _error = 'Error adding to favorites: $e';
      return false;
    }
  }

  // Remove course from favorites via backend API
  Future<bool> removeFromFavorites(Course course) async {
    if (course.id == null) {
      debugPrint('❌ Cannot remove course from favorites: course ID is null');
      _error = 'Course ID is missing';
      return false;
    }

    if (!_tokenService.hasValidToken) {
      debugPrint('❌ No valid token, cannot remove from favorites');
      _error = 'Authentication required';
      return false;
    }

    try {
      debugPrint('💔 Removing course ${course.id} from favorites...');

      // Use the user favorites endpoint with DELETE method
      final endpoint = 'user/favorites/${course.id}';  // DELETE /api/user/favorites/{courseId}
      
      debugPrint('🔗 DELETE endpoint: $endpoint');
      
      final response = await _apiClient.delete<Map<String, dynamic>>(endpoint);

      debugPrint('📥 Response: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true || data['message']?.toString().toLowerCase().contains('removed') == true) {
          // Remove from local list
          _favoritesCourses.removeWhere(
            (favCourse) => favCourse.id == course.id,
          );
          notifyListeners();
          debugPrint('✅ Course removed from favorites successfully');
          _error = null;
          return true;
        } else {
          debugPrint('❌ Failed to remove from favorites: ${data['message']}');
          _error = data['message'] ?? 'Failed to remove from favorites';
          return false;
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        _error = response.error?.message ?? 'Failed to remove from favorites';
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error removing from favorites: $e');
      _error = 'Error removing from favorites: $e';
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(Course course) async {
    if (course.id == null) {
      _error = 'Course ID is missing';
      return false;
    }
    
    // Clear any previous error
    _error = null;
    
    debugPrint('🔄 Toggling favorite for course: ${course.id}');
    debugPrint('   Current favorite status: ${isFavorite(course.id!)}');
    
    if (isFavorite(course.id!)) {
      debugPrint('   → Removing from favorites');
      return await removeFromFavorites(course);
    } else {
      debugPrint('   → Adding to favorites');
      return await addToFavorites(course);
    }
  }

  // Check if course is in favorites by ID
  bool isFavorite(String courseId) {
    return _favoritesCourses.any((course) => course.id == courseId);
  }

  // Check if course is in favorites by title and author (legacy support)
  bool isFavoriteByTitleAndAuthor(String courseTitle, String courseAuthor) {
    return _favoritesCourses.any(
      (course) => course.title == courseTitle && course.author == courseAuthor,
    );
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _favoritesCourses.clear();
    notifyListeners();
  }

  // Load favorites using the course favorites endpoint as fallback
  Future<void> _loadCourseFavorites() async {
    try {
      debugPrint('🔄 Trying to load favorites from course endpoint...');

      final response = await _apiClient.get<Map<String, dynamic>>(
        'courses/favorites',  // Remove leading slash to work with baseUrl
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true) {
          final coursesJson = data['courses'] ?? (data['data']?['courses']);

          if (coursesJson != null && coursesJson is List) {
            _favoritesCourses = coursesJson
                .map((courseJson) => Course.fromJson(courseJson))
                .toList();
            debugPrint(
              '✅ Successfully loaded ${_favoritesCourses.length} favorite courses from fallback endpoint',
            );
            _error = null; // Clear any previous error
          } else {
            debugPrint('⚠️ No courses found in the fallback response');
            _favoritesCourses = [];
          }
        } else {
          debugPrint(
            '❌ Fallback API returned success=false: ${data['message']}',
          );
          _error = data['message'] ?? 'Failed to load favorites';
        }
      } else {
        debugPrint('❌ Fallback API request failed: ${response.error?.message}');
        _error = response.error?.message ?? 'Failed to load favorites';
      }
    } catch (e) {
      debugPrint('❌ Error in fallback favorites load: $e');
      _error = 'Error loading favorites: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get favorite course by ID
  Course? getFavoriteCourseById(String courseId) {
    try {
      return _favoritesCourses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get favorite course by title and author (legacy support)
  Course? getFavoriteCourseByTitleAndAuthor(
    String courseTitle,
    String courseAuthor,
  ) {
    try {
      return _favoritesCourses.firstWhere(
        (course) =>
            course.title == courseTitle && course.author == courseAuthor,
      );
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
