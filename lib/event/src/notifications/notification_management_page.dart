import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_model.dart';
import 'notification_repository.dart';

class NotificationManagementPage extends StatefulWidget {
  const NotificationManagementPage({super.key});

  @override
  State<NotificationManagementPage> createState() =>
      _NotificationManagementPageState();
}

class _NotificationManagementPageState
    extends State<NotificationManagementPage> {
  final NotificationRepository _repository = NotificationRepository();
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _repository.getAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsSection(),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unreadCount = _repository.getUnreadCount();

    return AppBar(
      title: Row(
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 0,
      actions: [
        if (unreadCount > 0)
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            tooltip: 'Mark all as read',
          ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final totalCount = _notifications.length;
    final unreadCount = _repository.getUnreadCount();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total',
            totalCount.toString(),
            const Color(0xFF6D28D9),
          ),
          _buildStatItem('Unread', unreadCount.toString(), Colors.orange),
          _buildStatItem(
            'Read',
            (totalCount - unreadCount).toString(),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first notification using the + button',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withOpacity(0.2)
              : const Color(0xFF6D28D9).withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewNotification(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (!notification.isRead)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 12),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D28D9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: const Color(0xFF6D28D9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: notification.isRead
                            ? Colors.grey[700]
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleNotificationAction(value, notification),
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 20),
                          SizedBox(width: 12),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddNotificationDialog(),
      shape: const CircleBorder(),
      elevation: 6,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return Icons.info_outline;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.alert:
        return Icons.warning_amber;
    }
  }

  void _handleNotificationAction(
    String action,
    NotificationModel notification,
  ) {
    switch (action) {
      case 'mark_read':
        _repository.markAsRead(notification.id);
        _loadNotifications();
        _showSnackBar('Notification marked as read');
        break;
      case 'edit':
        _showEditNotificationDialog(notification);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(notification);
        break;
    }
  }

  void _viewNotification(NotificationModel notification) {
    if (!notification.isRead) {
      _repository.markAsRead(notification.id);
      _loadNotifications();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: GoogleFonts.poppins(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Type: ',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        notification.type.displayName,
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Priority: ',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        notification.priority.displayName,
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Created: ',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: const Color(0xFF6D28D9)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNotificationDialog() {
    _showNotificationDialog();
  }

  void _showEditNotificationDialog(NotificationModel notification) {
    _showNotificationDialog(notification: notification);
  }

  void _showNotificationDialog({NotificationModel? notification}) {
    final isEditing = notification != null;
    final titleController = TextEditingController(
      text: notification?.title ?? '',
    );
    final messageController = TextEditingController(
      text: notification?.message ?? '',
    );
    NotificationType selectedType =
        notification?.type ?? NotificationType.general;
    NotificationPriority selectedPriority =
        notification?.priority ?? NotificationPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEditing ? 'Edit Notification' : 'Add Notification',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NotificationType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  items: NotificationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.displayName,
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NotificationPriority>(
                  value: selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  items: NotificationPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(
                        priority.displayName,
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPriority = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    messageController.text.trim().isEmpty) {
                  _showSnackBar('Please fill in all required fields');
                  return;
                }

                final newNotification = NotificationModel(
                  id: isEditing
                      ? notification!.id
                      : DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  createdAt: isEditing
                      ? notification!.createdAt
                      : DateTime.now(),
                  type: selectedType,
                  priority: selectedPriority,
                  isRead: isEditing ? notification!.isRead : false,
                );

                if (isEditing) {
                  _repository.updateNotification(
                    notification!.id,
                    newNotification,
                  );
                  _showSnackBar('Notification updated successfully');
                } else {
                  _repository.addNotification(newNotification);
                  _showSnackBar('Notification added successfully');
                }

                _loadNotifications();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEditing ? 'Update' : 'Add',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Notification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${notification.title}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _repository.deleteNotification(notification.id);
              _loadNotifications();
              Navigator.pop(context);
              _showSnackBar('Notification deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() {
    _repository.markAllAsRead();
    _loadNotifications();
    _showSnackBar('All notifications marked as read');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6D28D9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
