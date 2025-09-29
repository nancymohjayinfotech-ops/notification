import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';

class EventAuthService {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  EventAuthService(this._apiClient, this._prefs);

  // Send OTP
  Future<AuthResponse> sendOtp(String phoneNumber, String role) async {
    try {
      final response = await _apiClient.post('/auth/send-otp', {
        'phoneNumber': phoneNumber,
        'role': role == 'Event Organizer' ? 'event' : 'student',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      print('🚨 Error in sendOtp: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Verify OTP
  Future<AuthResponse> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _apiClient.post('/auth/verify-otp', {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        // Save tokens and user data
        if (authResponse.data.accessToken != null &&
            authResponse.data.refreshToken != null) {
          await _apiClient.saveTokens(
            authResponse.data.accessToken!,
            authResponse.data.refreshToken!,
          );

          // Save user data
          if (authResponse.data.user != null) {
            await _saveUserData(authResponse.data.user!);
          }
        }

        return authResponse;
      } else {
        throw Exception('Failed to verify OTP');
      }
    } catch (e) {
      print('🚨 Error in verifyOtp: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/events/dashboard');
      print(
        '📡 Dashboard API Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Dashboard data: $data');

        if (data != null &&
            data['success'] == true &&
            data['summary'] != null) {
          return data['summary'] as Map<String, dynamic>;
        } else {
          throw Exception('Invalid dashboard response structure: $data');
        }
      } else {
        throw Exception(
          'Dashboard API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('🚨 Error in getDashboardStats: ${e.toString()}');
      throw Exception('Failed to load dashboard stats: ${e.toString()}');
    }
  }

  // Get current user profile
  Future<User> getUserProfile() async {
    try {
      final response = await _apiClient.get('/user/profile');
      print(
        '📡 Profile API Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Parsed data: $data');

        if (data != null && data['success'] == true && data['user'] != null) {
          final userMap = data['user'] as Map<String, dynamic>;
          final user = User.fromJson(userMap);
          await _saveUserData(user);
          return user;
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('🚨 Error in getUserProfile: ${e.toString()}');
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<User> updateUserProfile({
    String? name,
    String? avatar,
    String? bio,
    String? phone,
    String? address,
    String? college,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (avatar != null) data['avatar'] = avatar;
      if (bio != null) data['bio'] = bio;
      if (phone != null) data['phoneNumber'] = phone; // API expects phoneNumber
      if (address != null) data['address'] = address;
      if (college != null) data['college'] = college;

      print('📤 Updating profile with data: $data');
      final response = await _apiClient.patch('/user/profile', body: jsonEncode(data));
      print(
        '📡 Update API Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('📊 Update parsed data: $responseData');

        if (responseData != null && responseData['success'] == true) {
          // API returns success message, not user object
          // Fetch updated profile data
          print('✅ Profile update successful, fetching latest data...');
          final updatedUser = await getUserProfile();
          return updatedUser;
        } else {
          throw Exception(
            'Update failed: ${responseData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Update API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('🚨 Error in updateUserProfile: ${e.toString()}');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Upload profile image with bytes (web-compatible)
  Future<String> uploadProfileImageBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      print('📤 Uploading profile image: $fileName');

      final baseUrl = ApiClient.baseUrl;
      final token = await _apiClient.getAccessToken();

      if (token == null) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('$baseUrl/uploads/profile');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes('avatar', imageBytes, filename: fileName),
      );

      print('📡 Sending multipart request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        '📡 Upload API Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['avatarUrl'] != null) {
          print('✅ Image uploaded successfully: ${data['avatarUrl']}');
          return data['avatarUrl'];
        } else {
          throw Exception(
            'Upload failed: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('🚨 Error in uploadProfileImageBytes: ${e.toString()}');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Legacy method for backward compatibility
  Future<String> uploadProfileImage(String imagePath) async {
    throw Exception('Use uploadProfileImageBytes for web compatibility');
  }

  // Logout
  Future<void> logout() async {
    await _apiClient.clearTokens();
    await _prefs.remove('user_data');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _apiClient.isLoggedIn();
  }

  // Get cached user data
  Future<User?> getCachedUser() async {
    try {
      final userData = _prefs.getString('user_data');
      if (userData != null) {
        // Parse the JSON string properly
        final Map<String, dynamic> userJson = Map<String, dynamic>.from(
          jsonDecode(userData),
        );
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      print('🚨 Error in getCachedUser: ${e.toString()}');
      return null;
    }
  }

  // Private helper to save user data
  Future<void> _saveUserData(User user) async {
    await _prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // Send OTP for event
  Future<String?> sendEventOtp(String phoneNumber) async {
    try {
      final response = await _apiClient.post(
        '/event/send-otp',
        {
          'phoneNumber': phoneNumber,
        }, // Fixed parameter name (should be 'data' not named parameter)
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final otp = data['data']?['otp']?.toString();
        return otp;
      } else {
        return null;
      }
    } catch (e) {
      print('🚨 Error in sendEventOtp: ${e.toString()}');
      return null;
    }
  }
}
