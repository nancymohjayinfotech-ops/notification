import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'live_session_screen.dart';
import 'session_library_screen.dart';
import '../services/meeting_service.dart';
import '../services/livekit_service.dart';
import '../utils/time_utils.dart';
import '../services/student_service.dart';
import '../services/participant_service.dart';
import '../../student/models/user_role.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage>
    with SingleTickerProviderStateMixin {
  // User role and info
  String _currentUserRole = '';
  String _currentUserName = '';
  // Show dialog for adding participants
  void _showAddParticipantDialog(
    BuildContext context,
    _MeetingData meeting,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder(
              future: Future.wait([
                StudentService.fetchStudents(),
                ParticipantService.getParticipantsForSchedule(
                  scheduleId: meeting.scheduleId,
                  hostId: meeting.hostId,
                  platformId: 'miskills',
                ),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AlertDialog(
                    title: Text('Add Participant'),
                    content: SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AlertDialog(
                    title: const Text('Add Participant'),
                    content: Text(
                      'Failed to load students/participants.\n${snapshot.error}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                }
                final students =
                    (snapshot.data as List)[0] as List<Map<String, dynamic>>? ??
                    [];
                final added =
                    (snapshot.data as List)[1] as List<Map<String, dynamic>>? ??
                    [];

                print('[AddParticipantDialog] Raw students: $students');
                print('[AddParticipantDialog] Added participants: $added');

                final addable = students
                    .where(
                      (student) => !added.any(
                        (p) =>
                            p['participantId'] ==
                            (student['_id'] ?? student['id']),
                      ),
                    )
                    .toList();

                print('[AddParticipantDialog] Addable students: $addable');
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final isMobile = screenWidth < 600;

                    // Responsive dialog dimensions
                    final dialogWidth =
                        (isMobile
                                ? screenWidth * 0.95
                                : (screenWidth < 900
                                      ? screenWidth * 0.85
                                      : 700))
                            .toDouble();
                    final dialogHeight = (isMobile ? screenHeight * 0.7 : 500)
                        .toDouble();

                    return AlertDialog(
                      title: Text(
                        'Add Participant',
                        style: TextStyle(fontSize: isMobile ? 18 : 20),
                      ),
                      contentPadding: EdgeInsets.all(isMobile ? 16 : 24),
                      content: SizedBox(
                        width: dialogWidth,
                        height: dialogHeight,
                        child: isMobile
                            ? _buildMobileParticipantLayout(
                                addable,
                                added,
                                meeting,
                                setState,
                              )
                            : _buildDesktopParticipantLayout(
                                addable,
                                added,
                                meeting,
                                setState,
                              ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Mobile layout for Add Participant dialog
  Widget _buildMobileParticipantLayout(
    List<dynamic> addable,
    List<dynamic> added,
    _MeetingData meeting,
    StateSetter setState,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFF5F299E),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF5F299E),
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Add Students'),
              Tab(text: 'Added'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildAddableStudentsList(addable, meeting, setState),
                _buildAddedParticipantsList(added, meeting, setState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desktop layout for Add Participant dialog
  Widget _buildDesktopParticipantLayout(
    List<dynamic> addable,
    List<dynamic> added,
    _MeetingData meeting,
    StateSetter setState,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Addable Students List
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Addable Students',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildAddableStudentsList(addable, meeting, setState),
              ),
            ],
          ),
        ),
        const VerticalDivider(),
        // Added Participants List
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Added Participants',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildAddedParticipantsList(added, meeting, setState),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build addable students list widget
  Widget _buildAddableStudentsList(
    List<dynamic> addable,
    _MeetingData meeting,
    StateSetter setState,
  ) {
    return Scrollbar(
      thumbVisibility: true,
      child: addable.isEmpty
          ? const Center(
              child: Text(
                'No students available to add.\nAll students may already be added\nor no students exist in the system.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: addable.length,
              itemBuilder: (context, idx) {
                final student = addable[idx];
                final studentName =
                    student['name'] ?? student['fullName'] ?? 'No Name';
                final studentId = student['_id'] ?? student['id'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    title: Text(
                      studentName,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      studentId,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF5F299E)),
                      onPressed: () async {
                        final resp = await ParticipantService.addParticipant(
                          scheduleId: meeting.scheduleId,
                          participantId: studentId,
                          participantName: studentName,
                        );
                        print('[AddParticipantDialog] Add response: $resp');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                resp != null && resp['message'] != null
                                    ? resp['message']
                                    : 'Failed to add participant',
                              ),
                            ),
                          );
                        }
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Build added participants list widget
  Widget _buildAddedParticipantsList(
    List<dynamic> added,
    _MeetingData meeting,
    StateSetter setState,
  ) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: added.length,
        itemBuilder: (context, idx) {
          final student = added[idx];
          final studentName =
              student['participantName'] ??
              student['name'] ??
              student['fullName'] ??
              'No Name';
          final studentId =
              student['participantId'] ?? student['_id'] ?? student['id'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              title: Text(
                studentName,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                studentId,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.remove, color: Colors.red),
                onPressed: () async {
                  final success = await ParticipantService.deleteParticipant(
                    scheduleId: meeting.scheduleId,
                    participantId: studentId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Participant removed'
                              : 'Failed to remove participant',
                        ),
                      ),
                    );
                  }
                  setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Stub for add participant dialog
  late TabController _tabController;

  // Meeting data
  List<_MeetingData> _upcomingMeetings = [];
  List<_MeetingData> _todayMeetings = [];
  List<_MeetingData> _pastMeetings = [];

  // Store internal 24-hour format time values
  String _internalStartTime = '';
  String _internalEndTime = '';

  bool _isLoading = false;
  String? _errorMessage;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set current user ID from SharedPreferences
    _setCurrentUserId();

    // Ensure we start with a clean state
    setState(() {
      _isLoading = false;
      _isFetchingMeetings = false;
      _errorMessage = null;
    });

    // Fetch meetings with showLoadingIndicator: true
    _fetchMeetings(showLoadingIndicator: false);

    // Set up a timer to refresh meetings periodically
    // This ensures we're always showing the latest data
    _setupRefreshTimer();

    // Add a one-time delayed check to reset any stuck UI states
    Future.delayed(Duration(seconds: 5), _resetLoadingState);
  }

  // Set the current user ID from SharedPreferences
  Future<void> _setCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final userRole = prefs.getString('user_role') ?? '';
      final userName = prefs.getString('user_name') ?? '';
      setState(() {
        _currentUserId = userId;
        _currentUserRole = userRole;
        _currentUserName = userName;
      });
      print(
        'Loaded user info - ID: $_currentUserId, Role: $_currentUserRole, Name: $_currentUserName',
      );
    } catch (e) {
      print('Error loading user info from SharedPreferences: $e');
    }
  }

  // Determine if current user is the host of the meeting
  bool _isCurrentUserHost(String meetingHostId) {
    if (_currentUserId.isEmpty || meetingHostId.isEmpty) {
      return false;
    }
    return _currentUserId == meetingHostId;
  }

  // Check if current user is an instructor
  bool _isCurrentUserInstructor() {
    return _currentUserRole == UserRole.instructor.value;
  }

  // Start a meeting (only allowed for instructors)
  Future<bool> _startMeetingSession(String meetingId, String scheduleId) async {
    try {
      // This would call a backend API to mark the meeting as started
      // For now, we'll simulate this by updating local state
      print('Starting meeting session for ID: $meetingId');

      // TODO: Add actual API call to backend to start meeting
      // final response = await MeetingService.startMeeting(meetingId, scheduleId);

      return true; // Simulate success
    } catch (e) {
      print('Error starting meeting: $e');
      return false;
    }
  }

  // Check if a meeting has been started by the instructor
  Future<bool> _checkMeetingStatus(String meetingId, String scheduleId) async {
    try {
      // This would call a backend API to check meeting status
      // For now, we'll simulate this
      print('Checking meeting status for ID: $meetingId');

      // TODO: Add actual API call to backend to check meeting status
      // final response = await MeetingService.getMeetingStatus(meetingId, scheduleId);

      return false; // Simulate meeting not started yet
    } catch (e) {
      print('Error checking meeting status: $e');
      return false;
    }
  }

  // Join a meeting by ID - redirects to the appropriate meeting screen
  Future<void> _joinMeetingById(
    BuildContext context,
    String inputMeetingId,
  ) async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Check and request all necessary permissions first
      print('🔐 Checking permissions for joining meeting by ID...');
      await LiveKitService.requestAllPermissions();

      // Check if critical permissions are granted
      final areCriticalPermissionsGranted =
          await LiveKitService.areCriticalPermissionsGranted();

      if (!areCriticalPermissionsGranted) {
        setState(() {
          _isLoading = false;
        });
        // Show permission dialog
        final shouldProceed = await _showPermissionDialog(context);
        if (!shouldProceed) {
          return;
        }
        setState(() {
          _isLoading = true;
        });
      }

      print('Attempting to join meeting with ID: $inputMeetingId');

      // Fetch meeting details from backend using the ID
      final meetingDetails = await MeetingService.getMeetingById(
        inputMeetingId,
      );

      if (meetingDetails != null && meetingDetails['status'] == true) {
        // Extract meeting data
        final meetingData = meetingDetails['data'][0];

        if (meetingData != null) {
          print('');
          print('=========== JOINING MEETING BY ID ===========');
          print('Meeting ID input: $inputMeetingId');

          // Print all available keys in the meeting data
          print('All meeting data keys: ${meetingData.keys.join(', ')}');

          // Extract host information from API response
          final occurrenceId =
              meetingData['occurrenceId'] ?? meetingData['_id'] ?? '';
          final scheduleId = meetingData['scheduleId'] ?? '';
          final hostId = meetingData['userId'] ?? meetingData['hostId'] ?? '';
          final hostName =
              meetingData['username'] ??
              meetingData['hostName'] ??
              'Instructor';

          // Print raw values from the API
          if (meetingData.containsKey('occurrenceId')) {
            print('Raw occurrenceId value: ${meetingData['occurrenceId']}');
          }
          if (meetingData.containsKey('_id')) {
            print('Raw _id value: ${meetingData['_id']}');
          }
          if (meetingData.containsKey('scheduleId')) {
            print('Raw scheduleId value: ${meetingData['scheduleId']}');
          }
          if (meetingData.containsKey('userId')) {
            print('Raw userId value: ${meetingData['userId']}');
          }
          if (meetingData.containsKey('hostId')) {
            print('Raw hostId value: ${meetingData['hostId']}');
          }

          // Print extracted values
          print('Final meeting occurrenceId: $occurrenceId');
          print('Final meeting scheduleId: $scheduleId');
          print('Final meeting hostId: $hostId');
          print('Final meeting hostName: $hostName');
          print('============================================');

          // Save current user info to SharedPreferences for LiveKit
          _saveCurrentUserInfoForLiveKit();

          // Navigate to the LiveSessionScreen with the complete meeting data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveSessionScreen(
                meetingId: occurrenceId.isNotEmpty
                    ? occurrenceId
                    : (scheduleId.isNotEmpty ? scheduleId : inputMeetingId),
                scheduleId: scheduleId,
                meetingTitle: meetingData['title'] ?? 'Untitled Meeting',
                isHost:
                    _isCurrentUserHost(hostId) || _isCurrentUserInstructor(),
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Meeting data not found';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              meetingDetails?['message'] ?? 'Failed to join meeting';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reset method to ensure we don't have stuck loading states
  void _resetLoadingState() {
    if (mounted && (_isLoading || _isFetchingMeetings)) {
      print('Detected potentially stuck loading state - resetting');
      setState(() {
        _isLoading = false;
        _isFetchingMeetings = false;
      });
    }
  }

  void _setupRefreshTimer() {
    // Refresh meetings every 30 seconds to keep data fresh
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        // Don't show loading indicator for background refreshes to avoid blinking
        _fetchMeetings(showLoadingIndicator: false);
        _setupRefreshTimer(); // Set up the next refresh
      }
    });
  }

  // Removed unused _formatISTTime method

  // Track if a fetch operation is already in progress
  bool _isFetchingMeetings = false;

  // Fetch meetings from the service
  Future<void> _fetchMeetings({bool showLoadingIndicator = true}) async {
    // Prevent multiple simultaneous fetches
    if (_isFetchingMeetings) {
      print('Skipping fetch - already in progress');
      return;
    }

    _isFetchingMeetings = true;

    // Only show loading indicator if specifically requested
    if (showLoadingIndicator && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final meetings = await MeetingService.getInstructorMeetings();

      // Convert API data to our meeting model
      final upcomingMeetings = <_MeetingData>[];
      final todayMeetings = <_MeetingData>[];
      final pastMeetings = <_MeetingData>[];

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final futures = <Future<void>>[];
      for (final meeting in meetings) {
        try {
          final scheduledDateString =
              meeting['scheduledDate'] ?? meeting['startDateTime'];
          DateTime scheduledDate;
          try {
            scheduledDate = DateTime.parse(scheduledDateString).toLocal();
          } catch (e) {
            scheduledDate = now;
          }
          final future = _convertToMeetingData(meeting)
              .then((meetingData) async {
                // Parse end time for accurate past/upcoming logic
                DateTime endTime;
                try {
                  final endDateString =
                      meeting['endDate'] ?? meeting['endDateTime'] ?? '';
                  if (endDateString.isNotEmpty) {
                    endTime = DateTime.parse(endDateString).toLocal();
                  } else {
                    endTime = scheduledDate.add(
                      Duration(minutes: meeting['duration'] ?? 30),
                    );
                  }
                } catch (e) {
                  endTime = DateTime.now();
                }
                if (now.isAfter(endTime)) {
                  pastMeetings.add(meetingData);
                } else {
                  final meetingDate = DateTime(
                    meetingData.date == 'Today' ? now.year : scheduledDate.year,
                    meetingData.date == 'Today'
                        ? now.month
                        : scheduledDate.month,
                    meetingData.date == 'Today' ? now.day : scheduledDate.day,
                  );
                  if (meetingDate.isAfter(todayDate)) {
                    upcomingMeetings.add(meetingData);
                  } else if (meetingDate.isAtSameMomentAs(todayDate)) {
                    todayMeetings.add(meetingData);
                  } else {
                    pastMeetings.add(meetingData);
                  }
                }
              })
              .catchError((e) {
                print('Error processing meeting: $e');
                print('Problem meeting data: $meeting');
              });
          futures.add(future);
        } catch (e) {
          print('Error creating future for meeting: $e');
        }
      }
      await Future.wait(futures);
      if (mounted) {
        setState(() {
          _upcomingMeetings = upcomingMeetings;
          _todayMeetings = todayMeetings;
          _pastMeetings = pastMeetings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching meetings: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      _isFetchingMeetings = false;
    }
  }

  // Helper method to convert API data to our meeting model
  Future<_MeetingData> _convertToMeetingData(
    Map<String, dynamic> apiData,
  ) async {
    // Debug the raw API data first
    print(
      'Raw API data: ${apiData.toString().substring(0, min(300, apiData.toString().length))}',
    );

    // For debugging purposes, print the full JSON data
    try {
      print('Full API data structure: ${jsonEncode(apiData)}');
    } catch (e) {
      print('Error encoding API data: $e');
    }

    // The API returns time in UTC format with timezone information
    // We want to display it in the instructor's local time (IST)
    final scheduledDateString =
        apiData['scheduledDate'] ?? apiData['startDateTime'];
    final endDateString = apiData['endDate'] ?? apiData['endDateTime'] ?? '';

    // Parse UTC string and convert to local time
    final scheduledDate = DateTime.parse(scheduledDateString).toLocal();
    DateTime endTime;
    if (endDateString.isNotEmpty) {
      endTime = DateTime.parse(endDateString).toLocal();
    } else {
      endTime = scheduledDate.add(Duration(minutes: apiData['duration'] ?? 30));
    }

    // Format date string
    final now = DateTime.now();
    final isToday =
        now.day == scheduledDate.day &&
        now.month == scheduledDate.month &&
        now.year == scheduledDate.year;
    String dateString;
    if (isToday) {
      dateString = 'Today';
    } else {
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      dateString =
          '${monthNames[scheduledDate.month - 1]} ${scheduledDate.day}, ${scheduledDate.year}';
    }

    // Format time string using 12-hour format with IST indicator
    final timeString = TimeUtils.getTimeRangeWithFixedAmPm(
      scheduledDate,
      endTime,
    );

    // Extract the actual IDs from the API response based on the provided image and debug output
    print('');
    print('=========== MEETING DATA DEBUG OUTPUT ===========');
    print('Extracting meeting IDs from API response');

    // Debug: Print all available keys in the API response
    try {
      print('API Response Keys: ${apiData.keys.join(', ')}');
    } catch (e) {
      print('Error printing API keys: $e');
    }

    // Look for raw API data that might contain the meeting IDs directly
    String occurrenceId = '';
    String scheduleId = '';
    String userId = '';
    String username = '';

    // Check if the apiData contains the _id directly - this would be from the API response
    if (apiData.containsKey('_id')) {
      occurrenceId = apiData['_id']?.toString() ?? '';
      print('Found occurrenceId from _id field: $occurrenceId');
    }
    // Otherwise try to find it in 'occurrenceId'
    else if (apiData.containsKey('occurrenceId')) {
      occurrenceId = apiData['occurrenceId']?.toString() ?? '';
      print('Found occurrenceId from occurrenceId field: $occurrenceId');
    }

    // Check for scheduleId
    if (apiData.containsKey('scheduleId')) {
      scheduleId = apiData['scheduleId']?.toString() ?? '';
      print('Found scheduleId from scheduleId field: $scheduleId');
    }
    // Otherwise try to use 'id' as scheduleId
    else if (apiData.containsKey('id')) {
      scheduleId = apiData['id']?.toString() ?? '';
      print('Found scheduleId from id field: $scheduleId');
    }

    // Check for userId (hostId)
    if (apiData.containsKey('userId')) {
      userId = apiData['userId'] ?? '';
      print('Found userId/hostId from userId field: $userId');
    } else if (apiData.containsKey('hostId')) {
      userId = apiData['hostId'] ?? '';
      print('Found userId/hostId from hostId field: $userId');
    }

    // Check for username (hostName)
    if (apiData.containsKey('username')) {
      username = apiData['username'] ?? '';
      print('Found username/hostName from username field: $username');
    } else if (apiData.containsKey('hostName')) {
      username = apiData['hostName'] ?? '';
      print('Found username/hostName from hostName field: $username');
    }

    // Print the raw data object for each field if available
    if (apiData.containsKey('_id')) {
      print('Raw _id value: ${apiData['_id']}');
    }
    if (apiData.containsKey('occurrenceId')) {
      print('Raw occurrenceId value: ${apiData['occurrenceId']}');
    }
    if (apiData.containsKey('scheduleId')) {
      print('Raw scheduleId value: ${apiData['scheduleId']}');
    }
    if (apiData.containsKey('id')) {
      print('Raw id value: ${apiData['id']}');
    }
    if (apiData.containsKey('userId')) {
      print('Raw userId value: ${apiData['userId']}');
    }
    if (apiData.containsKey('hostId')) {
      print('Raw hostId value: ${apiData['hostId']}');
    }
    print('================================================');

    // Get current user ID and name from SharedPreferences to use as hostId and hostName
    SharedPreferences prefs;
    String hostId = '';
    String hostName = 'Instructor';

    try {
      prefs = await SharedPreferences.getInstance();
      hostId = prefs.getString('user_id') ?? '';
      hostName = prefs.getString('user_name') ?? 'Instructor';
    } catch (e) {
      print('Error getting SharedPreferences: $e');
    }

    // Debug the IDs to verify they're correct
    print(
      'Meeting data from API: ${apiData.toString().substring(0, min(100, apiData.toString().length))}',
    );
    print('Extracted occurrenceId: $occurrenceId');
    print('Extracted scheduleId: $scheduleId');
    print('Extracted hostId: $hostId');
    print('Extracted hostName: $hostName');

    return _MeetingData(
      title: apiData['title'],
      purpose: apiData['description'] ?? apiData['purpose'] ?? '',
      date: dateString,
      time: timeString,
      participants:
          apiData['participants'] ??
          (apiData['hosts'] != null ? (apiData['hosts'] as List).length : 0),
      isActive: apiData['status'] == 'live' || apiData['isActive'] == true,
      occurrenceId: occurrenceId,
      scheduleId: scheduleId,
      hostId: hostId,
      hostName: hostName,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Session Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SessionLibraryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Controls Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Join Meeting Button
                Expanded(
                  child: Material(
                    color: const Color(0xFF5F299E),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        _showJoinMeetingDialog(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Join Meeting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Create Meeting Button
                Expanded(
                  child: Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        _showCreateMeetingDialog(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_box, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Create Meeting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content with smooth transitions
          Expanded(
            child: Stack(
              children: [
                // Main content
                Opacity(
                  opacity: _isLoading ? 0.3 : 1.0, // Slightly dim when loading
                  child: _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  'Error loading meetings: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_errorMessage!.contains('FormatException') ||
                                  _errorMessage!.contains('date format'))
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'There appears to be a problem with the date format. '
                                    'The app will try to automatically fix this issue.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5F299E),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _fetchMeetings(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Upcoming Meetings
                            _upcomingMeetings.isEmpty
                                ? const Center(
                                    child: Text('No upcoming meetings'),
                                  )
                                : _buildMeetingsList(
                                    _upcomingMeetings,
                                    isUpcoming: true,
                                  ),

                            // Today's Meetings
                            _todayMeetings.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No meetings scheduled for today',
                                    ),
                                  )
                                : _buildMeetingsList(
                                    _todayMeetings,
                                    isToday: true,
                                  ),

                            // Past Meetings
                            _pastMeetings.isEmpty
                                ? const Center(child: Text('No past meetings'))
                                : _buildMeetingsList(_pastMeetings),
                          ],
                        ),
                ),

                // Loading indicator overlay - only visible when explicitly loading meetings
                if (_isLoading && !_isFetchingMeetings)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _isLoading ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Card(
                        color: Colors.white,
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF5F299E),
                              ),
                              SizedBox(height: 16),
                              Text('Loading meetings...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testMeeting,
        backgroundColor: const Color(0xFF5F299E),
        icon: const Icon(Icons.video_call, color: Colors.white),
        label: const Text(
          'Test Meeting',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Test method to join a meeting with known working data
  Future<void> _testMeeting() async {
    try {
      print('🧪 Starting test meeting...');

      // Navigate directly to the test meeting with known working data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveSessionScreen(
            meetingTitle: 'Test Meeting',
            meetingId:
                '68bf16a8419775aff4c9e985', // Known working occurrence ID from API
            scheduleId: 'AJ0LUJLGNM', // Known working schedule ID from API
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error starting test meeting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test meeting failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showJoinMeetingDialog(BuildContext context) {
    // Use an empty controller and let the user enter the meeting ID
    final meetingIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the meeting ID to join',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: meetingIdController,
              decoration: InputDecoration(
                hintText: 'Enter meeting ID',
                helperText: 'e.g. 60d21b4667d0d8992e610c85',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.tag),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F299E),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (meetingIdController.text.isNotEmpty) {
                // Join meeting with ID
                _joinMeetingById(context, meetingIdController.text);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  // Removed _startInstantMeeting method as it's no longer needed

  void _showEditMeetingDialog(BuildContext context, _MeetingData meeting) {
    final meetingTitleController = TextEditingController(text: meeting.title);
    final purposeController = TextEditingController(text: meeting.purpose);
    final dateController = TextEditingController(text: meeting.date);
    final timeController = TextEditingController(text: meeting.time);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: meetingTitleController,
              decoration: InputDecoration(
                labelText: 'Meeting Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: purposeController,
              decoration: InputDecoration(
                labelText: 'Meeting Purpose',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Brief description of the meeting purpose',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.access_time),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F299E),
            ),
            onPressed: () {
              // Update meeting logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meeting updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _startMeeting(BuildContext context, _MeetingData meeting) async {
    // Only instructors can start meetings
    if (!_isCurrentUserInstructor()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only instructors can start meetings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check and request all necessary permissions first
    print('🔐 Checking permissions for meeting...');
    await LiveKitService.requestAllPermissions();

    // Check if critical permissions are granted
    final areCriticalPermissionsGranted =
        await LiveKitService.areCriticalPermissionsGranted();

    if (!areCriticalPermissionsGranted) {
      // Show permission dialog
      final shouldProceed = await _showPermissionDialog(context);
      if (!shouldProceed) {
        return;
      }
    }

    // Use the actual occurrence ID from the meeting data
    final occurrenceId = meeting.occurrenceId;
    final scheduleId = meeting.scheduleId;
    final hostId = meeting.hostId;
    final hostName = meeting.hostName;

    // Prevent starting if meeting is over
    final now = DateTime.now();
    DateTime endTime;
    try {
      endTime = DateTime.parse(meeting.time.split(' - ').last);
    } catch (e) {
      endTime = now;
    }
    if (now.isAfter(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting has ended and cannot be started.'),
        ),
      );
      return;
    }

    // Determine if current user is the actual host
    final isActualHost =
        _isCurrentUserHost(hostId) || _isCurrentUserInstructor();

    print('Starting meeting with occurrenceId: $occurrenceId');
    print('Meeting scheduleId: $scheduleId');
    print('Meeting title: ${meeting.title}');
    print('Meeting hostId: $hostId');
    print('Meeting hostName: $hostName');
    print('Current user ID: $_currentUserId');
    print('Current user role: $_currentUserRole');
    print('Is actual host: $isActualHost');

    if (occurrenceId.isEmpty && scheduleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Meeting ID not found')),
      );
      return;
    }

    // Start the meeting session in backend
    final meetingStarted = await _startMeetingSession(
      occurrenceId.isNotEmpty ? occurrenceId : scheduleId,
      scheduleId,
    );

    if (!meetingStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start meeting. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save current user info for LiveKit (not meeting host info)
    _saveCurrentUserInfoForLiveKit();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting started successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveSessionScreen(
          meetingTitle: meeting.title,
          meetingId: occurrenceId.isNotEmpty ? occurrenceId : scheduleId,
          scheduleId: scheduleId,
          isHost: isActualHost,
        ),
      ),
    );
  }

  // Helper method removed as it's no longer used

  void _joinMeeting(BuildContext context, _MeetingData meeting) async {
    // Check and request all necessary permissions first
    print('🔐 Checking permissions for joining meeting...');
    await LiveKitService.requestAllPermissions();

    // Check if critical permissions are granted
    final areCriticalPermissionsGranted =
        await LiveKitService.areCriticalPermissionsGranted();

    if (!areCriticalPermissionsGranted) {
      // Show permission dialog
      final shouldProceed = await _showPermissionDialog(context);
      if (!shouldProceed) {
        return;
      }
    }

    // Use the actual occurrence ID from the meeting data
    final occurrenceId = meeting.occurrenceId;
    final scheduleId = meeting.scheduleId;
    final hostId = meeting.hostId;
    final hostName = meeting.hostName;

    // Prevent joining if meeting is over
    final now = DateTime.now();
    DateTime endTime;
    try {
      endTime = DateTime.parse(meeting.time.split(' - ').last);
    } catch (e) {
      endTime = now;
    }
    if (now.isAfter(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting has ended and cannot be joined.'),
        ),
      );
      return;
    }

    // For students, check if meeting has been started by instructor
    if (!_isCurrentUserInstructor()) {
      final meetingStarted = await _checkMeetingStatus(
        occurrenceId.isNotEmpty ? occurrenceId : scheduleId,
        scheduleId,
      );

      if (!meetingStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Meeting has not been started by the instructor yet. Please wait.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Determine if current user is the actual host
    final isActualHost =
        _isCurrentUserHost(hostId) || _isCurrentUserInstructor();

    print('Joining meeting with occurrenceId: $occurrenceId');
    print('Meeting scheduleId: $scheduleId');
    print('Meeting hostId: $hostId');
    print('Meeting hostName: $hostName');
    print('Current user ID: $_currentUserId');
    print('Current user role: $_currentUserRole');
    print('Is actual host: $isActualHost');

    if (occurrenceId.isEmpty && scheduleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Meeting ID not found')),
      );
      return;
    }

    // Save current user info for LiveKit (not meeting host info)
    _saveCurrentUserInfoForLiveKit();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveSessionScreen(
          meetingTitle: meeting.title,
          meetingId: occurrenceId.isNotEmpty ? occurrenceId : scheduleId,
          scheduleId: scheduleId,
          isHost: isActualHost,
        ),
      ),
    );
  }

  // Save current user information to SharedPreferences for LiveKit token generation
  Future<void> _saveCurrentUserInfoForLiveKit() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId.isNotEmpty) {
      await prefs.setString('user_id', _currentUserId);
    }
    if (_currentUserName.isNotEmpty) {
      await prefs.setString('user_name', _currentUserName);
    }
    print(
      'Saved current user info for LiveKit - ID: $_currentUserId, Name: $_currentUserName, Role: $_currentUserRole',
    );
  }

  // Method removed - functionality replaced by _joinMeetingById

  void _showCreateMeetingDialog(BuildContext context) {
    // Reset any loading states before showing dialog
    setState(() {
      _isLoading = false;
      _isFetchingMeetings = false;
    });

    // Controllers for form fields
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final groupController = TextEditingController();
    final startDateController = TextEditingController();
    final startTimeController = TextEditingController();
    final endDateController = TextEditingController();
    final endTimeController = TextEditingController();

    // Recurrence options
    String recurrenceType = 'once'; // Default to one-time meeting
    final List<bool> selectedDays = List.generate(
      7,
      (_) => false,
    ); // For weekly recurrence

    // Get current date and time for default values
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Format date for the fields
    final defaultStartDate =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    startDateController.text = defaultStartDate;
    endDateController.text = defaultStartDate; // Default end date same as start

    // Format time for the fields (both 12-hour for display and 24-hour for internal use)
    // IMPORTANT: These times are in IST (local time).
    // When sending to backend, we'll convert to UTC in the meeting_service.dart

    // For display (12-hour format)
    final defaultStartHour12 = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final defaultStartAmPm = now.hour >= 12 ? 'PM' : 'AM';
    startTimeController.text = '$defaultStartHour12:00 $defaultStartAmPm';

    // For internal use (24-hour format) - still in IST/local time
    _internalStartTime = '${now.hour.toString().padLeft(2, '0')}:00';

    // Default end time is 1 hour later
    final laterHour = (now.hour + 1) % 24;

    // For display (12-hour format)
    final defaultEndHour12 = laterHour > 12
        ? laterHour - 12
        : (laterHour == 0 ? 12 : laterHour);
    final defaultEndAmPm = laterHour >= 12 ? 'PM' : 'AM';
    endTimeController.text = '$defaultEndHour12:00 $defaultEndAmPm';

    // For internal use (24-hour format) - still in IST/local time
    _internalEndTime = '${laterHour.toString().padLeft(2, '0')}:00';

    // Maps day index to day name
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Show the dialog with form fields
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All times are in Indian Standard Time (IST/UTC+5:30)',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Meeting Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Brief description of the meeting (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: groupController,
                  decoration: InputDecoration(
                    labelText: 'Group',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Group name (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startDateController,
                        decoration: InputDecoration(
                          labelText: 'Start Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: tomorrow,
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDateController.text =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

                                  // If end date is before start date, update it
                                  final endDate = DateTime.tryParse(
                                    endDateController.text,
                                  );
                                  if (endDate != null &&
                                      endDate.isBefore(picked)) {
                                    endDateController.text =
                                        startDateController.text;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: InputDecoration(
                          labelText: 'Start Time (IST) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Indian Standard Time (12-hour format)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (BuildContext context, Widget? child) {
                                  // Use Material 3 time picker which shows AM/PM by default
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        hourMinuteShape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  // Calculate the display hour in 12-hour format
                                  final displayHour = picked.hour > 12
                                      ? picked.hour - 12
                                      : (picked.hour == 0 ? 12 : picked.hour);
                                  final amPm = picked.hour >= 12 ? 'PM' : 'AM';

                                  // Format the time for display using 12-hour format with AM/PM
                                  final formattedTime =
                                      '$displayHour:${picked.minute.toString().padLeft(2, '0')} $amPm';

                                  // Store the formatted 12-hour time in the text field
                                  startTimeController.text = formattedTime;

                                  // Store 24-hour format for internal use (this is the key part)
                                  _internalStartTime =
                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

                                  // For debug - extensive logging to verify time format conversions
                                  print('⏰ START TIME SELECTION:');
                                  print(
                                    '- Selected raw time: ${picked.hour}:${picked.minute}',
                                  );
                                  print('- Is PM? ${picked.hour >= 12}');
                                  print('- 12-hour format: $formattedTime');
                                  print(
                                    '- 24-hour format: $_internalStartTime',
                                  );
                                  print(
                                    '- If user selected 1:00 PM, internal time should be 13:00',
                                  );
                                  print(
                                    '- If user selected 3:00 PM, internal time should be 15:00',
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: endDateController,
                        decoration: InputDecoration(
                          labelText: 'End Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.tryParse(
                                      startDateController.text,
                                    ) ??
                                    tomorrow,
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() {
                                  endDateController.text =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: InputDecoration(
                          labelText: 'End Time (IST) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: 'Indian Standard Time (12-hour format)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: (now.hour + 1) % 24,
                                  minute: 0,
                                ),
                                builder: (BuildContext context, Widget? child) {
                                  // Use Material 3 time picker which shows AM/PM by default
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        hourMinuteShape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  // Calculate the display hour in 12-hour format
                                  final displayHour = picked.hour > 12
                                      ? picked.hour - 12
                                      : (picked.hour == 0 ? 12 : picked.hour);
                                  final amPm = picked.hour >= 12 ? 'PM' : 'AM';

                                  // Format the time for display using 12-hour format with AM/PM
                                  final formattedTime =
                                      '$displayHour:${picked.minute.toString().padLeft(2, '0')} $amPm';

                                  // Store the formatted 12-hour time in the text field
                                  endTimeController.text = formattedTime;

                                  // Store 24-hour format for internal use
                                  _internalEndTime =
                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

                                  // For debug - extensive logging to verify time format conversions
                                  print('⏰ END TIME SELECTION:');
                                  print(
                                    '- Selected raw time: ${picked.hour}:${picked.minute}',
                                  );
                                  print('- Is PM? ${picked.hour >= 12}');
                                  print('- 12-hour format: $formattedTime');
                                  print('- 24-hour format: $_internalEndTime');
                                  print(
                                    '- If user selected 3:00 PM, internal time should be 15:00',
                                  );
                                  print(
                                    '- If user selected 5:00 PM, internal time should be 17:00',
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Recurrence',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: recurrenceType,
                  items: const [
                    DropdownMenuItem(
                      value: 'once',
                      child: Text('One-time Meeting'),
                    ),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    // DropdownMenuItem(
                    //   value: 'weekly',
                    //   child: Text('Weekly'),
                    // ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('Custom Days'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        recurrenceType = value;
                        if (recurrenceType == 'once') {
                          // For one-time meeting, force End Date = Start Date
                          endDateController.text = startDateController.text;
                        }
                      });
                    }
                  },
                ),

                if (recurrenceType == 'custom' || recurrenceType == 'weekly')
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Days:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: List.generate(7, (index) {
                            return FilterChip(
                              label: Text(dayNames[index]),
                              selected: selectedDays[index],
                              onSelected: (selected) {
                                setState(() {
                                  selectedDays[index] = selected;
                                });
                              },
                              selectedColor: const Color(
                                0xFF5F299E,
                              ).withOpacity(0.3),
                              checkmarkColor: const Color(0xFF5F299E),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F299E),
              ),
              onPressed: () async {
                // Validate inputs
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a meeting title'),
                    ),
                  );
                  return;
                }

                if (startDateController.text.isEmpty ||
                    startTimeController.text.isEmpty ||
                    endDateController.text.isEmpty ||
                    endTimeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter all required date and time fields',
                      ),
                    ),
                  );
                  return;
                }

                // For one-time meeting, enforce End Date = Start Date
                if (recurrenceType == 'once') {
                  endDateController.text = startDateController.text;
                }
                // Validate that end time is after start time
                try {
                  final startIST = DateTime.parse(
                    '${startDateController.text}T$_internalStartTime:00',
                  );
                  final endIST = DateTime.parse(
                    '${endDateController.text}T$_internalEndTime:00',
                  );
                  if (!endIST.isAfter(startIST)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End time must be after start time'),
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Invalid date or time format: ${e.toString()}',
                      ),
                    ),
                  );
                  return;
                }

                // For custom recurrence, ensure at least one day is selected
                if (recurrenceType == 'custom' &&
                    !selectedDays.contains(true)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select at least one day for custom recurrence',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  // Close the dialog first, before any async operations
                  Navigator.pop(context);

                  // Explicitly disable loading state
                  setState(() {
                    _isLoading = false;
                    _isFetchingMeetings = false;
                  });

                  // Show temporary snackbar to indicate meeting creation in progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Creating meeting...'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.blue,
                    ),
                  );

                  // Convert selected days to API format (1-based day indices)
                  List<int>? daysOfWeek;

                  if (recurrenceType == 'custom') {
                    daysOfWeek = [];
                    for (int i = 0; i < selectedDays.length; i++) {
                      if (selectedDays[i]) {
                        // Adding 1 because the API uses 1-based indices (1=Monday, 7=Sunday)
                        daysOfWeek.add(i + 1);
                      }
                    }
                  } else if (recurrenceType == 'weekly') {
                    // For weekly, use the current day of week
                    final currentDayOfWeek =
                        now.weekday; // 1-7 where 1 is Monday
                    daysOfWeek = [currentDayOfWeek];
                  }

                  // Parse IST date and time strings
                  final startDateStr =
                      startDateController.text; // Format: YYYY-MM-DD
                  final endDateStr = endDateController.text;

                  // Use the internal 24-hour format time strings for parsing
                  final startTimeStr =
                      _internalStartTime; // Format: HH:MM (24-hour)
                  final endTimeStr =
                      _internalEndTime; // Format: HH:MM (24-hour)

                  // Display values for debugging
                  print('Time values for meeting creation:');
                  print('- Start date: $startDateStr');
                  print('- Start time (display): ${startTimeController.text}');
                  print('- Start time (internal 24h): $startTimeStr');
                  print('- End date: $endDateStr');
                  print('- End time (display): ${endTimeController.text}');
                  print('- End time (internal 24h): $endTimeStr');

                  // Parse IST datetimes from user input as local times
                  // The DateTime.parse() method assumes the string is in local timezone if no timezone is specified
                  // Send the selected IST time directly to the backend (no UTC conversion)
                  print('⏰ SENDING MEETING IN IST (NO UTC CONVERSION):');
                  print('- Start date: $startDateStr');
                  print('- Start time (24h): $startTimeStr');
                  print('- End date: $endDateStr');
                  print('- End time (24h): $endTimeStr');

                  final result = await MeetingService.scheduleMeeting(
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                    startDate: startDateStr,
                    startTime: startTimeStr,
                    endDate: endDateStr,
                    endTime: endTimeStr,
                    group: groupController.text.isNotEmpty
                        ? groupController.text
                        : null,
                    recurrence: recurrenceType,
                    daysOfWeek: daysOfWeek,
                  );

                  if (result['success'] == true) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meeting created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refresh the meeting list immediately but don't show loading indicator
                    await _fetchMeetings(showLoadingIndicator: false);
                  } else {
                    // Clear loading state if needed
                    if (_isLoading) {
                      setState(() {
                        _isLoading = false;
                      });
                    }

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to create meeting: ${result['message'] ?? 'Unknown error'}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Handle validation errors
                  print('Error creating meeting: $e');

                  // Update loading state
                  if (!mounted) return;
                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create Meeting'),
            ),
          ],
        ),
      ),
    );
  }
  // No more need for loading dialog

  Widget _buildMeetingsList(
    List<_MeetingData> meetings, {
    bool isUpcoming = false,
    bool isToday = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        final isHostForThisMeeting =
            (meeting.hostId.isNotEmpty && meeting.hostId == _currentUserId) ||
            _isCurrentUserInstructor();
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
                if (meeting.purpose.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      meeting.purpose,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
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
                      meeting.date,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      meeting.time,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${meeting.participants} participants',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Host controls BEFORE meeting is active
                    if ((isUpcoming || (isToday && !meeting.isActive)) &&
                        isHostForThisMeeting) ...[
                      OutlinedButton(
                        onPressed: () {
                          _showEditMeetingDialog(context, meeting);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5F299E)),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Color(0xFF5F299E)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _startMeeting(
                            context,
                            meeting,
                          ); // Host explicitly starts session
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F299E),
                        ),
                        child: const Text('Start'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.person_add,
                          color: Color(0xFF5F299E),
                        ),
                        label: const Text(
                          'Add Participant',
                          style: TextStyle(color: Color(0xFF5F299E)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5F299E)),
                        ),
                        onPressed: () {
                          _showAddParticipantDialog(context, meeting);
                        },
                      ),
                    ]
                    // Participant view BEFORE meeting active: show waiting indicator (no join)
                    else if ((isUpcoming || (isToday && !meeting.isActive)) &&
                        !isHostForThisMeeting) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'Waiting for instructor to start the meeting...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ]
                    // Meeting active: everyone sees Join Now
                    else if (isToday && meeting.isActive) ...[
                      ElevatedButton(
                        onPressed: () {
                          _joinMeeting(context, meeting);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Join Now'),
                      ),
                    ]
                    // Past meeting / recordings
                    else ...[
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SessionLibraryScreen(),
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show permission dialog when critical permissions are not granted
  Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Permissions Required'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To join the meeting, please grant the following permissions:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.videocam, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Camera - for video sharing'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.mic, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Microphone - for audio'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.screen_share, size: 20, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Screen sharing - for presentations'),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.storage, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Storage - for file sharing'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Note: You can still join without some permissions, but features may be limited.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Try to open app settings
                    try {
                      await LiveKitService.openAppSettings();
                    } catch (e) {
                      print('Error opening app settings: $e');
                    }
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Open Settings'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Continue Anyway'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

class _MeetingData {
  final String title;
  final String purpose;
  final String date;
  final String time;
  final int participants;
  final bool isActive;
  final String occurrenceId; // Actual meeting ID from the database
  final String scheduleId; // Schedule ID from the database
  final String hostId; // Host ID for the meeting
  final String hostName; // Host name for the meeting

  _MeetingData({
    required this.title,
    this.purpose = '',
    required this.date,
    required this.time,
    required this.participants,
    this.isActive = false,
    required this.occurrenceId, // Required field
    required this.scheduleId, // Required field
    this.hostId = '', // Optional with default
    this.hostName = 'Instructor', // Optional with default
  });
}
