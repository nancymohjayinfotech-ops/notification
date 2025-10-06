import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fluttertest/student/screens/auth/UserProfileForm.dart';
import 'package:fluttertest/instructor/pages/instructor_dashboard.dart';
import 'package:fluttertest/student/screens/categories/InterestBasedPage.dart';
import 'package:fluttertest/student/screens/auth/app_restart_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart' as app_models;
import '../models/user_role.dart';
import 'api_client.dart';
import 'token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'token_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final TokenService _tokenService = TokenService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Authentication state
  bool _isAuthenticated = false;
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // OTP state
  String? _pendingPhoneNumber;
  String? _otpSessionId;
  Timer? _otpTimer;
  int _otpTimeRemaining = 0;
  String _lastRole = 'student';
  String? _tempGoogleIdToken; // Store Google ID token until phone verification

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingPhoneNumber => _pendingPhoneNumber;
  bool get hasOtpSession => _otpSessionId != null;
  int get otpTimeRemaining => _otpTimeRemaining;
  bool get canResendOtp => _otpTimeRemaining == 0;

  bool get needsPhoneVerification {
    return _currentUser?.phoneNumber == null ||
        _currentUser!.phoneNumber!.isEmpty;
  }

  // Initialize auth service
  Future<void> initialize() async {
    try {
      await _tokenService.initialize();

      // Check if user is already signed in with Firebase
      User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        _isAuthenticated = true;
        // Create user object from Firebase user with null-safe defaults
        _currentUser = app_models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '', // Fixed: Handle null email
          name:
              firebaseUser.displayName ??
              'User', // Fixed: Handle null displayName
          phoneNumber:
              firebaseUser.phoneNumber ?? '', // Fixed: Handle null phoneNumber
          avatar: firebaseUser.photoURL ?? '', // Fixed: Handle null photoURL
          role: UserRole.student, // Default role
          isVerified: firebaseUser.emailVerified,
          joinDate: DateTime.now(),
        );
      } else if (_tokenService.isAuthenticated) {
        await loadCurrentUser();
        _isAuthenticated = _tokenService.hasValidToken;
      }

      notifyListeners();
    } catch (e) {}
  }

  // Firebase Google Sign-In (Simplified)
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _lastRole = role.value;

      // Create user with email and password
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        _setError('Failed to create user account');
        return false;
      }

      // Update user profile with display name
      await userCredential.user!.updateDisplayName(name);
      await userCredential.user!.reload();

      // Create user object
      _currentUser = app_models.User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phoneNumber: '',
        avatar: '',
        role: role,
        isVerified: userCredential.user!.emailVerified,
        joinDate: DateTime.now(),
      );

      // Get ID token
      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) {
        _setError('Failed to get ID token');
        return false;
      }

      // Save tokens
      await _tokenService.saveTokens(
        accessToken: idToken,
        refreshToken: userCredential.user!.refreshToken,
        expiresInSeconds: 3600,
        phoneNumber: '',
      );

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

 Future<bool> signInWithGoogle({String role = 'student'}) async {
  try {
    _setLoading(true);
    _clearError();
    _lastRole = role;

    GoogleSignInAccount? googleUser;
    User? firebaseUser;

    // Platform-specific Google Sign-In configuration
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>['email', 'profile'],
    );

    // Force account selection by signing out first
    await googleSignIn.signOut();

    googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      _setError('Google sign-in was cancelled');
      return false;
    }

    print('✅ Google user obtained: ${googleUser.email}');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    print('🔑 Google auth tokens received');
    debugPrint('   Access Token: ${googleAuth.accessToken?.substring(0, 50)}...');
    debugPrint('   ID Token: ${googleAuth.idToken?.substring(0, 50)}...');

    // Create Firebase credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      return false;
    }

    print('✅ Firebase authentication successful:');
    print('   User ID: ${firebaseUser.uid}');
    print('   Email: ${firebaseUser.email}');
    print('   Name: ${firebaseUser.displayName}');

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      _setError('Failed to get Google ID token');
      return false;
    }

    final backendResponse = await _verifyWithBackend(idToken, role);

    if (!backendResponse['success']) {
      _setError(backendResponse['message'] ?? 'Backend verification failed');
      await _signOutFromGoogle();
      return false;
    }

    // Backend verification successful - create user object
    _currentUser = app_models.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'User',
      phoneNumber: firebaseUser.phoneNumber ?? '',
      avatar: firebaseUser.photoURL ?? '',
      role: _parseUserRole(role),
      isVerified: firebaseUser.emailVerified,
      joinDate: DateTime.now(),
    );

    _isAuthenticated = true;

    // Save tokens after successful backend verification
    await _tokenService.saveTokens(
      accessToken: backendResponse['access_token'] ?? idToken,
      refreshToken: backendResponse['refresh_token'] ?? '',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    notifyListeners();
    return true;
  } catch (e) {
    String errorMessage = 'Failed to sign in with Google. Please try again.';

    // Handle specific errors
    if (e is PlatformException) {
      switch (e.code) {
        case 'sign_in_canceled':
          errorMessage = 'Google sign-in was cancelled';
          break;
        case 'sign_in_failed':
          errorMessage = 'Google sign-in failed. Please try again.';
          break;
        case 'network_error':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        case 'INVALID_CREDENTIAL':
          errorMessage = 'Invalid Google configuration. Please contact support.';
          break;
        default:
          errorMessage = 'Authentication failed. Please try again.';
      }
    } else if (e is FirebaseAuthException) {
      errorMessage = _getFirebaseAuthErrorMessage(e);
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
    }

    print('💥 Google Sign-In error: $e');
    _setError(errorMessage);

    // Clean up
    try {
      await _signOutFromGoogle();
    } catch (signOutError) {
      print('💥 Error during sign out cleanup: $signOutError');
    }

    return false;
  } finally {
    _setLoading(false);
  }
}

String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'invalid-verification-code':
      return 'Invalid Google token. Please try again.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with the same email address.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    default:
      return 'Authentication failed. Please try again.';
  }
}
  // Helper method to verify with backend API
  Future<Map<String, dynamic>> _verifyWithBackend(
    String idToken,
    String role,
  ) async {
    try {
      final url = Uri.parse(
        'http://54.82.53.11:5001/api/auth/google-login',
      );

      print('📤 Sending backend verification request:');
      print('   URL: $url');
      print('   Role: $role');
      print('   ID Token length: ${idToken.length}');

      final requestBody = {'idToken': idToken, 'role': role};

      print('   Request Body: $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Backend response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Backend verification successful');
        print(
          '   Access Token: ${responseData['access_token'] != null ? 'PRESENT' : 'MISSING'}',
        );
        print(
          '   Refresh Token: ${responseData['refresh_token'] != null ? 'PRESENT' : 'MISSING'}',
        );
        print(
          '   User Data: ${responseData['user'] != null ? 'PRESENT' : 'MISSING'}',
        );

        return {
          'success': true,
          'access_token': responseData['access_token'],
          'refresh_token': responseData['refresh_token'],
          'user': responseData['user'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        print(
          '❌ Backend verification failed with status: ${response.statusCode}',
        );
        print('   Error Message: ${errorData['message']}');

        return {
          'success': false,
          'message': errorData['message'] ?? 'Backend verification failed',
        };
      }
    } catch (e) {
      print('💥 Backend verification error: $e');
      debugPrint('Backend verification error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to authentication server',
      };
    }
  }

  // Sign out from Google and Firebase
  Future<void> _signOutFromGoogle() async {
    try {
      print('🚪 Starting Google/Firebase sign out...');
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      print('✅ Signed out from Google');

      // Sign out from Firebase
      await _firebaseAuth.signOut();
      print('✅ Signed out from Firebase');

      // Clear local tokens
      await _tokenService.clearTokens();
      print('✅ Local tokens cleared');

      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
      print('✅ Auth state reset and listeners notified');
    } catch (e) {
      print('💥 Error during sign out: $e');
      debugPrint('Error during sign out: $e');
    }
  }

  // Send OTP to phone number (kept for phone auth if needed)
  Future<String?> sendOtp(String phoneNumber, {String role = 'student'}) async {
    try {
      print('🔄 Starting OTP sending process');
      print('📱 Phone number: $phoneNumber');
      print('🎯 Role: $role');
      _setLoading(true);
      _clearError();

      if (!_isValidPhoneNumber(phoneNumber)) {
        _setError('Please enter a valid phone number');
        return null;
      }

      _lastRole = role;

      final requestData = {'phoneNumber': phoneNumber, 'role': role};
      print('📤 Sending OTP request to backend:');
      print('   Endpoint: ${ApiConfig.sendOtp}');
      print('   Data: $requestData');

      final response = await _apiClient.post(
        ApiConfig.sendOtp,
        data: requestData,
      );

      if (response.isSuccess) {
        print('✅ OTP sent successfully');
        print('📊 Response data: ${response.data}');

        _pendingPhoneNumber = phoneNumber;
        _otpSessionId = response.data['sessionId'] ?? 'temp_session';
        _startOtpTimer();

        final otp = response.data['data']?['otp']?.toString();
        debugPrint('OTP sent successfully to $phoneNumber, OTP: $otp');
        print('🔢 OTP code: $otp');
        return otp;
      } else {
        print('❌ OTP sending failed: ${response.error?.message}');
        _setError(response.error?.message ?? 'Failed to send OTP');
        return null;
      }
    } catch (e) {
      print('💥 Send OTP error: $e');
      _setError('Failed to send OTP. Please try again.');
      debugPrint('Send OTP error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP (kept for phone auth if needed)
  Future<bool> verifyOtp(String otp) async {
    try {
      print('🔄 Starting OTP verification process');
      print('🔢 OTP entered: $otp');
      print('📱 Pending phone: $_pendingPhoneNumber');
      _setLoading(true);
      _clearError();

      if (_pendingPhoneNumber == null || _pendingPhoneNumber!.isEmpty) {
        _setError('No phone found for OTP. Please request a new OTP.');
        return false;
      }

      if (otp.length != ApiConfig.otpLength) {
        _setError('Please enter a valid ${ApiConfig.otpLength}-digit OTP');
        return false;
      }

      final requestData = {'phoneNumber': _pendingPhoneNumber, 'otp': otp};
      print('📤 Sending OTP verification to backend:');
      print('   Endpoint: ${ApiConfig.verifyOtp}');
      print('   Data: $requestData');

      final response = await _apiClient.post(
        ApiConfig.verifyOtp,
        data: requestData,
      );

      if (response.isSuccess) {
        print('✅ OTP verification successful');
        print('📊 Full response: ${response.data}');

        final responseData = response.data;
        final data = responseData is Map<String, dynamic>
            ? (responseData['data'] as Map<String, dynamic>?) ?? {}
            : {};

        final accessToken =
            data['accessToken'] ?? data['access_token'] ?? data['token'] ?? '';
        final refreshToken = data['refreshToken'] ?? data['refresh_token'];
        final expiresIn = data['expiresIn'] ?? data['expires_in'];
        final phoneNumber = _pendingPhoneNumber!;

        print('🔑 Tokens received:');
        print(
          '   Access Token: ${accessToken.isNotEmpty ? accessToken.substring(0, 50) + "..." : "NOT FOUND"}',
        );
        print(
          '   Refresh Token: ${refreshToken != null ? "PRESENT" : "NOT FOUND"}',
        );
        print('   Expires In: $expiresIn');
        print(
          '   Temp Google Token: ${_tempGoogleIdToken != null ? "PRESENT" : "NOT FOUND"}',
        );

        if (accessToken.isNotEmpty || _tempGoogleIdToken != null) {
          // Use Google ID token if available (for Google Sign-In users), otherwise use phone auth token
          final finalAccessToken = _tempGoogleIdToken ?? accessToken;

          print('💾 Saving tokens to local storage...');
          await _tokenService.saveTokens(
            accessToken: finalAccessToken,
            refreshToken: refreshToken?.toString(),
            expiresInSeconds: expiresIn is int
                ? expiresIn
                : (expiresIn is String ? int.tryParse(expiresIn) : null),
            phoneNumber: phoneNumber,
          );

          // Clear temporary Google token after saving
          _tempGoogleIdToken = null;
          print('✅ Tokens saved successfully');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', _lastRole);
          print('💾 Role saved to SharedPreferences: $_lastRole');

          try {
            if (data['user'] != null) {
              print('👤 Parsing user data from response...');
              _currentUser = app_models.User.fromMap(data['user']);
              print('✅ User data parsed: ${_currentUser?.name}');
            } else {
              print('👤 Loading user data from profile API...');
              await loadCurrentUser();
            }
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            print('💥 Error parsing user data: $e');
          }

          _isAuthenticated = true;
          _clearOtpSession();

          print('✅ Authentication completed successfully');
          notifyListeners();

          // Register device token with backend now that JWT is saved
          print('📱 Registering device token with backend...');
          try {
            await registerDeviceTokenWithBackend(
              role: _lastRole,
              userId: _currentUser?.id,
            );
            print("✅ Device token registered successfully");
          } catch (e) {
            debugPrint(
              'registerDeviceTokenWithBackend after verifyOtp failed: $e',
            );
            print('💥 Device token registration failed: $e');
          }

          return true;
        } else {
          print('❌ No valid token received in response');
          _setError('Authentication failed: No valid token received');
          return false;
        }
      } else {
        print('❌ OTP verification failed: ${response.error?.message}');
        _setError(response.error?.message ?? 'Invalid OTP. Please try again.');
        return false;
      }
    } catch (e) {
      print('💥 Verify OTP error: $e');
      _setError('Failed to verify OTP. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerDeviceTokenWithBackend({
    String? role,
    String? userId,
  }) async {
    final tokenService = TokenService();
    try {
      print('📱 Starting device token registration...');
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ No FCM token found, skipping device registration');
        debugPrint(
          'registerDeviceTokenWithBackend: no fcm token found, skipping.',
        );
        return;
      }

      print('🔑 FCM Token obtained: ${fcmToken.substring(0, 50)}...');

      final prefs = await SharedPreferences.getInstance();
      // Adjust these keys if TokenService uses different names
      final jwt = tokenService.accessToken;

      print('🔐 JWT present: ${jwt != null && jwt.isNotEmpty}');
      if (jwt != null) {
        print('   JWT: ${jwt.substring(0, 50)}...');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      };

      final body = <String, dynamic>{
        'deviceId': fcmToken,
        "platform": "android",
        "token": fcmToken,
      };
      if (role != null) body['role'] = role;
      if (userId != null) body['userId'] = userId;

      final url = Uri.parse(
        'https://latest-backend-j9au.onrender.com/api/device-tokens/register',
      );

      print('📤 Sending device token to backend:');
      print('   URL: $url');
      print('   Headers: $headers');
      print('   Body: $body');

      final resp = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Device token registration response:');
      print('   Status Code: ${resp.statusCode}');
      print('   Response Body: ${resp.body}');

      debugPrint(
        'registerDeviceTokenWithBackend: response ${resp.statusCode} ${resp.body}',
      );
    } catch (e) {
      print('💥 Device token registration error: $e');
      debugPrint('registerDeviceTokenWithBackend error: $e');
    }
  }

  /// Unregister the current device token (call on logout).
  Future<void> unregisterDeviceTokenFromBackend() async {
    try {
      print('📱 Starting device token unregistration...');
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ No FCM token found, skipping unregistration');
        debugPrint(
          'unregisterDeviceTokenFromBackend: no fcm token found, skipping.',
        );
        return;
      }

      print('🔑 FCM Token to unregister: ${fcmToken.substring(0, 50)}...');

      final prefs = await SharedPreferences.getInstance();
      final jwt =
          prefs.getString('access_token') ??
          prefs.getString('auth_token') ??
          prefs.getString('accessToken') ??
          '';

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (jwt.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwt';
        print('🔐 JWT found for authorization');
      } else {
        print('⚠️ No JWT found for authorization');
      }

      final url = Uri.parse('https://latest-backend-j9au.onrender.com/api/device-tokens/');

      final requestBody = {'deviceToken': fcmToken};
      print('📤 Sending device token unregistration:');
      print('   URL: $url');
      print('   Headers: $headers');
      print('   Body: $requestBody');

      final resp = await http.delete(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📥 Device token unregistration response:');
      print('   Status Code: ${resp.statusCode}');
      print('   Response Body: ${resp.body}');

      debugPrint(
        'unregisterDeviceTokenFromBackend: response ${resp.statusCode} ${resp.body}',
      );
    } catch (e) {
      print('💥 Device token unregistration error: $e');
      debugPrint('unregisterDeviceTokenFromBackend error: $e');
    }
  }

  // Resend OTP
  Future<bool> resendOtp() async {
    if (_pendingPhoneNumber == null) {
      _setError('No phone number found. Please start over.');
      return false;
    }

    if (!canResendOtp) {
      _setError('Please wait before requesting a new OTP');
      return false;
    }

    print('🔄 Resending OTP to $_pendingPhoneNumber');
    final otp = await sendOtp(_pendingPhoneNumber!, role: _lastRole);
    return otp != null;
  }

  // Load current user profile
  Future<void> loadCurrentUser() async {
    try {
      print('🔄 Loading user profile from API...');
      final response = await _apiClient.get(ApiConfig.profile);

      if (response.isSuccess) {
        print('✅ Profile API response successful');
        print('📄 Response data: ${response.data}');

        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is Map<String, dynamic>) {
            final data = responseData['data'] as Map<String, dynamic>;
            if (data.containsKey('user')) {
              _currentUser = app_models.User.fromMap(data['user']);
              print('👤 User loaded from data.user: ${_currentUser?.name}');
            }
          } else if (responseData.containsKey('user')) {
            _currentUser = app_models.User.fromMap(responseData['user']);
            print('👤 User loaded from user: ${_currentUser?.name}');
          } else {
            _currentUser = app_models.User.fromMap(response.data);
            print('👤 User loaded from root: ${_currentUser?.name}');
          }
          notifyListeners(); // Notify UI to update
        }
      } else {
        print('❌ Failed to load user profile: ${response.error?.message}');
      }
    } catch (e) {
      print('💥 Error loading user profile: $e');
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      print('🔄 Starting profile update...');
      print('📊 Profile data to update: $profileData');
      _setLoading(true);
      _clearError();

      // Only send allowed fields to backend (phone number cannot be updated)
      final allowedFields = ['name', 'avatar', 'bio', 'address'];
      final updateData = <String, dynamic>{};

      for (final field in allowedFields) {
        if (profileData.containsKey(field) &&
            profileData[field] != null &&
            profileData[field].toString().trim().isNotEmpty) {
          updateData[field] = profileData[field];
        }
      }

      print('📤 Sending profile update to backend:');
      print('   Endpoint: ${ApiConfig.updateProfile}');
      print('   Data: $updateData');

      final response = await _apiClient.patch(
        ApiConfig.updateProfile,
        data: updateData,
      );

      if (response.isSuccess) {
        print('✅ Profile update successful');
        print('📊 Response: ${response.data}');

        // Backend returns user data directly, not nested under 'data'
        _currentUser = app_models.User.fromMap(
          response.data['user'] ?? response.data,
        );
        print('👤 Profile updated successfully: ${_currentUser?.name}');
        notifyListeners();
        return true;
      } else {
        print('❌ Profile update failed: ${response.error?.message}');
        _setError(response.error?.message ?? 'Failed to update profile');
        return false;
      }
    } catch (e) {
      print('💥 Update profile error: $e');
      _setError('Failed to update profile. Please try again.');
      debugPrint('Update profile error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('🔄 Starting logout process...');
      _setLoading(true);

      // Unregister device token first
      print('📱 Unregistering device token...');
      await unregisterDeviceTokenFromBackend();

      // Sign out from Google / Firebase
      await _signOutFromGoogle();

      print('✅ Logout successful');
      notifyListeners();
    } catch (e) {
      print('💥 Logout error: $e');
      // Clear local state even if API call fails
      await _tokenService.clearTokens();
      await _signOutFromGoogle();
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Handle 401 Unauthorized from API globally
  Future<void> handleUnauthorized() async {
    try {
      print('🔐 Handling 401 Unauthorized error...');
      await _tokenService.clearTokens();
      await _signOutFromGoogle();
      _isAuthenticated = false;
      _currentUser = null;
      _clearOtpSession();
      notifyListeners();
      print('✅ Unauthorized handled - user logged out');
    } catch (e) {
      print('💥 handleUnauthorized error: $e');
    }
  }

  // New method to explicitly save the role
  Future<void> checkAndSetRole(String role) async {
    print('🎯 Setting user role: $role');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    _lastRole = role;
    print('✅ Role saved: $role');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      print('⏳ Setting loading state: true');
    } else {
      print('✅ Setting loading state: false');
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    print('❌ Error set: $message');
    notifyListeners();
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = 'An account already exists with this email address';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Email/password accounts are not enabled';
        break;
      case 'weak-password':
        errorMessage = 'The password is too weak';
        break;
      case 'user-disabled':
        errorMessage = 'This user account has been disabled';
        break;
      case 'user-not-found':
        errorMessage = 'No user found with this email';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later';
        break;
      default:
        errorMessage = 'An error occurred. Please try again';
        break;
    }
    print('🔥 Firebase auth error: ${e.code} - $errorMessage');
    _setError(errorMessage);
  }

  void _clearError() {
    _errorMessage = null;
    print('🧹 Error cleared');
    notifyListeners();
  }

  void _startOtpTimer() {
    _otpTimeRemaining = ApiConfig.otpResendDelay.inSeconds;
    _otpTimer?.cancel();

    print('⏰ Starting OTP timer: $_otpTimeRemaining seconds remaining');
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpTimeRemaining > 0) {
        _otpTimeRemaining--;
        if (_otpTimeRemaining % 30 == 0) {
          // Log every 30 seconds to avoid spam
          print('⏰ OTP timer: $_otpTimeRemaining seconds remaining');
        }
        notifyListeners();
      } else {
        print('⏰ OTP timer expired');
        timer.cancel();
      }
    });
  }

  void _clearOtpSession() {
    print('🧹 Clearing OTP session data');
    _pendingPhoneNumber = null;
    _otpSessionId = null;
    _otpTimer?.cancel();
    _otpTimeRemaining = 0;
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phoneNumber.trim());
  }

  // Get formatted time remaining for OTP
  String getFormattedOtpTime() {
    final minutes = _otpTimeRemaining ~/ 60;
    final seconds = _otpTimeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  UserRole _parseUserRole(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == role,
      orElse: () => UserRole.everyone,
    );
  }

  Widget getHomeScreenForRole(
    UserRole role, {
    String instructorName = 'Instructor',
  }) {
    debugPrint('Navigating to home screen for role: ${role.toString()}');
    print('🏠 Getting home screen for role: ${role.value}');
    switch (role) {
      case UserRole.student:
        // For students, go to the profile form first
        print('🎓 Student role detected -> Navigating to UserProfileForm');
        return UserProfileForm();
      case UserRole.instructor:
        // For instructors, go directly to the dashboard
        print(
          '👨‍🏫 Instructor role detected -> Navigating to InstructorDashboard',
        );
        return InstructorDashboard(instructorName: instructorName);
      case UserRole.eventOrganizer:
        print(
          '🎪 Event Organizer role detected -> Navigating to AppRestartScreen',
        );
        return const AppRestartScreen();
      case UserRole.everyone:
      default:
        print('🌐 Default role detected -> Navigating to InterestBasedPage');
        return InterestBasedPage();
    }
  }

  @override
  void dispose() {
    print('♻️ AuthService disposed');
    _otpTimer?.cancel();
    super.dispose();
  }
}

class ComingSoonPage extends StatelessWidget {
  final String roleName;
  const ComingSoonPage({super.key, required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$roleName Page Coming Soon')),
      body: Center(
        child: Text(
          '$roleName page is under development.',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
