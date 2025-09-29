import 'package:flutter/material.dart';
import 'package:fluttertest/event/src/notifications/notification_management_page.dart';
import 'package:fluttertest/instructor/pages/notifications_page.dart';

class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuPressed;

  const CustomNavbar({
    super.key,
    required this.title,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
      ),
      actions: [
        // 🔔 Notification bell icon
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      elevation: 0,
      backgroundColor: const Color(0xFF9C27B0),
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
