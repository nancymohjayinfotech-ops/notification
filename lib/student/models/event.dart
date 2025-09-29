import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final String? imageUrl;
  final int maxParticipants;
  final int currentParticipants;
  final String? organizerName;
  final String? organizerId;
  final List<String>? tags;
  final String? eventType;
  final bool isActive;
  final DateTime? registrationDeadline;
  final String? meetingLink;
  final Map<String, dynamic>? additionalInfo;
  final String? contactPhone;
  final String? contactEmail;
  final DateTime? endDate;
  final String? endTime;
  final double? price;
  final List<dynamic>? images;
  final List<dynamic>? videos;
  final String? slug;
  final List<dynamic>? enrollments;
  final List<dynamic>? enrolledStudents;
  bool isRegistered;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    this.imageUrl,
    this.isRegistered = false,
    required this.maxParticipants,
    required this.currentParticipants,
    this.organizerName,
    this.organizerId,
    this.tags,
    this.eventType,
    this.isActive = true,
    this.registrationDeadline,
    this.meetingLink,
    this.additionalInfo,
    this.contactPhone,
    this.contactEmail,
    this.endDate,
    this.endTime,
    this.price,
    this.images,
    this.videos,
    this.slug,
    this.enrollments,
    this.enrolledStudents,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Debug: Log the entire JSON response structure
    debugPrint('🔍 Event.fromJson - Raw JSON keys: ${json.keys.toList()}');
    debugPrint('🔍 Event.fromJson - Looking for enrollment data...');
    
    // Get enrolled students list from different possible response formats
    List<dynamic>? enrolledStudents = json['enrolledStudents'] ?? 
                                  json['enrollments'] ?? 
                                  json['participants'] ?? 
                                  json['registeredStudents'];
    
    // Debug: Log what we found for enrollment data
    debugPrint('🔍 Event.fromJson - enrolledStudents: ${enrolledStudents?.length ?? 0} items');
    debugPrint('🔍 Event.fromJson - enrollments field: ${json['enrollments']}');
    debugPrint('🔍 Event.fromJson - participants field: ${json['participants']}');
    debugPrint('🔍 Event.fromJson - registeredStudents field: ${json['registeredStudents']}');
    debugPrint('🔍 Event.fromJson - isRegistered field: ${json['isRegistered']}');
    debugPrint('🔍 Event.fromJson - registered field: ${json['registered']}');
    
    // Check if current user is enrolled
    bool isUserRegistered = _checkIfUserIsEnrolled(enrolledStudents);
    debugPrint('🔍 Event.fromJson - isUserRegistered (calculated): $isUserRegistered');
    
    // Fallback to backend flag if available
    bool isRegistered = json['isRegistered'] ?? json['registered'] ?? isUserRegistered;
    debugPrint('🔍 Event.fromJson - Final isRegistered: $isRegistered');
    
    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['startDate'] ?? json['date'] ?? json['eventDate'] ?? '') ?? DateTime.now(),
      time: json['startTime'] ?? json['time'] ?? json['eventTime'] ?? '',
      location: json['location'] ?? json['venue'] ?? '',
      category: json['category'] ?? json['eventCategory'] ?? 'General',
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['banner'],
      isRegistered: isRegistered,
      maxParticipants: json['maxParticipants'] ?? json['capacity'] ?? 0,
      currentParticipants: enrolledStudents?.length ?? (json['currentParticipants'] ?? json['registeredCount'] ?? 0),
      organizerName: json['organizerName'] ?? json['organizer']?['name'],
      organizerId: json['organizerId'] ?? json['organizer']?['id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      eventType: json['eventType'] ?? json['type'],
      isActive: json['isActive'] ?? json['active'] ?? true,
      registrationDeadline: json['registrationDeadline'] != null 
          ? DateTime.tryParse(json['registrationDeadline']) 
          : null,
      meetingLink: json['meetingLink'] ?? json['onlineLink'],
      additionalInfo: json['additionalInfo'] ?? json['metadata'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      endTime: json['endTime'],
      price: json['price']?.toDouble(),
      images: json['images'],
      videos: json['videos'],
      slug: json['slug'],
      enrollments: json['enrollments'],
      enrolledStudents: enrolledStudents,
    );
  }
  
  // Check if current user is enrolled in the event
  static bool _checkIfUserIsEnrolled(List<dynamic>? enrolledStudents) {
    debugPrint('🔍 _checkIfUserIsEnrolled - Checking ${enrolledStudents?.length ?? 0} enrolled students');
    
    if (enrolledStudents == null || enrolledStudents.isEmpty) {
      debugPrint('🔍 _checkIfUserIsEnrolled - No enrolled students found');
      return false;
    }
    
    try {
      // Get current user from AuthService
      final authService = AuthService();
      final currentUser = authService.currentUser;
      
      debugPrint('🔍 _checkIfUserIsEnrolled - Current user: ${currentUser?.id ?? 'NULL'}');
      
      if (currentUser == null) {
        debugPrint('🔍 _checkIfUserIsEnrolled - No current user found');
        return false;
      }
      
      // Check if current user ID is in the enrolled students list
      for (int i = 0; i < enrolledStudents.length; i++) {
        var student = enrolledStudents[i];
        String? studentId;
        
        // Handle different formats of student data
        if (student is Map<String, dynamic>) {
          studentId = student['_id'] ?? student['id'] ?? student['userId'] ?? student['studentId'];
          debugPrint('🔍 _checkIfUserIsEnrolled - Student $i (Map): $studentId');
        } else if (student is String) {
          studentId = student;
          debugPrint('🔍 _checkIfUserIsEnrolled - Student $i (String): $studentId');
        } else {
          debugPrint('🔍 _checkIfUserIsEnrolled - Student $i (Unknown type): ${student.runtimeType}');
        }
        
        if (studentId == currentUser.id) {
          debugPrint('🔍 _checkIfUserIsEnrolled - ✅ MATCH FOUND! User ${currentUser.id} is enrolled');
          return true;
        }
      }
      
      debugPrint('🔍 _checkIfUserIsEnrolled - ❌ No match found for user ${currentUser.id}');
    } catch (e) {
      // If there's any error (like AuthService not available), fallback to false
      // This prevents the app from crashing if auth service isn't initialized
      debugPrint('🔍 _checkIfUserIsEnrolled - Error: $e');
    }
    
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'category': category,
      'imageUrl': imageUrl,
      'isRegistered': isRegistered,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'organizerName': organizerName,
      'organizerId': organizerId,
      'tags': tags,
      'eventType': eventType,
      'isActive': isActive,
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'meetingLink': meetingLink,
      'additionalInfo': additionalInfo,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'endDate': endDate?.toIso8601String(),
      'endTime': endTime,
      'price': price,
      'images': images,
      'videos': videos,
      'slug': slug,
      'enrollments': enrollments,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? location,
    String? category,
    String? imageUrl,
    bool? isRegistered,
    int? maxParticipants,
    int? currentParticipants,
    String? organizerName,
    String? organizerId,
    List<String>? tags,
    String? eventType,
    bool? isActive,
    DateTime? registrationDeadline,
    String? meetingLink,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isRegistered: isRegistered ?? this.isRegistered,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      organizerName: organizerName ?? this.organizerName,
      organizerId: organizerId ?? this.organizerId,
      tags: tags ?? this.tags,
      eventType: eventType ?? this.eventType,
      isActive: isActive ?? this.isActive,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      meetingLink: meetingLink ?? this.meetingLink,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  bool get isPast {
    final now = DateTime.now();
    final eventDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventDate.isBefore(today);
  }

  bool get isToday {
    final now = DateTime.now();
    final eventDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventDate.isAtSameMomentAs(today);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final eventDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return eventDate.isAfter(today);
  }

  bool get isFull {
    return currentParticipants >= maxParticipants;
  }

  bool get canRegister {
    if (isPast || !isActive || isFull || isRegistered) return false;
    if (registrationDeadline != null && DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }
    return true;
  }

  double get participationPercentage {
    if (maxParticipants == 0) return 0.0;
    return currentParticipants / maxParticipants;
  }
}
