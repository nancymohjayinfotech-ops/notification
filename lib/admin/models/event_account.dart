class EventAccount {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? state;
  final String? city;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.dateOfBirth,
    this.state,
    this.city,
    required this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory EventAccount.fromJson(Map<String, dynamic> json) {
    return EventAccount(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      dateOfBirth: json['dob'] ?? json['dateOfBirth'],
      state: json['state'],
      city: json['city'],
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'state': state,
      'city': city,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  EventAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? state,
    String? city,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      state: state ?? this.state,
      city: city ?? this.city,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
