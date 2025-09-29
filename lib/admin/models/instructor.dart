class Instructor {
  final String id;
  String name;
  String email;
  String phoneNumber;
  String? avatar;
  bool isActive;
  bool isVerified;
  List<String> skills;
  String bio;
  String? role;

  Instructor({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.avatar,
    required this.isActive,
    this.isVerified = false,
    required this.skills,
    required this.bio,
    this.role,
  });

  // Factory constructor to create from API response
  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      avatar: json['avatar'],
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      skills: List<String>.from(json['skills'] ?? []),
      bio: json['bio'] ?? '',
      role: json['role'],
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'isActive': isActive,
      'isVerified': isVerified,
      'skills': skills,
      'bio': bio,
      'role': role,
    };
  }

  // Sample data for testing (will be replaced by API data)
  static List<Instructor> getSampleInstructors() {
    return [
      Instructor(
        id: '1',
        name: 'John Smith',
        email: 'john.smith@example.com',
        phoneNumber: '+1 234 567 8900',
        avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        isActive: true,
        skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'State Management'],
        bio: 'Experienced Flutter developer with 8+ years in mobile app development. Passionate about creating beautiful and functional mobile applications.',
        role: 'instructor',
      ),
      Instructor(
        id: '2',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@example.com',
        phoneNumber: '+1 234 567 8901',
        avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        isActive: true,
        skills: ['React', 'Node.js', 'JavaScript', 'TypeScript', 'MongoDB'],
        bio: 'Full-stack web developer specializing in React and Node.js. Love teaching modern web technologies and best practices.',
        role: 'instructor',
      ),
      Instructor(
        id: '3',
        name: 'Michael Chen',
        email: 'michael.chen@example.com',
        phoneNumber: '+1 234 567 8902',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        isActive: true,
        skills: ['Python', 'Machine Learning', 'TensorFlow', 'Pandas', 'SQL'],
        bio: 'Data scientist with expertise in machine learning and AI. Passionate about making complex concepts accessible to everyone.',
        role: 'instructor',
      ),
    ];
  }

  String get initials {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }
}
