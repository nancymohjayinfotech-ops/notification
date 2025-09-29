import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../services/course_service.dart';

abstract class CourseRepository {
  Future<List<Course>> getAllCourses();
  Future<List<Course>> getCoursesByCategory(String category);
  Future<List<Course>> getCoursesBySubcategory(String subcategoryId);
  Future<List<Course>> searchCourses(String query);
  Future<Course?> getCourseById(String id);
  Future<Course?> getCourseBySlug(String slug);
  Future<List<Course>> getFeaturedCourses();
  Future<List<Course>> getRecommendedCourses();
  Future<bool> enrollInCourse(String courseId);
  Future<bool> updateCourseProgress(String courseId, double progress);
}

class CourseRepositoryImpl implements CourseRepository {
  static const String _coursesKey = 'cached_courses';
  static const String _enrolledCoursesKey = 'enrolled_courses';
  static const String _courseProgressKey = 'course_progress';

  final Duration _cacheExpiry = const Duration(hours: 1);
  DateTime? _lastFetchTime;
  List<Course>? _cachedCourses;
  final CourseService _courseService = CourseService();

  @override
  Future<List<Course>> getAllCourses() async {
    try {
      // Check cache first
      if (_cachedCourses != null && _lastFetchTime != null) {
        final timeDifference = DateTime.now().difference(_lastFetchTime!);
        if (timeDifference < _cacheExpiry) {
          return _cachedCourses!;
        }
      }

      // Fetch from API
      final courses = await _courseService.getAllCourses(published: true);

      // Cache the results
      _cachedCourses = courses;
      _lastFetchTime = DateTime.now();
      await _saveCourseCache(courses);

      return courses;
    } catch (e) {
      debugPrint('❌ Error fetching courses from API, falling back to cache: $e');

      // Fallback to cache if API fails
      final cachedCourses = await _loadCourseCache();
      if (cachedCourses != null) {
        return cachedCourses;
      }

      // If no cache, return empty list
      return [];
    }
  }
  
  @override
  Future<List<Course>> getCoursesByCategory(String category) async {
    try {
      return await _courseService.getCoursesByCategory(category);
    } catch (e) {
      debugPrint('❌ Error fetching courses by category, falling back to local filtering: $e');

      // Fallback to local filtering
      final allCourses = await getAllCourses();
      return allCourses.where((course) {
        final categoryLower = category.toLowerCase();
        final titleLower = course.title.toLowerCase();
        final descriptionLower = course.description.toLowerCase();
        final courseCategoryName = course.category?.name?.toLowerCase() ?? '';

        return titleLower.contains(categoryLower) ||
               descriptionLower.contains(categoryLower) ||
               courseCategoryName.contains(categoryLower);
      }).toList();
    }
  }

  @override
  Future<List<Course>> getCoursesBySubcategory(String subcategoryId) async {
    try {
      return await _courseService.getCoursesBySubcategory(subcategoryId);
    } catch (e) {
      debugPrint('❌ Error fetching courses by subcategory, falling back to local filtering: $e');
      final allCourses = await getAllCourses();
      return allCourses.where((course) => course.subcategory?.id == subcategoryId).toList();
    }
  }

  @override
  Future<List<Course>> searchCourses(String query) async {
    try {
      return await _courseService.searchCourses(query);
    } catch (e) {
      debugPrint('❌ Error searching courses, falling back to local search: $e');

      // Fallback to local search
      if (query.trim().isEmpty) {
        return await getAllCourses();
      }

      final allCourses = await getAllCourses();
      final queryLower = query.toLowerCase();

      return allCourses.where((course) {
        return course.title.toLowerCase().contains(queryLower) ||
               course.author.toLowerCase().contains(queryLower) ||
               course.description.toLowerCase().contains(queryLower);
      }).toList();
    }
  }

  @override
  Future<Course?> getCourseById(String id) async {
    try {
      return await _courseService.getCourseById(id);
    } catch (e) {
      debugPrint('❌ Error fetching course by ID, falling back to local search: $e');

      // Fallback to local search
      final allCourses = await getAllCourses();
      try {
        return allCourses.firstWhere((course) => course.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Future<Course?> getCourseBySlug(String slug) async {
    try {
      return await _courseService.getCourseBySlug(slug);
    } catch (e) {
      debugPrint('❌ Error fetching course by slug, falling back to local search: $e');
      final allCourses = await getAllCourses();
      try {
        return allCourses.firstWhere((course) => course.slug == slug);
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Future<List<Course>> getFeaturedCourses() async {
    try {
      return await _courseService.getFeaturedCourses();
    } catch (e) {
      debugPrint('❌ Error fetching featured courses, falling back to local filtering: $e');

      // Fallback to local filtering
      final allCourses = await getAllCourses();
      return allCourses.where((course) => course.averageRating >= 4.7).take(5).toList();
    }
  }

  @override
  Future<List<Course>> getRecommendedCourses() async {
    try {
      return await _courseService.getRecommendedCourses();
    } catch (e) {
      debugPrint('❌ Error fetching recommended courses, falling back to local filtering: $e');

      // Fallback to local filtering
      final allCourses = await getAllCourses();
      final shuffled = List<Course>.from(allCourses)..shuffle();
      return shuffled.take(6).toList();
    }
  }

  @override
  Future<bool> enrollInCourse(String courseId) async {
    try {
      // Try API first
      final success = await _courseService.enrollInCourse(courseId);

      if (success) {
        // Also update local storage for offline access
        final prefs = await SharedPreferences.getInstance();
        final enrolledCourses = prefs.getStringList(_enrolledCoursesKey) ?? [];

        if (!enrolledCourses.contains(courseId)) {
          enrolledCourses.add(courseId);
          await prefs.setStringList(_enrolledCoursesKey, enrolledCourses);
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error enrolling in course: $e');
      return false;
    }
  }
  
  @override
  Future<bool> updateCourseProgress(String courseId, double progress) async {
    try {
      // Update local storage for offline access
      final prefs = await SharedPreferences.getInstance();
      final progressMap = prefs.getString(_courseProgressKey);

      Map<String, double> courseProgress = {};
      if (progressMap != null) {
        final decoded = json.decode(progressMap) as Map<String, dynamic>;
        courseProgress = decoded.map((key, value) => MapEntry(key, value.toDouble()));
      }

      courseProgress[courseId] = progress;
      await prefs.setString(_courseProgressKey, json.encode(courseProgress));

      return true;
    } catch (e) {
      debugPrint('Error updating course progress: $e');
      return false;
    }
  }
  
  // Helper methods
  Future<void> _saveCourseCache(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = json.encode(courses.map((c) => c.toMap()).toList());
      await prefs.setString(_coursesKey, coursesJson);
    } catch (e) {
      debugPrint('Error saving course cache: $e');
    }
  }
  
  Future<List<Course>?> _loadCourseCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getString(_coursesKey);
      
      if (coursesJson != null) {
        final coursesList = json.decode(coursesJson) as List;
        return coursesList.map((c) => Course.fromMap(c)).toList();
      }
    } catch (e) {
      debugPrint('Error loading course cache: $e');
    }
    return null;
  }
  
  // Public utility methods
  Future<List<String>> getEnrolledCourseIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_enrolledCoursesKey) ?? [];
  }
  
  Future<double> getCourseProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressMap = prefs.getString(_courseProgressKey);
    
    if (progressMap != null) {
      final decoded = json.decode(progressMap) as Map<String, dynamic>;
      return decoded[courseId]?.toDouble() ?? 0.0;
    }
    
    return 0.0;
  }
  
  Future<void> clearCache() async {
    _cachedCourses = null;
    _lastFetchTime = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coursesKey);
  }
}