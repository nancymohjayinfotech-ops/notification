import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'offers_service.dart';

class OffersApiTest {
  static final ApiClient _apiClient = ApiClient();
  static final OffersService _offersService = OffersService();

  /// Test all offers API endpoints
  static Future<Map<String, dynamic>> runAllOffersTests() async {
    debugPrint('🚀 Starting comprehensive offers API tests...');
    
    final results = <String, dynamic>{
      'getAllOffersTest': await testGetAllOffers(),
      'getOfferByIdTest': await testGetOfferById(),
      'validateCouponTest': await testValidateCoupon(),
      'offersServiceTest': await testOffersService(),
      'summary': {},
    };

    final allTestsResults = [
      results['getAllOffersTest']['success'] as bool,
      results['getOfferByIdTest']['success'] as bool,
      results['validateCouponTest']['success'] as bool,
      results['offersServiceTest']['success'] as bool,
    ];

    final passedTests = allTestsResults.where((test) => test).length;
    final totalTests = allTestsResults.length;

    results['summary'] = {
      'allTestsPassed': passedTests == totalTests,
      'passedTests': passedTests,
      'totalTests': totalTests,
      'successRate': '${(passedTests / totalTests * 100).toStringAsFixed(1)}%',
      'recommendations': _getRecommendations(results),
    };

    debugPrint('🏁 Offers API tests completed: $passedTests/$totalTests passed');
    return results;
  }

  /// Test GET /api/offers (get all offers)
  static Future<Map<String, dynamic>> testGetAllOffers() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing GET /api/offers...');
      debugPrint('🌐 URL: ${ApiConfig.baseUrl}${ApiConfig.allOffers}');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.allOffers,
      );

      debugPrint('📥 Response received: ${response.isSuccess}');
      debugPrint('📊 Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        if (data['success'] == true) {
          final offers = data['data'] as List<dynamic>?;
          result['success'] = true;
          result['message'] = 'Successfully fetched ${offers?.length ?? 0} offers';
          result['details'] = {
            'offersCount': offers?.length ?? 0,
            'responseStructure': data.keys.toList(),
            'sampleOffer': offers?.isNotEmpty == true ? offers!.first : null,
            'allOffers': offers?.map((o) => {
              'id': o['_id'],
              'title': o['title'],
              'code': o['code'],
              'isActive': o['isActive'],
              'discountType': o['discountType'],
              'discountValue': o['discountValue'],
            }).toList(),
          };
          debugPrint('✅ Get all offers test passed');
        } else {
          result['message'] = 'API returned success=false: ${data['message']}';
          result['details'] = data;
          debugPrint('❌ Get all offers test failed: API returned success=false');
        }
      } else {
        result['message'] = 'API request failed: ${response.error?.message}';
        result['details'] = {
          'error': response.error?.message,
          'errorType': response.error?.type.toString(),
        };
        debugPrint('❌ Get all offers test failed: API request failed');
      }
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Get all offers test failed: Exception - $e');
    }

    return result;
  }

  /// Test GET /api/offers/:id (get offer by ID)
  static Future<Map<String, dynamic>> testGetOfferById() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing GET /api/offers/:id...');
      
      // First get all offers to find a valid ID
      final allOffersResult = await testGetAllOffers();
      if (!allOffersResult['success']) {
        result['message'] = 'Cannot test offer by ID: getAllOffers failed';
        result['details'] = allOffersResult;
        return result;
      }

      final sampleOffer = allOffersResult['details']['sampleOffer'];
      if (sampleOffer == null) {
        result['message'] = 'No offers available to test offer by ID';
        result['details'] = {'note': 'Database might be empty'};
        return result;
      }

      // Try to get offer by ID using the service
      final offerId = sampleOffer['_id'] ?? sampleOffer['id'];
      if (offerId == null) {
        result['message'] = 'No valid offer ID found in sample offer';
        result['details'] = {'sampleOffer': sampleOffer};
        return result;
      }

      final offer = await _offersService.getOfferById(offerId.toString());
      
      if (offer != null) {
        result['success'] = true;
        result['message'] = 'Successfully fetched offer by ID';
        result['details'] = {
          'offerId': offerId,
          'offerTitle': offer.title,
          'offerCode': offer.code,
          'isActive': offer.isActive,
        };
        debugPrint('✅ Get offer by ID test passed');
      } else {
        result['message'] = 'Offer by ID returned null';
        result['details'] = {'offerId': offerId};
        debugPrint('❌ Get offer by ID test failed: returned null');
      }
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Get offer by ID test failed: Exception - $e');
    }

    return result;
  }

  /// Test validate coupon functionality
  static Future<Map<String, dynamic>> testValidateCoupon() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing validate coupon...');
      
      // Test with invalid coupon first
      final invalidResult = await _offersService.validateCoupon('INVALID123');
      
      // Test with valid coupon if we have offers
      final allOffersResult = await testGetAllOffers();
      String? validCoupon;
      
      if (allOffersResult['success']) {
        final offers = allOffersResult['details']['allOffers'] as List<dynamic>?;
        if (offers?.isNotEmpty == true) {
          validCoupon = offers!.first['code'];
        }
      }

      result['success'] = true;
      result['message'] = 'Coupon validation test completed';
      result['details'] = {
        'invalidCouponResult': invalidResult,
        'validCoupon': validCoupon,
        'validCouponResult': validCoupon != null 
            ? await _offersService.validateCoupon(validCoupon) 
            : 'No valid coupons to test',
      };
      debugPrint('✅ Validate coupon test passed');
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ Validate coupon test failed: Exception - $e');
    }

    return result;
  }

  /// Test OffersService functionality
  static Future<Map<String, dynamic>> testOffersService() async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'details': {},
    };

    try {
      debugPrint('🔍 Testing OffersService...');
      
      // Test fetchOffers method
      await _offersService.fetchOffers();
      
      final offers = _offersService.offers;
      final activeOffers = _offersService.activeOffers;
      final homePageOffers = _offersService.getHomePageOffers();
      
      result['success'] = true;
      result['message'] = 'OffersService test completed';
      result['details'] = {
        'totalOffers': offers.length,
        'activeOffers': activeOffers.length,
        'homePageOffers': homePageOffers.length,
        'isLoading': _offersService.isLoading,
        'errorMessage': _offersService.errorMessage,
        'sampleOffers': offers.take(3).map((o) => {
          'title': o.title,
          'code': o.code,
          'isValid': o.isValid,
          'discountText': o.discountText,
        }).toList(),
      };
      debugPrint('✅ OffersService test passed');
    } catch (e) {
      result['message'] = 'Exception occurred: ${e.toString()}';
      result['details'] = {
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
      debugPrint('❌ OffersService test failed: Exception - $e');
    }

    return result;
  }

  static List<String> _getRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    final getAllSuccess = results['getAllOffersTest']['success'] as bool;
    final getByIdSuccess = results['getOfferByIdTest']['success'] as bool;
    final validateSuccess = results['validateCouponTest']['success'] as bool;
    final serviceSuccess = results['offersServiceTest']['success'] as bool;

    if (!getAllSuccess) {
      recommendations.addAll([
        'Check if backend server is running on port 5000',
        'Verify offers route is configured in backend',
        'Check if MongoDB has offer data',
        'Verify API base URL is correct for your platform',
        'Add some test offers to your database',
      ]);
    }

    if (getAllSuccess && !getByIdSuccess) {
      recommendations.addAll([
        'Check offer ID format in database',
        'Verify getOfferById route is working',
      ]);
    }

    if (getAllSuccess && !serviceSuccess) {
      recommendations.addAll([
        'Check OffersService implementation',
        'Verify data parsing in Offer.fromMap method',
        'Check for any provider initialization issues',
      ]);
    }

    if (getAllSuccess && serviceSuccess) {
      final offersCount = results['offersServiceTest']['details']['totalOffers'] as int;
      if (offersCount == 0) {
        recommendations.addAll([
          'Database has no offers - add some test offers',
          'Check if offers are marked as active in database',
          'Verify offer dates are valid (not expired)',
        ]);
      } else {
        recommendations.add('All offers API tests passed! The offers API is working correctly.');
      }
    }

    return recommendations;
  }
}
