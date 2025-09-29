import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ConnectivityTest {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  /// Test basic connectivity to the backend server
  static Future<Map<String, dynamic>> testBackendConnectivity() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing backend connectivity...');
      debugPrint('🌐 Testing URL: ${ApiConfig.baseUrl}');

      // Test basic connectivity with a simple GET request
      final response = await _dio.get(
        '${ApiConfig.baseUrl.replaceAll('/api', '')}/', // Remove /api and test root
        options: Options(
          // Timeouts are now set on Dio instance, not in Options
        ),
      );

      if (response.statusCode == 200) {
        result['success'] = true;
        result['message'] = 'Backend server is reachable';
        result['details'] = {
          'statusCode': response.statusCode,
          'responseData': response.data,
        };
        debugPrint('✅ Backend connectivity test passed');
      } else {
        result['message'] = 'Backend returned status: ${response.statusCode}';
        result['details'] = {
          'statusCode': response.statusCode,
          'responseData': response.data,
        };
        debugPrint(
          '⚠️ Backend returned non-200 status: ${response.statusCode}',
        );
      }
    } catch (e) {
      result['message'] = 'Failed to connect to backend: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Backend connectivity test failed: $e');
    }

    return result;
  }

  /// Test specific OTP endpoint
  static Future<Map<String, dynamic>> testOtpEndpoint() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing OTP endpoint...');
      debugPrint('🌐 Testing URL: ${ApiConfig.baseUrl}${ApiConfig.sendOtp}');

      // Test with invalid data to see if endpoint exists
      final response = await _dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.sendOtp}',
        data: {}, // Empty data should return validation error
        options: Options(
          // Timeouts are now set on Dio instance, not in Options
        ),
      );

      result['success'] = true;
      result['message'] = 'OTP endpoint is reachable';
      result['details'] = {
        'statusCode': response.statusCode,
        'responseData': response.data,
      };
      debugPrint('✅ OTP endpoint test passed');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // 400 is expected for empty data - means endpoint exists
        result['success'] = true;
        result['message'] =
            'OTP endpoint exists (returned validation error as expected)';
        result['details'] = {
          'statusCode': e.response?.statusCode,
          'responseData': e.response?.data,
        };
        debugPrint('✅ OTP endpoint exists (validation error expected)');
      } else {
        result['message'] = 'OTP endpoint error: ${e.message}';
        result['details'] = {
          'statusCode': e.response?.statusCode,
          'error': e.message,
          'responseData': e.response?.data,
        };
        debugPrint('❌ OTP endpoint test failed: ${e.message}');
      }
    } catch (e) {
      result['message'] = 'Failed to reach OTP endpoint: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ OTP endpoint test failed: $e');
    }

    return result;
  }

  /// Run all connectivity tests
  static Future<Map<String, dynamic>> runAllTests() async {
    debugPrint('🚀 Starting comprehensive connectivity tests...');

    final results = <String, dynamic>{
      'backendTest': await testBackendConnectivity(),
      'otpEndpointTest': await testOtpEndpoint(),
      'summary': {},
    };

    final backendSuccess = results['backendTest']['success'] as bool;
    final otpSuccess = results['otpEndpointTest']['success'] as bool;

    results['summary'] = {
      'allTestsPassed': backendSuccess && otpSuccess,
      'backendReachable': backendSuccess,
      'otpEndpointReachable': otpSuccess,
      'recommendations': _getRecommendations(backendSuccess, otpSuccess),
    };

    debugPrint('🏁 Connectivity tests completed');
    return results;
  }

  static List<String> _getRecommendations(
    bool backendSuccess,
    bool otpSuccess,
  ) {
    final recommendations = <String>[];

    if (!backendSuccess) {
      recommendations.addAll([
        'Check if the backend server is running (npm run dev)',
        'Verify the API base URL in ApiConfig matches your setup',
        'If using physical device, use your computer\'s IP address',
        'Check firewall settings on your computer',
        'Ensure MongoDB is connected',
      ]);
    }

    if (backendSuccess && !otpSuccess) {
      recommendations.addAll([
        'Check if auth routes are properly configured',
        'Verify the OTP endpoint exists in your backend',
        'Check for any middleware blocking the request',
      ]);
    }

    if (backendSuccess && otpSuccess) {
      recommendations.add(
        'All connectivity tests passed! The issue might be with request data or validation.',
      );
    }

    return recommendations;
  }
}
