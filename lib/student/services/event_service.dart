import 'package:flutter/foundation.dart';
import '../models/event.dart';
import 'api_client.dart';
import 'token_service.dart';
import '../config/api_config.dart';

class EventService extends ChangeNotifier {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final ApiClient _apiClient = ApiClient();
  final TokenService _tokenService = TokenService();

  List<Event> _events = [];
  List<Event> _enrolledEvents = [];
  bool _isLoading = false;
  bool _isLoadingEnrolled = false;
  String? _error;

  List<Event> get events => List.unmodifiable(_events);
  List<Event> get enrolledEvents => List.unmodifiable(_enrolledEvents);
  bool get isLoading => _isLoading;
  bool get isLoadingEnrolled => _isLoadingEnrolled;
  String? get error => _error;

  // Get all events from API
  Future<List<Event>> getAllEvents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('🎉 Loading events from API...');
      debugPrint('🔑 Token valid: ${_tokenService.hasValidToken}');
      debugPrint('🌐 API Base URL: ${_apiClient.dio.options.baseUrl}');
      debugPrint('📍 Endpoint: student/events');

      if (!_tokenService.hasValidToken) {
        debugPrint('❌ No valid token, cannot load events');
        _error = 'Authentication required';
        _events = [];
        return _events;
      }

      Future<Event> getEventDetailsById(String id) async {
        try {
          final response = await _apiClient.get<Map<String, dynamic>>(
            'student/events/$id',
          );

          if (response.isSuccess && response.data != null) {
            final data = response.data!;

            // API might return: { success: true, event: {...} } OR { data: {...} }

            final eventData = data['event'] ?? data['data'] ?? data;

            if (eventData is Map<String, dynamic>) {
              return Event.fromJson(eventData);
            } else {
              throw Exception('Unexpected response format');
            }
          } else {
            throw Exception(
              response.error?.message ?? 'Failed to load event details',
            );
          }
        } catch (e) {
          throw Exception('Error loading event: $e');
        }
      }

      // Try to get auth headers for debugging
      try {
        final authHeaders = await _tokenService.getAuthHeaders();
        debugPrint(
          '🔐 Auth headers: ${authHeaders.containsKey('Authorization') ? 'Bearer token present' : 'No auth token'}',
        );
      } catch (e) {
        debugPrint('❌ Error getting auth headers: $e');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        'student/events', // GET /api/student/events
      );

      debugPrint('📥 Events response status: ${response.isSuccess}');
      debugPrint('📥 Events response data: ${response.data}');
      debugPrint('📥 Events response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('📊 Response keys: ${data.keys.toList()}');
        debugPrint(
          '✅ Response success: ${data['success']}, status: ${data['status']}',
        );

        if (data['success'] == true || data['status'] == 'success') {
          // Handle different response formats:
          // 1. { success: true, events: [...] }
          // 2. { success: true, data: { events: [...] } }
          // 3. { status: 'success', data: [...] }
          final eventsJson =
              data['events'] ?? (data['data']?['events']) ?? data['data'];

          debugPrint('🔍 Events JSON type: ${eventsJson?.runtimeType}');
          debugPrint('🔍 Events JSON value: $eventsJson');

          if (eventsJson != null && eventsJson is List) {
            debugPrint('📝 Parsing ${eventsJson.length} event objects...');
            _events = [];
            for (int i = 0; i < eventsJson.length; i++) {
              try {
                final eventJson = eventsJson[i];
                debugPrint(
                  '📝 Parsing event $i: ${eventJson['title'] ?? 'No title'}',
                );
                debugPrint(
                  '🔍 Event $i raw data keys: ${eventJson.keys.toList()}',
                );
                debugPrint('🔍 Event $i enrollment data:');
                debugPrint(
                  '  - enrolledStudents: ${eventJson['enrolledStudents']}',
                );
                debugPrint('  - enrollments: ${eventJson['enrollments']}');
                debugPrint('  - participants: ${eventJson['participants']}');
                debugPrint(
                  '  - registeredStudents: ${eventJson['registeredStudents']}',
                );
                debugPrint('  - isRegistered: ${eventJson['isRegistered']}');
                debugPrint('  - registered: ${eventJson['registered']}');

                final event = Event.fromJson(eventJson);
                debugPrint(
                  '✅ Event $i parsed - isRegistered: ${event.isRegistered}',
                );
                _events.add(event);
              } catch (e) {
                debugPrint('❌ Error parsing event $i: $e');
              }
            }
            debugPrint('✅ Successfully loaded ${_events.length} events');
          } else {
            debugPrint('⚠️ No events found in the response');
            debugPrint('⚠️ Response structure:');
            debugPrint('  - events: ${data['events']}');
            debugPrint('  - data: ${data['data']}');
            debugPrint('  - data[events]: ${data['data']?['events']}');
            _events = [];
          }
        } else {
          debugPrint(
            '❌ API returned error: ${data['message'] ?? data['error']}',
          );
          _error = data['message'] ?? data['error'] ?? 'Failed to load events';
          _events = [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        debugPrint('❌ API error details: ${response.error?.details}');
        debugPrint('❌ API error type: ${response.error?.type}');
        _error = response.error?.message ?? 'Failed to load events';
        _events = [];
      }
    } catch (e) {
      debugPrint('❌ Error loading events: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _error = 'Error loading events: $e';
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _events;
  }

  // Note: Registration/Unregistration endpoints don't exist in the actual API
  // Only enrollment is available via enrollInEvent method

  // Get events by category
  List<Event> getEventsByCategory(String category) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (category.toLowerCase()) {
      case 'today':
        return _events.where((event) {
          final eventDate = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          return eventDate.isAtSameMomentAs(today);
        }).toList();
      case 'upcoming':
        return _events.where((event) {
          final eventDate = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          return eventDate.isAfter(today);
        }).toList();
      case 'past':
        return _events.where((event) {
          final eventDate = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          return eventDate.isBefore(today);
        }).toList();
      default:
        return _events;
    }
  }

  // Get event details by title (based on actual API)
  Future<Event> getEventDetails(String eventTitle) async {
    try {
      debugPrint('🔍 Getting event details for: $eventTitle');

      // Ensure we have a valid token
      if (!_tokenService.hasValidToken) {
        debugPrint('❌ No valid token, cannot load event details');
        throw Exception('Authentication required to view event details');
      }

      // Encode the title to handle spaces and special characters
      final encodedTitle = Uri.encodeComponent(eventTitle);
      debugPrint('📤 Requesting event with encoded title: $encodedTitle');

      final response = await _apiClient.get<Map<String, dynamic>>(
        'student/events/$encodedTitle',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint(
          '📥 Event details response: ${data.toString().substring(0, 200)}...',
        );

        // Handle different response structures
        dynamic eventData = data['event'] ?? data['data'] ?? data;

        // If the API returns a list, take the first item
        if (eventData is List && eventData.isNotEmpty) {
          eventData = eventData.first;
        }

        if (eventData is Map<String, dynamic>) {
          try {
            final event = Event.fromJson(eventData);
            debugPrint('✅ Successfully parsed event: ${event.title}');
            return event;
          } catch (e) {
            debugPrint('❌ Error parsing event data: $e');
            debugPrint('Event data: $eventData');
            throw Exception('Failed to parse event data: $e');
          }
        } else {
          debugPrint(
            '❌ Unexpected event data format: ${eventData.runtimeType}',
          );
          throw Exception('Unexpected event data format');
        }
      } else {
        final errorMsg = response.error?.message ?? 'Unknown error';
        debugPrint('❌ Failed to load event details: $errorMsg');
        debugPrint('Response data: ${response.data}');
        throw Exception('Failed to load event details: $errorMsg');
      }
    } catch (e) {
      debugPrint('❌ Error in getEventDetails: $e');
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Enroll in an event
  Future<bool> enrollInEvent(String eventId) async {
    try {
      debugPrint('🎟️ Attempting to enroll in event: $eventId');

      // Ensure we have a valid token
      if (!_tokenService.hasValidToken) {
        debugPrint('❌ No valid token, cannot enroll in event');
        throw Exception('Authentication required to enroll in events');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        'events/$eventId/enroll',
        data: {},
      );

      debugPrint('📥 Enrollment response: ${response.data}');

      if (response.isSuccess) {
        // Check for success in response data if needed
        final success =
            response.data?['success'] ?? response.data?['status'] == 'success';

        if (success) {
          debugPrint('✅ Successfully enrolled in event: $eventId');

          // Update local event data
          final eventIndex = _events.indexWhere((event) => event.id == eventId);
          if (eventIndex != -1) {
            _events[eventIndex] = _events[eventIndex].copyWith(
              isRegistered: true,
              currentParticipants: _events[eventIndex].currentParticipants + 1,
            );
            notifyListeners();
          }
          return true;
        } else {
          final errorMsg =
              response.data?['message'] ??
              response.data?['error'] ??
              'Failed to enroll in event';
          debugPrint('❌ Enrollment failed: $errorMsg');
          return false;
        }
      } else {
        final errorMsg =
            response.error?.message ??
            response.data?['message'] ??
            'Failed to enroll in event';
        debugPrint('❌ API error during enrollment: $errorMsg');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in enrollInEvent: $e');
      rethrow;
    }
  }

  // Get enrolled events from dedicated endpoint
  Future<List<Event>> getEnrolledEvents() async {
    debugPrint('🎯 Getting enrolled events from dedicated endpoint...');

    try {
      _isLoadingEnrolled = true;
      _error = null;
      notifyListeners();

      // Check authentication status first
      try {
        final authHeaders = await _tokenService.getAuthHeaders();
        debugPrint(
          '🔐 Auth headers: ${authHeaders.containsKey('Authorization') ? 'Bearer token present' : 'No auth token'}',
        );

        if (!authHeaders.containsKey('Authorization')) {
          debugPrint(
            '❌ No authentication token available - user needs to login',
          );
          _error =
              'Authentication required. Please login to view enrolled events.';
          _enrolledEvents = [];
          return _enrolledEvents;
        }
      } catch (e) {
        debugPrint('❌ Error getting auth headers: $e');
        _error = 'Authentication error: ${e.toString()}';
        _enrolledEvents = [];
        return _enrolledEvents;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.enrolledEvents, // GET /api/student/events/enrolled
      );

      debugPrint('📥 Enrolled events response status: ${response.isSuccess}');
      debugPrint('📥 Enrolled events response data: ${response.data}');
      debugPrint('📥 Enrolled events response error: ${response.error}');

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        debugPrint('📊 Enrolled events response keys: ${data.keys.toList()}');
        debugPrint(
          '✅ Response success: ${data['success']}, status: ${data['status']}',
        );

        if (data['success'] == true || data['status'] == 'success') {
          // Handle enrolled events response format:
          // { success: true, data: [{ event: {...}, enrollment: {...} }] }
          final eventsJson = data['data'];

          debugPrint(
            '🔍 Enrolled events JSON type: ${eventsJson?.runtimeType}',
          );
          debugPrint('🔍 Enrolled events JSON value: $eventsJson');

          if (eventsJson != null && eventsJson is List) {
            debugPrint(
              '📝 Parsing ${eventsJson.length} enrolled event objects...',
            );
            _enrolledEvents = [];
            for (int i = 0; i < eventsJson.length; i++) {
              try {
                final enrollmentItem = eventsJson[i];
                debugPrint('📝 Parsing enrollment item $i');
                debugPrint(
                  '🔍 Enrollment item $i keys: ${enrollmentItem.keys.toList()}',
                );

                // Check if the event data is nested inside an 'event' object
                if (enrollmentItem.containsKey('event') &&
                    enrollmentItem['event'] is Map) {
                  final eventJson =
                      enrollmentItem['event'] as Map<String, dynamic>;
                  debugPrint(
                    '📝 Parsing enrolled event $i: ${eventJson['title'] ?? 'No title'}',
                  );
                  debugPrint(
                    '🔍 Enrolled event $i raw data keys: ${eventJson.keys.toList()}',
                  );
                  debugPrint('🔍 Enrolled event $i enrollment data:');
                  debugPrint(
                    '  - enrolledStudents: ${eventJson['enrolledStudents']}',
                  );
                  debugPrint('  - enrollments: ${eventJson['enrollments']}');
                  debugPrint('  - participants: ${eventJson['participants']}');
                  debugPrint(
                    '  - registeredStudents: ${eventJson['registeredStudents']}',
                  );
                  debugPrint('  - isRegistered: ${eventJson['isRegistered']}');
                  debugPrint('  - registered: ${eventJson['registered']}');

                  // Since this is from enrolled events endpoint, set isRegistered to true
                  final event = Event.fromJson(eventJson);
                  // Force isRegistered to true since this is from enrolled events endpoint
                  event.isRegistered = true;
                  debugPrint(
                    '✅ Enrolled event $i parsed - isRegistered: ${event.isRegistered}',
                  );
                  _enrolledEvents.add(event);
                } else {
                  debugPrint(
                    '⚠️ Enrollment item $i does not contain nested event object',
                  );
                  debugPrint(
                    '⚠️ Available keys: ${enrollmentItem.keys.toList()}',
                  );
                }
              } catch (e) {
                debugPrint('❌ Error parsing enrolled event $i: $e');
              }
            }
            debugPrint(
              '✅ Successfully loaded ${_enrolledEvents.length} enrolled events',
            );
          } else {
            debugPrint('⚠️ No enrolled events found in the response');
            debugPrint('⚠️ Response structure:');
            debugPrint('  - events: ${data['events']}');
            debugPrint('  - data: ${data['data']}');
            debugPrint('  - data[events]: ${data['data']?['events']}');
            _enrolledEvents = [];
          }
        } else {
          debugPrint(
            '❌ API returned error: ${data['message'] ?? data['error']}',
          );
          _error =
              data['message'] ??
              data['error'] ??
              'Failed to load enrolled events';
          _enrolledEvents = [];
        }
      } else {
        debugPrint('❌ API request failed: ${response.error?.message}');
        debugPrint('❌ API error details: ${response.error?.details}');
        debugPrint('❌ API error type: ${response.error?.type}');
        _error = response.error?.message ?? 'Failed to load enrolled events';
        _enrolledEvents = [];
      }
    } catch (e) {
      debugPrint('❌ Error loading enrolled events: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      _error = 'Error loading enrolled events: $e';
      _enrolledEvents = [];
    } finally {
      _isLoadingEnrolled = false;
      notifyListeners();
    }

    return _enrolledEvents;
  }

  // Filter events by status
  List<Event> filterEventsByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'today':
        return _events.where((event) => event.isToday).toList();
      case 'upcoming':
        return _events.where((event) => event.isUpcoming).toList();
      case 'past':
        return _events.where((event) => event.isPast).toList();
      default:
        return _events;
    }
  }

  // Search events
  List<Event> searchEvents(String query) {
    if (query.isEmpty) return _events;

    return _events.where((event) {
      return event.title.toLowerCase().contains(query.toLowerCase()) ||
          event.description.toLowerCase().contains(query.toLowerCase()) ||
          event.category.toLowerCase().contains(query.toLowerCase()) ||
          (event.organizerName?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (event.tags?.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ) ??
              false);
    }).toList();
  }

  // Get registered events (local filtering)
  List<Event> getRegisteredEvents() {
    return _events.where((event) => event.isRegistered).toList();
  }

  Future<void> refreshEvents() async {
    await getAllEvents();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get event by ID
  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }
}
