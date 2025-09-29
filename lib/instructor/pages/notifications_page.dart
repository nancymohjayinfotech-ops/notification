import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _Filter _activeFilter = _Filter.all;
  List<_NotificationItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await NotificationService.getNotifications();
      setState(() {
        _items = data.map<_NotificationItem>((n) {
          return _NotificationItem(
            id: n["_id"] ?? "",
            title: n["title"] ?? "No Title",
            message: n["message"] ?? "",
            timeAgo: n["createdAt"] ?? "",
            isRead: n["isRead"] ?? false,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load notifications")),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    _fetchNotifications();
  }

  Future<void> _toggleRead(_NotificationItem item) async {
    if (!item.isRead) {
      await NotificationService.markAsRead(item.id);
      setState(() => item.isRead = true);
    }
  }

  Future<void> _deleteNotification(_NotificationItem item) async {
    await NotificationService.deleteNotification(item.id);
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount = _items.where((e) => !e.isRead).length;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, unreadCount);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFF5F299E),
          foregroundColor: Colors.white,
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context, unreadCount);
            },
          ),
          actions: <Widget>[
            if (unreadCount > 0)
              IconButton(
                tooltip: 'Mark All as Read',
                icon: const Icon(Icons.mark_email_read, color: Colors.white),
                onPressed: _markAllAsRead,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? const Center(child: Text("No notifications"))
            : Column(
                children: <Widget>[
                  // filter chips
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        _buildFilterChip(label: 'All', filter: _Filter.all),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Unread',
                          filter: _Filter.unread,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(label: 'Read', filter: _Filter.read),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = _filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(
                                  0xFF5F299E,
                                ).withOpacity(0.12),
                                child: const Icon(
                                  Icons.notifications,
                                  color: Color(0xFF5F299E),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(item.message),
                              trailing: Wrap(
                                spacing: 4,
                                children: <Widget>[
                                  if (!item.isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5F299E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: item.isRead
                                        ? 'Read'
                                        : 'Mark as Read',
                                    icon: Icon(
                                      item.isRead
                                          ? Icons.mark_email_read
                                          : Icons.mark_email_unread,
                                      color: item.isRead
                                          ? Colors.grey
                                          : const Color(0xFF5F299E),
                                    ),
                                    onPressed: () => _toggleRead(item),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteNotification(item),
                                  ),
                                ],
                              ),
                              onTap: () => _toggleRead(item),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<_NotificationItem> get _filteredItems {
    switch (_activeFilter) {
      case _Filter.unread:
        return _items.where((e) => !e.isRead).toList();
      case _Filter.read:
        return _items.where((e) => e.isRead).toList();
      case _Filter.all:
        return _items;
    }
  }

  Widget _buildFilterChip({required String label, required _Filter filter}) {
    final bool selected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF5F299E).withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF5F299E) : Colors.black,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          _activeFilter = filter;
        });
      },
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? const Color(0xFF5F299E)
              : Colors.grey.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String timeAgo;
  bool isRead;
}

enum _Filter { all, unread, read }
