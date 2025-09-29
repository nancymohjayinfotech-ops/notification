import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/category.dart';
import 'api_client.dart';
import 'course_service.dart';

class CategoriesService {
  // Singleton pattern
  static final CategoriesService _instance = CategoriesService._internal();
  factory CategoriesService() => _instance;
  CategoriesService._internal();

  // ApiClient is now accessed directly since it's also a singleton
  final ApiClient _apiClient = ApiClient();

  // Cache for categories
  List<Category>? _cachedCategories;
  List<CategoryModel>? _cachedCategoryModels;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Get all categories from API
  Future<List<Category>> getAllCategories({bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh && _cachedCategories != null && _lastFetchTime != null) {
        final timeDifference = DateTime.now().difference(_lastFetchTime!);
        if (timeDifference < _cacheExpiry) {
          return _cachedCategories!;
        }
      }

      debugPrint('🔍 Fetching categories from API...');

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.allCategories,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true && data['categories'] != null) {
          final categoriesJson = data['categories'] as List<dynamic>;
          final categories = categoriesJson
              .map((categoryJson) => Category.fromJson(categoryJson))
              .toList();

          // Update cache
          _cachedCategories = categories;
          _lastFetchTime = DateTime.now();

          debugPrint('✅ Successfully fetched ${categories.length} categories');
          return categories;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to fetch categories');
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        throw Exception(response.error?.message ?? 'Failed to fetch categories');
      }
    } catch (e) {
      debugPrint('❌ Error in getAllCategories: $e');

      // Return cached data if available
      if (_cachedCategories != null) {
        debugPrint('📦 Returning cached categories');
        return _cachedCategories!;
      }

      rethrow;
    }
  }

  /// Get all categories as CategoryModel
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh && _cachedCategoryModels != null && _lastFetchTime != null) {
        final timeDifference = DateTime.now().difference(_lastFetchTime!);
        if (timeDifference < _cacheExpiry) {
          return _cachedCategoryModels!;
        }
      }

      final categories = await getAllCategories(forceRefresh: forceRefresh);
      final categoryModels = await getCategoriesWithCourseCounts(categories);

      _cachedCategoryModels = categoryModels;
      return categoryModels;
    } catch (e) {
      debugPrint('❌ Error in getCategories: $e');

      // Return cached data if available
      if (_cachedCategoryModels != null) {
        return _cachedCategoryModels!;
      }

      rethrow;
    }
  }

  /// Get categories with real course counts from API
  Future<List<CategoryModel>> getCategoriesWithCourseCounts(List<Category> categories) async {
    try {
      debugPrint('📊 Fetching real course counts for ${categories.length} categories');
      
      final courseService = CourseService();
      final categoryIds = categories.map((cat) => cat.id ?? '').where((id) => id.isNotEmpty).toList();
      
      if (categoryIds.isEmpty) {
        // Fallback to default conversion if no IDs available
        return categories.map((category) => CategoryModel.fromCategory(category)).toList();
      }
      
      final courseCounts = await courseService.getCourseCountsForCategories(categoryIds);
      
      final categoryModels = categories.map((category) {
        final courseCount = courseCounts[category.id] ?? 0;
        return CategoryModel(
          name: category.name,
          icon: category.iconData,
          color: category.colorValue,
          courseCount: courseCount,
        );
      }).toList();
      
      debugPrint('✅ Successfully created ${categoryModels.length} categories with real course counts');
      return categoryModels;
    } catch (e) {
      debugPrint('❌ Error in getCategoriesWithCourseCounts: $e');
      // Fallback to default conversion
      return categories.map((category) => CategoryModel.fromCategory(category)).toList();
    }
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      debugPrint('🔍 Fetching category by ID: $categoryId');

      final endpoint = ApiConfig.categoryById.replaceAll('{id}', categoryId);
      final response = await _apiClient.get<Map<String, dynamic>>(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true && data['category'] != null) {
          final category = Category.fromJson(data['category']);
          debugPrint('✅ Successfully fetched category: ${category.name}');
          return category;
        } else {
          debugPrint('❌ Category not found: ${data['message']}');
          return null;
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in getCategoryById: $e');
      return null;
    }
  }

  /// Get subcategories for a category
  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    try {
      debugPrint('🔍 Fetching subcategories for category: $categoryId');

      final endpoint = ApiConfig.subcategoriesByCategory.replaceAll('{categoryId}', categoryId);
      final response = await _apiClient.get<Map<String, dynamic>>(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        if (data['success'] == true && data['subcategories'] != null) {
          final subcategoriesJson = data['subcategories'] as List<dynamic>;
          final subcategories = subcategoriesJson
              .map((subJson) => Subcategory.fromJson(subJson))
              .toList();

          debugPrint('✅ Successfully fetched ${subcategories.length} subcategories');
          return subcategories;
        } else {
          debugPrint('❌ API returned success=false: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error in getSubcategories: $e');
      return [];
    }
  }

  /// Get category by name
  Future<CategoryModel?> getCategoryByName(String name) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search categories by query
  Future<List<CategoryModel>> searchCategories(String query) async {
    final categories = await getCategories();
    if (query.isEmpty) return categories;

    return categories.where((category) {
      return category.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Get popular categories (top 6 by course count)
  Future<List<CategoryModel>> getPopularCategories() async {
    final categories = await getCategories();
    categories.sort((a, b) => b.courseCount.compareTo(a.courseCount));
    return categories.take(6).toList();
  }

  /// Get categories by course count range
  Future<List<CategoryModel>> getCategoriesByRange(
    int minCourses,
    int maxCourses,
  ) async {
    final categories = await getCategories();
    return categories.where((category) {
      return category.courseCount >= minCourses &&
          category.courseCount <= maxCourses;
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _cachedCategories = null;
    _cachedCategoryModels = null;
    _lastFetchTime = null;
  }

  /// Refresh categories (force API call)
  Future<List<CategoryModel>> refreshCategories() async {
    return await getCategories(forceRefresh: true);
  }

  /// Get category statistics
  Future<Map<String, dynamic>> getCategoryStats() async {
    final categories = await getCategories();

    int totalCategories = categories.length;
    int totalCourses = categories.fold(
      0,
      (sum, category) => sum + category.courseCount,
    );
    double averageCoursesPerCategory = totalCategories > 0
        ? totalCourses / totalCategories
        : 0;

    CategoryModel? mostPopular;
    if (categories.isNotEmpty) {
      mostPopular = categories.reduce(
        (a, b) => a.courseCount > b.courseCount ? a : b,
      );
    }

    return {
      'totalCategories': totalCategories,
      'totalCourses': totalCourses,
      'averageCoursesPerCategory': averageCoursesPerCategory.round(),
      'mostPopularCategory': mostPopular?.name ?? 'None',
      'mostPopularCourseCount': mostPopular?.courseCount ?? 0,
    };
  }
}

// Extension for CategoryModel to add utility methods
extension CategoryModelExtension on CategoryModel {
  bool get isPopular => courseCount >= 10;
  bool get isNew => courseCount <= 5;

  String get popularityLabel {
    if (courseCount >= 15) return 'Very Popular';
    if (courseCount >= 10) return 'Popular';
    if (courseCount >= 5) return 'Growing';
    return 'New';
  }

  Color get popularityColor {
    if (courseCount >= 15) return Colors.green;
    if (courseCount >= 10) return Colors.orange;
    if (courseCount >= 5) return Colors.blue;
    return Colors.grey;
  }
}