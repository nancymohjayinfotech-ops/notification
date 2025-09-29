import 'package:flutter/material.dart';
import '../../../live_session/pages/live_session_screen.dart';
import 'meeting_detail_page.dart';
import '../../../live_session/services/meeting_api_service.dart';
import '../../models/meeting.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentMeetingsPage extends StatefulWidget {
  const StudentMeetingsPage({super.key});

  @override
  State<StudentMeetingsPage> createState() => _StudentMeetingsPageState();
}

class _StudentMeetingsPageState extends State<StudentMeetingsPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Today'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingsContent(_upcomingMeetings, isUpcoming: true),
                _buildMeetingsContent(_todayMeetings, isToday: true),
                _buildMeetingsContent(_pastMeetings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  late TabController _tabController;
  // Remove MeetingsService, use MeetingApiService instead

  List<Meeting> _upcomingMeetings = [];
  List<Meeting> _todayMeetings = [];
  List<Meeting> _pastMeetings = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get student ID from auth service

      // STUDENT DEBUG: Print student info
      final authService = Provider.of<AuthService>(context, listen: false);
      final student = authService.currentUser;
      final studentId = student?.id ?? 'p1'; // Default fallback
      final studentName = student?.name ?? 'Unknown';
      print('==== STUDENT DEBUG INFO ====');
      print('Student ID: $studentId');
      print('Student Name: $studentName');
      print('============================');

      // Fetch all meetings for the student using MeetingApiService
      final allMeetingsJson = await MeetingApiService.fetchMeetingsForStudent(
        studentId,
      );
      print('Fetched ${allMeetingsJson.length} meetings for student.');
      // Parse meetings into Meeting model and print each meeting's IDs
      final allMeetings = allMeetingsJson.map((json) {
        final m = Meeting.fromJson(json);
        print(
          '-- Meeting: title=${m.title}, occurrenceId=${m.id}, scheduleId=${m.scheduleId}, studentId=$studentId, studentName=$studentName',
        );
        return m;
      }).toList();

      // Split meetings into upcoming, today, and past using endTime
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final upcoming = <Meeting>[];
      final today = <Meeting>[];
      final past = <Meeting>[];
      for (final m in allMeetings) {
        DateTime endTime = m.endTime;
        if (now.isAfter(endTime)) {
          past.add(m);
        } else {
          final meetingDate = DateTime(
            m.startTime.year,
            m.startTime.month,
            m.startTime.day,
          );
          if (meetingDate.isAfter(todayDate)) {
            upcoming.add(m);
          } else if (meetingDate.isAtSameMomentAs(todayDate)) {
            today.add(m);
          } else {
            past.add(m);
          }
        }
      }
      setState(() {
        _upcomingMeetings = upcoming;
        _todayMeetings = today;
        _pastMeetings = past;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading meetings: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _joinMeeting(BuildContext context, Meeting meeting) {
    // Use MongoDB _id and scheduleId directly from meeting object
    final occurrenceId = meeting.id; // MongoDB _id
    final scheduleId = meeting.scheduleId;

    // Prevent joining if meeting is over
    final now = DateTime.now();
    final endTime = meeting.endTime;
    if (now.isAfter(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting has ended and cannot be joined.'),
        ),
      );
      return;
    }

    // Get student info
    final authService = Provider.of<AuthService>(context, listen: false);
    final student = authService.currentUser;
    final studentId = student?.id ?? 'p1';
    final studentName = student?.name ?? 'Unknown';

    // Before joining, set student info in SharedPreferences so LiveSessionScreen picks up correct role
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', studentId);
      await prefs.setString('user_name', studentName);
      await prefs.setString('user_role', 'student');
    }();

    // Print all details for debugging
    print(
      'STUDENT_JOIN: occurrenceId=$occurrenceId, scheduleId=$scheduleId, studentId=$studentId, studentName=$studentName (role=student)',
    );

    // Navigate to live session screen with all required info
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveSessionScreen(
          meetingTitle: meeting.title,
          meetingId: occurrenceId,
          scheduleId: scheduleId,
          isHost: false, // Student is not host
        ),
      ),
    );
  }

  void _joinMeetingWithId(BuildContext context, String meetingId) {
    // Here you would validate the meeting ID and get the meeting title
    // For demo purposes, we'll create a placeholder
    final meetingTitle = 'Meeting $meetingId';

    // Navigate to live session screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveSessionScreen(meetingTitle: meetingTitle, meetingId: meetingId),
      ),
    );
  }

  Widget _buildMeetingsContent(
    List<Meeting> meetings, {
    bool isUpcoming = false,
    bool isToday = false,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5F299E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading meetings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMeetings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? 'No upcoming meetings'
                  : isToday
                  ? 'No meetings today'
                  : 'No past meetings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return _buildMeetingsList(
      meetings,
      isUpcoming: isUpcoming,
      isToday: isToday,
    );
  }

  Widget _buildMeetingsList(
    List<Meeting> meetings, {
    bool isUpcoming = false,
    bool isToday = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam, color: Color(0xFF5F299E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meeting.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isToday && meeting.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meeting.formattedDate,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      meeting.formattedTime,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(meeting.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(meeting.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isToday && meeting.isActive)
                      ElevatedButton(
                        onPressed: () {
                          _joinMeeting(context, meeting);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Join Now'),
                      )
                    else if (isUpcoming || (isToday && !meeting.isActive))
                      ElevatedButton(
                        onPressed: () {
                          _joinMeeting(context, meeting);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F299E),
                        ),
                        child: const Text('Join'),
                      )
                    else
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MeetingDetailPage(
                                meeting: MeetingDetailData(
                                  title: meeting.title,
                                  date: meeting.formattedDate,
                                  time: meeting.formattedTime,
                                  duration: meeting.duration,
                                  participants: meeting.participants,
                                  hasRecording: meeting.hasRecording,
                                  hasAttendanceReport: true,
                                  hasEngagementReport: true,
                                ),
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5F299E)),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(color: Color(0xFF5F299E)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper methods for status display
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
      case 'ended':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return 'LIVE';
      case 'active':
        return 'ACTIVE';
      case 'upcoming':
        return 'UPCOMING';
      case 'completed':
        return 'COMPLETED';
      case 'ended':
        return 'ENDED';
      default:
        return status.toUpperCase();
    }
  }
}

// Removed _MeetingData class as we now use Meeting model from API
