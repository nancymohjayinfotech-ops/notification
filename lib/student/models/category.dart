import 'package:flutter/material.dart';

class Subcategory {
  final String? id;
  final String name;
  final String? slug;
  final String description;
  final String icon;
  final int order;
  final String backgroundColor;
  final bool isActive;
  final String? categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Subcategory({
    this.id,
    required this.name,
    this.slug,
    this.description = '',
    this.icon = '',
    this.order = 0,
    this.backgroundColor = '',
    this.isActive = true,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      order: json['order'] ?? 0,
      backgroundColor: json['backgroundColor'] ?? '',
      isActive: json['isActive'] ?? true,
      categoryId: json['categoryId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Get icon as IconData similar to Category
  IconData get iconData {
    if (icon.isEmpty) return Icons.category;
    switch (icon.toLowerCase()) {
      case 'code': return Icons.code;
      case 'design': return Icons.design_services;
      case 'business': return Icons.business;
      case 'marketing': return Icons.campaign;
      case 'data': return Icons.analytics;
      case 'mobile': return Icons.phone_android;
      case 'web': return Icons.web;
      case 'cloud': return Icons.cloud;
      case 'security': return Icons.security;
      case 'ai': return Icons.psychology;
      case 'game': return Icons.games;
      case 'photo': return Icons.photo_camera;
      case 'video': return Icons.videocam;
      case 'music': return Icons.music_note;
      case 'book': return Icons.book;
      case 'language': return Icons.language;
      case 'science': return Icons.science;
      case 'math': return Icons.calculate;
      case 'art': return Icons.palette;
      case 'fitness': return Icons.fitness_center;
      case 'health': return Icons.health_and_safety;
      case 'food': return Icons.restaurant;
      case 'travel': return Icons.flight;
      case 'finance': return Icons.account_balance;
      case 'education': return Icons.school;
      default: return Icons.category;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'order': order,
      'backgroundColor': backgroundColor,
      'isActive': isActive,
      'categoryId': categoryId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Get background color as Flutter Color
  Color get colorValue {
    if (backgroundColor.isEmpty) return Colors.blue.shade100;
    
    try {
      // Handle hex color codes
      if (backgroundColor.startsWith('#')) {
        final hexColor = backgroundColor.substring(1);
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      
      // Handle named colors
      switch (backgroundColor.toLowerCase()) {
        case 'red': return Colors.red.shade100;
        case 'blue': return Colors.blue.shade100;
        case 'green': return Colors.green.shade100;
        case 'orange': return Colors.orange.shade100;
        case 'purple': return Colors.purple.shade100;
        case 'pink': return Colors.pink.shade100;
        case 'teal': return Colors.teal.shade100;
        case 'amber': return Colors.amber.shade100;
        default: return Colors.blue.shade100;
      }
    } catch (e) {
      return Colors.blue.shade100;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subcategory &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class Category {
  final String? id;
  final String name;
  final String? slug;
  final String description;
  final String icon;
  final int order;
  final String backgroundColor;
  final bool isActive;
  final List<Subcategory> subcategories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    this.id,
    required this.name,
    this.slug,
    this.description = '',
    this.icon = '',
    this.order = 0,
    this.backgroundColor = '',
    this.isActive = true,
    this.subcategories = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      order: json['order'] ?? 0,
      backgroundColor: json['backgroundColor'] ?? '',
      isActive: json['isActive'] ?? true,
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List<dynamic>)
              .map((sub) => Subcategory.fromJson(sub))
              .toList()
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'order': order,
      'backgroundColor': backgroundColor,
      'isActive': isActive,
      'subcategories': subcategories.map((sub) => sub.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Get background color as Flutter Color
  Color get colorValue {
    if (backgroundColor.isEmpty) return Colors.blue.shade100;
    
    try {
      // Handle hex color codes
      if (backgroundColor.startsWith('#')) {
        final hexColor = backgroundColor.substring(1);
        return Color(int.parse('FF$hexColor', radix: 16));
      }
      
      // Handle named colors
      switch (backgroundColor.toLowerCase()) {
        case 'red': return Colors.red.shade100;
        case 'blue': return Colors.blue.shade100;
        case 'green': return Colors.green.shade100;
        case 'orange': return Colors.orange.shade100;
        case 'purple': return Colors.purple.shade100;
        case 'pink': return Colors.pink.shade100;
        case 'teal': return Colors.teal.shade100;
        case 'amber': return Colors.amber.shade100;
        default: return Colors.blue.shade100;
      }
    } catch (e) {
      return Colors.blue.shade100;
    }
  }

  // Get icon as IconData
  IconData get iconData {
    if (icon.isEmpty) return Icons.category;
    
    // Map common icon names to IconData
    switch (icon.toLowerCase()) {
      case 'code': return Icons.code;
      case 'design': return Icons.design_services;
      case 'business': return Icons.business;
      case 'marketing': return Icons.campaign;
      case 'data': return Icons.analytics;
      case 'mobile': return Icons.phone_android;
      case 'web': return Icons.web;
      case 'cloud': return Icons.cloud;
      case 'security': return Icons.security;
      case 'ai': return Icons.psychology;
      case 'game': return Icons.games;
      case 'photo': return Icons.photo_camera;
      case 'video': return Icons.videocam;
      case 'music': return Icons.music_note;
      case 'book': return Icons.book;
      case 'language': return Icons.language;
      case 'science': return Icons.science;
      case 'math': return Icons.calculate;
      case 'art': return Icons.palette;
      case 'fitness': return Icons.fitness_center;
      case 'health': return Icons.health_and_safety;
      case 'food': return Icons.restaurant;
      case 'travel': return Icons.flight;
      case 'finance': return Icons.account_balance;
      case 'education': return Icons.school;
      default: return Icons.category;
    }
  }

  // Get course count (for display purposes)
  int get courseCount => subcategories.length * 5; // Approximate

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// Legacy CategoryModel for backward compatibility
class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;
  final int courseCount;

  CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    this.courseCount = 0,
  });

  // Convert from new Category model
  factory CategoryModel.fromCategory(Category category) {
    return CategoryModel(
      name: category.name,
      icon: category.iconData,
      color: category.colorValue,
      courseCount: category.courseCount,
    );
  }
}
