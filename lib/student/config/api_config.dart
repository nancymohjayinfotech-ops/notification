import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://54.82.53.11:5001/api/';
    }
    // For Android/iOS, use your LAN IP
    return 'http://54.82.53.11:5001/api/';
  }

  // API Endpoints
  static const String authEndpoint = 'auth';
  static const String coursesEndpoint = 'courses';
  static const String usersEndpoint = '/user';
  static const String categoriesEndpoint = '/categories';
  static const String contentEndpoint = '/content';

  // Authentication Endpoints
  static const String signup = 'auth/signup';
  static const String googleSignIn = '$authEndpoint/google-login';
  static const String sendOtp = 'auth/send-otp';
  static const String verifyOtp = 'auth/verify-otp';
  static const String refreshToken = '$authEndpoint/refresh-token';
  static const String logout = '$authEndpoint/logout';

  // User Endpoints
  static const String profile = '$usersEndpoint/profile';
  static const String updateProfile = '$usersEndpoint/profile';
  static const String uploadProfileImage = 'uploads/profile';
  static const String setCollege = '$usersEndpoint/set-college';
  static const String userInterests = '$usersEndpoint/interests';
  static const String interestsStatus = '$usersEndpoint/interests/status';

  // Cart Endpoints
  static const String cart = 'cart';
  static const String addToCart = 'cart/add';
  static String removeFromCart(String courseId) => 'cart/remove/$courseId';

  // Favorite Endpoints
  static const String userFavorites = '/user/favorites';
  static const String addToFavorites = '/user/favorites/{courseId}';
  static const String removeFromFavorites = '/user/favorites/{courseId}';

  // Offers Endpoints
  static const String offersEndpoint = '/offers';
  static const String allOffers = offersEndpoint;
  static const String offerById = '$offersEndpoint/{id}';
  static const String offersForCourse = '$offersEndpoint/course/{courseId}';
  static const String applyOffer = '$offersEndpoint/apply';
  static const String validateCoupon = '$offersEndpoint/validate-coupon';

  // Course Endpoints (relative paths - baseUrl is added by ApiClient)
  static String get courses => 'courses';
  static String get allCourses => 'courses';
  static String get featuredCourses => 'courses/featured';
  static String get popularCourses => 'courses/popular';
  static String get recommendedCourses => 'courses/recommended';
  static String get courseDetails => 'courses';
  static String get courseById => 'courses';
  static String get courseBySlug => 'courses/slug';
  static String get searchCourses => '$coursesEndpoint/search';
  static String get enrollCourse => '$coursesEndpoint/{id}/enroll';
  static String get enrolledCourses => '/courses/student/enrolled';
  static String get dashboardStats =>
      '$coursesEndpoint/student/dashboard/stats';
  static String get favoriteCourses => '$coursesEndpoint/favorites';

  // Category Endpoints
  static String get allCategories => categoriesEndpoint;
  static String get categoryById => '$categoriesEndpoint/{id}';
  static String get categoriesWithPagination => '$categoriesEndpoint/paginated';

  // Subcategory Endpoints
  static String get subcategoriesByCategory =>
      '/subcategories/category/{categoryId}';
  static String get subcategoriesWithPagination =>
      '$categoriesEndpoint/{categoryId}/subcategories/paginated';
  static String get subcategoryById =>
      '$categoriesEndpoint/{categoryId}/subcategories/{id}';
  static String get createSubcategory =>
      '$categoriesEndpoint/{categoryId}/subcategories';

  // Content Endpoints
  static String contentByType(String type) => 'content/$type';

  // Event Endpoints - Based on actual API
  static const String eventsEndpoint = '/events';
  static String get allEvents => 'student/events';
  static String get enrolledEvents => 'events/my-enrollments';
  static String getEventByTitle(String title) => 'student/events/$title';
  static String enrollInEvent(String eventId) => 'events/$eventId/enroll';

  // Groups Endpoints - Updated to match actual backend API
  static const String myGroups = '/groups/my-groups';
  static String getMessages(String groupId) => '/groups/$groupId/with-messages';
  static String leaveGroup(String groupId) => '/groups/$groupId/leave';

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Token Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userPhoneKey = 'user_phone';

  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // OTP Configuration
  static const int otpLength = 6;
  static const Duration otpTimeout = Duration(minutes: 5);
  static const Duration otpResendDelay = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration shortCacheExpiry = Duration(minutes: 15);

  // Environment Configuration
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get enableLogging => !isProduction;

  // API Response Status Codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int validationErrorCode = 422;
  static const int serverErrorCode = 500;

  // Error Messages
  static const String networkErrorMessage =
      'Network connection failed. Please check your internet connection.';
  static const String serverErrorMessage =
      'Server error occurred. Please try again later.';
  static const String unauthorizedMessage =
      'Session expired. Please login again.';
  static const String validationErrorMessage =
      'Invalid data provided. Please check your input.';
  static const String unknownErrorMessage =
      'An unexpected error occurred. Please try again.';
}
