class CourseReview {
  final String? id;
  final int rating;
  final String review;
  final String? user;
  final DateTime? createdAt;

  CourseReview({
    this.id,
    required this.rating,
    required this.review,
    this.user,
    this.createdAt,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) {
    return CourseReview(
      id: json['_id'] ?? json['id'],
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      user: json['user'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'review': review,
      'user': user,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class CourseInstructor {
  final String? id;
  final String? name;
  final String? email;
  final String? avatar;
  final String? bio;

  CourseInstructor({this.id, this.name, this.email, this.avatar, this.bio});

  factory CourseInstructor.fromJson(Map<String, dynamic> json) {
    return CourseInstructor(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'avatar': avatar, 'bio': bio};
  }
}

class CourseCategory {
  final String? id;
  final String? name;

  CourseCategory({this.id, this.name});

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(id: json['_id'] ?? json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class CourseSubcategory {
  final String? id;
  final String? name;
  final String? description;
  final String? icon;

  CourseSubcategory({this.id, this.name, this.description, this.icon});

  factory CourseSubcategory.fromJson(Map<String, dynamic> json) {
    return CourseSubcategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'icon': icon};
  }
}

class CourseVideo {
  final String id;
  final String title;
  final String? description;
  final String url;
  final int? durationSeconds;
  final int? order;

  CourseVideo({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.durationSeconds,
    this.order,
  });

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    return CourseVideo(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Video',
      description: json['description'],
      url: json['url'] ?? '',
      durationSeconds: json['durationSeconds'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'durationSeconds': durationSeconds,
      'order': order,
    };
  }
}

class CourseSection {
  final String id;
  final String title;
  final String? description;
  final int? order;
  final int? videoCount;
  final List<CourseVideo> videos;

  CourseSection({
    required this.id,
    required this.title,
    this.description,
    this.order,
    this.videoCount,
    this.videos = const [],
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Section',
      description: json['description'],
      order: json['order'],
      videoCount: json['videoCount'],
      videos:
          (json['videos'] as List<dynamic>?)
              ?.map((v) => CourseVideo.fromJson(v))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'videoCount': videoCount,
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }
}

class Course {
  final String? id;
  final String title;
  final String? slug;
  final String description;
  final double price;
  final CourseInstructor? instructor;
  final String? thumbnail;
  final CourseCategory? category;
  final CourseSubcategory? subcategory;
  final String level;
  final bool published;
  final List<String> enrolledStudents;
  final int enrolledStudentsCount;
  final double averageRating;
  final CourseVideo? introVideo;
  final List<CourseSection> sections;
  final List<CourseReview> reviews;
  final int totalVideos;
  final int totalDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legacy fields for backward compatibility
  final String author;
  final String imageAsset;
  final double progress;
  final String progressText;
  final String students;
  final String duration;
  final List<String>? videoIds;
  final bool hasVideo;
  final String? language;

  Course({
    this.id,
    required this.title,
    this.slug,
    this.description = '',
    this.price = 0.0,
    this.instructor,
    this.thumbnail,
    this.category,
    this.subcategory,
    this.level = 'beginner',
    this.published = true,
    this.enrolledStudents = const [],
    this.enrolledStudentsCount = 0,
    this.averageRating = 0.0,
    this.introVideo,
    this.sections = const [],
    this.reviews = const [],
    this.totalVideos = 0,
    this.totalDuration = 0,
    this.createdAt,
    this.updatedAt,
    // Legacy fields with defaults
    String? author,
    String? imageAsset,
    this.progress = 0.0,
    this.progressText = '0% completed',
    String? students,
    String? duration,
    this.videoIds,
    bool? hasVideo,
    this.language,
  }) : author = author ?? instructor?.name ?? 'Unknown Instructor',
       imageAsset = imageAsset ?? _mapThumbnailToAsset(thumbnail),
       students = students ?? _formatStudentCount(enrolledStudents.length),
       duration = duration ?? _formatDurationFromMinutes(totalDuration),
       hasVideo = hasVideo ?? (introVideo != null || sections.isNotEmpty);

  // Helper method to format duration from minutes (API returns duration in minutes)
  static String _formatDurationFromMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0 min';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else {
      return '${minutes}m';
    }
  }

  // Helper method to format student count
  static String _formatStudentCount(int count) {
    if (count == 0) return '0 students';
    if (count == 1) return '1 student';
    if (count < 1000) return '$count students';
    if (count < 1000000) {
      final k = (count / 1000).toStringAsFixed(1);
      return '${k}k students';
    } else {
      final m = (count / 1000000).toStringAsFixed(1);
      return '${m}M students';
    }
  }

  // Helper method to map API thumbnail to local asset
  static String _mapThumbnailToAsset(String? thumbnail) {
    if (thumbnail == null || thumbnail.isEmpty) {
      return 'assets/images/developer.png';
    }

    // Map API thumbnails to local assets
    switch (thumbnail.toLowerCase()) {
      case 'default-course.jpg':
      case 'flutter.jpg':
      case 'flutter.png':
        return 'assets/images/developer.png';
      case 'design.jpg':
      case 'design.png':
      case 'ui-ux.jpg':
        return 'assets/images/tester.jpg';
      case 'marketing.jpg':
      case 'marketing.png':
        return 'assets/images/splash1.png';
      case 'react.jpg':
      case 'react.png':
      case 'react-native.jpg':
        return 'assets/images/devop.jpg';
      case 'python.jpg':
      case 'python.png':
      case 'data-science.jpg':
        return 'assets/images/homescreen.png';
      default:
        return 'assets/images/developer.png';
    }
  }

  // Legacy helper method to format duration from seconds (kept for backward compatibility)
  static String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0 min';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Helper methods to safely parse nested objects that might be strings or objects
  static CourseInstructor? _parseInstructor(dynamic instructorData) {
    if (instructorData == null) return null;
    if (instructorData is String) {
      // If it's just an ID string, create a minimal instructor object
      return CourseInstructor(id: instructorData, name: 'Unknown Instructor');
    }
    if (instructorData is Map<String, dynamic>) {
      return CourseInstructor.fromJson(instructorData);
    }
    return null;
  }

  static CourseCategory? _parseCategory(dynamic categoryData) {
    if (categoryData == null) return null;
    if (categoryData is String) {
      // If it's just an ID string, create a minimal category object
      return CourseCategory(id: categoryData, name: 'Unknown Category');
    }
    if (categoryData is Map<String, dynamic>) {
      return CourseCategory.fromJson(categoryData);
    }
    return null;
  }

  static CourseSubcategory? _parseSubcategory(dynamic subcategoryData) {
    if (subcategoryData == null) return null;
    if (subcategoryData is String) {
      // If it's just an ID string, create a minimal subcategory object
      return CourseSubcategory(
        id: subcategoryData,
        name: 'Unknown Subcategory',
      );
    }
    if (subcategoryData is Map<String, dynamic>) {
      return CourseSubcategory.fromJson(subcategoryData);
    }
    return null;
  }

  static CourseVideo? _parseIntroVideo(dynamic videoData) {
    if (videoData == null) return null;
    if (videoData is String) {
      // If it's just an ID string, skip it (can't create a meaningful video object)
      return null;
    }
    if (videoData is Map<String, dynamic>) {
      try {
        return CourseVideo.fromJson(videoData);
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }
    return null;
  }

  static List<CourseSection> _parseSections(dynamic sectionsData) {
    if (sectionsData == null) return [];
    if (sectionsData is! List) return [];
    
    final List<CourseSection> sections = [];
    for (final sectionData in sectionsData) {
      if (sectionData is Map<String, dynamic>) {
        try {
          sections.add(CourseSection.fromJson(sectionData));
        } catch (e) {
          // Skip invalid sections
          continue;
        }
      }
    }
    return sections;
  }

    static List<CourseReview> _parseReviews(dynamic ratingsData) {
    if (ratingsData == null) return [];
    
    // Handle direct array of ratings from API
    if (ratingsData is List) {
      final List<CourseReview> reviews = [];
      for (final reviewData in ratingsData) {
        if (reviewData is Map<String, dynamic>) {
          try {
            reviews.add(CourseReview.fromJson(reviewData));
          } catch (e) {
            // Skip invalid reviews
            continue;
          }
        }
      }
      return reviews;
    }
    
    // Handle nested structure { reviews: [...] }
    if (ratingsData is Map<String, dynamic>) {
      final reviewsData = ratingsData['reviews'];
      if (reviewsData != null && reviewsData is List) {
        final List<CourseReview> reviews = [];
        for (final reviewData in reviewsData) {
          if (reviewData is Map<String, dynamic>) {
            try {
              reviews.add(CourseReview.fromJson(reviewData));
            } catch (e) {
              // Skip invalid reviews
              continue;
            }
          }
        }
        return reviews;
      }
    }
    
    return [];
  }

  static double _parseAverageRating(Map<String, dynamic> json) {
    // Try different possible rating fields in order of preference
    
    // First, try direct rating field
    if (json['rating'] != null) {
      final rating = double.tryParse(json['rating'].toString());
      if (rating != null) return rating;
    }
    
    // Then try ratings.average field (this is where the error was occurring)
    if (json['ratings'] != null && json['ratings'] is Map<String, dynamic>) {
      final ratingsMap = json['ratings'] as Map<String, dynamic>;
      if (ratingsMap['average'] != null) {
        final average = double.tryParse(ratingsMap['average'].toString());
        if (average != null) return average;
      }
    }
    
    // Finally try averageRating field
    if (json['averageRating'] != null) {
      final avgRating = double.tryParse(json['averageRating'].toString());
      if (avgRating != null) return avgRating;
    }
    
    // Default to 0.0 if all parsing fails
    return 0.0;
  }

  // Factory constructor from API JSON response
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      slug: json['slug'],
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      instructor: _parseInstructor(json['instructor']),
      thumbnail: json['thumbnail'],
      category: _parseCategory(json['category']),
      subcategory: _parseSubcategory(json['subcategory']),
      level: json['level'] ?? 'beginner',
      published: json['published'] ?? true,
      enrolledStudents: json['enrolledStudents'] != null
          ? List<String>.from(json['enrolledStudents'])
          : [],
      enrolledStudentsCount: json['enrollmentCount'] ?? json['enrolledStudentsCount'] ?? 0,
      averageRating: _parseAverageRating(json),
      introVideo: _parseIntroVideo(json['introVideo']),
      sections: _parseSections(json['sections']),
      reviews: _parseReviews(json['ratings']),
      totalVideos: json['videoCount'] ?? json['totalVideos'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert Course to JSON for API
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'price': price,
      'instructor': instructor?.toJson(),
      'thumbnail': thumbnail,
      'category': category?.toJson(),
      'subcategory': subcategory?.toJson(),
      'level': level,
      'published': published,
      'enrolledStudents': enrolledStudents,
      'averageRating': averageRating,
      'introVideo': introVideo?.toJson(),
      'sections': sections.map((s) => s.toJson()).toList(),
      'totalVideos': totalVideos,
      'totalDuration': totalDuration,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Convert Course to Map for storage (legacy compatibility)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'imageAsset': imageAsset,
      'progress': progress,
      'progressText': progressText,
      'price': price.toString(),
      'rating': averageRating,
      'students': students,
      'duration': duration,
      'description': description,
      'videoIds': videoIds,
      'hasVideo': hasVideo,
      'category': category?.name,
      'level': level,
      'language': language,
      'id': id,
    };
  }

  // Create Course from Map (legacy compatibility)
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      imageAsset: map['imageAsset'] ?? '',
      progress: map['progress']?.toDouble() ?? 0.0,
      progressText: map['progressText'] ?? '0% completed',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      students: map['students'] ?? '0',
      duration: map['duration'] ?? '0 min',
      description: map['description'] ?? '',
      videoIds: map['videoIds'] != null
          ? List<String>.from(map['videoIds'])
          : null,
      hasVideo: map['hasVideo'] ?? false,
      level: map['level'] ?? 'beginner',
      language: map['language'],
      id: map['id'],
      averageRating: map['rating']?.toDouble() ?? 0.0,
    );
  }

  // Getters for compatibility with search service
  String get imageUrl => imageAsset;
  String get instructorName => author;
  double get rating => averageRating;

  // Create a copy with updated fields
  Course copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    double? price,
    CourseInstructor? instructor,
    String? thumbnail,
    CourseCategory? category,
    CourseSubcategory? subcategory,
    String? level,
    bool? published,
    List<String>? enrolledStudents,
    double? averageRating,
    CourseVideo? introVideo,
    List<CourseSection>? sections,
    int? totalVideos,
    int? totalDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Legacy fields
    String? author,
    String? imageAsset,
    double? progress,
    String? progressText,
    String? students,
    String? duration,
    List<String>? videoIds,
    bool? hasVideo,
    String? language,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      price: price ?? this.price,
      instructor: instructor ?? this.instructor,
      thumbnail: thumbnail ?? this.thumbnail,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      level: level ?? this.level,
      published: published ?? this.published,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      averageRating: averageRating ?? this.averageRating,
      introVideo: introVideo ?? this.introVideo,
      sections: sections ?? this.sections,
      totalVideos: totalVideos ?? this.totalVideos,
      totalDuration: totalDuration ?? this.totalDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Legacy fields
      author: author ?? this.author,
      imageAsset: imageAsset ?? this.imageAsset,
      progress: progress ?? this.progress,
      progressText: progressText ?? this.progressText,
      students: students ?? this.students,
      duration: duration ?? this.duration,
      videoIds: videoIds ?? this.videoIds,
      hasVideo: hasVideo ?? this.hasVideo,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id && other.title == title;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
