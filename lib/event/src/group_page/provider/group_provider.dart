import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';

class GroupProvider with ChangeNotifier {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;
  ApiClient? _apiClient;

  GroupProvider() {
    _initializeApiClient();
  }

  Future<void> _initializeApiClient() async {
    final prefs = await SharedPreferences.getInstance();
    _apiClient = ApiClient(prefs);
  }

  List<Map<String, dynamic>> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMyGroups() async {
    _setLoading(true);
    _clearError();

    try {
      // Ensure API client is initialized
      if (_apiClient == null) {
        await _initializeApiClient();
      }

      final response = await _apiClient!.get('/events/my-groups');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _groups = List<Map<String, dynamic>>.from(data['groups']);
        } else {
          _setError(data['message'] ?? 'Failed to load groups');
        }
      } else {
        _setError('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Network error: $e');
    }

    _setLoading(false);
  }

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
  }

  // Load group messages by ID
  Future<Map<String, dynamic>?> loadGroupMessages(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Ensure API client is initialized
      if (_apiClient == null) {
        await _initializeApiClient();
      }

      final response = await _apiClient!.get(
        '/events/$groupId/with-messages?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Return the entire data object which contains both group and messages
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to load messages');
        }
      } else {
        throw Exception(
          'API request failed with status ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      // Log error for debugging in development
      if (kDebugMode) {
        print('Error in loadGroupMessages: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Helper method to get member count
  int getMemberCount(Map<String, dynamic> group) {
    int instructorCount = (group['instructors'] as List?)?.length ?? 0;
    int studentCount = (group['students'] as List?)?.length ?? 0;
    return instructorCount + studentCount + 1; // +1 for admin
  }

  // Helper method to get admin name
  String getAdminName(Map<String, dynamic> group) {
    if (group['admin'] != null) {
      return group['admin']['name'] ?? 'Unknown Admin';
    }
    return 'Unknown Admin';
  }

  // Helper method to get group image (use admin avatar as fallback)
  String getGroupImage(Map<String, dynamic> group) {
    // Try to get admin avatar first
    if (group['admin'] != null && group['admin']['avatar'] != null) {
      final avatar = group['admin']['avatar'];
      if (avatar.startsWith('/uploads/')) {
        return 'http://54.82.53.11:5001/api$avatar';
      }
      return avatar;
    }

    // If no admin avatar, try to get first student avatar
    if (group['students'] != null && (group['students'] as List).isNotEmpty) {
      final firstStudent = (group['students'] as List)[0];
      if (firstStudent['avatar'] != null) {
        return firstStudent['avatar'];
      }
    }

    // Default fallback image
    return 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&h=200&fit=crop';
  }

  // Create a new group
  Future<Map<String, dynamic>> createGroup(
    Map<String, dynamic> groupData,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      // Ensure API client is initialized
      if (_apiClient == null) {
        await _initializeApiClient();
      }

      final response = await _apiClient!.post(
        '/events/create-group',
        groupData,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Add the new group to the beginning of the list
          _groups.insert(0, data['group']);
          notifyListeners();
          return data['group'];
        } else {
          throw Exception(data['message'] ?? 'Failed to create group');
        }
      } else {
        throw Exception('Failed to create group: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error creating group: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
