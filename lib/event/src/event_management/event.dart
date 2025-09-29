import 'package:equatable/equatable.dart';

enum EventMode { online, offline, hybrid }

enum EventCategory {
  academic,
  cultural,
  technical,
  workshop,
  seminar,
  webinar,
  conference,
  sports,
  social,
  other,
}

class ParticipantStats extends Equatable {
  final int totalEnrollments;
  final int approvedParticipants;
  final int pendingRequests;
  final int declinedRequests;
  final int availableSpots;

  const ParticipantStats({
    required this.totalEnrollments,
    required this.approvedParticipants,
    required this.pendingRequests,
    required this.declinedRequests,
    required this.availableSpots,
  });

  factory ParticipantStats.fromJson(Map<String, dynamic> json) {
    return ParticipantStats(
      totalEnrollments: json['totalEnrollments'] ?? 0,
      approvedParticipants: json['approvedParticipants'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      declinedRequests: json['declinedRequests'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEnrollments': totalEnrollments,
      'approvedParticipants': approvedParticipants,
      'pendingRequests': pendingRequests,
      'declinedRequests': declinedRequests,
      'availableSpots': availableSpots,
    };
  }

  @override
  List<Object?> get props => [
    totalEnrollments,
    approvedParticipants,
    pendingRequests,
    declinedRequests,
    availableSpots,
  ];
}

class CreatedBy extends Equatable {
  final String id;
  final String name;
  final String email;

  const CreatedBy({required this.id, required this.name, required this.email});

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'email': email};
  }

  @override
  List<Object?> get props => [id, name, email];
}

class Event extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final List<String> images;
  final List<String> videos;
  final CreatedBy createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String slug;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? startTime;
  final String? endTime;

  // Legacy fields for backward compatibility
  final DateTime? dateTime;
  final DateTime? endDateTime;
  final String? venue;
  final EventMode? mode;
  final EventCategory? category;
  final List<String> resources;
  final String? imageUrl;
  final double? price;
  final int? maxAttendees;
  final int? currentAttendees;
  final String? organizerId;
  final String? organizerName;
  final List<String> tags;
  final String? meetingLink;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime? registrationDeadline;
  final ParticipantStats? participantStats;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.images,
    required this.videos,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.dateTime,
    this.endDateTime,
    this.venue,
    this.mode,
    this.category,
    this.resources = const [],
    this.imageUrl,
    this.price,
    this.maxAttendees,
    this.currentAttendees,
    this.organizerId,
    this.organizerName,
    this.tags = const [],
    this.meetingLink,
    this.contactEmail,
    this.contactPhone,
    this.registrationDeadline,
    this.participantStats,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? endDateTime,
    String? venue,
    EventMode? mode,
    EventCategory? category,
    List<String>? resources,
    String? imageUrl,
    double? price,
    int? maxAttendees,
    int? currentAttendees,
    String? organizerId,
    String? organizerName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? meetingLink,
    String? contactEmail,
    String? contactPhone,
    String? slug,
    DateTime? registrationDeadline,
    ParticipantStats? participantStats,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location,
      images: images,
      videos: videos,
      createdBy: createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      venue: venue ?? this.venue,
      mode: mode ?? this.mode,
      category: category ?? this.category,
      resources: resources ?? this.resources,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      tags: tags ?? this.tags,
      meetingLink: meetingLink ?? this.meetingLink,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      participantStats: participantStats ?? this.participantStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'images': images,
      'videos': videos,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'eventType': mode?.name,
      'category': category?.name,
      'maxParticipants': maxAttendees,
      'price': price,
      'tags': tags,
      'isActive': isActive,
      // Legacy fields for backward compatibility
      'dateTime': dateTime?.toIso8601String(),
      'venue': venue,
      'mode': mode?.name,
      'resources': resources,
      'imageUrl': imageUrl,
      'currentAttendees': currentAttendees,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'meetingLink': meetingLink,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      location: json['location'] ?? 'TBD',
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      createdBy: const CreatedBy(id: '', name: 'Unknown', email: ''),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      slug: json['slug'] ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : null,
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'])
          : null,
      venue: json['venue'],
      mode: json['mode'] != null
          ? EventMode.values.firstWhere(
              (e) => e.name == json['mode'],
              orElse: () => EventMode.online,
            )
          : null,
      category: json['category'] != null
          ? EventCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => EventCategory.technical,
            )
          : null,
      resources: List<String>.from(json['resources'] ?? []),
      imageUrl: json['imageUrl'],
      price: json['price']?.toDouble(),
      maxAttendees: json['maxAttendees'],
      currentAttendees: json['currentAttendees'] ?? 0,
      organizerId: json['organizerId'],
      organizerName: json['organizerName'],
      tags: List<String>.from(json['tags'] ?? []),
      meetingLink: json['meetingLink'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      participantStats: json['participantStats'] != null
          ? ParticipantStats.fromJson(json['participantStats'])
          : null,
    );
  }

  /// Factory method to create Event from API response
  factory Event.fromApiJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(
      json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
    final updatedAt = DateTime.parse(
      json['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
    late final CreatedBy createdBy;
    if (json['createdBy'] is Map<String, dynamic>) {
      createdBy = CreatedBy.fromJson(json['createdBy'] as Map<String, dynamic>);
    } else if (json['createdBy'] is String) {
      createdBy = CreatedBy(
        id: json['createdBy'] as String,
        name: 'Unknown',
        email: '',
      );
    } else {
      createdBy = const CreatedBy(id: '', name: 'Unknown', email: '');
    }
    final images = List<String>.from(json['images'] ?? []);
    final videos = List<String>.from(json['videos'] ?? []);

    // Parse start and end dates
    DateTime? startDate;
    DateTime? endDate;
    DateTime? eventDateTime;

    if (json['startDate'] != null) {
      startDate = DateTime.parse(json['startDate']);
      // Also create combined dateTime for backward compatibility
      if (json['startTime'] != null) {
        final timeString = json['startTime'] as String;
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          eventDateTime = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
            hour,
            minute,
          );
        }
      }
    }

    if (json['endDate'] != null) {
      endDate = DateTime.parse(json['endDate']);
    }

    // Map eventType to EventMode
    EventMode eventMode = EventMode.offline;
    if (json['eventType'] != null) {
      switch (json['eventType'].toString().toLowerCase()) {
        case 'online':
          eventMode = EventMode.online;
          break;
        case 'hybrid':
          eventMode = EventMode.hybrid;
          break;
        default:
          eventMode = EventMode.offline;
      }
    }

    // Map category string to EventCategory enum
    EventCategory eventCategory = EventCategory.other;
    if (json['category'] != null) {
      final categoryStr = json['category'].toString().toLowerCase();
      switch (categoryStr) {
        case 'academic':
          eventCategory = EventCategory.academic;
          break;
        case 'cultural':
          eventCategory = EventCategory.cultural;
          break;
        case 'technical':
          eventCategory = EventCategory.technical;
          break;
        case 'workshop':
          eventCategory = EventCategory.workshop;
          break;
        case 'seminar':
          eventCategory = EventCategory.seminar;
          break;
        case 'webinar':
          eventCategory = EventCategory.webinar;
          break;
        case 'conference':
          eventCategory = EventCategory.conference;
          break;
        case 'sports':
          eventCategory = EventCategory.sports;
          break;
        case 'social':
          eventCategory = EventCategory.social;
          break;
        default:
          eventCategory = EventCategory.other;
      }
    }

    // Parse participant stats
    ParticipantStats? participantStats;
    if (json['participantStats'] != null) {
      participantStats = ParticipantStats.fromJson(json['participantStats']);
    }

    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      location: json['location'] ?? 'TBD',
      images: images,
      videos: videos,
      createdBy: createdBy,
      isActive: json['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
      slug: json['slug'] ?? '',
      startDate: startDate,
      endDate: endDate,
      startTime: json['startTime'],
      endTime: json['endTime'],
      // Map API fields to legacy fields
      dateTime: eventDateTime ?? createdAt,
      venue: json['location'] ?? 'TBD',
      mode: eventMode,
      category: eventCategory,
      maxAttendees: json['maxParticipants'] ?? 100,
      currentAttendees: json['enrollments']?.length ?? 0,
      price: json['price']?.toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      resources: const [],
      imageUrl: images.isNotEmpty ? images.first : null,
      organizerName: createdBy.name,
      contactEmail: createdBy.email.isNotEmpty ? createdBy.email : null,
      contactPhone: null,
      meetingLink: null,
      participantStats: participantStats,
    );
  }

  // Add this static method or getter:
  static Event empty() {
    return Event(
      id: '',
      title: '',
      description: '',
      location: '',
      dateTime: null,
      category: EventCategory.other,
      mode: EventMode.offline,
      resources: [],
      images: [],
      videos: [],
      createdBy: const CreatedBy(id: '', name: 'Unknown', email: ''),
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      slug: '',
      tags: [],
      imageUrl: null,
      price: null,
      maxAttendees: null,
      currentAttendees: null,
      organizerId: null,
      organizerName: null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    dateTime,
    venue,
    mode,
    category,
    resources,
    imageUrl,
    price,
    maxAttendees,
    currentAttendees,
    organizerId,
    organizerName,
    isActive,
    createdAt,
    updatedAt,
    tags,
    meetingLink,
    contactEmail,
    contactPhone,
    location,
    images,
    videos,
    createdBy,
    slug,
    startDate,
    endDate,
    startTime,
    endTime,
    participantStats,
  ];
}
