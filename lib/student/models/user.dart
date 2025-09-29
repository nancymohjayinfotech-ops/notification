import 'user_role.dart'; // Import the UserRole enum

class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String avatar;
  final UserRole role; // Changed from String to UserRole enum
  final String? bio;
  final String? college;
  final String? studentId;
  final String? address;
  final DateTime joinDate;
  final bool isVerified;
  final String? password; // Optional for backward compatibility

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.avatar,
    required this.role,
    this.bio,
    this.college,
    this.studentId,
    this.address,
    required this.joinDate,
    required this.isVerified,
    this.password,
  });

  // Convert User to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'role': role.toString().split('.').last, // Store enum as string
      'bio': bio,
      'college': college,
      'studentId': studentId,
      'address': address,
      'joinDate': joinDate.toIso8601String(),
      'isVerified': isVerified,
      'password': password,
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    final phoneNumber = map['phoneNumber'] ?? '';
    
    // Parse role from string to enum
    UserRole userRole;
    try {
      userRole = UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}' || 
               e.toString().split('.').last == map['role'],
        orElse: () => UserRole.everyone,
      );
    } catch (e) {
      userRole = UserRole.everyone;
    }

    return User(
      id: map['_id'] ?? map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
      avatar: map['avatar'] ?? 'assets/default_avatar.png',
      role: userRole,
      bio: map['bio'] ?? '',
      college: map['college'] ?? '',
      studentId: map['studentId'] ?? '',
      address: map['address'] ?? '',
      joinDate: DateTime.tryParse(map['createdAt'] ?? map['joinDate'] ?? '') ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      password: map['password'],
    );
  }

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatar,
    UserRole? role,
    String? bio,
    String? college,
    String? studentId,
    String? address,
    DateTime? joinDate,
    bool? isVerified,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      college: college ?? this.college,
      studentId: studentId ?? this.studentId,
      address: address ?? this.address,
      joinDate: joinDate ?? this.joinDate,
      isVerified: isVerified ?? this.isVerified,
      password: password ?? this.password,
    );
  }

  // Check if user needs phone verification
  bool get needsPhoneVerification => phoneNumber == null || phoneNumber!.isEmpty;

  // Get user role as string for display
  String get roleName {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.instructor:
        return 'Instructor';
      case UserRole.eventOrganizer:
        return 'Event Organizer';
      case UserRole.everyone:
        return 'General User';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $roleName, phone: $phoneNumber)';
  }
}

// Legacy support - keeping for backward compatibility
List<User> registeredUsers = [];