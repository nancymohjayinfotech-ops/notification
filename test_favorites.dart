import 'package:flutter/material.dart';
import 'lib/student/models/course.dart';
import 'lib/student/services/favorites_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing Favorites Service...');
  
  final favoritesService = FavoritesService();
  
  // Create test courses
  final course1 = Course(
    title: 'Flutter Development Fundamentals',
    author: 'By John Carter',
    imageAsset: 'assets/images/developer.png',
  );
  
  final course2 = Course(
    title: 'User Experience Design Fundamentals',
    author: 'By John Carter',
    imageAsset: 'assets/images/tester.jpg',
  );
  
  print('Initial favorites count: ${favoritesService.favoritesCount}');
  
  // Test adding to favorites
  await favoritesService.addToFavorites(course1);
  print('After adding course1: ${favoritesService.favoritesCount}');
  print('Is course1 favorite: ${favoritesService.isFavoriteByTitleAndAuthor(course1.title, course1.author)}');
  
  await favoritesService.addToFavorites(course2);
  print('After adding course2: ${favoritesService.favoritesCount}');
  print('Is course2 favorite: ${favoritesService.isFavoriteByTitleAndAuthor(course2.title, course2.author)}');
  
  // Test toggle
  await favoritesService.toggleFavorite(course1);
  print('After toggling course1: ${favoritesService.favoritesCount}');
  print('Is course1 favorite: ${favoritesService.isFavoriteByTitleAndAuthor(course1.title, course1.author)}');
  
  // Test toggle again
  await favoritesService.toggleFavorite(course1);
  print('After toggling course1 again: ${favoritesService.favoritesCount}');
  print('Is course1 favorite: ${favoritesService.isFavoriteByTitleAndAuthor(course1.title, course1.author)}');
  
  print('All favorites:');
  for (var course in favoritesService.favoritesCourses) {
    print('- ${course.title} by ${course.author}');
  }
  
  print('Favorites service test completed successfully!');
}
