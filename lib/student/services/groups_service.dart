import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../utils/error_handler.dart';

class GroupsService {
  final ApiClient _apiClient = ApiClient();

  /// Get all groups for the current user
  Future<ApiResponse<List<Group>>> getMyGroups() async {
    try {
      final response = await _apiClient.get('/groups/my-groups');
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
      print("Response Data: ${response.data}");
      if (response.isSuccess && response.data != null) {
        if (response.data['groups'] != null) {
          final List<dynamic> groupsData = response.data['groups'];
          final groups = groupsData
              .map((json) => Group.fromJson(json))
              .toList();
          return ApiResponse.success(groups);
        } else {
          return ApiResponse.success([]);
        }
      } else {
        return ApiResponse.error('Failed to fetch groups');
      }
    } catch (e) {
      final err = ErrorHandler.handleError(e);
      return ApiResponse.error(err.message);
    }
  }

  /// Get group with messages
  Future<ApiResponse<Map<String, dynamic>>> getGroupWithMessages(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/groups/$groupId/with-messages',
        queryParameters: {'page': page, 'limit': limit},
      );
      print("response>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
      print(response);
      if (response.isSuccess && response.data != null) {
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        print("Group with Messages Response: ${response.data}");
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error('Failed to fetch group messages');
      }
    } catch (e) {
      final err = ErrorHandler.handleError(e);
      return ApiResponse.error(err.message);
    }
  }

  /// Leave a group
  Future<ApiResponse<bool>> leaveGroup(String groupId) async {
    try {
      final response = await _apiClient.post('/groups/$groupId/leave');

      if (response.isSuccess) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to leave group');
      }
    } catch (e) {
      final err = ErrorHandler.handleError(e);
      return ApiResponse.error(err.message);
    }
  }

  /// Get group by ID
  Future<ApiResponse<Group>> getGroupById(String groupId) async {
    try {
      final response = await _apiClient.get('/groups/$groupId');

      if (response.isSuccess && response.data != null) {
        final group = Group.fromJson(response.data);
        return ApiResponse.success(group);
      } else {
        return ApiResponse.error('Failed to fetch group');
      }
    } catch (e) {
      final err = ErrorHandler.handleError(e);
      return ApiResponse.error(err.message);
    }
  }

  /// Get group members
  Future<ApiResponse<Map<String, dynamic>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      final response = await _apiClient.get('/groups/$groupId/members');

      if (response.isSuccess && response.data != null) {
        return ApiResponse.success(response.data);
      } else {
        return ApiResponse.error('Failed to fetch group members');
      }
    } catch (e) {
      final err = ErrorHandler.handleError(e);
      return ApiResponse.error(err.message);
    }
  }
}

/// Generic API Response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.isSuccess,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse<T>(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
