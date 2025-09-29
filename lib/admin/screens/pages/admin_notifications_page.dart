import 'package:flutter/material.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  int unreadCount = 3;
  String selectedFilter = "All";

  final List<Map<String, String>> notifications = [
    {
      "title": "NEW COURSE CREATED",
      "body": "A new course has been created in the system.",
    },
    {
      "title": "USER ENROLLMENT APPROVED",
      "body": "An enrollment request has been approved.",
    },
    {
      "title": "COURSE DELETED",
      "body": "A course has been removed from the platform.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Notifications")),
      body: Column(
        children: [
          // Filter buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("All"),
              _buildFilterButton("Unread"),
              _buildFilterButton("Read"),
            ],
          ),
          // Notification list
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.purple,
                    ),
                    title: Text(notifications[index]["title"]!),
                    subtitle: Text(notifications[index]["body"]!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.mark_email_unread,
                          color: Color.fromARGB(255, 188, 136, 197),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete, color: Colors.red),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(filter),
        selected: selectedFilter == filter,
        onSelected: (_) {
          setState(() => selectedFilter = filter);
        },
      ),
    );
  }
}
