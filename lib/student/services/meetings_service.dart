import 'package:dio/dio.dart';
import '../../live_session/utils/network_config.dart';
import '../models/meeting.dart';

class MeetingsService {
  final Dio _dio = Dio();

  // Fixed bearer token as specified
  static const String _fixedBearerToken =
      'eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I';

  // Fixed platform ID as shown in the image
  static const String _platformId = 'miskills';

  MeetingsService() {
  // Centralized base URL
  _dio.options.baseUrl = NetworkConfig.socketBaseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_fixedBearerToken',
      'Content-Type': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    // Add interceptor to log all requests
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );
  }

  /// Get meetings with required parameters
  /// [participantId] - Student ID (required)
  /// [type] - Meeting type: 'past', 'upcoming', 'today' (optional)
  /// [todayDate] - Required when type is provided, format: 'YYYY-MM-DD'
  Future<List<Meeting>> getMeetings({
    required String participantId,
    String? type,
    String? todayDate,
  }) async {
    try {
      // Validate that if type is provided, todayDate must also be provided
      if (type != null && todayDate == null) {
        throw ArgumentError('todayDate is required when type is specified');
      }

      // Build query parameters
      final queryParams = <String, dynamic>{
        'platformId': _platformId,
        'participantId': participantId,
      };

      // Add optional parameters if provided
      if (type != null) {
        queryParams['type'] = type;
        queryParams['todayDate'] = todayDate;
      }

      print(
        '🔗 Making API call to: ${_dio.options.baseUrl}/schedule/occurrence/participant',
      );
      print('📋 Query params: $queryParams');

      final response = await _dio.get(
        '/schedule/occurrence/participant',
        queryParameters: queryParams,
      );

      print('✅ API Response Status: ${response.statusCode}');
      print('📄 API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('📋 Raw API Response: ${response.data}');
        print('📋 Response Type: ${response.data.runtimeType}');

        if (response.data is Map && response.data['data'] is List) {
          // Handle wrapped response format: {status: true, message: "...", data: [...]}
          final List<dynamic> meetingsJson = response.data['data'];
          print('📋 Found ${meetingsJson.length} meetings in wrapped response');

          final meetings = <Meeting>[];
          for (int i = 0; i < meetingsJson.length; i++) {
            try {
              final meeting = Meeting.fromJson(meetingsJson[i]);
              meetings.add(meeting);
              print('✅ Successfully parsed meeting ${i + 1}: ${meeting.title}');
            } catch (e) {
              print('❌ Error parsing meeting ${i + 1}: $e');
              print('❌ Meeting data: ${meetingsJson[i]}');
            }
          }

          print('📋 Successfully parsed ${meetings.length} meetings');
          return meetings;
        } else if (response.data is List) {
          final List<dynamic> meetingsJson = response.data;
          print(
            '📋 Found ${meetingsJson.length} meetings in direct array response',
          );

          final meetings = <Meeting>[];
          for (int i = 0; i < meetingsJson.length; i++) {
            try {
              final meeting = Meeting.fromJson(meetingsJson[i]);
              meetings.add(meeting);
              print('✅ Successfully parsed meeting ${i + 1}: ${meeting.title}');
            } catch (e) {
              print('❌ Error parsing meeting ${i + 1}: $e');
              print('❌ Meeting data: ${meetingsJson[i]}');
            }
          }

          print('📋 Successfully parsed ${meetings.length} meetings');
          return meetings;
        } else {
          print('⚠️ Unexpected response format: ${response.data}');
          print('⚠️ Response type: ${response.data.runtimeType}');
          return [];
        }
      } else {
        throw Exception('Failed to load meetings: ${response.statusMessage}');
      }
    } on DioException catch (dioError) {
      print('🚨 Dio Error: ${dioError.type}');
      print('🚨 Dio Message: ${dioError.message}');
      print('🚨 Dio Response: ${dioError.response?.data}');
      print('🚨 Dio Response Status: ${dioError.response?.statusCode}');

      if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.connectionError) {
        throw Exception(
          'Network connection error. Please check your internet connection and try again.',
        );
      } else if (dioError.type == DioExceptionType.badResponse) {
        throw Exception(
          'Server error: ${dioError.response?.statusCode}. Please try again later.',
        );
      } else {
        throw Exception('Network error: ${dioError.message}');
      }
    } catch (e) {
      print('🚨 General Error: $e');
      throw Exception('Error fetching meetings: $e');
    }
  }

  /// Get upcoming meetings for a student
  Future<List<Meeting>> getUpcomingMeetings(String studentId) async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return getMeetings(
      participantId: studentId,
      type: 'upcoming',
      todayDate: todayString,
    );
  }

  /// Get today's meetings for a student
  Future<List<Meeting>> getTodayMeetings(String studentId) async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return getMeetings(
      participantId: studentId,
      type: 'today',
      todayDate: todayString,
    );
  }

  /// Get past meetings for a student
  Future<List<Meeting>> getPastMeetings(String studentId) async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return getMeetings(
      participantId: studentId,
      type: 'past',
      todayDate: todayString,
    );
  }

  /// Get all meetings for a student (without type filter)
  Future<List<Meeting>> getAllMeetings(String studentId) async {
    return getMeetings(participantId: studentId);
  }
}
