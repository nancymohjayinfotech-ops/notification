import 'package:flutter/material.dart';
import 'package:fluttertest/instructor/pages/CategoriesPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoriesService {
  static const String _baseUrl = 'http://54.82.53.11:5001/api';
  static const String _localBaseUrl = 'http://54.82.53.11:5001/api';

  // Singleton pattern
  static final CategoriesService _instance = CategoriesService._internal();
  factory CategoriesService() => _instance;
  CategoriesService._internal();

  // Cache for categories
  List<CategoryModel>? _cachedCategories;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  // Mock data for development (replace with actual API calls)
  List<CategoryModel> _getMockCategories() {
    return [
      CategoryModel(
        name: 'Digital Marketing',
        icon: Icons.campaign,
        color: Color(0xFFE91E63),
        courseCount: 12,
      ),
      CategoryModel(
        name: 'UI/UX Design',
        icon: Icons.design_services,
        color: Color(0xFF9C27B0),
        courseCount: 8,
      ),
      CategoryModel(
        name: 'Flutter Development',
        icon: Icons.phone_android,
        color: Color(0xFF2196F3),
        courseCount: 15,
      ),
      CategoryModel(
        name: 'DevOps',
        icon: Icons.cloud,
        color: Color(0xFF4CAF50),
        courseCount: 10,
      ),
      CategoryModel(
        name: 'Data Science',
        icon: Icons.analytics,
        color: Color(0xFFFF9800),
        courseCount: 7,
      ),
      CategoryModel(
        name: 'Software Testing',
        icon: Icons.bug_report,
        color: Color(0xFFF44336),
        courseCount: 6,
      ),
      CategoryModel(
        name: 'Web Development',
        icon: Icons.web,
        color: Color(0xFF00BCD4),
        courseCount: 11,
      ),
      CategoryModel(
        name: 'Machine Learning',
        icon: Icons.psychology,
        color: Color(0xFF795548),
        courseCount: 9,
      ),
      CategoryModel(
        name: 'Business Analytics',
        icon: Icons.trending_up,
        color: Color(0xFF607D8B),
        courseCount: 5,
      ),
      CategoryModel(
        name: 'Cybersecurity',
        icon: Icons.security,
        color: Color(0xFF3F51B5),
        courseCount: 4,
      ),
      CategoryModel(
        name: 'Project Management',
        icon: Icons.assignment,
        color: Color(0xFF009688),
        courseCount: 6,
      ),
      CategoryModel(
        name: 'Graphic Design',
        icon: Icons.palette,
        color: Color(0xFFFF5722),
        courseCount: 8,
      ),
    ];
  }

  // Get all categories
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _cachedCategories != null && _lastFetchTime != null) {
      final timeDifference = DateTime.now().difference(_lastFetchTime!);
      if (timeDifference < _cacheExpiry) {
        return _cachedCategories!;
      }
    }

    try {
      // TODO: Replace with actual API call
      // final response = await http.get(
      //   Uri.parse('$_baseUrl/categories'),
      //   headers: {'Content-Type': 'application/json'},
      // );

      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   final categories = data.map((json) => CategoryModel.fromJson(json)).toList();
      //
      //   // Update cache
      //   _cachedCategories = categories;
      //   _lastFetchTime = DateTime.now();
      //
      //   return categories;
      // } else {
      //   throw Exception('Failed to load categories: ${response.statusCode}');
      // }

      // For now, return mock data
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Simulate network delay
      final categories = _getMockCategories();

      // Update cache
      _cachedCategories = categories;
      _lastFetchTime = DateTime.now();

      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      // Return cached data if available, otherwise return mock data
      return _cachedCategories ?? _getMockCategories();
    }
  }

  // Get category by name
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

  // Search categories
  Future<List<CategoryModel>> searchCategories(String query) async {
    final categories = await getCategories();
    if (query.isEmpty) return categories;

    return categories.where((category) {
      return category.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get popular categories (top 6)
  Future<List<CategoryModel>> getPopularCategories() async {
    final categories = await getCategories();
    // Sort by course count and take top 6
    categories.sort((a, b) => b.courseCount.compareTo(a.courseCount));
    return categories.take(6).toList();
  }

  // Get categories by course count range
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

  // Clear cache
  void clearCache() {
    _cachedCategories = null;
    _lastFetchTime = null;
  }

  // Refresh categories
  Future<List<CategoryModel>> refreshCategories() async {
    return await getCategories(forceRefresh: true);
  }

  // Get categories with counts from local API for instructor
  Future<List<CategoryWithCount>> getCategoriesWithCounts() async {
    try {
      // Using the specific endpoint for categories with counts
      final response = await http.get(
        Uri.parse('$_localBaseUrl/categories/with-counts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_AUTH_TOKEN_HERE', // You'll need to replace this with actual token
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the response has a 'data' field with categories
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> categoriesData =
              responseData['data']['categories'] ?? [];
          return categoriesData
              .map((json) => CategoryWithCount.fromJson(json))
              .toList();
        } else {
          return []; // Return empty list if no categories found
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to load categories with counts: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching categories with counts: $e');
      throw Exception('Error fetching categories with counts: $e');
    }
  }

  // Get category statistics
  Future<Map<String, dynamic>> getCategoryStats() async {
    final categories = await getCategories();

    int totalCategories = categories.length;
    int totalCourses = categories.fold(
      0,
      (sum, category) => sum + category.courseCount,
    );
    double averageCoursesPerCategory = totalCourses / totalCategories;

    CategoryModel mostPopular = categories.reduce(
      (a, b) => a.courseCount > b.courseCount ? a : b,
    );

    return {
      'totalCategories': totalCategories,
      'totalCourses': totalCourses,
      'averageCoursesPerCategory': averageCoursesPerCategory.round(),
      'mostPopularCategory': mostPopular.name,
      'mostPopularCourseCount': mostPopular.courseCount,
    };
  }
}

// Category with count model
class CategoryWithCount {
  final String id;
  final String name;
  final int courseCount;
  final String? description;
  final String? imageUrl;

  CategoryWithCount({
    required this.id,
    required this.name,
    required this.courseCount,
    this.description,
    this.imageUrl,
  });

  factory CategoryWithCount.fromJson(Map<String, dynamic> json) {
    return CategoryWithCount(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      courseCount:
          json['courseCount'] ??
          json['count'] ??
          0, // Handle different API response formats
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['image'],
    );
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
