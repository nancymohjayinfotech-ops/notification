class EventReport {
  final String id;
  final String eventName;
  final DateTime date;
  final int totalAttendees;
  final int checkedInAttendees;
  final double attendanceRate;
  final List<Map<String, dynamic>> attendanceData;

  EventReport({
    required this.id,
    required this.eventName,
    required this.date,
    required this.totalAttendees,
    required this.checkedInAttendees,
    required this.attendanceData,
  }) : attendanceRate = totalAttendees > 0 
      ? (checkedInAttendees / totalAttendees) * 100 
      : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventName': eventName,
      'date': date.toIso8601String(),
      'totalAttendees': totalAttendees,
      'checkedInAttendees': checkedInAttendees,
      'attendanceRate': attendanceRate,
      'attendanceData': attendanceData,
    };
  }

  factory EventReport.fromJson(Map<String, dynamic> json) {
    return EventReport(
      id: json['id'],
      eventName: json['eventName'],
      date: DateTime.parse(json['date']),
      totalAttendees: json['totalAttendees'],
      checkedInAttendees: json['checkedInAttendees'],
      attendanceData: List<Map<String, dynamic>>.from(json['attendanceData']),
    );
  }
}
