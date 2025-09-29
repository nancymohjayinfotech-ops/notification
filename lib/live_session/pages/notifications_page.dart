import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _Filter _activeFilter = _Filter.all;
  final List<_NotificationItem> _items = <_NotificationItem>[
    _NotificationItem(
      title: 'You have requested to Withdrawal',
      timeAgo: '2 hrs ago',
      icon: Icons.reply,
      color: Colors.amber,
      isRead: false,
    ),
    _NotificationItem(
      title: 'Your Deposit Order is placed',
      timeAgo: '2 hrs ago',
      icon: Icons.refresh,
      color: Colors.teal,
      isRead: false,
    ),
    _NotificationItem(
      title: 'Welcome to the Instructor Dashboard',
      timeAgo: 'Yesterday',
      icon: Icons.campaign,
      color: const Color(0xFF5F299E),
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (final _NotificationItem item in _items) {
        item.isRead = true;
      }
    });
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
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final EdgeInsets pagePadding = constraints.maxWidth < 700
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: pagePadding.copyWith(bottom: 8),
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
                      child: ListView.builder(
                        padding: pagePadding.copyWith(top: 0),
                        itemCount: _filteredItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final _NotificationItem item = _filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
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
                                backgroundColor: item.color.withOpacity(0.12),
                                child: Icon(item.icon, color: item.color),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.timeAgo,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  if (!item.isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5F299E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: item.isRead
                                        ? 'Mark as Unread'
                                        : 'Mark as Read',
                                    icon: Icon(
                                      item.isRead
                                          ? Icons.mark_email_unread
                                          : Icons.mark_email_read,
                                      color: item.isRead
                                          ? Colors.grey
                                          : const Color(0xFF5F299E),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        item.isRead = !item.isRead;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  item.isRead = true;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // bottomNavigationBar intentionally removed per request
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
    required this.title,
    required this.timeAgo,
    required this.icon,
    required this.color,
    required this.isRead,
  });

  final String title;
  final String timeAgo;
  final IconData icon;
  final Color color;
  bool isRead;
}

enum _Filter { all, unread, read }
