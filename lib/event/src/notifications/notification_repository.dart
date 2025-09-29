import 'notification_model.dart';

class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();

  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Welcome to Event Manager',
      message: 'Start creating and managing your events efficiently.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.general,
      priority: NotificationPriority.medium,
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      title: 'Event Reminder',
      message: 'Your upcoming event "Tech Conference 2024" is tomorrow.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
      type: NotificationType.reminder,
      priority: NotificationPriority.high,
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      title: 'System Update',
      message: 'New features have been added to your dashboard.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.general,
      priority: NotificationPriority.low,
      isRead: true,
    ),
  ];

  List<NotificationModel> getAllNotifications() {
    return List.from(_notifications);
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
  }

  void updateNotification(String id, NotificationModel updatedNotification) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = updatedNotification;
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  bool hasUnreadNotifications() {
    return getUnreadCount() > 0;
  }
}
