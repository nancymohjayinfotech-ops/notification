class IntroVideo {
  final String title;
  final String description;
  final String url;
  final int durationSeconds;
  final String? thumbnail;

  IntroVideo({
    required this.title,
    required this.description,
    required this.url,
    required this.durationSeconds,
    this.thumbnail,
  });

  factory IntroVideo.fromJson(Map<String, dynamic> json) {
    return IntroVideo(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      durationSeconds: json['durationSeconds'] is int ? json['durationSeconds'] : 0,
      thumbnail: json['thumbnail']?.toString(),
    );
  }
}

class Course {
  final String id;
  final String title;
  final String slug;
  final String description;
  final double price;
  final Instructor instructor;
  final String thumbnail;
  final Category category;
  final Subcategory subcategory;
  final String level;
  final bool published;
  final bool isFeatured;
  final List<EnrolledStudent> enrolledStudents;
  final List<Rating> ratings;
  final double averageRating;
  final int totalVideos;
  final int totalDuration;
  final List<CourseSection> sections;
  final IntroVideo? introVideo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deletedAt;

  Course({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.price,
    required this.instructor,
    required this.thumbnail,
    required this.category,
    required this.subcategory,
    required this.level,
    required this.published,
    required this.isFeatured,
    required this.enrolledStudents,
    required this.ratings,
    required this.averageRating,
    required this.totalVideos,
    required this.totalDuration,
    required this.sections,
    this.introVideo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    try {
      return Course(
        id: json['_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: _parseDouble(json['price']),
        instructor: _parseInstructor(json['instructor']),
        thumbnail: json['thumbnail']?.toString() ?? '',
        category: _parseCategory(json['category']),
        subcategory: _parseSubcategory(json['subcategory']),
        level: json['level']?.toString() ?? 'beginner',
        published: _parseBool(json['published']),
        isFeatured: _parseBool(json['isFeatured']),
        enrolledStudents: _parseEnrolledStudents(json['enrolledStudents']),
        ratings: _parseRatings(json['ratings']),
        averageRating: _parseDouble(json['averageRating']),
        totalVideos: _parseInt(json['totalVideos']),
        totalDuration: _parseInt(json['totalDuration']),
        sections: _parseSections(json['sections']),
        introVideo: _parseIntroVideo(json['introVideo']),
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
        deletedAt: json['deletedAt']?.toString(),
      );
    } catch (e) {
      print('Error parsing Course from JSON: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Instructor _parseInstructor(dynamic value) {
    if (value == null || value is! Map<String, dynamic>) {
      return Instructor(id: '', name: 'Unknown', email: '');
    }
    try {
      return Instructor.fromJson(value);
    } catch (e) {
      print('Error parsing instructor: $e');
      return Instructor(id: '', name: 'Unknown', email: '');
    }
  }

  static Category _parseCategory(dynamic value) {
    if (value == null || value is! Map<String, dynamic>) {
      return Category(id: '', name: 'Uncategorized');
    }
    try {
      return Category.fromJson(value);
    } catch (e) {
      print('Error parsing category: $e');
      return Category(id: '', name: 'Uncategorized');
    }
  }

  static Subcategory _parseSubcategory(dynamic value) {
    if (value == null || value is! Map<String, dynamic>) {
      return Subcategory(id: '', name: 'General');
    }
    try {
      return Subcategory.fromJson(value);
    } catch (e) {
      print('Error parsing subcategory: $e');
      return Subcategory(id: '', name: 'General');
    }
  }

  static List<EnrolledStudent> _parseEnrolledStudents(dynamic value) {
    if (value == null || value is! List) {
      print('EnrolledStudents is null or not a list: $value');
      return [];
    }
    try {
      print('Parsing ${value.length} enrolled students');
      final students = value
          .map((student) {
            try {
              return EnrolledStudent.fromJson(student);
            } catch (e) {
              print('Error parsing individual student: $e, data: $student');
              return null;
            }
          })
          .where((student) => student != null)
          .cast<EnrolledStudent>()
          .toList();
      print('Successfully parsed ${students.length} enrolled students');
      return students;
    } catch (e) {
      print('Error parsing enrolled students: $e');
      return [];
    }
  }

  static List<Rating> _parseRatings(dynamic value) {
    if (value == null || value is! List) return [];
    try {
      return value
          .map((rating) => Rating.fromJson(rating))
          .toList();
    } catch (e) {
      print('Error parsing ratings: $e');
      return [];
    }
  }

  static List<CourseSection> _parseSections(dynamic value) {
    if (value == null || value is! List) return [];
    try {
      return value
          .map((section) => CourseSection.fromJson(section))
          .toList();
    } catch (e) {
      print('Error parsing sections: $e');
      return [];
    }
  }

  static IntroVideo? _parseIntroVideo(dynamic value) {
    if (value == null || value is! Map<String, dynamic>) return null;
    try {
      return IntroVideo.fromJson(value);
    } catch (e) {
      print('Error parsing intro video: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'price': price,
      'instructor': instructor.toJson(),
      'thumbnail': thumbnail,
      'category': category.toJson(),
      'subcategory': subcategory.toJson(),
      'level': level,
      'published': published,
      'isFeatured': isFeatured,
      'enrolledStudents': enrolledStudents.map((s) => s.toJson()).toList(),
      'ratings': ratings.map((r) => r.toJson()).toList(),
      'averageRating': averageRating,
      'totalVideos': totalVideos,
      'totalDuration': totalDuration,
      'sections': sections.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    double? price,
    Instructor? instructor,
    String? thumbnail,
    Category? category,
    Subcategory? subcategory,
    String? level,
    bool? published,
    bool? isFeatured,
    List<EnrolledStudent>? enrolledStudents,
    List<Rating>? ratings,
    double? averageRating,
    int? totalVideos,
    int? totalDuration,
    List<CourseSection>? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deletedAt,
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
      isFeatured: isFeatured ?? this.isFeatured,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      ratings: ratings ?? this.ratings,
      averageRating: averageRating ?? this.averageRating,
      totalVideos: totalVideos ?? this.totalVideos,
      totalDuration: totalDuration ?? this.totalDuration,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class Instructor {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;

  Instructor({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
    };
  }
}

class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class Subcategory {
  final String id;
  final String name;

  Subcategory({
    required this.id,
    required this.name,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class EnrolledStudent {
  final String id;
  final String name;
  final String email;
  final String avatar;

  EnrolledStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory EnrolledStudent.fromJson(Map<String, dynamic> json) {
    print('Parsing enrolled student: $json');
    return EnrolledStudent(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}

class Rating {
  final int rating;
  final String review;
  final RatingUser user;
  final DateTime createdAt;
  final String id;

  Rating({
    required this.rating,
    required this.review,
    required this.user,
    required this.createdAt,
    required this.id,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      user: RatingUser.fromJson(json['user'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'review': review,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
      '_id': id,
    };
  }
}

class RatingUser {
  final String id;
  final String name;
  final String avatar;

  RatingUser({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory RatingUser.fromJson(Map<String, dynamic> json) {
    return RatingUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}

class CourseSection {
  final String id;
  final String title;
  final String description;
  final int order;
  final List<CourseVideo> videos;

  CourseSection({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.videos,
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    return CourseSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
      videos: (json['videos'] as List<dynamic>?)
          ?.map((video) => CourseVideo.fromJson(video))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }
}

class CourseVideo {
  final String id;
  final String title;
  final String description;
  final String url;
  final int durationSeconds;
  final int order;

  CourseVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.durationSeconds,
    required this.order,
  });

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    return CourseVideo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 0,
      order: json['order'] ?? 0,
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

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

enum CourseLevel {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case CourseLevel.beginner:
        return 'Beginner';
      case CourseLevel.intermediate:
        return 'Intermediate';
      case CourseLevel.advanced:
        return 'Advanced';
    }
  }
}