import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../../event_management/event.dart';

class EventApiService {
  final ApiClient _apiClient;
  final Dio _dio;

  EventApiService(this._apiClient)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiClient.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  /// Fetch all events from the API
  Future<EventsResponse> getAllEvents({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.get('/events?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['success'] == true && data['data'] != null) {
          return EventsResponse.fromJson(data['data']);
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load events: ${e.toString()}');
    }
  }

  /// Create a new event
  Future<Event> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
    EventMode mode = EventMode.offline,
    EventCategory category = EventCategory.other,
    double? price,
    int? maxParticipants,
    DateTime? registrationDeadline,
    List<String>? images,
    List<String>? videos,
    List<String>? tags,
  }) async {
    try {
      final token = await _apiClient.getAccessToken();
      final eventData = {
        'title': title,
        'description': description,
        'location': location,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'mode': mode.toString().split('.').last,
        'category': category.toString().split('.').last,
        if (price != null) 'price': price,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
        if (registrationDeadline != null)
          'registrationDeadline': registrationDeadline.toIso8601String(),
        if (images != null && images.isNotEmpty) 'images': images,
        if (videos != null && videos.isNotEmpty) 'videos': videos,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };

      final response = await _dio.post(
        '/events',
        data: eventData,
        options: Options(
          headers: {
            'Authorization': token != null ? 'Bearer $token' : '',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true && data['data'] != null) {
          return Event.fromApiJson(data['data']);
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception('Failed to create event: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  /// Update an existing event
  Future<Event> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
    EventMode mode = EventMode.offline,
    EventCategory category = EventCategory.other,
    double? price,
    int? maxParticipants,
    DateTime? registrationDeadline,
    List<String>? images,
    List<String>? videos,
    List<String>? tags,
    bool? isActive,
  }) async {
    try {
      final token = await _apiClient.getAccessToken();
      final eventData = {
        'title': title,
        'description': description,
        'location': location,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'mode': mode.toString().split('.').last,
        'category': category.toString().split('.').last,
        if (price != null) 'price': price,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
        if (registrationDeadline != null)
          'registrationDeadline': registrationDeadline.toIso8601String(),
        if (images != null && images.isNotEmpty) 'images': images,
        if (videos != null && videos.isNotEmpty) 'videos': videos,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _dio.patch(
        '/events/$eventId',
        data: eventData,
        options: Options(
          headers: {
            'Authorization': token != null ? 'Bearer $token' : '',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true && data['data'] != null) {
          return Event.fromApiJson(data['data']);
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception('Failed to update event: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final token = await _apiClient.getAccessToken();
      final response = await _dio.delete(
        '/events/$eventId',
        options: Options(
          headers: {'Authorization': token != null ? 'Bearer $token' : ''},
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.statusMessage}',
        );
      }
    } catch (e) {
      throw Exception('Failed to delete event: ${e.toString()}');
    }
  }

  /// Get event by ID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await _apiClient.get('/events/$eventId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['success'] == true && data['data'] != null) {
          return Event.fromApiJson(data['data']);
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load event: ${e.toString()}');
    }
  }

  /// Get event by slug
  Future<Event> getEventBySlug(String slug) async {
    try {
      final response = await _apiClient.get('/events/slug/$slug');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['success'] == true && data['data'] != null) {
          return Event.fromApiJson(data['data']);
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load event: ${e.toString()}');
    }
  }

  /// Upload an image file to the server
  Future<String> uploadImage(String filePath) async {
    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(filePath));
        final bytes = response.bodyBytes;
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        multipartFile = await MultipartFile.fromFile(filePath);
      }

      final formData = FormData.fromMap({'images': multipartFile});

      final token = await _apiClient.getAccessToken();

      final response = await _dio.post(
        '/uploads/event/images',
        data: formData,
        options: Options(
          headers: {
            'Authorization': token != null ? 'Bearer $token' : '',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'] as Map<String, dynamic>;
          if (responseData['images'] != null &&
              responseData['images'] is List) {
            final images = responseData['images'] as List;
            if (images.isNotEmpty && images[0]['url'] != null) {
              return images[0]['url'] as String;
            }
          }
        }
        throw Exception('Invalid response structure: $data');
      } else {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload a video file to the server
  Future<String> uploadVideo(String filePath) async {
    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(filePath));
        final bytes = response.bodyBytes;
        final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        multipartFile = await MultipartFile.fromFile(filePath);
      }

      final formData = FormData.fromMap({'videos': multipartFile});

      final token = await _apiClient.getAccessToken();

      final response = await _dio.post(
        '/uploads/event/videos',
        data: formData,
        options: Options(
          headers: {
            'Authorization': token != null ? 'Bearer $token' : '',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'] as Map<String, dynamic>;
          if (responseData['videos'] != null &&
              responseData['videos'] is List) {
            final videos = responseData['videos'] as List;
            if (videos.isNotEmpty && videos[0]['url'] != null) {
              return videos[0]['url'] as String;
            }
          }
        }
        throw Exception('Invalid response structure: $data');
      } else {
        throw Exception('Failed to upload video: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error uploading video: $e');
    }
  }

  /// Upload a file to the server (legacy method for backward compatibility)
  Future<String> uploadFile(String filePath) async {
    final lower = filePath.toLowerCase();
    if (kIsWeb && filePath.startsWith('blob:')) {
      return await uploadImage(filePath);
    } else if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif')) {
      return await uploadImage(filePath);
    } else if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) {
      return await uploadVideo(filePath);
    } else {
      try {
        MultipartFile multipartFile;
        if (kIsWeb) {
          final response = await http.get(Uri.parse(filePath));
          final bytes = response.bodyBytes;
          final fileName = 'file_${DateTime.now().millisecondsSinceEpoch}';
          multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
        } else {
          multipartFile = await MultipartFile.fromFile(filePath);
        }

        final formData = FormData.fromMap({'file': multipartFile});

        final token = await _apiClient.getAccessToken();

        final response = await _dio.post(
          '/upload',
          data: formData,
          options: Options(
            headers: {
              'Authorization': token != null ? 'Bearer $token' : '',
              'Content-Type': 'multipart/form-data',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          if (data['success'] == true && data['url'] != null) {
            return data['url'] as String;
          } else {
            throw Exception('Invalid response structure: $data');
          }
        } else {
          throw Exception('Failed to upload file: ${response.statusMessage}');
        }
      } catch (e) {
        throw Exception('Error uploading file: $e');
      }
    }
  }

  /// Upload multiple files and return their URLs
  Future<List<String>> uploadFiles(List<String> filePaths) async {
    final List<String> urls = [];
    for (final path in filePaths) {
      try {
        final url = await uploadFile(path);
        urls.add(url);
      } catch (e) {
        // Continue with other files if one fails
      }
    }
    return urls;
  }
}

class EventsResponse {
  final List<Event> events;
  final EventsPagination pagination;

  EventsResponse({required this.events, required this.pagination});

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    return EventsResponse(
      events: (json['events'] as List<dynamic>)
          .map(
            (eventJson) => Event.fromApiJson(eventJson as Map<String, dynamic>),
          )
          .toList(),
      pagination: EventsPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

class EventsPagination {
  final int currentPage;
  final int totalPages;
  final int totalEvents;
  final bool hasNextPage;
  final bool hasPrevPage;

  EventsPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalEvents,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory EventsPagination.fromJson(Map<String, dynamic> json) {
    return EventsPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalEvents: json['totalEvents'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}
