// <--------rohit---->
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message.dart';
import '../../services/groups_service.dart';
import "../../services/socket_service.dart"; // Import for WebSocket
import '../../../instructor/utils/scroll_utils.dart'; // Import for scroll utilities
import 'GroupInfoPage.dart';
import 'dart:async';

class GroupChatPage extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupChatPage({super.key, required this.group});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroupsService _groupsService = GroupsService();
  final SocketService _socketService = SocketService(); // Singleton instance
  late String _groupId;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _messageReadSubscription;
  Map<String, dynamic> _typingUsers = {}; // userId -> {userName, timestamp}
  Timer? _typingTimer;
  bool _shouldScrollToBottom = true;
  bool _isSocketInitializing = true; // Track initialization state
  bool _socketFailed = false; // Track socket initialization failure

  @override
  void initState() {
    super.initState();
    _groupId = widget.group['id'] ?? '1';

    // Initialize chat and WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.initializeGroupChat(_groupId);
      _initSocketConnection();
      _scrollToBottom();
      // _fetchGroupDetails();
    });

    // Listen to new messages from ChatProvider
    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).addListener(_onNewMessage);
  }

  Future<void> _fetchGroupDetails() async {
    print(
      "dcfvgbhnjmklkjnhbgvfcdxsdcfvgbhnjmkjnhbgvfcdxsxdcfvgbhnjmkmjnhbgvfcd",
    );
    try {
      final groupsService = GroupsService();
      final result = await groupsService.getGroupWithMessages(_groupId);

      var data = result.data;
      data = data?['data'] as Map<String, dynamic>?;
      print("$data bdcujhdkhdkjhjdvkjdhjhjdvbdjh");
      if (result.isSuccess && data != null) {
        final messages = (data['messages']?['items'] as List<dynamic>?) ?? [];
        print("11111111111111111111111111$messages");
        for (var msg in messages) {
          print("22222222222222222222222$msg");
          _handleIncomingMessage(msg as Map<String, dynamic>);
        }
      } else {
        print('Failed to fetch group details: ${result.message}');
      }
    } catch (e) {
      print('Error fetching group details: $e');
    }
  }

  // Initialize WebSocket connection
  Future<void> _initSocketConnection() async {
    setState(() {
      _isSocketInitializing = true;
      _socketFailed = false;
    });
    try {
      bool initialized = await _socketService.initSocket();
      if (initialized) {
        _socketService.joinGroup(_groupId);

        // Listen for incoming messages
        _messageSubscription = _socketService.messageStream.listen((data) {
          debugPrint(
            'Received message: $data',
          ); // Log incoming message for debugging
          _handleIncomingMessage(data);
        });

        // Listen for typing events
        _typingSubscription = _socketService.typingStream.listen((data) {
          _handleTypingEvent(data);
        });

        // Listen for message read events
        _messageReadSubscription = _socketService.messageReadStream.listen((
          data,
        ) {
          _handleMessageReadEvent(data);
        });

        // Listen for connection status changes
        _socketService.connectionStatus.listen((isConnected) {
          setState(() {}); // Trigger UI update
          if (isConnected) {
            _socketService.joinGroup(_groupId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing socket: $e');
      setState(() {
        _socketFailed = true;
      });
    } finally {
      setState(() {
        _isSocketInitializing = false;
      });
    }
  }

  // Handle incoming WebSocket messages
  void _handleIncomingMessage(Map<String, dynamic> data) {
    // if (data['groupId'] != _groupId) return;
    print(
      "Incoming message data>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $data",
    );
    _shouldScrollToBottom = ScrollUtils.isAtBottom(_scrollController);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(
      _groupId,
      Message(
        id: data['_id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
        groupId: _groupId,
        senderId: data['senderId']?['_id'] ?? 'unknown',
        senderName: data['senderId']?['name'] ?? 'Unknown',
        text: data['content'] ?? '',
        timestamp: DateTime.parse(
          data['createdAt'] ?? DateTime.now().toString(),
        ),
        isRead:
            (data['readBy'] as List<dynamic>?)?.contains('current_user_id') ??
            false,
      ),
    );

    if (_shouldScrollToBottom) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  // Handle typing events
  void _handleTypingEvent(Map<String, dynamic> data) {
    if (data['groupId'] != _groupId) return;

    final String userId = data['userId'] ?? '';
    final String userName = data['userName'] ?? 'Someone';
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

  // Handle message read events
  void _handleMessageReadEvent(Map<String, dynamic> data) {
    if (data['groupId'] != _groupId) return;

    final String messageId = data['messageId'] ?? '';
    final String userId = data['userId'] ?? '';

    if (messageId.isNotEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.markMessageAsRead(_groupId, messageId, userId);
    }
  }

  void _onNewMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Send message - DISABLED (read-only chat)
  Future<void> _sendMessage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat is read-only. You cannot send messages.'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.removeListener(_onNewMessage);
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageReadSubscription?.cancel();
    _socketService.leaveGroup(_groupId);
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context, isDarkMode),
      body: Column(
        children: [
          // Connection and Typing Indicators
          Column(
            children: [
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                width: double.infinity,
                color: _isSocketInitializing
                    ? Colors.grey[300]
                    : (_socketFailed || !_socketService.isConnected
                          ? Colors.red[100]
                          : Colors.green[100]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSocketInitializing
                          ? Icons.sync
                          : (_socketFailed || !_socketService.isConnected
                                ? Icons.error
                                : Icons.check_circle),
                      size: 14,
                      color: _isSocketInitializing
                          ? Colors.grey[600]
                          : (_socketFailed || !_socketService.isConnected
                                ? Colors.red
                                : Colors.green),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSocketInitializing
                          ? 'Connecting to chat...'
                          : (_socketFailed
                                ? 'Failed to connect: Check authentication'
                                : (_socketService.isConnected
                                      ? 'Live chat connected'
                                      : 'Chat offline - messages will be delayed')),
                      style: TextStyle(
                        color: _isSocketInitializing
                            ? Colors.grey[600]
                            : (_socketFailed || !_socketService.isConnected
                                  ? Colors.red
                                  : Colors.green),
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
              // Retry connection button
              if (!_isSocketInitializing &&
                  (_socketFailed || !_socketService.isConnected))
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  width: double.infinity,
                  alignment: Alignment.center,
                  color: Colors.red[50],
                  child: GestureDetector(
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attempting to reconnect...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
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
            ],
          ),
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getGroupMessages(_groupId);
                print("Messages in UI>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $messages");
                final isLoading = chatProvider.isLoading(_groupId);
                final error = chatProvider.getError(_groupId);

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              chatProvider.refreshMessages(_groupId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No messages in this group.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // Mark message as read when it appears
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (message.id != null &&
                          !message.isRead &&
                          message.senderId != 'current_user_id') {
                        _socketService.markMessageAsRead(message.id!, _groupId);
                      }
                    });
                    return _buildMessageBubble(message, isDarkMode);
                  },
                );
              },
            ),
          ),
          // Message Input - DISABLED (read-only chat)
          _buildReadOnlyMessageInput(isDarkMode),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode
          ? const Color(0xFF2D1B69)
          : const Color(0xFF5F299E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => _showGroupInfo(context),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(
                      int.parse(
                            (widget.group['color'] ?? '#DC2626').substring(1),
                            radix: 16,
                          ) +
                          0xFF000000,
                    ),
                    Color(
                      int.parse(
                            (widget.group['color'] ?? '#DC2626').substring(1),
                            radix: 16,
                          ) +
                          0xFF000000,
                    ).withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  widget.group['name'][0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuSelection,
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'group_info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.black),
                  SizedBox(width: 12),
                  Text('Group info'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20, color: Colors.black),
                  SizedBox(width: 12),
                  Text('Refresh messages'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'leave_group',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Leave group', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isDarkMode) {
    final isMe = message.senderId == 'current_user_id';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF5F299E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  message.senderName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF5F299E)],
                      )
                    : null,
                color: isMe ? null : (isDarkMode ? Colors.black : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImage) ...[
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: message.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.senderName ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? Colors.white
                          : (isDarkMode
                                ? Colors.white
                                : const Color(0xFF2D3748)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe
                          ? Colors.white
                          : (isDarkMode
                                ? Colors.white
                                : const Color(0xFF2D3748)),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe
                              ? Colors.white.withOpacity(0.8)
                              : (isDarkMode
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.grey[600]),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead
                              ? Colors.blue.withOpacity(0.8)
                              : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildReadOnlyMessageInput(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: false, // Disabled for read-only
                      decoration: InputDecoration(
                        hintText: 'Chat is read-only',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.4)
                              : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.4)
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey[400],
                    ),
                    onPressed: null, // Disabled
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey[400],
                    ),
                    onPressed: null, // Disabled
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.grey, size: 20),
              onPressed: null, // Disabled
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'group_info':
        _showGroupInfo(context);
        break;
      case 'refresh':
        _refreshMessages();
        break;
      case 'leave_group':
        _showLeaveGroupDialog();
        break;
    }
  }

  void _refreshMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.refreshMessages(_groupId);
  }

  void _showGroupInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupInfoPage(group: widget.group),
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave group'),
          content: Text(
            'Are you sure you want to leave "${widget.group['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Leaving group...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                try {
                  final response = await _groupsService.leaveGroup(_groupId);
                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Left "${widget.group['name']}"')),
                    );
                    Navigator.pop(context, 'left');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to leave group: ${response.message}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error leaving group: ${e.toString()}'),
                    ),
                  );
                }
              },
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 30,
      child: Row(children: [_buildDot(0), _buildDot(1), _buildDot(2)]),
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
    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }
}
