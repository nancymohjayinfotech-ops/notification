class Group {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final List<String> instructorIds;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color;
  final String? image;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.instructorIds,
    required this.studentIds,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.image,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      adminId: json['admin']?['_id'] ?? json['admin'] ?? '',
      instructorIds: _extractIds(json['instructors']),
      studentIds: _extractIds(json['students']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      color: json['color'] ?? '#5F299E',
      image: json['image'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  static List<String> _extractIds(dynamic items) {
    if (items == null) return [];
    if (items is List) {
      return items.map<String>((item) {
        if (item is String) return item;
        if (item is Map && item['_id'] != null) return item['_id'];
        return '';
      }).where((id) => id.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'instructorIds': instructorIds,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'image': image,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? adminId,
    List<String>? instructorIds,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? image,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      adminId: adminId ?? this.adminId,
      instructorIds: instructorIds ?? this.instructorIds,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      image: image ?? this.image,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
