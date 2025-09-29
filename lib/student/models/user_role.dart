// user_role.dart
enum UserRole {
  student,
  instructor,
  eventOrganizer,
  everyone,
}

// Extension for easy conversion to string
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
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
  
  String get value {
    return toString().split('.').last;
  }
}