import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal() {
    _loadFavorites();
  }

  List<Course> _favoritesCourses = [];
  static const String _favoritesKey = 'favorites_courses';

  List<Course> get favoritesCourses => List.unmodifiable(_favoritesCourses);

  int get favoritesCount => _favoritesCourses.length;

  bool get hasFavorites => _favoritesCourses.isNotEmpty;

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favoritesCourses = favoritesList
            .map((courseMap) => Course.fromMap(courseMap))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(
        _favoritesCourses.map((course) => course.toMap()).toList(),
      );
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  // Add course to favorites
  Future<void> addToFavorites(Course course) async {
    if (!isFavorite(course.title, course.author)) {
      _favoritesCourses.add(course);
      await _saveFavorites();
      notifyListeners();
    }
  }

  // Remove course from favorites
  Future<void> removeFromFavorites(Course course) async {
    _favoritesCourses.removeWhere(
      (favCourse) =>
          favCourse.title == course.title &&
          favCourse.author == course.author,
    );
    await _saveFavorites();
    notifyListeners();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(Course course) async {
    if (isFavorite(course.title, course.author)) {
      await removeFromFavorites(course);
    } else {
      await addToFavorites(course);
    }
  }

  // Check if course is in favorites
  bool isFavorite(String courseTitle, String courseAuthor) {
    return _favoritesCourses.any(
      (course) =>
          course.title == courseTitle &&
          course.author == courseAuthor,
    );
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _favoritesCourses.clear();
    await _saveFavorites();
    notifyListeners();
  }

  // Get favorite course by title and author
  Course? getFavoriteCourse(String courseTitle, String courseAuthor) {
    try {
      return _favoritesCourses.firstWhere(
        (course) =>
            course.title == courseTitle &&
            course.author == courseAuthor,
      );
    } catch (e) {
      return null;
    }
  }
}
