import 'dart:convert';
import '../core/api/api_client.dart';

class EnrollmentApiService {
  final ApiClient _apiClient;

  EnrollmentApiService(this._apiClient);

  /// Fetch enrollments for a specific event
  Future<EnrollmentResponse> getEventEnrollments(String eventId) async {
    try {
      final response = await _apiClient.get('/events/$eventId/enrollments');
      print('📡 Enrollments API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Parsed enrollments data: $data');
        
        if (data != null && data['success'] == true && data['data'] != null) {
          return EnrollmentResponse.fromJson(data['data']);
        } else {
          throw Exception('Invalid response structure: $data');
        }
      } else {
        throw Exception('API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error in getEventEnrollments: ${e.toString()}');
      throw Exception('Failed to load enrollments: ${e.toString()}');
    }
  }

  /// Update enrollment status (approve/decline)
  Future<bool> updateEnrollmentStatus(String eventId, String enrollmentId, String status) async {
    try {
      final body = jsonEncode({
        'status': status,
      });

      print('📡 Updating enrollment status: $eventId/$enrollmentId -> $status');
      
      final response = await _apiClient.patch(
        '/events/$eventId/enrollments/$enrollmentId',
        body: body,
      );

      print('📡 Update enrollment API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error in updateEnrollmentStatus: ${e.toString()}');
      throw Exception('Failed to update enrollment status: ${e.toString()}');
    }
  }
}

/// Response model for enrollments API
class EnrollmentResponse {
  final EventInfo event;
  final List<Enrollment> enrollments;
  final EnrollmentStats stats;

  EnrollmentResponse({
    required this.event,
    required this.enrollments,
    required this.stats,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) {
    return EnrollmentResponse(
      event: EventInfo.fromJson(json['event'] as Map<String, dynamic>? ?? {}),
      enrollments: (json['enrollments'] as List<dynamic>? ?? [])
          .map((enrollmentJson) => Enrollment.fromJson(
            enrollmentJson as Map<String, dynamic>,
            eventId: (json['event'] as Map<String, dynamic>?)?['_id'] ?? '',
          ))
          .toList(),
      stats: EnrollmentStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Event info model
class EventInfo {
  final String id;
  final String title;
  final int maxParticipants;
  final String category;
  final String location;
  final String type;

  EventInfo({
    required this.id,
    required this.title,
    required this.maxParticipants,
    required this.category,
    required this.location,
    required this.type,
  });

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    return EventInfo(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      maxParticipants: json['maxParticipants'] ?? 0,
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

/// Enrollment model
class Enrollment {
  final String id;
  final String userId;
  final String eventId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String status; // 'pending', 'approved', 'declined'
  final DateTime enrolledAt;
  final String? college;
  final String? phoneNumber;

  Enrollment({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.status,
    required this.enrolledAt,
    this.college,
    this.phoneNumber,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json, {String? eventId}) {
    // Handle the new API response structure with nested student object
    final student = json['student'] as Map<String, dynamic>? ?? {};
    
    return Enrollment(
      id: json['_id'] ?? json['id'] ?? '',
      userId: student['_id'] ?? student['id'] ?? json['userId'] ?? '',
      eventId: eventId ?? json['eventId'] ?? '',
      userName: student['name'] ?? json['userName'] ?? json['user']?['name'] ?? 'Unknown User',
      userEmail: student['email'] ?? json['userEmail'] ?? json['user']?['email'] ?? '',
      userAvatar: student['avatar'] ?? json['userAvatar'] ?? json['user']?['avatar'],
      status: json['status'] ?? 'pending',
      enrolledAt: DateTime.tryParse(json['requestedAt'] ?? json['enrolledAt'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      college: student['college'] ?? json['college'] ?? json['user']?['college'],
      phoneNumber: student['phoneNumber'] ?? json['phoneNumber'] ?? json['user']?['phoneNumber'],
    );
  }
}

/// Enrollment statistics model
class EnrollmentStats {
  final int totalEnrollments;
  final int approvedEnrollments;
  final int pendingEnrollments;
  final int declinedEnrollments;
  final int availableSpots;

  EnrollmentStats({
    required this.totalEnrollments,
    required this.approvedEnrollments,
    required this.pendingEnrollments,
    required this.declinedEnrollments,
    required this.availableSpots,
  });

  factory EnrollmentStats.fromJson(Map<String, dynamic> json) {
    return EnrollmentStats(
      totalEnrollments: json['total'] ?? 0,
      approvedEnrollments: json['approved'] ?? 0,
      pendingEnrollments: json['pending'] ?? 0,
      declinedEnrollments: json['declined'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
    );
  }
}
