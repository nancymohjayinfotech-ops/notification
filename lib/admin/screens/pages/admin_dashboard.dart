import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:fluttertest/event/src/notifications/notification_management_page.dart';
import 'admin_notifications_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _unreadNotifications = 3; // later replace with API count

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple, // fallback if gradient not used
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -4, end: -4),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(6),
              ),
              badgeContent: Text(
                '$_unreadNotifications',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              showBadge: _unreadNotifications > 0,
              child: IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () async {
                  final int? unread = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationManagementPage(),
                    ),
                  );
                  if (unread != null) {
                    setState(() => _unreadNotifications = unread);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, Admin!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Here's what's happening with your admin panel today.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Example stats grid
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildStatCard(
                    "238",
                    "Total Users",
                    Icons.people,
                    Colors.green,
                  ),
                  _buildStatCard(
                    "110",
                    "Total Students",
                    Icons.school,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    "70",
                    "Total Instructors",
                    Icons.person,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    "15",
                    "Total Courses",
                    Icons.book,
                    Colors.teal,
                  ),
                  _buildStatCard(
                    "9",
                    "Total Events",
                    Icons.event,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    "53",
                    "Total Enrollments",
                    Icons.list,
                    Colors.red,
                  ),
                  _buildStatCard(
                    "₹0",
                    "Total Revenue",
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildStatCard(
                    "₹0",
                    "Monthly Revenue",
                    Icons.show_chart,
                    Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String count,
    String label,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
