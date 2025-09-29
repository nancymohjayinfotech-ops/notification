import 'package:flutter/material.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String venue;
  final DateTime dateTime;
  final int maxAttendees;
  final double? price;
  final String? contactEmail;
  final String? contactPhone;
  final String? meetingLink;
  final List<String> tags;
  final EventMode mode;
  final EventCategory category;
  final List<String> resources;
  final String? imageUrl;
  final List<String> images;
  final List<String> videos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentAttendees;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.dateTime,
    required this.maxAttendees,
    this.price,
    this.contactEmail,
    this.contactPhone,
    this.meetingLink,
    required this.tags,
    required this.mode,
    required this.category,
    required this.resources,
    this.imageUrl,
    this.images = const [],
    this.videos = const [],
    required this.createdAt,
    required this.updatedAt,
    this.currentAttendees = 0,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? venue,
    DateTime? dateTime,
    int? maxAttendees,
    double? price,
    String? contactEmail,
    String? contactPhone,
    String? meetingLink,
    List<String>? tags,
    EventMode? mode,
    EventCategory? category,
    List<String>? resources,
    String? imageUrl,
    List<String>? images,
    List<String>? videos,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentAttendees,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      dateTime: dateTime ?? this.dateTime,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      price: price ?? this.price,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      meetingLink: meetingLink ?? this.meetingLink,
      tags: tags ?? this.tags,
      mode: mode ?? this.mode,
      category: category ?? this.category,
      resources: resources ?? this.resources,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentAttendees: currentAttendees ?? this.currentAttendees,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'venue': venue,
      'dateTime': dateTime.toIso8601String(),
      'maxAttendees': maxAttendees,
      'price': price,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'meetingLink': meetingLink,
      'tags': tags,
      'mode': mode.name,
      'category': category.name,
      'resources': resources,
      'imageUrl': imageUrl,
      'images': images,
      'videos': videos,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'currentAttendees': currentAttendees,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      venue: json['venue'],
      dateTime: DateTime.parse(json['dateTime']),
      maxAttendees: json['maxAttendees'],
      price: json['price']?.toDouble(),
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      meetingLink: json['meetingLink'],
      tags: List<String>.from(json['tags'] ?? []),
      mode: EventMode.values.firstWhere((e) => e.name == json['mode']),
      category: EventCategory.values.firstWhere((e) => e.name == json['category']),
      resources: List<String>.from(json['resources'] ?? []),
      imageUrl: json['imageUrl'],
      images: _parseImageUrls(json['images']),
      videos: _parseVideoUrls(json['videos']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      currentAttendees: json['currentAttendees'] ?? 0,
    );
  }

  // Helper method to parse image URLs from backend response
  static List<String> _parseImageUrls(dynamic imagesData) {
    if (imagesData == null) return [];
    
    List<String> imageUrls = [];
    
    if (imagesData is List) {
      for (var item in imagesData) {
        if (item is String) {
          // Parse the stringified object to extract URL
          String imageString = item;
          RegExp urlRegex = RegExp(r'url:\s*([^,}]+)');
          Match? match = urlRegex.firstMatch(imageString);
          if (match != null) {
            String url = match.group(1)!.trim();
            imageUrls.add(url);
          }
        }
      }
    }
    
    return imageUrls;
  }

  // Helper method to parse video URLs from backend response
  static List<String> _parseVideoUrls(dynamic videosData) {
    if (videosData == null) return [];
    
    List<String> videoUrls = [];
    
    if (videosData is List) {
      for (var item in videosData) {
        if (item is String) {
          // Parse the stringified object to extract URL
          String videoString = item;
          RegExp urlRegex = RegExp(r'url:\s*([^,}]+)');
          Match? match = urlRegex.firstMatch(videoString);
          if (match != null) {
            String url = match.group(1)!.trim();
            videoUrls.add(url);
          }
        }
      }
    }
    
    return videoUrls;
  }
}

enum EventMode {
  online,
  offline,
  hybrid,
}

enum EventCategory {
  workshop,
  seminar,
  conference,
  training,
  webinar,
  meeting,
  networking,
  other,
}

extension EventModeExtension on EventMode {
  String get displayName {
    switch (this) {
      case EventMode.online:
        return 'Online';
      case EventMode.offline:
        return 'Offline';
      case EventMode.hybrid:
        return 'Hybrid';
    }
  }

  IconData get icon {
    switch (this) {
      case EventMode.online:
        return Icons.computer;
      case EventMode.offline:
        return Icons.location_on;
      case EventMode.hybrid:
        return Icons.hub;
    }
  }
}

extension EventCategoryExtension on EventCategory {
  String get displayName {
    switch (this) {
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.conference:
        return 'Conference';
      case EventCategory.training:
        return 'Training';
      case EventCategory.webinar:
        return 'Webinar';
      case EventCategory.meeting:
        return 'Meeting';
      case EventCategory.networking:
        return 'Networking';
      case EventCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case EventCategory.workshop:
        return const Color(0xFF4CAF50);
      case EventCategory.seminar:
        return const Color(0xFF2196F3);
      case EventCategory.conference:
        return const Color(0xFF9C27B0);
      case EventCategory.training:
        return const Color(0xFFFF9800);
      case EventCategory.webinar:
        return const Color(0xFF00BCD4);
      case EventCategory.meeting:
        return const Color(0xFF795548);
      case EventCategory.networking:
        return const Color(0xFFE91E63);
      case EventCategory.other:
        return const Color(0xFF607D8B);
    }
  }
}
