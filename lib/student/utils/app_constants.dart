import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'LMS Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Professional Learning Management System';
  
  // API Configuration
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Validation Constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int otpLength = 6;
  static const int phoneMinLength = 10;
  static const int phoneMaxLength = 15;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Colors
  static const Color primaryColor = Color(0xFF5F299E);
  static const Color primaryDarkColor = Color(0xFF8B5CF6);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';
  static const String favoritesKey = 'favorites';
  static const String cartKey = 'cart_items';
  
  // Course Constants
  static const int maxCourseTitle = 100;
  static const int maxCourseDescription = 500;
  static const double minCoursePrice = 0.0;
  static const double maxCoursePrice = 10000.0;
  static const int maxCourseDuration = 365; // days
  
  // File Upload Constants
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedVideoTypes = ['mp4', 'avi', 'mov', 'wmv'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Settings
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration shortCacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 100; // number of items
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection failed. Please check your internet connection.';
  static const String serverErrorMessage = 'Server error occurred. Please try again later.';
  static const String unauthorizedMessage = 'Session expired. Please login again.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  static const String unknownErrorMessage = 'An unexpected error occurred. Please try again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'OTP Verified';
  static const String signupSuccessMessage = 'Account created successfully!';
  static const String profileUpdateMessage = 'Profile updated successfully!';
  static const String passwordChangeMessage = 'Password changed successfully!';
  
  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;
  static const bool enableOfflineMode = true;
  static const bool enableDarkMode = true;
  
  // Social Media Links
  static const String facebookUrl = 'https://facebook.com/lmspro';
  static const String twitterUrl = 'https://twitter.com/lmspro';
  static const String linkedinUrl = 'https://linkedin.com/company/lmspro';
  static const String instagramUrl = 'https://instagram.com/lmspro';
  
  // Support Information
  static const String supportEmail = 'support@lmspro.com';
  static const String supportPhone = '+1-800-LMS-HELP';
  static const String privacyPolicyUrl = 'https://lmspro.com/privacy';
  static const String termsOfServiceUrl = 'https://lmspro.com/terms';
  
  // Rating and Review
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
  static const int maxReviewLength = 500;
  
  // Search
  static const int minSearchLength = 2;
  static const int maxSearchResults = 50;
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
  
  // Notification Types
  static const String notificationTypeCourse = 'course';
  static const String notificationTypeMessage = 'message';
  static const String notificationTypeOffer = 'offer';
  static const String notificationTypeSystem = 'system';
  
  // Course Status
  static const String courseStatusDraft = 'draft';
  static const String courseStatusPublished = 'published';
  static const String courseStatusArchived = 'archived';
  
  // User Roles
  static const String roleStudent = 'student';
  static const String roleInstructor = 'instructor';
  static const String roleAdmin = 'admin';
  
  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';
  
  // Environment
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool enableDebugMode = !isProduction;
  
  // Regular Expressions
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'h:mm a';
  
  // Utility Methods
  static bool isValidEmail(String email) {
    return RegExp(emailRegex).hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    return RegExp(phoneRegex).hasMatch(phone);
  }
  
  static bool isValidPassword(String password) {
    return RegExp(passwordRegex).hasMatch(password);
  }
  
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
