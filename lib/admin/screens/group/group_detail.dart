import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../event/src/group_page/group_api_service.dart';
import 'package:fluttertest/instructor/services/socket_service.dart';
import 'package:fluttertest/instructor/utils/scroll_utils.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupDescription;
  final int memberCount;
  final Color color;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.memberCount,
    required this.color,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _instructors = [];
  Map<String, dynamic>? _groupDetails;
  bool _isLoading = true;
  bool _isAddingStudent = false;
  bool _shouldScrollToBottom = true;
  final TextEditingController _studentEmailController = TextEditingController();

  // Socket service instance
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _messageReadSubscription;

  // Typing status tracking
  Map<String, dynamic> _typingUsers = {}; // userId -> {userName, timestamp}
  Timer? _typingTimer;

  // Add this field for tracking pending messages
  Map<String, Map<String, dynamic>> _pendingMessages =
      {}; // tempId -> full message data

  // Add this field to track if we've joined the group
  bool _hasJoinedGroup = false;

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    //debugPrint('GroupDetailPage groupId: ${widget.groupId}');
    _fetchGroupDetails();
    _fetchCurrentUserId();
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _initSocketConnection(),
    );
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await _getUserId();
    print('Current user ID: $_currentUserId');
    setState(() {}); // Update UI if needed
  }

  // Initialize socket connection
  Future<void> _initSocketConnection() async {
    //debugPrint('Initializing socket connection for group ${widget.groupId}');
    bool initialized = false;
    int retryCount = 0;
    const maxRetries = 3;

    // Retry socket initialization
    while (!initialized && retryCount < maxRetries) {
      //debugPrint('Socket initialization attempt ${retryCount + 1}');
      initialized = await _socketService.initSocket();
      if (!initialized) {
        //debugPrint('❌ Failed to initialize socket, retrying in 5 seconds...');
        await Future.delayed(Duration(seconds: 5));
        retryCount++;
      }
    }

    if (initialized) {
      // Wait for socket to connect
      try {
        await _socketService.connectionStatus
            .firstWhere((isConnected) => isConnected)
            .timeout(
              Duration(seconds: 40),
              onTimeout: () {
                //debugPrint('❌ Socket connection timed out after 40 seconds');
                return false;
              },
            );
        if (_socketService.isConnected) {
          //debugPrint('✅ Socket is connected, joining group ${widget.groupId}');
          if (!_hasJoinedGroup) {
            _socketService.joinGroup(widget.groupId);
            _hasJoinedGroup = true;
            //debugPrint('✅ Requested to join group ${widget.groupId}');
          }

          // Set up stream subscriptions
          _messageSubscription = _socketService.messageStream.listen((data) {
            //debugPrint('📬 Received message via stream: $data');
            _handleIncomingMessage(data);
          }, onError: (e) => debugPrint('❌ Message stream error: $e'));

          _typingSubscription = _socketService.typingStream.listen((data) {
            //debugPrint('📝 Received typing event: $data');
            _handleTypingEvent(data);
          });

          _messageReadSubscription = _socketService.messageReadStream.listen((
            data,
          ) {
            //debugPrint('📖 Received message read event: $data');
            _handleMessageReadEvent(data);
          });

          _socketService.connectionStatus.listen((isConnected) {
            //debugPrint('🔌 Connection status changed: $isConnected');
            setState(() {
              // Update UI for connection status
            });
            if (isConnected && !_hasJoinedGroup) {
              _socketService.joinGroup(widget.groupId);
              _hasJoinedGroup = true;
              //debugPrint('✅ Rejoined group ${widget.groupId} on reconnect');
            } else if (!isConnected) {
              _hasJoinedGroup = false;
            }
          });

          //debugPrint('Socket initialized and joined group ${widget.groupId}');
        } else {
          //debugPrint('❌ Socket not connected after initialization');
        }
      } catch (e) {
        //debugPrint('❌ Socket connection error: $e');
      }
    } else {
      //debugPrint('❌ Failed to initialize socket after $maxRetries retries');
    }
  }

  // Handle typing events
  void _handleTypingEvent(Map<String, dynamic> data) {
    if (data['groupId'] != widget.groupId) return;

    final String userId = data['userId'] ?? '';
    final String userName = data['userName'] ?? 'Someone';
    final bool isTyping = data['isTyping'] ?? false;

    setState(() {
      if (isTyping) {
        // Add or update user in typing list
        _typingUsers[userId] = {
          'userName': userName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        // Remove user from typing list
        _typingUsers.remove(userId);
      }
    });

    // Clean up old typing statuses after 5 seconds
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final staleCutoff = now - 5000; // 5 seconds

      setState(() {
        _typingUsers.removeWhere(
          (key, value) => value['timestamp'] < staleCutoff,
        );
      });
    });
  }

  // Handle message read events
  void _handleMessageReadEvent(Map<String, dynamic> data) {
    if (data['groupId'] != widget.groupId) return;

    final String messageId = data['messageId'] ?? '';
    final String userId = data['userId'] ?? '';

    if (messageId.isNotEmpty) {
      setState(() {
        final msgIndex = _messages.indexWhere((msg) => msg['_id'] == messageId);
        if (msgIndex != -1) {
          // Add userId to the read list for this message
          if (_messages[msgIndex]['readBy'] == null) {
            _messages[msgIndex]['readBy'] = [];
          }

          // Ensure we don't add duplicates
          if (!(_messages[msgIndex]['readBy'] as List).contains(userId)) {
            (_messages[msgIndex]['readBy'] as List).add(userId);
          }

          _messages[msgIndex]['status'] = 'read';
        }
      });
    }
  }

  Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print("<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
      return prefs.getString('user_id') ?? '';
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return '';
    }
  }

  // Handle incoming socket messages
  void _handleIncomingMessage(Map<String, dynamic> data) {
    //debugPrint('Received message via socket: $data');

    String? receivedGroupId = data['groupId'] is Map
        ? data['groupId']['_id']?.toString()
        : data['groupId']?.toString();

    if (receivedGroupId != widget.groupId) return;

    // Enhanced duplicate check
    final msgId = data['_id']?.toString();
    final msgContent = data['content']?.toString();
    final msgTimeStr = data['createdAt']?.toString();
    DateTime? msgTime;
    try {
      msgTime = DateTime.parse(msgTimeStr ?? '');
    } catch (e) {}

    bool isDuplicate = false;

    // Check 1: Exact ID match
    if (msgId != null && _messages.any((msg) => msg['_id'] == msgId)) {
      isDuplicate = true;
    }
    // Check 2: For outgoing messages - match temp via content + time (±5s)
    else if (msgContent != null && msgTime != null) {
      for (var msg in _messages) {
        if (msg['tempId'] != null && // It's pending
            msg['content'] == msgContent &&
            msg['senderId']?['_id'] ==
                data['senderId']?['_id'] && // Same sender
            msgTime
                    .difference(DateTime.parse(msg['createdAt'] ?? ''))
                    .inSeconds
                    .abs() <
                5) {
          // Replace temp with real
          final index = _messages.indexOf(msg);
          if (index != -1) {
            _messages[index] = {...data, 'status': 'delivered'};
            _sortMessagesByTimestamp();
            _pendingMessages.remove(msg['tempId']);
          }
          isDuplicate = true;
          break;
        }
      }
    }

    if (isDuplicate) {
      //debugPrint('Duplicate message ignored: $msgId');
      return;
    }

    // Proceed with add
    _shouldScrollToBottom = ScrollUtils.isAtBottom(_scrollController);
    setState(() {
      _messages.add(data);
      _sortMessagesByTimestamp();
    });
    if (_shouldScrollToBottom) {
      Future.delayed(const Duration(milliseconds: 100), () {
        ScrollUtils.scrollToBottom(_scrollController);
      });
    }
  }

  // Sort messages by timestamp (oldest first, like WhatsApp)
  void _sortMessagesByTimestamp() {
    _messages.sort((a, b) {
      final String aTimeStr = a['createdAt']?.toString() ?? '';
      final String bTimeStr = b['createdAt']?.toString() ?? '';

      // Parse dates safely
      DateTime? aTime;
      DateTime? bTime;

      try {
        aTime = DateTime.parse(aTimeStr);
      } catch (e) {
        aTime = DateTime(1970); // Default date if parsing fails
      }

      try {
        bTime = DateTime.parse(bTimeStr);
      } catch (e) {
        bTime = DateTime(1970); // Default date if parsing fails
      }

      // Sort oldest first (ascending order)
      return aTime.compareTo(bTime);
    });
  }

  Future<void> _fetchGroupDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use GroupService to get group details with messages in a single API call
      final result = await GroupService.getGroupDetailsWithMessages(
        widget.groupId,
      );
      //print('API response: $result');

      if (result['success']) {
        final groupDetails = result['groupDetails'] as Map<String, dynamic>;
        final messages = result['messages'] as List<Map<String, dynamic>>;
        final students = result['students'] as List<Map<String, dynamic>>;
        final memberCounts = result['memberCounts'] as Map<String, dynamic>;
        //print('Group details: $groupDetails');
        print('Messages: ${messages}');
        //print('Students: ${students.length}');
        //print('Member counts: $memberCounts');

        // Filter students into students and instructors lists
        final List<Map<String, dynamic>> studentsList = [];
        final List<Map<String, dynamic>> instructorsList = [];

        // Include instructors from the instructors array if available
        if (groupDetails['instructors'] != null &&
            groupDetails['instructors'] is List) {
          List<Map<String, dynamic>> instructorsFromGroup =
              List<Map<String, dynamic>>.from(groupDetails['instructors']);
          instructorsList.addAll(instructorsFromGroup);
          //print(
          //   'Added ${instructorsFromGroup.length} instructors from group details',
          // );
        }

        // Process students
        for (var student in students) {
          if (student['role'] == 'instructor') {
            // Avoid duplicates
            if (!instructorsList.any((i) => i['_id'] == student['_id'])) {
              instructorsList.add(student);
            }
          } else {
            studentsList.add(student);
          }
        }

        // Add admin as instructor if not already included
        if (groupDetails['admin'] != null && groupDetails['admin'] is Map) {
          final admin = groupDetails['admin'] as Map<String, dynamic>;
          if (!instructorsList.any((i) => i['_id'] == admin['_id'])) {
            admin['role'] = 'admin';
            instructorsList.add(admin);
            //print('Added admin to instructors list');
          }
        }

        //print(
        // 'Final counts: ${studentsList.length} students, ${instructorsList.length} instructors',
        // );

        // Convert messages to a properly typed list
        List<Map<String, dynamic>> typedMessages =
            List<Map<String, dynamic>>.from(messages);

        setState(() {
          _students = studentsList;
          _instructors = instructorsList;
          _messages = typedMessages;
          _sortMessagesByTimestamp(); // Sort messages in chronological order
          _groupDetails = groupDetails;
          _isLoading = false;
        });

        // Scroll to the bottom after the messages are loaded and UI is updated
        Future.delayed(const Duration(milliseconds: 300), () {
          ScrollUtils.scrollToBottom(_scrollController);
        });
      } else {
        // Fallback to separate API calls if the combined endpoint fails
        //print('Falling back to separate API calls: ${result['message']}');
        await _fetchGroupDetailsLegacy();
      }
    } catch (e) {
      //print('Error fetching group details: $e');
      // Try fallback method
      await _fetchGroupDetailsLegacy();
    }
  }

  // Legacy method for backward compatibility using separate API calls
  Future<void> _fetchGroupDetailsLegacy() async {
    try {
      // Use GroupService to get group students and messages in parallel
      final studentsResult = await GroupService.getGroupStudents(
        widget.groupId,
      );
      final messagesResult = await GroupService.getGroupMessages(
        widget.groupId,
      );

      if (studentsResult['success'] && messagesResult['success']) {
        final students =
            studentsResult['students'] as List<Map<String, dynamic>>;
        final messages =
            messagesResult['messages'] as List<Map<String, dynamic>>;

        // Filter students into students and instructors lists
        final List<Map<String, dynamic>> studentsList = [];
        final List<Map<String, dynamic>> instructorsList = [];

        for (var student in students) {
          if (student['role'] == 'instructor') {
            instructorsList.add(student);
          } else {
            studentsList.add(student);
          }
        }

        setState(() {
          _students = studentsList;
          _instructors = instructorsList;
          _messages = messages;

          // Construct group details using widget data as fallback
          _groupDetails = {
            'name': widget.groupName,
            'description': widget.groupDescription,
            'students': students,
            'memberCounts': {'total': widget.memberCount},
          };

          _isLoading = false;
        });

        // Scroll to the bottom after the messages are loaded
        Future.delayed(const Duration(milliseconds: 300), () {
          ScrollUtils.scrollToBottom(_scrollController);
        });
      } else {
        throw Exception(
          'Failed to load group details: ${studentsResult['message'] ?? messagesResult['message']}',
        );
      }
    } catch (e) {
      //print('Error in legacy method for fetching group details: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load group details: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                _fetchGroupDetails();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    // Generate a temporary ID for the message for optimistic updates
    final tempMsgId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final currentTime = DateTime.now().toString();

    // Get current user ID if not already fetched
    _currentUserId ??= await _getUserId();

    // Optimistic update
    setState(() {
      final tempMessage = {
        'tempId': tempMsgId,
        'content': message,
        'createdAt': currentTime,
        'senderId': {'_id': _currentUserId ?? 'current-user', 'name': 'You'},
        'groupId': widget.groupId,
        'status': 'sending',
      };
      _messages.add(tempMessage);
      _sortMessagesByTimestamp();
      _pendingMessages[tempMsgId] = tempMessage; // Track it
    });

    // Scroll to bottom to show the new message
    Future.delayed(const Duration(milliseconds: 100), () {
      ScrollUtils.scrollToBottom(_scrollController);
    });

    try {
      // Send message via socket if connected
      if (_socketService.isConnected) {
        _socketService.sendGroupMessage(widget.groupId, message);
        //debugPrint('Message sent via socket');

        // Update message status to delivered
        setState(() {
          final msgIndex = _messages.indexWhere(
            (msg) => msg['tempId'] == tempMsgId,
          );
          if (msgIndex != -1) {
            _messages[msgIndex]['status'] = 'delivered';
          }
        });
      } else {
        // Handle case where socket is not connected
        setState(() {
          final msgIndex = _messages.indexWhere(
            (msg) => msg['tempId'] == tempMsgId,
          );
          if (msgIndex != -1) {
            _messages[msgIndex]['status'] = 'failed';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to send message: No connection available',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () {
                // Remove failed message and retry
                setState(() {
                  final msgIndex = _messages.indexWhere(
                    (msg) => msg['tempId'] == tempMsgId,
                  );
                  if (msgIndex != -1) {
                    _messages.removeAt(msgIndex);
                  }
                });
                _messageController.text = message;
                _sendMessage();
              },
            ),
          ),
        );
      }
    } catch (e) {
      //debugPrint('Error sending message via socket: $e');

      setState(() {
        final msgIndex = _messages.indexWhere(
          (msg) => msg['tempId'] == tempMsgId,
        );
        if (msgIndex != -1) {
          _messages[msgIndex]['status'] = 'failed';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () {
              // Remove failed message and retry
              setState(() {
                final msgIndex = _messages.indexWhere(
                  (msg) => msg['tempId'] == tempMsgId,
                );
                if (msgIndex != -1) {
                  _messages.removeAt(msgIndex);
                }
              });
              _messageController.text = message;
              _sendMessage();
            },
          ),
        ),
      );
    }
  }

  Future<void> _addStudentToGroup() async {
    if (_studentEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a student email or ID')),
      );
      return;
    }

    setState(() {
      _isAddingStudent = true;
    });

    try {
      final input = _studentEmailController.text.trim();
      String? studentId;

      // Check if input looks like a MongoDB ObjectId
      if (RegExp(r'^[0-9a-f]{24}$').hasMatch(input)) {
        // It's already a student ID
        //print('Input looks like a student ID: $input');
        studentId = input;
      } else if (input.contains('@')) {
        // Try to find student by email
        //print('Input looks like an email, searching for student ID');
        final result = await GroupService.findStudentByEmail(input);
        if (result['success'] == true && result['studentId'] != null) {
          studentId = result['studentId'];
          //print('Found student with ID: $studentId');
        }
      } else {
        // Try to find student by email anyway as a fallback
        //print('Input format unclear, trying as email: $input');
        final result = await GroupService.findStudentByEmail(input);
        if (result['success'] == true && result['studentId'] != null) {
          studentId = result['studentId'];
          //print('Found student with ID: $studentId');
        }
      }

      if (studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Student not found. Please check the email or ID and try again.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isAddingStudent = false;
        });
        return;
      }

      //print(
      // 'Using student ID: $studentId - Adding to group: ${widget.groupId}',
      // );

      // Use GroupService to add the student to the group
      final result = await GroupService.addStudentToGroup(
        widget.groupId,
        studentId,
      );
      //print('Add student result: $result');

      if (result['success']) {
        _studentEmailController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh group details to show the new student
        await _fetchGroupDetails();

        // Close dialog if it's still open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show members dialog again with updated list
        _showMembersDialog();
      } else {
        // Show helpful message for common errors
        String message = result['message'] ?? 'Failed to add student';

        // Give more specific guidance based on error message
        if (message.toLowerCase().contains('not found')) {
          message =
              'Student ID not found or does not exist. Please verify the ID is correct.';
        } else if (message.toLowerCase().contains('already exists')) {
          message = 'This student is already in the group.';
        } else if (message.toLowerCase().contains('permission')) {
          message = 'You do not have permission to add students to this group.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      //print('Error adding student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add student: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingStudent = false;
      });
    }
  }

  Future<void> _removeStudentFromGroup(String studentId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Removal'),
          content: const Text(
            'Are you sure you want to remove this student from the group?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      //print('Removing student $studentId from group ${widget.groupId}');

      // Use GroupService to remove the student from the group
      final result = await GroupService.removeStudentFromGroup(
        widget.groupId,
        studentId,
      );
      //print('Remove student result: $result');

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh group details to update the student list
        await _fetchGroupDetails();

        // Close dialog if it's still open
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show members dialog again with updated list
        _showMembersDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      //print('Error removing student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove student: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFF5F299E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              _showMembersDialog();
            },
            tooltip: 'Group Members',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showGroupInfoDialog();
            },
            tooltip: 'Group Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F299E)),
            )
          : Column(
              children: [
                // Group info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.color,
                        radius: 24,
                        child: Text(
                          widget.groupName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.groupName,
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.groupDescription} • ${widget.memberCount} members',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: isDark ? Colors.black : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          // Display messages in chronological order (oldest at top, newest at bottom)
                          reverse: false,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            // Use the index directly since we're not reversing the list
                            final message = _messages[index];
                            //printToConsole('Building message item: $message');
                            final isCurrentUser =
                                (message['senderId'] is Map
                                    ? message['senderId']['_id']
                                    : null) ==
                                _currentUserId;
                            print(message['senderId']['_id']);
                            print("isCurrentUser: $isCurrentUser");
                            // Mark message as read when it appears on screen
                            // This is using a post-frame callback to ensure it runs after the widget is built
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              // Only mark messages as read if they haven't been marked already
                              // and they have a valid ID (not a temporary message)
                              if (message['_id'] != null &&
                                  message['status'] != 'read' &&
                                  message['senderId'] != null &&
                                  message['senderId'] is Map &&
                                  message['senderId']['_id'] !=
                                      _currentUserId) {
                                _socketService.markMessageAsRead(
                                  message['_id'],
                                  widget.groupId,
                                );
                              }
                            });

                            final sender = message['senderId'] is Map
                                ? message['senderId']['name'] ?? 'Unknown'
                                : 'Unknown';
                            final content =
                                message['content'] ??
                                message['decryptedContent'] ??
                                '';
                            final timestamp = _formatTimestamp(
                              message['createdAt'] ?? '',
                            );
                            final isSystemMessage =
                                message['isSystemMessage'] == true;
                            final isInstructor = _instructors.any(
                              (instructor) =>
                                  instructor['_id'] ==
                                  (message['senderId'] is Map
                                      ? message['senderId']['_id']
                                      : null),
                            );

                            if (isSystemMessage) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        143,
                                        28,
                                        28,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      content,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                // Debug color
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: isCurrentUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser)
                                      CircleAvatar(
                                        backgroundColor: isInstructor
                                            ? const Color(0xFF5F299E)
                                            : Colors.grey[400],
                                        child: Text(
                                          sender.substring(0, 1),
                                          style: const TextStyle(),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 250,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                sender,
                                                textAlign: isCurrentUser
                                                    ? TextAlign.right
                                                    : TextAlign
                                                          .left, // ✅ move here
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,

                                                  // color: isInstructor
                                                  //     ? const Color(0xFF5F299E)
                                                  //     : Theme.of(context)
                                                  //           .textTheme
                                                  //           .bodyMedium
                                                  //           ?.color,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                timestamp,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        content,
                                                        softWrap: true,
                                                        style: TextStyle(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (message['status'] !=
                                                    null) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (message['status'] ==
                                                          'sending')
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      if (message['status'] ==
                                                          'socket-delivered')
                                                        Icon(
                                                          Icons.check,
                                                          size: 12,
                                                          color:
                                                              Colors.blue[600],
                                                        ),
                                                      if (message['status'] ==
                                                          'delivered')
                                                        Icon(
                                                          Icons.done_all,
                                                          size: 12,
                                                          color:
                                                              Colors.blue[600],
                                                        ),
                                                      if (message['status'] ==
                                                          'socket-only')
                                                        Icon(
                                                          Icons.wifi,
                                                          size: 12,
                                                          color:
                                                              Colors.green[600],
                                                        ),
                                                      if (message['status'] ==
                                                          'failed')
                                                        Icon(
                                                          Icons.error_outline,
                                                          size: 12,
                                                          color:
                                                              Colors.red[600],
                                                        ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        message['status'] ==
                                                                'sending'
                                                            ? 'Sending...'
                                                            : message['status'] ==
                                                                  'socket-delivered'
                                                            ? 'Delivered'
                                                            : message['status'] ==
                                                                  'delivered'
                                                            ? 'Saved'
                                                            : message['status'] ==
                                                                  'socket-only'
                                                            ? 'Delivered (not saved)'
                                                            : message['status'] ==
                                                                  'failed'
                                                            ? 'Failed'
                                                            : '',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              message['status'] ==
                                                                  'failed'
                                                              ? Colors.red[600]
                                                              : Colors
                                                                    .grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCurrentUser)
                                      CircleAvatar(
                                        backgroundColor: isInstructor
                                            ? const Color(0xFF5F299E)
                                            : Colors.grey[400],
                                        child: Text(
                                          sender.substring(0, 1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Message input
                Column(
                  children: [
                    // Socket connection indicator
                    Column(
                      children: [
                        // Connection status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          width: double.infinity,
                          color: _socketService.isConnected
                              ? Colors.green[100]
                              : Colors.orange[100],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _socketService.isConnected
                                    ? Icons.check_circle
                                    : Icons.wifi_off,
                                size: 14,
                                color: _socketService.isConnected
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _socketService.isConnected
                                    ? 'Live chat connected'
                                    : 'Chat offline - messages saved locally',
                                style: TextStyle(
                                  color: _socketService.isConnected
                                      ? Colors.green
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Typing indicator
                        if (_typingUsers.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 8),
                                _buildTypingIndicator(),
                                const SizedBox(width: 4),
                                Text(
                                  _getTypingText(),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Retry connection button if disconnected
                    if (!_socketService.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: Colors.orange[50],
                        child: GestureDetector(
                          onTap: () async {
                            // Show reconnecting indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Attempting to reconnect...'),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            // Re-initialize socket connection
                            _socketService.dispose();
                            await _initSocketConnection();
                          },
                          child: Text(
                            'Retry connection',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: () {
                              // Attachment functionality
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              onChanged: (text) {
                                // Send typing status when the user types
                                if (_socketService.isConnected) {
                                  // Only send typing = true when the field is not empty
                                  if (text.isNotEmpty) {
                                    _socketService.sendTypingStatus(
                                      widget.groupId,
                                      true,
                                    );
                                  } else {
                                    _socketService.sendTypingStatus(
                                      widget.groupId,
                                      false,
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            color: const Color(0xFF5F299E),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showGroupInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.groupName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Course', widget.groupDescription),
                _infoRow(
                  'Members',
                  '${_students.length} students, ${_instructors.length} instructors',
                ),
                _infoRow(
                  'Created by',
                  _groupDetails?['admin']?['name'] ?? 'Admin',
                ),
                _infoRow('Group ID', widget.groupId),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Group Members'),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add student form
                      const Text(
                        'Add Student',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _studentEmailController,
                              decoration: const InputDecoration(
                                hintText: 'Enter student email or ID',
                                helperText:
                                    'Enter email address or 24-character MongoDB ID',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5F299E),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isAddingStudent
                                ? null
                                : () {
                                    _addStudentToGroup().then((_) {
                                      setState(() {}); // Refresh the dialog
                                    });
                                  },
                            child: _isAddingStudent
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),

                      // Instructors list
                      const Text(
                        'Instructors',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _instructors.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No instructors assigned to this group',
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _instructors.length,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              itemBuilder: (context, index) {
                                final instructor = _instructors[index];
                                final bool isAdmin =
                                    instructor['role'] == 'admin';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isAdmin
                                          ? Colors.orange
                                          : const Color(0xFF5F299E),
                                      backgroundImage:
                                          instructor['avatar'] != null
                                          ? NetworkImage(instructor['avatar'])
                                          : null,
                                      child: instructor['avatar'] == null
                                          ? Text(
                                              (instructor['name'] ?? 'U')
                                                  .toString()
                                                  .substring(0, 1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      instructor['name'] ??
                                          'Unknown Instructor',
                                      style: TextStyle(
                                        fontWeight: isAdmin
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: isAdmin
                                        ? const Text(
                                            'Group Admin',
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 16),

                      // Students list
                      Row(
                        children: [
                          const Text(
                            'Students',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5F299E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_students.length}',
                              style: const TextStyle(
                                color: Color(0xFF5F299E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _students.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text('No students in this group yet'),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _students.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[400],
                                    backgroundImage: student['avatar'] != null
                                        ? NetworkImage(student['avatar'])
                                        : null,
                                    child: student['avatar'] == null
                                        ? Text(
                                            student['name']
                                                .toString()
                                                .substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    student['name'] ?? 'Unknown Student',
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Remove student',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove Student'),
                                          content: Text(
                                            'Are you sure you want to remove ${student['name']} from this group?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _removeStudentFromGroup(
                                                  student['_id'],
                                                ).then((_) {
                                                  setState(
                                                    () {},
                                                  ); // Refresh the dialog
                                                });
                                              },
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    ).then(
      (_) => _fetchGroupDetails(),
    ); // Refresh group details when dialog is closed
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup socket resources
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageReadSubscription?.cancel();
    _socketService.leaveGroup(widget.groupId);

    // Cancel typing timer
    _typingTimer?.cancel();

    // Dispose controllers
    _messageController.dispose();
    _studentEmailController.dispose();
    _scrollController.dispose();

    _pendingMessages.clear();
    _hasJoinedGroup = false;
    super.dispose();
  }

  // Build typing indicator animation
  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 30,
      child: Row(children: [_buildDot(0), _buildDot(1), _buildDot(2)]),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          0,
          (DateTime.now().millisecondsSinceEpoch / 500 + index * 0.5) % 2 == 0
              ? -1
              : 1,
          0,
        ),
      ),
    );
  }

  // Get text showing who's typing
  String _getTypingText() {
    if (_typingUsers.isEmpty) return '';

    final names = _typingUsers.values
        .map((user) => user['userName'] as String)
        .toList();

    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }
}
