import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';
import '../utils/constants.dart';

/// Helper service for fetching meeting information directly from the API
class MeetingApiService {
  /// Fetch all meetings for a student (participant)
  static Future<List<Map<String, dynamic>>> fetchMeetingsForStudent(
    String participantId,
  ) async {
    print(AppConstants.apiToken);
    try {
      final baseUrl = getBaseUrl();
      final url =
          '$baseUrl/schedule/occurrence/participant?platformId=$platformId&participantId=$participantId';
      debugPrint('Fetching student meetings from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.apiToken}',
        },
                
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true &&
            data['data'] != null &&
            data['data'] is List) {
          debugPrint(
            'Successfully fetched ${data['data'].length} student meetings',
          );
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          debugPrint('API response not in expected format: ${response.body}');
          return [];
        }
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching student meetings: $e');
      return [];
    }
  }

  // Base URLs are centralized via NetworkConfig; platform map removed.

  // Platform ID
  static const String platformId = 'miskills';

  /// Get the current logged-in instructor's host ID dynamically
  /// This replaces the hardcoded hostId to support multiple instructors
  static Future<String> getCurrentHostId() async {
    final prefs = await SharedPreferences.getInstance();
    final hostId = prefs.getString('user_id');

    if (hostId == null || hostId.isEmpty) {
      throw Exception(
        'No instructor logged in. Please ensure the instructor is properly authenticated before accessing meetings.',
      );
    }

    debugPrint('Using dynamic host ID for API calls: $hostId');
    return hostId;
  }

  /// Get the appropriate base URL for the current platform
  static String getBaseUrl() {
    // Prefer override / platform-aware config
    return NetworkConfig.socketBaseUrl;
  }

  /// Fetch all meetings
  /// This is a direct API call to fetch meetings based on your Postman screenshots
  /// Now uses dynamic host ID from logged-in instructor
  static Future<List<Map<String, dynamic>>> fetchAllMeetings() async {
    try {
      // Get the appropriate base URL for the current platform
      final baseUrl = getBaseUrl();

      // Get the current instructor's host ID dynamically (no more hardcoded values!)
      final hostId = await getCurrentHostId();

      // This matches exactly the URL structure in your Postman screenshot
      final url =
          '$baseUrl/schedule/occurrence/all?platformId=$platformId&hostId=$hostId';

      debugPrint('Fetching all meetings from: $url');
      debugPrint('Using dynamic host ID: $hostId');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Include Authorization like in fetchMeetingsForStudent (protected endpoint)
          'Authorization': 'Bearer ${AppConstants.apiToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check response format
        if (data['status'] == true &&
            data['data'] != null &&
            data['data'] is List) {
          debugPrint('Successfully fetched ${data['data'].length} meetings');
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          debugPrint('API response not in expected format: ${response.body}');
          return [];
        }
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching meetings: $e');
      return [];
    }
  }

  /// Find a meeting by its scheduleId
  /// Returns the MongoDB ObjectId (_id) for the meeting
  static Future<String?> findMeetingObjectIdByScheduleId(
    String scheduleId,
  ) async {
    try {
      final meetings = await fetchAllMeetings();

      // Find the meeting with the matching scheduleId
      for (var meeting in meetings) {
        if (meeting['scheduleId'] == scheduleId) {
          final String objectId = meeting['_id'];
          debugPrint(
            'Found meeting with ObjectId: $objectId for scheduleId: $scheduleId',
          );
          return objectId;
        }
      }

      debugPrint('No meeting found with scheduleId: $scheduleId');
      return null;
    } catch (e) {
      debugPrint('Error finding meeting by scheduleId: $e');
      return null;
    }
  }
}
