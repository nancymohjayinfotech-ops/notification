import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart';

class InstructorSchedulePage extends StatefulWidget {
  const InstructorSchedulePage({super.key});

  @override
  State<InstructorSchedulePage> createState() => _InstructorSchedulePageState();
}

class _InstructorSchedulePageState extends State<InstructorSchedulePage> {
  final List<Map<String, dynamic>> sessions = [
    {
      "title": "Web Development with React",
      "date": DateTime(2025, 9, 10, 10, 0),
      "duration": const Duration(hours: 2),
    },
    {
      "title": "JavaScript Basics",
      "date": DateTime(2025, 9, 27, 12, 0),
      "duration": const Duration(hours: 1),
    },
    {
      "title": "Blockchain Basics",
      "date": DateTime(2025, 9, 17, 7, 0),
      "duration": const Duration(hours: 3),
    },
    {
      "title": "Flutter Basics",
      "date": DateTime(2025, 9, 1, 12, 0),
      "duration": const Duration(hours: 2),
    },
    {
      "title": "UI/UX in Flutter",
      "date": DateTime(2025, 8, 29, 14, 0),
      "duration": const Duration(hours: 1),
    },
    {
      "title": "Dart Advanced",
      "date": DateTime(2025, 8, 24, 16, 30),
      "duration": const Duration(hours: 1, minutes: 30),
    },
  ];

  String formatDateTime(DateTime date, Duration duration) {
    final dateFormatter = DateFormat('EEE, d MMM yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final endTime = date.add(duration);

    return "${dateFormatter.format(date)}\n"
        "${timeFormatter.format(date)} - ${timeFormatter.format(endTime)}"
        "  •  ${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final upcoming = sessions
        .where((s) => (s["date"] as DateTime).isAfter(now))
        .toList();
    final past = sessions
        .where((s) => (s["date"] as DateTime).isBefore(now))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Schedule"),
        backgroundColor: const Color(0xFF5F299E),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarPage(sessions: sessions),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (upcoming.isNotEmpty) ...[
            _buildSectionTitle("Upcoming Classes", Colors.green),
            const SizedBox(height: 12),
            ...upcoming.map((session) => _buildSessionCard(session, true)),
            const SizedBox(height: 28),
          ],
          if (past.isNotEmpty) ...[
            _buildSectionTitle("Past Sessions", Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 12),
            ...past.map((session) => _buildSessionCard(session, false)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarPage(sessions: sessions),
            ),
          );
        },
        backgroundColor: const Color(0xFF5F299E),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, bool isUpcoming) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session["title"],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isUpcoming ? "Upcoming" : "Completed",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: isUpcoming ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Theme.of(context).iconTheme.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatDateTime(session["date"], session["duration"]),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}