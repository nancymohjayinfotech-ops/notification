class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String? avatar;
  final String bio;
  final String dob;
  final String state;
  final String city;
  final String college;
  final String studentId;
  final String address;
  final bool isInterestsSet;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotificationPreferences notificationPreferences;
  final Interests interests;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.avatar,
    required this.bio,
    required this.dob,
    required this.state,
    required this.city,
    required this.college,
    required this.studentId,
    required this.address,
    required this.isInterestsSet,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.notificationPreferences,
    required this.interests,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'] ?? '',
      dob: json['dob'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      college: json['college'] ?? '',
      studentId: json['studentId'] ?? '',
      address: json['address'] ?? '',
      isInterestsSet: json['isInterestsSet'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      notificationPreferences: NotificationPreferences.fromJson(
        json['notificationPreferences'] ?? {},
      ),
      interests: Interests.fromJson(json['interests'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'avatar': avatar,
      'bio': bio,
      'dob': dob,
      'state': state,
      'city': city,
      'college': college,
      'studentId': studentId,
      'address': address,
      'isInterestsSet': isInterestsSet,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notificationPreferences': notificationPreferences.toJson(),
      'interests': interests.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? avatar,
    String? bio,
    String? dob,
    String? state,
    String? city,
    String? college,
    String? studentId,
    String? address,
    bool? isInterestsSet,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    NotificationPreferences? notificationPreferences,
    Interests? interests,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      dob: dob ?? this.dob,
      state: state ?? this.state,
      city: city ?? this.city,
      college: college ?? this.college,
      studentId: studentId ?? this.studentId,
      address: address ?? this.address,
      isInterestsSet: isInterestsSet ?? this.isInterestsSet,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      interests: interests ?? this.interests,
    );
  }
}

class NotificationPreferences {
  final bool session;
  final bool messages;
  final bool feedBack;
  final bool newEnrollments;
  final bool reviews;

  const NotificationPreferences({
    required this.session,
    required this.messages,
    required this.feedBack,
    required this.newEnrollments,
    required this.reviews,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      session: json['session'] ?? true,
      messages: json['messages'] ?? true,
      feedBack: json['feedBack'] ?? true,
      newEnrollments: json['newEnrollments'] ?? true,
      reviews: json['reviews'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'messages': messages,
      'feedBack': feedBack,
      'newEnrollments': newEnrollments,
      'reviews': reviews,
    };
  }
}

class Interests {
  final List<String> categories;
  final List<String> subcategories;

  const Interests({
    required this.categories,
    required this.subcategories,
  });

  factory Interests.fromJson(Map<String, dynamic> json) {
    return Interests(
      categories: List<String>.from(json['categories'] ?? []),
      subcategories: List<String>.from(json['subcategories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'subcategories': subcategories,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final AuthData data;

  const AuthResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: AuthData.fromJson(json['data'] ?? {}),
    );
  }
}

class AuthData {
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final String? phoneNumber;
  final int? expiresIn;
  final String? otp;

  const AuthData({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.phoneNumber,
    this.expiresIn,
    this.otp,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      phoneNumber: json['phoneNumber'],
      expiresIn: json['expiresIn'],
      otp: json['otp'],
    );
  }
}
