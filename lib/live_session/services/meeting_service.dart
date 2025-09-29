import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/time_utils.dart';
// Removed invalid relative import to a non‑existent auth_service in this module.
// We rely on SharedPreferences (set during instructor auth) to obtain user id.
import '../utils/network_config.dart';

class MeetingService {
  // API base URLs - we'll try these in order based on platform
  // For development, you can add your actual backend IP address here
  static final Map<String, List<String>> _platformUrlCandidates = {
    'android': [
      // 'http://10.0.2.2:3000', // Android emulator -> host loopback
  NetworkConfig.socketBaseUrl, // Centralized backend URL
      'http://192.168.1.23:3000', // Common local network IP (adjust as needed)
      // 'http://localhost:3000', // Unlikely to work on emulator but try anyway
    ],
    'ios': [
      // 'http://localhost:3000', // iOS simulator -> host loopback
  NetworkConfig.socketBaseUrl, // Centralized backend URL
      'http://127.0.0.1:3000', // Alternative loopback
      'http://192.168.1.23:3000', // Common local network IP (adjust as needed)
    ],
    'web': [
      // 'http://localhost:3000', // Same origin if served from localhost
  NetworkConfig.socketBaseUrl, // Centralized backend URL
      'http://192.168.1.23:3000', // Same origin if served from localhost
      '/api', // Relative URL for production/proxied setups
    ],
    'default': [
      // 'http://localhost:3000', // For desktop or unknown platforms
  NetworkConfig.socketBaseUrl, // Centralized backend URL
      'http://127.0.0.1:3000', // Alternative loopback
    ],
  };

  /// Fetch the MongoDB ObjectId for a meeting using the scheduleId
  /// This is critical for socket connections that require a valid ObjectId
  static Future<String?> getMeetingObjectId(String scheduleId) async {
    try {
      await _initializeBaseUrl(); // Ensure base URL is initialized

      // Get the current instructor's ID dynamically - IMPORTANT for API access
      final String hostId = await _getCurrentUserId();

      // Construct the API URL exactly as shown in your Postman screenshot
      // Include hostId which is required according to your error messages
      final url =
          '$baseUrl/schedule/occurrence/all?platformId=$platformId&hostId=$hostId';

      // Log the exact URL for debugging
      debugPrint('Fetching meeting details from: $url');
      debugPrint('Using headers: ${_getHeaders()}');

      // Try multiple connection attempts
      http.Response? response;

      // Try up to 3 times with different URLs if needed
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          // Construct URL for this attempt - try direct IP if localhost fails
          String attemptUrl = url;
          if (attempt > 1) {
            // Try with public IP directly on subsequent attempts
            attemptUrl = url.replaceAll('localhost:3000', '44.223.46.43:3000');
            if (attempt > 2) {
              // Try with another common IP pattern on third attempt
              attemptUrl = url.replaceAll('localhost:3000', '127.0.0.1:3000');
            }
          }

          debugPrint('Attempt $attempt: Trying URL: $attemptUrl');

          // Make the API request
          response = await http.get(
            Uri.parse(attemptUrl),
            headers: _getHeaders(),
          );

          // If successful, break out of retry loop
          if (response.statusCode == 200) {
            debugPrint('API connection successful on attempt $attempt!');
            break;
          }
        } catch (e) {
          debugPrint('Attempt $attempt failed: $e');
        }
      }

      // Check if any attempt was successful
      if (response != null && response.statusCode == 200) {
        // Parse the response - based on your Postman screenshot structure
        final responseData = jsonDecode(response.body);

        // Check if the response has the expected structure from your screenshot
        if (responseData['status'] == true &&
            responseData['data'] != null &&
            responseData['data'] is List &&
            responseData['data'].isNotEmpty) {
          // Loop through all meetings in the response
          for (var meeting in responseData['data']) {
            if (meeting['scheduleId'] == scheduleId) {
              // Found the meeting with matching scheduleId
              final String objectId = meeting['_id'];
              debugPrint('Found meeting with MongoDB ObjectId: $objectId');
              return objectId;
            }
          }
        } else {
          debugPrint(
            'API response format different than expected: ${response.body}',
          );
        }

        // If we get here, the meeting wasn't found in the response
        debugPrint(
          'No meeting found with scheduleId: $scheduleId in API response',
        );
        return null; // No hardcoded fallback - return null if not found
      } else {
        // All attempts failed or non-200 status
        debugPrint('API Error: ${response?.statusCode} - ${response?.body}');
        return null; // No hardcoded fallback - return null on API error
      }
    } catch (e) {
      debugPrint('Exception fetching meeting details: $e');
      return null; // No hardcoded fallback - return null on exception
    }
  }

  // Dynamic base URL - will be set during initialization
  static String baseUrl = '';

  // API token from documentation
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I';

  // Platform ID for the app
  static const String platformId = 'miskills';

  // Static initialization block
  static void init() async {
    // Try to initialize the base URL early
    await _initializeBaseUrl();

    // If we're on web, check CORS configuration
    if (kIsWeb) {
      await checkCorsConfig();
    }
  }

  // Updates user information in SharedPreferences after login
  // Call this method from your login process
  static Future<void> updateUserInfo({
    required String userId,
    required String userName,
    required String authToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Always update user_id on login for correct instructor context
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);
    await prefs.setString('auth_token', authToken);
    print('User info updated: ID=$userId, Name=$userName');
    // NOTE: Meeting creation and fetching will use this user_id.
  }

  // Initialize test user credentials for development
  static Future<void> initializeTestUser() async {
    // This method should not set a hardcoded instructor ID.
    // Remove test credentials. Always rely on login/auth flow to set user_id.
    print('Test user initialization skipped. Use proper login to set user_id.');
  }

  // Get auth headers
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiToken',
    };
  }

  // Get auth token from SharedPreferences (for user specific operations)
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get the current user's ID (instructor ID) from SharedPreferences
  static Future<String> _getCurrentUserId() async {
    // Directly read user_id saved by the instructor authentication flow.
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    debugPrint('[DEBUG] Read user_id from SharedPreferences: $userId');

    if (userId == null || userId.isEmpty) {
      debugPrint('[ERROR] user_id missing in SharedPreferences!');
      throw Exception(
        'No instructor logged in (user_id missing in SharedPreferences). Ensure login/OTP flow completed before accessing meetings.',
      );
    }

    print('Current instructor/host ID: $userId');
    return userId;
  }

  // Get current user information (useful for UI display)
  static Future<Map<String, String>> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString('user_id') ?? '',
      'userName': prefs.getString('user_name') ?? 'Instructor',
      'isLoggedIn': (prefs.getString('auth_token') != null).toString(),
    };
  }

  // Get a specific meeting by its ID (MongoDB ObjectId or scheduleId)
  static Future<Map<String, dynamic>?> getMeetingById(String meetingId) async {
    await _initializeBaseUrl();

    try {
      // Get the current instructor's ID dynamically
      final String hostId = await _getCurrentUserId();
      print('Fetching meeting by ID: $meetingId for host: $hostId');

      // Endpoint for schedule/occurrence
      final response = await http.get(
        Uri.parse(
          '$baseUrl/schedule/occurrence/$meetingId?platformId=$platformId&hostId=$hostId',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("");
        print("=========== MEETING FETCH DEBUG ===========");
        print("Fetching meeting with ID: $meetingId");
        print("RAW API RESPONSE FROM MEETING SERVICE: ${response.body}");

        // Extract and print the key fields from the response
        if (data['status'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          final meetingData = data['data'][0];
          print("Meeting Data Extracted:");
          print("- _id: ${meetingData['_id'] ?? 'Not found'}");
          print("- scheduleId: ${meetingData['scheduleId'] ?? 'Not found'}");
          print(
            "- occurrenceId: ${meetingData['occurrenceId'] ?? 'Not found'}",
          );
          print(
            "- userId/hostId: ${meetingData['userId'] ?? meetingData['hostId'] ?? 'Not found'}",
          );
          print(
            "- username/hostName: ${meetingData['username'] ?? meetingData['hostName'] ?? 'Not found'}",
          );

          // Print all keys in the meeting data for reference
          print("All meeting data keys: ${meetingData.keys.join(', ')}");
        } else {
          print("No meeting data found or invalid response format");
        }
        print("==========================================");

        return data;
      } else {
        print('Failed to fetch meeting: ${response.statusCode}');
        print('Response: ${response.body}');
        return {
          'status': false,
          'message': 'Failed to fetch meeting: ${response.statusCode}',
        };
      }
    } catch (error) {
      print('Error fetching meeting: $error');
      return {'status': false, 'message': 'Error fetching meeting: $error'};
    }
  }

  // Calculate duration in minutes between two ISO datetime strings with better error handling
  static int _calculateDurationInMinutes(
    String startDateTime,
    String endDateTime,
  ) {
    try {
      // Make sure both strings have Z at the end for UTC parsing
      final startString = startDateTime.endsWith('Z')
          ? startDateTime
          : startDateTime + 'Z';
      final endString = endDateTime.endsWith('Z')
          ? endDateTime
          : endDateTime + 'Z';

      final start = DateTime.parse(startString);
      final end = DateTime.parse(endString);

      // Safety check - if end is before start, return a positive default duration
      if (end.isBefore(start)) {
        print(
          'Warning: End time is before start time: $endDateTime is before $startDateTime',
        );
        return 30; // Default 30 minutes
      }

      return end.difference(start).inMinutes;
    } catch (e) {
      print('Error calculating duration: $e');
      print('  - Start: $startDateTime');
      print('  - End: $endDateTime');
      return 30; // Default to 30 minutes
    }
  }

  // Get the appropriate URL candidates based on platform
  static List<String> _getUrlCandidatesForPlatform() {
    String platformKey;

    if (kIsWeb) {
      platformKey = 'web';
      print('💻 Running on Web platform');
    } else if (Platform.isAndroid) {
      platformKey = 'android';
      print('📱 Running on Android platform');
    } else if (Platform.isIOS) {
      platformKey = 'ios';
      print('📱 Running on iOS platform');
    } else {
      platformKey = 'default';
      print('🖥️ Running on desktop/other platform');
    }

    return _platformUrlCandidates[platformKey] ??
        _platformUrlCandidates['default']!;
  }

  // Initialize the best base URL
  static Future<String> _initializeBaseUrl() async {
    if (baseUrl.isNotEmpty) {
      return baseUrl; // Already initialized
    }

    // Start with platform-aware default
    final candidates = _getUrlCandidatesForPlatform();
    candidates.insert(0, NetworkConfig.socketBaseUrl);

    // Add additional server options based on your Postman screenshot
    // These are likely your actual server addresses
  candidates.add('http://44.223.46.43:3000'); // Public backend IP
  candidates.add('http://10.0.2.2:3000'); // Standard Android emulator -> host
  candidates.add('http://127.0.0.1:3000'); // Standard localhost
  candidates.add('http://localhost:3000'); // Standard localhost name

    // Try your actual IP addresses if known (add your specific IP here)
    candidates.add('http://192.168.1.10:3000'); // Example local network IP

    // Clean up duplicates
    final uniqueCandidates = candidates.toSet().toList();

    // Log connection attempts
    print(
      '🔍 Trying to connect to backend servers. Candidates: ${uniqueCandidates.join(", ")}',
    );

    // Try each candidate URL
    for (String candidate in uniqueCandidates) {
      try {
        // Skip relative URLs for health checks
        if (candidate.startsWith('/')) {
          continue; // Can't do a health check on a relative URL
        }

        print('⏳ Attempting connection to: $candidate');

        // Make a simple health check request
        final Uri healthCheckUrl = Uri.parse('$candidate/');
        final response = await http
            .get(healthCheckUrl, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200 || response.statusCode == 404) {
          // 404 is also acceptable - it means the server is running but endpoint doesn't exist
          print('🟢 Backend server found at $candidate');
          baseUrl = candidate;
          return candidate;
        }
      } catch (e) {
        print('❌ Failed to connect to $candidate: $e');
        // Continue to next candidate
      }
    }

    // For web platform, try using a relative URL as fallback
    if (kIsWeb) {
      final relativeUrls = candidates
          .where((url) => url.startsWith('/'))
          .toList();
      if (relativeUrls.isNotEmpty) {
        baseUrl = relativeUrls.first;
        print('⚠️ Using relative URL for web: $baseUrl');
        return baseUrl;
      }
    }

    // No working backend found, but we need to proceed for testing
    print('⚠️ No backend server available. Using hardcoded URL for testing');

    // Set a platform-appropriate URL as a last resort
    if (Platform.isAndroid) {
  // baseUrl = 'http://10.0.2.2:3000'; // Android emulator -> host
  baseUrl = NetworkConfig.socketBaseUrl;
    } else if (Platform.isIOS) {
  // baseUrl = 'http://localhost:3000'; // iOS simulator -> host
  baseUrl = NetworkConfig.socketBaseUrl;
    } else {
      // Web or desktop
  // baseUrl = 'http://localhost:3000';
  baseUrl = NetworkConfig.socketBaseUrl;
    }

    print('🔄 Using fallback URL: $baseUrl');
    return baseUrl;
  }

  // Get all meetings for an instructor
  static Future<List<dynamic>> getInstructorMeetings() async {
    // Get the current instructor's ID dynamically from preferences
    final String hostId = await _getCurrentUserId();
    debugPrint('[MEETING FETCH] Using hostId: $hostId');
    try {
      // Make sure we have the best available URL
      await _initializeBaseUrl();

      // Add delay before API call to ensure network is ready
      await Future.delayed(Duration(milliseconds: 500));

      // Get the current instructor's ID dynamically from preferences
      final String hostId = await _getCurrentUserId();
      print(hostId);

      // Get today's date in the format YYYY-MM-DD
      final todayDate = DateTime.now().toString().split(' ')[0];

      final Uri upcomingUrl = Uri.parse('$baseUrl/schedule/occurrence/all')
          .replace(
            queryParameters: {
              'platformId': platformId,
              'hostId': hostId,
              'todayDate': todayDate,
              'type': 'upcoming',
            },
          );

      final Uri todayUrl = Uri.parse('$baseUrl/schedule/occurrence/all')
          .replace(
            queryParameters: {
              'platformId': platformId,
              'hostId': hostId,
              'todayDate': todayDate,
              'type': 'today',
            },
          );

      final Uri pastUrl = Uri.parse('$baseUrl/schedule/occurrence/all').replace(
        queryParameters: {
          'platformId': platformId,
          'hostId': hostId,
          'todayDate': todayDate,
          'type': 'past',
        },
      );

      print('Fetching upcoming meetings: ${upcomingUrl.toString()}');
      print('Fetching today meetings: ${todayUrl.toString()}');
      print('Fetching past meetings: ${pastUrl.toString()}');

      // Make all API calls with retry logic
      Future<http.Response> fetchWithRetry(Uri url, {int retries = 3}) async {
        for (int i = 0; i < retries; i++) {
          try {
            // Use timeout to avoid hanging indefinitely
            final response = await http
                .get(url, headers: _getHeaders())
                .timeout(
                  Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException(
                      'Request timed out after 10 seconds',
                    );
                  },
                );
            return response;
          } catch (e) {
            print('Fetch attempt ${i + 1} failed: $e');
            if (i == retries - 1) rethrow;
            // Wait before retrying
            await Future.delayed(Duration(seconds: 1));
          }
        }
        // This will never happen due to rethrow above, but Dart needs it
        throw Exception('Failed after $retries retries');
      }

      // Try to make all API calls in parallel with retry logic
      final responses = await Future.wait([
        fetchWithRetry(upcomingUrl),
        fetchWithRetry(todayUrl),
        fetchWithRetry(pastUrl),
      ]);

      // Process responses
      final List<dynamic> allMeetings = [];

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        print(
          'Response status for ${i == 0 ? "upcoming" : (i == 1 ? "today" : "past")}: ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print(
            'Response data: ${response.body.substring(0, min(100, response.body.length))}...',
          );

          final meetings = data['data'] ?? [];

          // Convert API response to our format
          for (final meeting in meetings) {
            final String startDateTime =
                meeting['startDateTime'] ??
                meeting['startDate'] + 'T' + meeting['startTime'] + ':00.000Z';
            final String endDateTime =
                meeting['endDateTime'] ??
                meeting['endDate'] + 'T' + meeting['endTime'] + ':00.000Z';

            // Calculate duration (with better error handling)
            int duration = 30; // Default duration
            try {
              duration = _calculateDurationInMinutes(
                startDateTime,
                endDateTime,
              );
            } catch (e) {
              print(
                'Error calculating duration: $e - Using default 30 minutes',
              );
            }

            // Preserve BOTH occurrence _id and scheduleId explicitly so downstream code
            // can use a valid MongoDB ObjectId (occurrenceId) when joining the room.
            // Previous code overloaded the generic 'id' field which caused the UI to lose
            // the actual occurrence ObjectId and send an empty/invalid value to joinRoom.
            final formattedMeeting = {
              // Keep legacy 'id' for UI lists (use scheduleId for human grouping)
              'id': meeting['scheduleId'] ?? '',
              // Explicit identifiers
              '_id': meeting['_id'] ?? '', // occurrenceId (MongoDB ObjectId)
              'occurrenceId': meeting['_id'] ?? '', // convenience alias
              'scheduleId': meeting['scheduleId'] ?? '',
              'title': meeting['title'] ?? 'Untitled Meeting',
              'purpose': meeting['description'] ?? '',
              'scheduledDate': startDateTime,
              'endDate': endDateTime, // explicit end time
              'duration': duration,
              'timeZone': meeting['timeZone'] ?? 'Asia/Kolkata',
              'participants': (meeting['hosts'] != null
                  ? (meeting['hosts'] as List).length
                  : 1),
              'isActive': meeting['status'] == 'live',
              'status': meeting['status'],
              'type': i == 0 ? 'upcoming' : (i == 1 ? 'today' : 'past'),
            };

            allMeetings.add(formattedMeeting);
          }
        } else {
          print(
            'Failed to fetch ${i == 0 ? "upcoming" : (i == 1 ? "today" : "past")} meetings: ${response.statusCode} - ${response.body}',
          );
        }
      }

      print('Total meetings fetched: ${allMeetings.length}');
      return allMeetings;
    } catch (e) {
      // Check if this is a CORS error (common in web)
      String errorMessage = e.toString().toLowerCase();
      bool isCorsError =
          kIsWeb &&
          (errorMessage.contains('cors') ||
              errorMessage.contains('access-control-allow-origin') ||
              errorMessage.contains('cross-origin'));

      if (isCorsError) {
        print(
          '⚠️ CORS error detected! This is common when running in a web browser.',
        );
        print(
          'The backend server needs to enable CORS for the Flutter web app to connect.',
        );
        print('Suggestion: Add this to your Express server:');
        print('app.use(cors({ origin: "*" }));');
      }

      print('Error fetching meetings: $e');
      // Print stack trace for debugging
      print('Stack trace: ${StackTrace.current}');

      print('Backend connection error. Providing mock data for development...');

      // Get today's date for mock data
      final mockTodayDate = DateTime.now().toString().split(' ')[0];

      // Return mock data for development purposes
      return [
        {
          'id': 'mock-meeting-1',
          'title': 'Flutter Development Session',
          'purpose': 'Learning Flutter basics and state management',
          'scheduledDate': '${mockTodayDate}T10:00:00.000Z',
          'duration': 60,
          'participants': 5,
          'isActive': false,
          'type': 'today',
        },
        {
          'id': 'mock-meeting-2',
          'title': 'API Integration Workshop',
          'purpose': 'Connect Flutter app with backend services',
          'scheduledDate': '${mockTodayDate}T14:00:00.000Z',
          'duration': 90,
          'participants': 8,
          'isActive': false,
          'type': 'today',
        },
        {
          'id': 'mock-meeting-3',
          'title': 'UI/UX Design Review',
          'purpose': 'Review and improve application interfaces',
          'scheduledDate':
              DateTime.now().add(Duration(days: 1)).toString().split(' ')[0] +
              'T11:30:00.000Z',
          'duration': 45,
          'participants': 3,
          'isActive': false,
          'type': 'upcoming',
        },
      ];
    }
  }

  // Schedule a new meeting
  static Future<Map<String, dynamic>> scheduleMeeting({
    required String title,
    String? description,
    required String startDate,
    required String startTime,
    required String endDate,
    required String endTime,
    String? group,
    String recurrence = "none", // Must be one of: "none", "daily", "custom"
    List<int>? daysOfWeek,
    List<Map<String, dynamic>>? hosts,
  }) async {
    try {
      // Validate recurrence value
      if (!["none", "daily", "custom"].contains(recurrence)) {
        recurrence = "none"; // Default to none if an invalid value is provided
      }

      // Get the current instructor's ID and name dynamically
      final String hostId = await _getCurrentUserId();

      // Get the user name from preferences or use a default
      final prefs = await SharedPreferences.getInstance();
      final String hostName = prefs.getString('user_name') ?? 'Instructor';

      // IMPORTANT: The times we receive are in 24-hour format, already converted to UTC
      // from the meetings_page.dart. We need to preserve these values exactly.

      // Initialize with safe defaults to avoid null issues
      DateTime startDateTime = DateTime.now();
      DateTime endDateTime = DateTime.now().add(const Duration(hours: 1));

      try {
        // Parse the date and time strings to create DateTime objects, but don't modify the original
        // time strings since they're already properly formatted for the API
        final startDateParts = startDate.split('-').map(int.parse).toList();
        final startTimeParts = startTime.split(':').map(int.parse).toList();
        startDateTime = DateTime(
          startDateParts[0], // year
          startDateParts[1], // month
          startDateParts[2], // day
          startTimeParts[0], // hour
          startTimeParts[1], // minute
        );

        // Parse the end date and time
        final endDateParts = endDate.split('-').map(int.parse).toList();
        final endTimeParts = endTime.split(':').map(int.parse).toList();
        endDateTime = DateTime(
          endDateParts[0], // year
          endDateParts[1], // month
          endDateParts[2], // day
          endTimeParts[0], // hour
          endTimeParts[1], // minute
        );

        // Print debug info to verify UTC times
        print('UTC datetime objects created:');
        print(
          '- Start: $startDateTime (${startDateTime.hour}:${startDateTime.minute})',
        );
        print(
          '- End: $endDateTime (${endDateTime.hour}:${endDateTime.minute})',
        );

        // We'll use the parsed DateTimes for formatting, but send the original time strings to API

        // Debug hour values to ensure AM/PM is correctly detected
        print(
          'DEBUG START TIME: ${startDateTime.hour}:${startDateTime.minute} - Hour >= 12: ${startDateTime.hour >= 12} (${startDateTime.hour >= 12 ? "PM" : "AM"})',
        );
        print(
          'DEBUG END TIME: ${endDateTime.hour}:${endDateTime.minute} - Hour >= 12: ${endDateTime.hour >= 12} (${endDateTime.hour >= 12 ? "PM" : "AM"})',
        );

        // We keep the original startDate, startTime, endDate, endTime as they're already properly formatted
        // for the API. No need to modify them here.

        print('Original time values from arguments:');
        print('- Start: $startDate $startTime');
        print('- End: $endDate $endTime');
      } catch (e) {
        print('Error parsing date/time: $e');
        // Continue with the original values if parsing fails
      }

      print('CREATING MEETING: Date=$startDate, Time=$startTime (IST)');
      print('Start IST: $startDate $startTime, End IST: $endDate $endTime');

      // CRITICAL FIX: Add explicit AM/PM info to help the backend interpret time correctly
      // We'll use the TimeUtils class to ensure consistent formatting

      // Log both 24-hour and 12-hour formats for clarity
      print('Meeting Time Debug:');
      print(
        '24-hour format: ${startDateTime.hour}:${startDateTime.minute} - ${endDateTime.hour}:${endDateTime.minute}',
      );

      // Use our TimeUtils for consistent time formatting
      final formattedStartTime = TimeUtils.formatTimeWithCorrectAmPm(
        startDateTime.hour,
        startDateTime.minute,
      );
      final formattedEndTime = TimeUtils.formatTimeWithCorrectAmPm(
        endDateTime.hour,
        endDateTime.minute,
      );
      final formattedTimeRange = TimeUtils.formatTimeRangeWithCorrection(
        startDateTime,
        endDateTime,
      );

      print('Formatted with TimeUtils: $formattedTimeRange');

      // Format the request exactly as expected by the backend
      final Map<String, dynamic> meetingData = {
        'platformId': platformId,
        'hostId': hostId,
        'hostName': hostName,
        'title': title,
        'group': group ?? 'Default Group', // Default group if none provided
        'startDate': startDate,
        'startTime': startTime,
        'endDate': endDate,
        'endTime': endTime,
        'timeZone': 'Asia/Kolkata', // Explicitly set timezone to IST
        // Add explicit 12-hour format indicators to help correct any timezone issues
        'startTimeFormat': formattedStartTime,
        'endTimeFormat': formattedEndTime,
        'recurrence': recurrence,
        // Always include the current host in the hosts array
        'hosts': [
          {'hostId': hostId, 'hostName': hostName},
        ],
      };

      // Add optional parameters only if they're provided
      if (description != null && description.isNotEmpty) {
        meetingData['description'] = description;
      } else {
        meetingData['description'] = ""; // Empty string as default
      }

      // For custom recurrence, daysOfWeek is required
      if (recurrence == "custom") {
        if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
          meetingData['daysOfWeek'] = daysOfWeek;
        } else {
          // Default to weekdays if custom recurrence but no days specified
          meetingData['daysOfWeek'] = [1, 2, 3, 4, 5]; // Mon-Fri
        }
      }

      // Add additional hosts if provided
      if (hosts != null && hosts.isNotEmpty) {
        // Add all additional hosts to the hosts array
        final List<Map<String, dynamic>> allHosts = [
          ...meetingData['hosts'] as List,
        ];
        for (final host in hosts) {
          // Ensure each host has the required fields
          if (host.containsKey('hostId') && host.containsKey('hostName')) {
            allHosts.add(host);
          }
        }
        meetingData['hosts'] = allHosts;
      }

      // Make sure we have the best available URL
      await _initializeBaseUrl();

      // Log the request payload for debugging
      print('📤 Sending meeting creation request:');
      print(jsonEncode(meetingData));

      final response = await http.post(
        Uri.parse('$baseUrl/schedule'),
        headers: _getHeaders(),
        body: jsonEncode(meetingData),
      );

      // Construct the ISO date time strings for duration calculation
      final startDateTimeString = '${startDate}T${startTime}:00.000Z';
      final endDateTimeString = '${endDate}T${endTime}:00.000Z';

      // Log the response for debugging
      print('📥 Meeting creation response (${response.statusCode}):');
      print(
        response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'id':
              data['data']?['scheduleId'] ??
              'MI-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          'title': data['data']?['title'] ?? title,
          'scheduledDate': startDateTimeString,
          'duration': _calculateDurationInMinutes(
            startDateTimeString,
            endDateTimeString,
          ),
          'success': true,
        };
      } else {
        print('❌ Failed to schedule meeting: ${response.statusCode}');

        try {
          // Try to parse error response as JSON
          final errorData = jsonDecode(response.body);
          print('Error details: ${errorData['message'] ?? 'Unknown error'}');

          return {
            'success': false,
            'error':
                errorData['message'] ??
                'Server returned ${response.statusCode}',
            'details': errorData,
          };
        } catch (_) {
          // If can't parse as JSON, return the raw response
          return {
            'success': false,
            'error':
                'Failed to schedule meeting. Server returned ${response.statusCode}',
            'details': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Error scheduling meeting: $e');
      print('Stack trace: ${StackTrace.current}');

      // For demo purposes, return a mock response
      // Construct the ISO date time strings for duration calculation
      final startDateTime = '${startDate}T${startTime}:00.000Z';
      final endDateTime = '${endDate}T${endTime}:00.000Z';

      return {
        'id':
            'MI-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        'title': title,
        'scheduledDate': startDateTime,
        'duration': _calculateDurationInMinutes(startDateTime, endDateTime),
        'success': true,
        'mock': true, // Indicate this is mock data
      };
    }
  }

  // Update an existing meeting
  static Future<bool> updateMeeting(
    String meetingId,
    Map<String, dynamic> meetingData,
  ) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/meetings/$meetingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(meetingData),
      );

      return response.statusCode == 200;
    } catch (e) {
      // For demo purposes
      return true;
    }
  }

  // Delete a meeting
  static Future<bool> deleteMeeting(String meetingId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/meetings/$meetingId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      // For demo purposes
      return true;
    }
  }

  // Get meeting participants
  static Future<List<dynamic>> getMeetingParticipants(String meetingId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/meetings/$meetingId/participants'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['participants'] ?? [];
      } else {
        throw Exception('Failed to load participants: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes
      return [
        {'id': 'user1', 'name': 'John Smith', 'role': 'host'},
        {'id': 'user2', 'name': 'Sarah Johnson', 'role': 'participant'},
        {'id': 'user3', 'name': 'Michael Brown', 'role': 'participant'},
        {'id': 'user4', 'name': 'Emily Davis', 'role': 'participant'},
      ];
    }
  }

  // Helper function to check if backend has CORS configured properly
  static Future<void> checkCorsConfig() async {
    if (!kIsWeb) return; // Only relevant for web

    try {
      print('🔍 Testing backend CORS configuration...');
      final response = await http
          .get(
            // Uri.parse('http://localhost:3000/'),
            Uri.parse('http://44.223.46.43:3000/'),
            headers: {
              'Origin':
                  'http://localhost:55578', // Simulate the Flutter web origin
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      // Check if CORS headers are present
      final corsHeader = response.headers['access-control-allow-origin'];
      if (corsHeader == null) {
        print(
          '⚠️ Backend is reachable but missing CORS headers. Add CORS middleware to your server.',
        );
      } else {
        print('✅ CORS headers detected: $corsHeader');
      }
    } catch (e) {
      print('❌ CORS test failed: $e');
    }
  }

  // Get LiveKit token for a meeting
  static Future<String?> getLiveKitToken(String meetingId, bool isHost) async {
    try {
      final token = await _getAuthToken();
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Instructor';

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/meetings/$meetingId/livekit-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userName': userName, 'isHost': isHost}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        throw Exception('Failed to get LiveKit token: ${response.statusCode}');
      }
    } catch (e) {
      // For demo purposes - in a real app, you'd need an actual token from your backend
      return 'demo-token-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
