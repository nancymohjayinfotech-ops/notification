import 'package:flutter/foundation.dart';

/// single session (class/meeting).
class Session {
  final String title;
  final DateTime date;
  final Duration duration;
  final String type; 

  Session({
    required this.title,
    required this.date,
    required this.duration,
    required this.type,
  });
}

/// multiple sessions
class ClassSchedule {
  final List<Session> sessions;

  ClassSchedule({required this.sessions});
}

/// manage sessions (upcoming & past)
class ScheduleProvider with ChangeNotifier {
  final List<Session> _sessions = [
    // Dummy data 
    Session(
      title: "Flutter Basics",
      date: DateTime.now().add(const Duration(days: 1)),
      duration: const Duration(hours: 2),
      type: "upcoming",
    ),
    Session(
      title: "Dart OOP Concepts",
      date: DateTime.now().subtract(const Duration(days: 2)),
      duration: const Duration(hours: 1, minutes: 30),
      type: "past",
    ),
  ];

  List<Session> get upcomingSessions =>
      _sessions.where((s) => s.type == "upcoming").toList();

  List<Session> get pastSessions =>
      _sessions.where((s) => s.type == "past").toList();

  void addSession(Session session) {
    _sessions.add(session);
    notifyListeners();
  }

  void removeSession(Session session) {
    _sessions.remove(session);
    notifyListeners();
  }
}
