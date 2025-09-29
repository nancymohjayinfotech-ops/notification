import 'package:flutter/material.dart';

class DashboardResponse {
  final bool success;
  final String message;
  final DashboardData data;

  DashboardResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: DashboardData.fromJson(json['data'] ?? {}),
    );
  }
}

class DashboardData {
  final List<EventItem> today;
  final List<EventItem> upcoming;
  final List<EventItem> past;
  final EventSummary summary;

  DashboardData({
    required this.today,
    required this.upcoming,
    required this.past,
    required this.summary,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      today: (json['today'] as List<dynamic>?)
          ?.map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      upcoming: (json['upcoming'] as List<dynamic>?)
          ?.map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      past: (json['past'] as List<dynamic>?)
          ?.map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      summary: EventSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class EventItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String location;
  final String eventType;
  final DateTime startDate;
  final String startTime;
  final DateTime endDate;
  final String endTime;
  final DateTime registrationDeadline;
  final int maxParticipants;
  final double price;
  final List<String> tags;
  final List<String> images;
  final List<String> videos;
  final EventCreator createdBy;
  final bool isActive;
  final List<dynamic> enrollments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String slug;
  final ParticipantStats participantStats;

  EventItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.eventType,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.registrationDeadline,
    required this.maxParticipants,
    required this.price,
    required this.tags,
    required this.images,
    required this.videos,
    required this.createdBy,
    required this.isActive,
    required this.enrollments,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    required this.participantStats,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['_id'] ?? '',
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      eventType: json['eventType'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] ?? '',
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] ?? '',
      registrationDeadline: DateTime.parse(json['registrationDeadline'] ?? DateTime.now().toIso8601String()),
      maxParticipants: json['maxParticipants'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      createdBy: EventCreator.fromJson(json['createdBy'] ?? {}),
      isActive: json['isActive'] ?? false,
      enrollments: json['enrollments'] ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      slug: json['slug'] ?? '',
      participantStats: ParticipantStats.fromJson(json['participantStats'] ?? {}),
    );
  }

  // Helper methods to convert to the format expected by your UI
  Map<String, dynamic> toHomePageFormat() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'time': '$startTime - $endTime',
      'startTime': startTime,
      'endTime': endTime,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'attendees': participantStats.totalEnrollments,
      'category': _mapCategoryToUI(category),
      'color': _getCategoryColor(category),
      'date': _formatDate(startDate),
      'image': images.isNotEmpty ? images.first : 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
      'description': description,
      'eventType': eventType,
      'price': price,
      'maxParticipants': maxParticipants,
      'availableSpots': participantStats.availableSpots,
    };
  }

  String _mapCategoryToUI(String apiCategory) {
    switch (apiCategory.toLowerCase()) {
      case 'conference':
        return 'Technical';
      case 'workshop':
        return 'Academic';
      case 'cultural':
        return 'Cultural';
      default:
        return 'Technical';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'conference':
        return const Color(0xFF6C5CE7);
      case 'workshop':
        return const Color(0xFF00B894);
      case 'cultural':
        return const Color(0xFFE17055);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                   'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class EventCreator {
  final String id;
  final String name;
  final String email;

  EventCreator({
    required this.id,
    required this.name,
    required this.email,
  });

  factory EventCreator.fromJson(Map<String, dynamic> json) {
    return EventCreator(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class ParticipantStats {
  final int totalEnrollments;
  final int approvedParticipants;
  final int pendingRequests;
  final int availableSpots;

  ParticipantStats({
    required this.totalEnrollments,
    required this.approvedParticipants,
    required this.pendingRequests,
    required this.availableSpots,
  });

  factory ParticipantStats.fromJson(Map<String, dynamic> json) {
    return ParticipantStats(
      totalEnrollments: json['totalEnrollments'] ?? 0,
      approvedParticipants: json['approvedParticipants'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
    );
  }
}

class EventSummary {
  final int todayCount;
  final int upcomingCount;
  final int pastCount;
  final int totalActiveEvents;

  EventSummary({
    required this.todayCount,
    required this.upcomingCount,
    required this.pastCount,
    required this.totalActiveEvents,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    return EventSummary(
      todayCount: json['todayCount'] ?? 0,
      upcomingCount: json['upcomingCount'] ?? 0,
      pastCount: json['pastCount'] ?? 0,
      totalActiveEvents: json['totalActiveEvents'] ?? 0,
    );
  }
}
