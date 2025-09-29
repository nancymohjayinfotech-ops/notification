import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CategoryService {
  static const String baseUrl = 'http://54.82.53.11:5001/api';

  // Get all categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'GET',
        url: '$baseUrl/categories',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Categories API response: ${jsonEncode(data)}');

        if (data['success'] == true) {
          List<dynamic> categoriesData = [];

          // Based on the API response, categories are directly in the 'categories' key
          if (data['categories'] is List) {
            categoriesData = data['categories'] as List;
            debugPrint(
              'Found ${categoriesData.length} categories directly in categories key',
            );
          } else if (data['data'] is List) {
            categoriesData = data['data'] as List;
          } else if (data['data'] != null &&
              data['data']['categories'] is List) {
            categoriesData = data['data']['categories'] as List;
          }

          return {
            'success': true,
            'categories': categoriesData,
            'message': data['message'] ?? 'Categories retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve categories',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to retrieve categories. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Create a new category
  static Future<Map<String, dynamic>> createCategory({
    required String name,
    required String description,
    List<String> subCategories = const [],
  }) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'POST',
        url: '$baseUrl/categories',
        body: jsonEncode({
          'name': name,
          'description': description,
          'subCategories': subCategories.map((tag) => {'name': tag}).toList(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'category': data['data']?['category'] ?? data['category'] ?? {},
            'message': data['message'] ?? 'Category created successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to create category',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to create category. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error creating category: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update a category
  static Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    List<String> subCategories = const [],
  }) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'PUT',
        url: '$baseUrl/categories/$categoryId',
        body: jsonEncode({
          'name': name,
          'description': description,
          'subCategories': subCategories.map((tag) => {'name': tag}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'category': data['data']?['category'] ?? data['category'] ?? {},
            'message': data['message'] ?? 'Category updated successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to update category',
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Failed to update category. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete a category
  static Future<Map<String, dynamic>> deleteCategory(String categoryId) async {
    try {
      final response = await InstructorAuthService.authenticatedRequest(
        method: 'DELETE',
        url: '$baseUrl/categories/$categoryId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Category deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to delete category. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
