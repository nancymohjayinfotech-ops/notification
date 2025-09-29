import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/instructor/services/group_service.dart';
import 'package:fluttertest/instructor/services/socket_service.dart';
import 'package:fluttertest/instructor/utils/scroll_utils.dart';


class GroupChatPage extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupChatPage({super.key, required this.group});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _studentEmailController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _instructors = [];
  Map<String, dynamic>? _groupDetails;
  bool _isLoading = true;
  bool _isAddingStudent = false;
  bool _shouldScrollToBottom = true;
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _messageReadSubscription;
  Map<String, dynamic> _typingUsers = {};
  Timer? _typingTimer;
  Map<String, Map<String, dynamic>> _pendingMessages = {};
  bool _hasJoinedGroup = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
    Future.delayed(const Duration(milliseconds: 500), _initSocketConnection);
  }

  Future<void> _initSocketConnection() async {
    debugPrint(
      'Initializing socket connection for group ${widget.group['id']}',
    );
    bool initialized = false;
    int retryCount = 0;
    const maxRetries = 3;

    while (!initialized && retryCount < maxRetries) {
      debugPrint('Socket initialization attempt ${retryCount + 1}');
      initialized = await _socketService.initSocket();
      if (!initialized) {
        debugPrint('❌ Failed to initialize socket, retrying in 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        retryCount++;
      }
    }

    if (initialized) {
      try {
        await _socketService.connectionStatus
            .firstWhere((isConnected) => isConnected)
            .timeout(
              const Duration(seconds: 40),
              onTimeout: () {
                debugPrint('❌ Socket connection timed out after 40 seconds');
                return false;
              },
            );
        if (_socketService.isConnected) {
          debugPrint(
            '✅ Socket is connected, joining group ${widget.group['id']}',
          );
          if (!_hasJoinedGroup) {
            _socketService.joinGroup(widget.group['id']?.toString() ?? '');
            _hasJoinedGroup = true;
            debugPrint('✅ Requested to join group ${widget.group['id']}');
          }

          _messageSubscription = _socketService.messageStream.listen(
            _handleIncomingMessage,
            onError: (e) => debugPrint('❌ Message stream error: $e'),
          );

          _typingSubscription = _socketService.typingStream.listen(
            _handleTypingEvent,
            onError: (e) => debugPrint('❌ Typing stream error: $e'),
          );

          _messageReadSubscription = _socketService.messageReadStream.listen(
            _handleMessageReadEvent,
            onError: (e) => debugPrint('❌ Message read stream error: $e'),
          );

          _socketService.connectionStatus.listen((isConnected) {
            debugPrint('🔌 Connection status changed: $isConnected');
            setState(() {});
            if (isConnected && !_hasJoinedGroup) {
              _socketService.joinGroup(widget.group['id']?.toString() ?? '');
              _hasJoinedGroup = true;
              debugPrint('✅ Rejoined group ${widget.group['id']} on reconnect');
            } else if (!isConnected) {
              _hasJoinedGroup = false;
            }
          });
        } else {
          debugPrint('❌ Socket not connected after initialization');
        }
      } catch (e) {
        debugPrint('❌ Socket connection error: $e');
      }
    } else {
      debugPrint('❌ Failed to initialize socket after $maxRetries retries');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to connect to live chat. Messages will be saved locally.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleTypingEvent(Map<String, dynamic> data) {
    if (data['groupId'] != widget.group['id']?.toString()) return;

    final String userId = data['userId']?.toString() ?? '';
    final String userName = data['userName']?.toString() ?? 'Someone';
    final bool isTyping = data['isTyping'] ?? false;

    setState(() {
      if (isTyping) {
        _typingUsers[userId] = {
          'userName': userName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else {
        _typingUsers.remove(userId);
      }
    });

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final staleCutoff = now - 5000;

      setState(() {
        _typingUsers.removeWhere(
          (key, value) => value['timestamp'] < staleCutoff,
        );
      });
    });
  }

  void _handleMessageReadEvent(Map<String, dynamic> data) {
    if (data['groupId'] != widget.group['id']?.toString()) return;

    final String messageId = data['messageId']?.toString() ?? '';
    final String userId = data['userId']?.toString() ?? '';

    if (messageId.isNotEmpty) {
      setState(() {
        final msgIndex = _messages.indexWhere((msg) => msg['_id'] == messageId);
        if (msgIndex != -1) {
          if (_messages[msgIndex]['readBy'] == null) {
            _messages[msgIndex]['readBy'] = [];
          }
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
      return prefs.getString('user_id') ?? '';
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return '';
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    String? receivedGroupId = data['groupId'] is Map
        ? data['groupId']['_id']?.toString()
        : data['groupId']?.toString();

    if (receivedGroupId != widget.group['id']?.toString()) return;

    final msgId = data['_id']?.toString();
    final msgContent = data['content']?.toString();
    final msgTimeStr = data['createdAt']?.toString();
    DateTime? msgTime;
    try {
      msgTime = DateTime.parse(msgTimeStr ?? '');
    } catch (e) {}

    bool isDuplicate = false;

    if (msgId != null && _messages.any((msg) => msg['_id'] == msgId)) {
      isDuplicate = true;
    } else if (msgContent != null && msgTime != null) {
      for (var msg in _messages) {
        if (msg['tempId'] != null &&
            msg['content'] == msgContent &&
            msg['senderId']?['_id'] == data['senderId']?['_id'] &&
            msgTime
                    .difference(DateTime.parse(msg['createdAt'] ?? ''))
                    .inSeconds
                    .abs() <
                5) {
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
      debugPrint('Duplicate message ignored: $msgId');
      return;
    }

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

  void _sortMessagesByTimestamp() {
    _messages.sort((a, b) {
      final String aTimeStr = a['createdAt']?.toString() ?? '';
      final String bTimeStr = b['createdAt']?.toString() ?? '';
      DateTime? aTime;
      DateTime? bTime;

      try {
        aTime = DateTime.parse(aTimeStr);
      } catch (e) {
        aTime = DateTime(1970);
      }

      try {
        bTime = DateTime.parse(bTimeStr);
      } catch (e) {
        bTime = DateTime(1970);
      }

      return aTime.compareTo(bTime);
    });
  }

  Future<void> _fetchGroupDetails() async {
    setState(() => _isLoading = true);

    try {
      final result = await GroupService.getGroupDetailsWithMessages(
        widget.group['id']?.toString() ?? '',
      );
      if (result['success']) {
        final groupDetails = result['groupDetails'] as Map<String, dynamic>;
        final messages = List<Map<String, dynamic>>.from(result['messages']);
        final students = List<Map<String, dynamic>>.from(result['students']);
        final memberCounts = result['memberCounts'] as Map<String, dynamic>;

        final List<Map<String, dynamic>> studentsList = [];
        final List<Map<String, dynamic>> instructorsList = [];

        if (groupDetails['instructors'] != null &&
            groupDetails['instructors'] is List) {
          instructorsList.addAll(
            List<Map<String, dynamic>>.from(groupDetails['instructors']),
          );
        }

        for (var student in students) {
          if (student['role'] == 'instructor') {
            if (!instructorsList.any((i) => i['_id'] == student['_id'])) {
              instructorsList.add(student);
            }
          } else {
            studentsList.add(student);
          }
        }

        if (groupDetails['admin'] != null && groupDetails['admin'] is Map) {
          final admin = groupDetails['admin'] as Map<String, dynamic>;
          if (!instructorsList.any((i) => i['_id'] == admin['_id'])) {
            admin['role'] = 'admin';
            instructorsList.add(admin);
          }
        }

        setState(() {
          _students = studentsList;
          _instructors = instructorsList;
          _messages = messages;
          _sortMessagesByTimestamp();
          _groupDetails = groupDetails;
          _isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          ScrollUtils.scrollToBottom(_scrollController);
        });
      } else {
        throw Exception('Failed to load group details: ${result['message']}');
      }
    } catch (e) {
      debugPrint('Error fetching group details: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load group details: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _fetchGroupDetails,
          ),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();
    final tempMsgId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final currentTime = DateTime.now().toString();
    _currentUserId ??= await _getUserId();

    setState(() {
      final tempMessage = {
        'tempId': tempMsgId,
        'content': message,
        'createdAt': currentTime,
        'senderId': {'_id': _currentUserId ?? 'current-user', 'name': 'You'},
        'groupId': widget.group['id']?.toString(),
        'status': 'sending',
      };
      _messages.add(tempMessage);
      _sortMessagesByTimestamp();
      _pendingMessages[tempMsgId] = tempMessage;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      ScrollUtils.scrollToBottom(_scrollController);
    });

    try {
      if (_socketService.isConnected) {
        _socketService.sendGroupMessage(
          widget.group['id']?.toString() ?? '',
          message,
        );
        setState(() {
          final msgIndex = _messages.indexWhere(
            (msg) => msg['tempId'] == tempMsgId,
          );
          if (msgIndex != -1) {
            _messages[msgIndex]['status'] = 'delivered';
          }
        });
      } else {
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
      debugPrint('Error sending message via socket: $e');
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
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () {
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

    setState(() => _isAddingStudent = true);

    try {
      final input = _studentEmailController.text.trim();
      String? studentId;

      if (RegExp(r'^[0-9a-f]{24}$').hasMatch(input)) {
        studentId = input;
      } else if (input.contains('@')) {
        final result = await GroupService.findStudentByEmail(input);
        if (result['success'] && result['studentId'] != null) {
          studentId = result['studentId'];
        }
      } else {
        final result = await GroupService.findStudentByEmail(input);
        if (result['success'] && result['studentId'] != null) {
          studentId = result['studentId'];
        }
      }

      if (studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student not found. Please check the email or ID.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isAddingStudent = false);
        return;
      }

      final result = await GroupService.addStudentToGroup(
        widget.group['id']?.toString() ?? '',
        studentId,
      );
      if (result['success']) {
        _studentEmailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchGroupDetails();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showMembersDialog();
      } else {
        String message = result['message'] ?? 'Failed to add student';
        if (message.toLowerCase().contains('not found')) {
          message = 'Student ID not found. Please verify the ID.';
        } else if (message.toLowerCase().contains('already exists')) {
          message = 'This student is already in the group.';
        } else if (message.toLowerCase().contains('permission')) {
          message = 'You do not have permission to add students.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint('Error adding student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAddingStudent = false);
    }
  }

  Future<void> _removeStudentFromGroup(String studentId) async {
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

    try {
      final result = await GroupService.removeStudentFromGroup(
        widget.group['id']?.toString() ?? '',
        studentId,
      );
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchGroupDetails();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
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
      debugPrint('Error removing student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove student: $e'),
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
    final groupName = widget.group['name']?.toString() ?? 'Unknown Group';
    final groupDescription =
        widget.group['description']?.toString() ?? 'No description';
    final memberCount = widget.group['memberCount'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          groupName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: _showMembersDialog,
            tooltip: 'Group Members',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupInfoDialog,
            tooltip: 'Group Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 24,
                        child: Text(
                          groupName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
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
                              groupName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$groupDescription • $memberCount members',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: GoogleFonts.poppins(
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
                          reverse: false,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (message['_id'] != null &&
                                  message['status'] != 'read' &&
                                  message['senderId'] is Map &&
                                  message['senderId']['_id'] !=
                                      _currentUserId) {
                                _socketService.markMessageAsRead(
                                  message['_id'],
                                  widget.group['id']?.toString() ?? '',
                                );
                              }
                            });

                            final sender = message['senderId'] is Map
                                ? message['senderId']['name']?.toString() ??
                                      'Unknown'
                                : 'Unknown';
                            final content =
                                message['content']?.toString() ??
                                message['decryptedContent']?.toString() ??
                                '';
                            final timestamp = _formatTimestamp(
                              message['createdAt']?.toString() ?? '',
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
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      content,
                                      style: GoogleFonts.poppins(
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isInstructor
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[400],
                                    child: Text(
                                      sender.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              sender,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                color: isInstructor
                                                    ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                    : Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              timestamp,
                                              style: GoogleFonts.poppins(
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
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                content,
                                                style: GoogleFonts.poppins(),
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
                                                        color: Colors.grey[600],
                                                      ),
                                                    if (message['status'] ==
                                                        'delivered')
                                                      Icon(
                                                        Icons.done_all,
                                                        size: 12,
                                                        color: Colors.blue[600],
                                                      ),
                                                    if (message['status'] ==
                                                        'failed')
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 12,
                                                        color: Colors.red[600],
                                                      ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      message['status'] ==
                                                              'sending'
                                                          ? 'Sending...'
                                                          : message['status'] ==
                                                                'delivered'
                                                          ? 'Delivered'
                                                          : message['status'] ==
                                                                'failed'
                                                          ? 'Failed'
                                                          : '',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        color:
                                                            message['status'] ==
                                                                'failed'
                                                            ? Colors.red[600]
                                                            : Colors.grey[600],
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
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Column(
                  children: [
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
                            style: GoogleFonts.poppins(
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
                    if (_typingUsers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTypingIndicator(),
                            const SizedBox(width: 4),
                            Text(
                              _getTypingText(),
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_socketService.isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: Colors.orange[50],
                        child: GestureDetector(
                          onTap: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Attempting to reconnect...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            _socketService.dispose();
                            await _initSocketConnection();
                          },
                          child: Text(
                            'Retry connection',
                            style: GoogleFonts.poppins(
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
                            onPressed: () {},
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
                                if (_socketService.isConnected) {
                                  _socketService.sendTypingStatus(
                                    widget.group['id']?.toString() ?? '',
                                    text.isNotEmpty,
                                  );
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF5F299E),
                            ),
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
      builder: (context) => AlertDialog(
        title: Text(widget.group['name']?.toString() ?? 'Unknown Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                'Description',
                widget.group['description']?.toString() ?? 'No description',
              ),
              _infoRow(
                'Members',
                '${_students.length} students, ${_instructors.length} instructors',
              ),
              _infoRow(
                'Created by',
                _groupDetails?['admin']?['name']?.toString() ?? 'Admin',
              ),
              _infoRow('Group ID', widget.group['id']?.toString() ?? 'Unknown'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isAddingStudent
                            ? null
                            : () => _addStudentToGroup().then(
                                (_) => setState(() {}),
                              ),
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
                  const Text(
                    'Instructors',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _instructors.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('No instructors assigned'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _instructors.length,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemBuilder: (context, index) {
                            final instructor = _instructors[index];
                            final isAdmin = instructor['role'] == 'admin';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAdmin
                                    ? Colors.orange
                                    : Theme.of(context).primaryColor,
                                backgroundImage: instructor['avatar'] != null
                                    ? NetworkImage(instructor['avatar'])
                                    : null,
                                child: instructor['avatar'] == null
                                    ? Text(
                                        (instructor['name']?.toString() ?? 'U')
                                            .substring(0, 1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                instructor['name']?.toString() ??
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
                                      style: TextStyle(color: Colors.orange),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 16),
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
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_students.length}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _students.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No students in this group yet'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _students.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                                        (student['name']?.toString() ?? 'S')
                                            .substring(0, 1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                student['name']?.toString() ??
                                    'Unknown Student',
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
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
                                        'Are you sure you want to remove ${student['name']?.toString() ?? 'this student'} from this group?',
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
                                            ).then((_) => setState(() {}));
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ).then((_) => _fetchGroupDetails());
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
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 30,
      child: Row(children: List.generate(3, (index) => _buildDot(index))),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
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

  String _getTypingText() {
    if (_typingUsers.isEmpty) return '';
    final names = _typingUsers.values
        .map((user) => user['userName'] as String)
        .toList();
    if (names.length == 1) return '${names[0]} is typing...';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing...';
    return 'Several people are typing...';
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageReadSubscription?.cancel();
    _socketService.leaveGroup(widget.group['id']?.toString() ?? '');
    _typingTimer?.cancel();
    _messageController.dispose();
    _studentEmailController.dispose();
    _scrollController.dispose();
    _pendingMessages.clear();
    _hasJoinedGroup = false;
    super.dispose();
  }
}