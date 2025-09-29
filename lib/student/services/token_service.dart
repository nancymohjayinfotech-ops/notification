import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _userPhone;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  String? get userPhone => _userPhone;

  bool get hasValidToken {
    if (_accessToken == null || _tokenExpiry == null) return false;
    
    // Add a buffer of 5 minutes to avoid using tokens that are about to expire
    final bufferTime = const Duration(minutes: 5);
    final validUntil = _tokenExpiry!.subtract(bufferTime);
    
    return DateTime.now().isBefore(validUntil);
  }

  bool get isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  // Initialize token service - call this on app startup
  Future<void> initialize() async {
    try {
      await _loadTokensFromStorage();
      await debugStorageContents(); // Add this line to debug storage contents
      debugPrint('TokenService initialized. Has valid token: $hasValidToken');
    } catch (e) {
      debugPrint('Error initializing TokenService: $e');
    }
  }

  // Debug method to check storage contents
  Future<void> debugStorageContents() async {
    try {
      debugPrint('=== Secure Storage Contents ===');
      final allValues = await _secureStorage.readAll();
      
      if (allValues.isEmpty) {
        debugPrint('Storage is EMPTY - no values found');
        return;
      }
      
      allValues.forEach((key, value) {
        debugPrint('$key: ${value.isNotEmpty ? "✓ (length: ${value.length})" : "EMPTY"}');
      });
      debugPrint('================================');
    } catch (e) {
      debugPrint('❌ Error reading storage contents: $e');
    }
  }

  // Save tokens after successful authentication
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
    DateTime? expiresAt,
    String? phoneNumber,
  }) async {
    try {
      // Validate input
      if (accessToken.isEmpty) {
        throw Exception('Access token cannot be empty');
      }
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number cannot be empty');
      }

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _userPhone = phoneNumber;

      // Calculate expiry from backend response or fallback to provided expiresAt
      if (expiresInSeconds != null) {
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));
      } else if (expiresAt != null) {
        _tokenExpiry = expiresAt;
      } else {
        // Fallback to 15 minutes if no expiry info provided
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 15));
      }

      debugPrint('💾 Attempting to save tokens:');
      debugPrint('   Access Token: ${accessToken.substring(0, min(20, accessToken.length))}...');
      debugPrint('   Refresh Token: ${refreshToken != null ? "${refreshToken.substring(0, min(20, refreshToken.length))}..." : "null"}');
      debugPrint('   Expiry: ${_tokenExpiry?.toIso8601String()}');
      debugPrint('   Phone: $phoneNumber');

      // Save each value individually with error handling
      try {
        await _secureStorage.write(key: ApiConfig.accessTokenKey, value: accessToken);
        debugPrint('   ✓ Access token saved');
      } catch (e) {
        debugPrint('   ❌ Failed to save access token: $e');
        rethrow;
      }

      try {
        await _secureStorage.write(
          key: ApiConfig.tokenExpiryKey,
          value: _tokenExpiry!.toIso8601String(),
        );
        debugPrint('   ✓ Token expiry saved');
      } catch (e) {
        debugPrint('   ❌ Failed to save token expiry: $e');
        rethrow;
      }

      try {
        await _secureStorage.write(key: ApiConfig.userPhoneKey, value: phoneNumber);
        debugPrint('   ✓ User phone saved');
      } catch (e) {
        debugPrint('   ❌ Failed to save user phone: $e');
        rethrow;
      }

      if (refreshToken != null) {
        try {
          await _secureStorage.write(
            key: ApiConfig.refreshTokenKey,
            value: refreshToken,
          );
          debugPrint('   ✓ Refresh token saved');
        } catch (e) {
          debugPrint('   ❌ Failed to save refresh token: $e');
          rethrow;
        }
      }

      debugPrint('✅ All tokens saved successfully');

    } catch (e) {
      debugPrint('❌ CRITICAL ERROR saving tokens: $e');
      // Don't throw here - just log so we can see what happened
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Load tokens from secure storage
  Future<void> _loadTokensFromStorage() async {
    try {
      final results = await Future.wait([
        _secureStorage.read(key: ApiConfig.accessTokenKey),
        _secureStorage.read(key: ApiConfig.tokenExpiryKey),
        _secureStorage.read(key: ApiConfig.userPhoneKey),
        _secureStorage.read(key: ApiConfig.refreshTokenKey),
      ]);

      _accessToken = results[0];
      _userPhone = results[2];
      _refreshToken = results[3];

      if (results[1] != null) {
        _tokenExpiry = DateTime.parse(results[1]!);
      }

      // Add debug logging
      debugPrint('Loaded tokens from storage:');
      debugPrint('Access Token: ${_accessToken != null ? "exists" : "null"}');
      debugPrint('Refresh Token: ${_refreshToken != null ? "exists" : "null"}');
      debugPrint('Token Expiry: ${_tokenExpiry?.toIso8601String()}');
      debugPrint('Current Time: ${DateTime.now().toIso8601String()}');
      debugPrint('User Phone: $_userPhone');
      debugPrint('Is expired: $isTokenExpired');
      debugPrint('Has valid token: $hasValidToken');
      debugPrint('Time until expiry: ${_tokenExpiry != null ? _tokenExpiry!.difference(DateTime.now()).inMinutes : "N/A"} minutes');

    } catch (e) {
      debugPrint('Error loading tokens from storage: $e');
      await clearTokens(); // Clear corrupted data
    }
  }

  // Clear all tokens (logout)
  Future<void> clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _userPhone = null;

      await Future.wait([
        _secureStorage.delete(key: ApiConfig.accessTokenKey),
        _secureStorage.delete(key: ApiConfig.refreshTokenKey),
        _secureStorage.delete(key: ApiConfig.tokenExpiryKey),
        _secureStorage.delete(key: ApiConfig.userPhoneKey),
      ]);

      debugPrint('All tokens cleared');
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  // Get authorization header
  Future<Map<String, String>> getAuthHeaders() async {
    // Ensure tokens are loaded from storage
    if (_accessToken == null) {
      await _loadTokensFromStorage();
    }
    
    if (_accessToken == null) {
      debugPrint('❌ No access token available for API request');
      return {};
    }
    
    debugPrint('✅ Adding Bearer token to request headers');
    return {'Authorization': 'Bearer $_accessToken'};
  }

  // Check if user is authenticated
  bool get isAuthenticated => hasValidToken;

  // Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      debugPrint('❌ No refresh token available');
      return false;
    }
    try {
      debugPrint('🔄 Refreshing access token...');

      final dio = Dio();
      final response = await dio.post(
        ApiConfig.refreshToken,
        data: {'refreshToken': _refreshToken},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken']; // If provided
        final expiresIn = data['expiresIn']; // If provided

        // Update tokens
        _accessToken = newAccessToken;
        if (newRefreshToken != null) {
          _refreshToken = newRefreshToken;
        }

        // Calculate expiry - prefer expiresIn from backend
        if (expiresIn != null) {
          _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        } else {
          _tokenExpiry = DateTime.now().add(const Duration(minutes: 15));
        }

        // Save updated tokens
        final saveFutures = [
          _secureStorage.write(
            key: ApiConfig.accessTokenKey,
            value: newAccessToken,
          ),
          _secureStorage.write(
            key: ApiConfig.tokenExpiryKey,
            value: _tokenExpiry!.toIso8601String(),
          ),
        ];

        if (newRefreshToken != null) {
          saveFutures.add(
            _secureStorage.write(
              key: ApiConfig.refreshTokenKey,
              value: newRefreshToken,
            ),
          );
        }

        await Future.wait(saveFutures);

        debugPrint('✅ Access token refreshed successfully');
        debugPrint('New Access Token: ${newAccessToken != null ? "exists" : "null"}');
        debugPrint('New Token Expiry: ${_tokenExpiry?.toIso8601String()}');
        debugPrint('New Refresh Token: ${newRefreshToken != null ? "exists" : "unchanged"}');
        
        return true;
      } else {
        debugPrint('❌ Token refresh failed: ${response.data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
      return false;
    }
  }

  // Get token info for debugging
  Map<String, dynamic> getTokenInfo() {
    return {
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      'tokenExpiry': _tokenExpiry?.toIso8601String(),
      'isExpired': isTokenExpired,
      'hasValidToken': hasValidToken,
      'userPhone': _userPhone,
      'timeUntilExpiry': _tokenExpiry != null 
          ? '${_tokenExpiry!.difference(DateTime.now()).inMinutes} minutes'
          : 'N/A',
    };
  }

  // Get access token (tries in-memory, loads from storage, refreshes if expired)
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    // If we already have a valid token in memory and not forcing refresh, return it
    if (!forceRefresh && _accessToken != null && hasValidToken) {
      debugPrint('Using cached valid access token');
      return _accessToken;
    }

    // Ensure we have latest values from secure storage
    await _loadTokensFromStorage();

    // If token is valid after loading, return it
    if (!forceRefresh && _accessToken != null && hasValidToken) {
      debugPrint('Using valid access token from storage');
      return _accessToken;
    }

    // If token expired and we have a refresh token, attempt to refresh
    if ((isTokenExpired || forceRefresh) && _refreshToken != null) {
      debugPrint('Token expired or force refresh requested. Attempting refresh...');
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        debugPrint('Refresh successful, returning new access token');
        return _accessToken;
      } else {
        debugPrint('Refresh failed, returning null');
        return null;
      }
    }

    // Return whatever is available (may be null)
    debugPrint('No valid token available. Returning: ${_accessToken != null ? "expired token" : "null"}');
    return _accessToken;
  }

  // Verification status methods
  Future<void> setVerificationStatus(bool isVerified) async {
    try {
      await _secureStorage.write(
        key: 'verification_status',
        value: isVerified.toString(),
      );
      debugPrint('✅ Verification status saved: $isVerified');
    } catch (e) {
      debugPrint('❌ Error saving verification status: $e');
    }
  }

  Future<bool> getVerificationStatus() async {
    try {
      final status = await _secureStorage.read(key: 'verification_status');
      final isVerified = status == 'true';
      debugPrint('📋 Retrieved verification status: $isVerified');
      return isVerified;
    } catch (e) {
      debugPrint('❌ Error reading verification status: $e');
      return false; // Default to false if error
    }
  }

  // Helper function to avoid substring errors
  int min(int a, int b) => a < b ? a : b;
}