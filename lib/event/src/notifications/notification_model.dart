class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final bool isActive;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.scheduledAt,
    required this.type,
    required this.priority,
    this.isRead = false,
    this.isActive = true,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? scheduledAt,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    bool? isActive,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum NotificationType {
  general,
  event,
  reminder,
  alert,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'General';
      case NotificationType.event:
        return 'Event';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.alert:
        return 'Alert';
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}
