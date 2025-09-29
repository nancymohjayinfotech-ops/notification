import '../../live_session/utils/time_utils.dart';

class Meeting {
  final String id;
  final String scheduleId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String instructor;
  final int participants;
  final String status; // 'upcoming', 'active', 'completed'
  final String? meetingUrl;
  final String? recordingUrl;
  final bool hasRecording;

  Meeting({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.instructor,
    required this.participants,
    required this.status,
    this.meetingUrl,
    this.recordingUrl,
    this.hasRecording = false,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing meeting JSON: $json');

    // Parse exact API response structure
    final id = json['_id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final scheduleId = json['scheduleId']?.toString() ?? '';
    final title = json['title']?.toString() ?? 'Meeting';
    final description = json['description']?.toString() ?? '';

    // Parse startDateTime and endDateTime from API (assume UTC, convert to local)
    DateTime startTimeUtc;
    DateTime endTimeUtc;

    try {
      startTimeUtc = DateTime.parse(json['startDateTime']?.toString() ?? '');
    } catch (e) {
      print('⚠️ Error parsing startDateTime: $e');
      startTimeUtc = DateTime.now().toUtc();
    }

    try {
      endTimeUtc = DateTime.parse(json['endDateTime']?.toString() ?? '');
    } catch (e) {
      print('⚠️ Error parsing endDateTime: $e');
      endTimeUtc = startTimeUtc.add(const Duration(hours: 1));
    }

    // Convert UTC to local time
    final startTime = startTimeUtc.toLocal();
    final endTime = endTimeUtc.toLocal();

    // Default values for fields not in API
    final instructor = json['group']?.toString() ?? 'Instructor';
    final participants = 0; // Not provided in API
    final status = json['status']?.toString() ?? 'upcoming';

    // Generate meeting URL from scheduleId if available
    final meetingUrl = scheduleId.isNotEmpty
        ? 'https://video-calling-api-w3gp.onrender.com/join/$scheduleId'
        : null;

    final meeting = Meeting(
      id: id,
      scheduleId: scheduleId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      instructor: instructor,
      participants: participants,
      status: status,
      meetingUrl: meetingUrl,
      recordingUrl: null,
      hasRecording: false,
    );

    print('✅ Parsed meeting: ${meeting.title} at ${meeting.formattedDate} ${meeting.formattedTime}');
    return meeting;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'instructor': instructor,
      'participants': participants,
      'status': status,
      'meetingUrl': meetingUrl,
      'recordingUrl': recordingUrl,
      'hasRecording': hasRecording,
    };
  }

  // Helper methods
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(startTime.year, startTime.month, startTime.day);
    
    if (meetingDate == today) {
      return 'Today';
    } else if (meetingDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (meetingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${_getMonthName(startTime.month)} ${startTime.day}, ${startTime.year}';
    }
  }

  String get formattedTime {
    // Use TimeUtils to format the time range in local time
    return TimeUtils.getTimeRangeWithFixedAmPm(startTime, endTime);
  }

  String get duration {
    final diff = endTime.difference(startTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(startTime);
  }

  bool get isPast {
    return DateTime.now().isAfter(endTime);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
