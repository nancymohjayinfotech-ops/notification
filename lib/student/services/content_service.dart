import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class ContentService with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, String> _cache = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> fetchContent(String type) async {
    try {
      _setLoading(true);
      _clearError();

      if (_cache.containsKey(type)) {
        return _cache[type];
      }

      // Build the endpoint using the content type
      final endpoint = ApiConfig.contentByType(type);
      debugPrint('🔄 Fetching content from: $endpoint');
      
      final response = await _apiClient.get(endpoint);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Handle different possible response formats
        if (data is Map<String, dynamic>) {
          // Format 1: { content: { content: "..." } }
          if (data['content'] is Map<String, dynamic>) {
            final contentText = (data['content']['content'] ?? '').toString();
            if (contentText.isNotEmpty) {
              _cache[type] = contentText;
              return contentText;
            }
          } 
          // Format 2: { content: "..." }
          else if (data['content'] != null) {
            final contentText = data['content'].toString();
            if (contentText.isNotEmpty) {
              _cache[type] = contentText;
              return contentText;
            }
          }
        }
        
        debugPrint('⚠️ No valid content found in response');
      } else {
        debugPrint('❌ API Error: ${response.error?.message}');
      }
    } catch (e) {
      _setError('Failed to load content');
    } finally {
      _setLoading(false);
    }

    // Return fallback content based on type
    switch (type) {
      case 'term':
      case 'terms':
      case 'terms-and-conditions':
        return _getFallbackTermsAndConditions();
      case 'about':
      case 'about-us':
        return _getFallbackAboutUs();
      case 'privacy':
      case 'privacy-policy':
        return _getFallbackPrivacyPolicy();
      default:
        return 'Content not available. Please try again later.';
    }
  }

  String _getFallbackTermsAndConditions() {
    return '''
Last updated: ${DateTime.now().year}

1. Introduction
Welcome to our Learning Management System. By accessing or using our services, you agree to be bound by these terms and conditions.

2. Use of Service
Our service allows you to access educational content, courses, and materials. You agree to use the service only for lawful purposes and in accordance with these terms.

3. Account Registration
You may be required to create an account to access certain features. You are responsible for maintaining the confidentiality of your account information.

4. Intellectual Property
All content, including text, graphics, and course materials, is the property of the platform or its content providers and is protected by copyright laws.

5. Limitation of Liability
We are not liable for any indirect, incidental, or consequential damages arising from your use of the service.

6. Changes to Terms
We reserve the right to modify these terms at any time. Your continued use of the service constitutes acceptance of those changes.

For any questions about these terms, please contact us.''';
  }

  String _getFallbackAboutUs() {
    return '''About Us

We are a leading online learning platform dedicated to providing high-quality education to learners worldwide.

Our Mission
To make quality education accessible to everyone, everywhere.

Our Vision
To create a world where anyone can learn anything, anytime, anywhere.

Contact Us
Email: support@example.com
Phone: +1 (555) 123-4567''';
  }

  String _getFallbackPrivacyPolicy() {
    return '''Privacy Policy
Last updated: ${DateTime.now().year}

1. Information We Collect
We collect personal information you provide when you register, enroll in courses, or contact us.

2. How We Use Your Information
We use your information to provide and improve our services, process transactions, and communicate with you.

3. Data Security
We implement security measures to protect your personal information.

4. Your Rights
You have the right to access, update, or delete your personal information.

5. Cookies
We use cookies to enhance your experience on our platform.

For any privacy-related questions, please contact us.''';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
