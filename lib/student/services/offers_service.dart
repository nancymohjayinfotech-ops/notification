import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/offer.dart';
import 'api_client.dart';
import 'token_service.dart';
import 'auth_service.dart';

class OffersService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Offer> _offers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Offer> get offers => List.unmodifiable(_offers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get active offers only
  List<Offer> get activeOffers =>
      _offers.where((offer) => offer.isValid).toList();

  // Get offers by discount type
  List<Offer> get percentageOffers =>
      _offers.where((offer) => offer.discountType == 'percentage').toList();
  List<Offer> get fixedOffers =>
      _offers.where((offer) => offer.discountType == 'fixed').toList();

  // Fetch all offers from API
  Future<void> fetchOffers() async {
    debugPrint('🔍 Starting to fetch offers from API...');
    _setLoading(true);
    _clearError();

    try {
      // Try to obtain a valid access token (TokenService handles refresh)
      String? token;
      try {
        token = await TokenService().getAccessToken();
      } catch (e) {
        debugPrint('⚠️ TokenService.getAccessToken error: $e');
        token = null;
      }

      // If there's no token available, set a friendly error and return (do NOT force logout)
      if (token == null || token.isEmpty) {
        debugPrint('❌ No access token available, skipping offers fetch');
        _setError('No access token available');
        return;
      }

      // Build headers with Authorization
      final headers = {'Authorization': 'Bearer $token'};

      debugPrint('🚀 Making API call to: ${ApiConfig.allOffers} (auth=true)');
      // Pass headers via Dio Options (many ApiClient wrappers forward this to Dio)
      final response = await _apiClient.get(
        ApiConfig.allOffers,
        options: Options(headers: headers),
      );

      debugPrint('📥 Offers API response received: ${response.isSuccess}');

      if (response.isSuccess) {
        final responseData = response.data;
        debugPrint('📊 Response data type: ${responseData.runtimeType}');
        debugPrint('📊 Response data: $responseData');

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            final offersData = responseData['data'] as List;
            debugPrint('📊 Raw offers data: $offersData');
            _offers = offersData
                .map((offerJson) => Offer.fromMap(offerJson))
                .toList();
            debugPrint('✅ Loaded ${_offers.length} offers from API');
          } else if (responseData.containsKey('success')) {
            if (responseData['success'] == true) {
              final offersData = responseData['data'] as List? ?? [];
              _offers = offersData
                  .map((offerJson) => Offer.fromMap(offerJson))
                  .toList();
              debugPrint('✅ Loaded ${_offers.length} offers (alt format)');
            } else {
              debugPrint(
                '❌ API returned success=false: ${responseData['message']}',
              );
              _setError(responseData['message'] ?? 'Failed to load offers');
            }
          } else {
            debugPrint(
              '❌ Invalid response format - missing data/success field',
            );
            _setError('Invalid offers response format');
          }
        } else {
          debugPrint(
            '❌ Response data is not a Map: ${responseData.runtimeType}',
          );
          _setError('Invalid offers response type');
        }
      } else {
        debugPrint('❌ API call failed: ${response.error?.message}');
        _setError(response.error?.message ?? 'Failed to fetch offers');
      }
    } catch (e) {
      _setError('Failed to load offers: $e');
      debugPrint('❌ Error fetching offers: $e');

      // Only treat explicit unauthorized/401 as reason to force logout
      final message = e.toString().toLowerCase();
      if (message.contains('401') || message.contains('unauthorized')) {
        try {
          await AuthService().handleUnauthorized();
        } catch (authErr) {
          debugPrint('❌ Error while handling unauthorized: $authErr');
        }
      }
    } finally {
      _setLoading(false);
      debugPrint('🏁 Finished fetching offers');
    }
  }

  // Get a single offer by ID
  Future<Offer?> getOfferById(String offerId) async {
    try {
      final endpoint = ApiConfig.offerById.replaceAll('{id}', offerId);
      final response = await _apiClient.get(endpoint);

      if (response.isSuccess) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return Offer.fromMap(responseData['data']);
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error fetching offer by ID: $e');
      return null;
    }
  }

  // Get offers for a specific course
  Future<List<Offer>> getOffersForCourse(String courseId) async {
    try {
      final endpoint = ApiConfig.offersForCourse.replaceAll(
        '{courseId}',
        courseId,
      );
      final response = await _apiClient.get(endpoint);

      if (response.isSuccess) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final offersData = responseData['data'] as List;
          return offersData
              .map((offerJson) => Offer.fromMap(offerJson))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error fetching offers for course: $e');
      return [];
    }
  }

  // Apply an offer to a course
  Future<Map<String, dynamic>?> applyOffer(
    String offerCode,
    String courseId,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.applyOffer,
        data: {'code': offerCode, 'courseId': courseId},
      );

      if (response.isSuccess) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          debugPrint('✅ Offer applied successfully');
          return responseData['data'];
        }
      } else {
        throw Exception(response.error?.message ?? 'Failed to apply offer');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error applying offer: $e');
      rethrow;
    }
  }

  // Validate a coupon code
  Future<bool> validateCoupon(String couponCode) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.validateCoupon,
        data: {'code': couponCode},
      );

      if (response.isSuccess) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          final data = responseData['data'];
          return data['isValid'] ?? false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error validating coupon: $e');
      return false;
    }
  }

  // Get offers suitable for home page display (limited number)
  List<Offer> getHomePageOffers({int limit = 3}) {
    debugPrint('🏠 getHomePageOffers called - Total offers: ${_offers.length}');
    debugPrint('🏠 Active offers: ${activeOffers.length}');
    debugPrint(
      '🏠 All offers: ${_offers.map((o) => '${o.title} (${o.code}) - Valid: ${o.isValid} - EndDate: ${o.endDate}').join(', ')}',
    );
    final result = activeOffers.take(limit).toList();
    debugPrint('🏠 Returning ${result.length} offers for home page');
    return result;
  }

  // Search offers by title or description
  List<Offer> searchOffers(String query) {
    if (query.isEmpty) return _offers;

    final lowercaseQuery = query.toLowerCase();
    return _offers.where((offer) {
      return offer.title.toLowerCase().contains(lowercaseQuery) ||
          offer.description.toLowerCase().contains(lowercaseQuery) ||
          offer.code.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _offers.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
