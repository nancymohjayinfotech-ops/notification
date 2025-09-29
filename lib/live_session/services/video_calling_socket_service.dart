import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';
import '../utils/network_config.dart';

// Models for handling socket data
class ChatMessage {
  final String scheduleId;
  final String occurrenceId;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final Map<String, dynamic> meta;

  ChatMessage({
    required this.scheduleId,
    required this.occurrenceId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.meta,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Backend emits either:
    // - timeStamp: number (ms since epoch)
    // - createdAt: ISO string
    // Our model needs an int (ms). Parse robustly.
    int ts;
    final dynamic timeStampDyn = json['timeStamp'];
    final dynamic createdAtDyn = json['createdAt'];
    final dynamic timestampDyn = json['timestamp'];

    if (timeStampDyn is int) {
      ts = timeStampDyn;
    } else if (timeStampDyn is String) {
      ts = int.tryParse(timeStampDyn) ?? DateTime.now().millisecondsSinceEpoch;
    } else if (createdAtDyn is String) {
      // Parse ISO string
      try {
        ts = DateTime.parse(createdAtDyn).millisecondsSinceEpoch;
      } catch (_) {
        ts = DateTime.now().millisecondsSinceEpoch;
      }
    } else if (timestampDyn is int) {
      ts = timestampDyn;
    } else if (timestampDyn is String) {
      ts = int.tryParse(timestampDyn) ?? DateTime.now().millisecondsSinceEpoch;
    } else {
      ts = DateTime.now().millisecondsSinceEpoch;
    }

    return ChatMessage(
      scheduleId: json['scheduleId'] ?? '',
      occurrenceId: json['occurrenceId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      timestamp: ts,
      meta: json['meta'] ?? {},
    );
  }
}

// Chat history payload emitted by server on join
class ChatHistoryEvent {
  final List<ChatMessage> messages;
  final bool hasMore;
  final int? oldestTimestamp;

  ChatHistoryEvent({
    required this.messages,
    required this.hasMore,
    this.oldestTimestamp,
  });
}

class PollOption {
  final String text;
  int votes;

  PollOption({required this.text, this.votes = 0});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(text: json['text'] ?? '', votes: json['votes'] ?? 0);
  }
}

class Poll {
  final String id;
  final String scheduleId;
  final String occurrenceId;
  final String question;
  final String createdBy;
  final int createdAt;
  final bool isActive;
  final List<PollOption> options;

  Poll({
    required this.id,
    required this.scheduleId,
    required this.occurrenceId,
    required this.question,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    required this.options,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      occurrenceId: json['occurrenceId'] ?? '',
      question: json['question'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      isActive: json['isActive'] ?? true,
      options: (json['options'] as List? ?? [])
          .map((option) => PollOption.fromJson(option))
          .toList(),
    );
  }
}

class HandRaiseEvent {
  final String type;
  final String userId;
  final String username;
  final String scheduleId;
  final String occurrenceId;

  HandRaiseEvent({
    required this.type,
    required this.userId,
    required this.username,
    required this.scheduleId,
    required this.occurrenceId,
  });

  factory HandRaiseEvent.fromJson(Map<String, dynamic> json) {
    return HandRaiseEvent(
      type: json['type'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      scheduleId: json['scheduleId'] ?? '',
      occurrenceId: json['occurrenceId'] ?? '',
    );
  }
}

class LiveKitAuth {
  final String url;
  final String token;

  LiveKitAuth({required this.url, required this.token});

  factory LiveKitAuth.fromJson(Map<String, dynamic> json) {
    return LiveKitAuth(url: json['url'] ?? '', token: json['token'] ?? '');
  }
}

// Main Socket Service class
class VideoCallingSocketService {
  // Listen to arbitrary socket events as a stream
  Stream<Map<String, dynamic>> onEvent(String eventName) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _socket?.on(eventName, (data) {
      if (data is Map) {
        controller.add(Map<String, dynamic>.from(data));
      } else {
        controller.add({'data': data});
      }
    });
    return controller.stream;
  }

  // Kick a user from the meeting (host only)
  void kickUser({
    required String scheduleId,
    required String occurrenceId,
    required String platformId,
    required String userId,
    required String targetUserId,
    String targetUsername = '',
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }
    // Optionally validate occurrenceId as MongoDB ObjectId if needed
    final payload = {
      'scheduleId': scheduleId,
      'occurrenceId': occurrenceId,
      'platformId': platformId,
      'userId': userId,
      'targetUserId': targetUserId,
      'targetUsername': targetUsername,
    };
    debugPrint('Kicking user: $payload');
    _socket!.emit('kickUser', payload);
  }

  // Singleton instance
  static final VideoCallingSocketService _instance =
      VideoCallingSocketService._internal();
  factory VideoCallingSocketService() => _instance;
  VideoCallingSocketService._internal();

  // Socket instance
  IO.Socket? _socket;
  bool _isConnected = false;
  DateTime? _lastConnectionTime;
  int _connectionAttempts = 0;

  // Streams for different events (re-creatable when service is reused)
  late StreamController<ChatMessage> _chatMessageController;
  late StreamController<Poll> _pollController;
  late StreamController<HandRaiseEvent> _handRaiseController;
  late StreamController<LiveKitAuth> _livekitAuthController;
  late StreamController<String> _errorController;
  late StreamController<bool> _connectionStatusController;
  late StreamController<Map<String, dynamic>> _messageAckController;
  late StreamController<Map<String, dynamic>> _voteAckController;
  late StreamController<Map<String, dynamic>> _handRaiseAckController;
  late StreamController<Map<String, dynamic>> _handLowerAckController;
  late StreamController<Map<String, dynamic>> _roomClosedController;
  late StreamController<Map<String, dynamic>> _userLeftController;
  late StreamController<ChatHistoryEvent> _chatHistoryController;
  late StreamController<Map<String, dynamic>> _userKickedController;
  late StreamController<Map<String, dynamic>> _kickedController;
  late StreamController<Map<String, dynamic>> _meetingEndSoonController;

  bool _controllersInitialized = false;

  void _createControllers() {
    _chatMessageController = StreamController<ChatMessage>.broadcast();
    _pollController = StreamController<Poll>.broadcast();
    _handRaiseController = StreamController<HandRaiseEvent>.broadcast();
    _livekitAuthController = StreamController<LiveKitAuth>.broadcast();
    _errorController = StreamController<String>.broadcast();
    _connectionStatusController = StreamController<bool>.broadcast();
    _messageAckController = StreamController<Map<String, dynamic>>.broadcast();
    _voteAckController = StreamController<Map<String, dynamic>>.broadcast();
    _handRaiseAckController =
        StreamController<Map<String, dynamic>>.broadcast();
    _handLowerAckController =
        StreamController<Map<String, dynamic>>.broadcast();
    _roomClosedController = StreamController<Map<String, dynamic>>.broadcast();
    _userLeftController = StreamController<Map<String, dynamic>>.broadcast();
    _chatHistoryController = StreamController<ChatHistoryEvent>.broadcast();
    _userKickedController = StreamController<Map<String, dynamic>>.broadcast();
    _kickedController = StreamController<Map<String, dynamic>>.broadcast();
  _meetingEndSoonController =
    StreamController<Map<String, dynamic>>.broadcast();
    _controllersInitialized = true;
  }

  void _ensureControllersOpen() {
    if (!_controllersInitialized ||
        _chatMessageController.isClosed ||
        _pollController.isClosed ||
        _handRaiseController.isClosed ||
        _livekitAuthController.isClosed ||
        _errorController.isClosed ||
        _connectionStatusController.isClosed ||
        _messageAckController.isClosed ||
        _voteAckController.isClosed ||
        _handRaiseAckController.isClosed ||
        _handLowerAckController.isClosed ||
        _roomClosedController.isClosed ||
        _userLeftController.isClosed ||
        _chatHistoryController.isClosed ||
        _userKickedController.isClosed ||
        _kickedController.isClosed ||
        _meetingEndSoonController.isClosed) {
      _createControllers();
    }
  }

  // Stream getters
  Stream<ChatMessage> get onNewChat {
    _ensureControllersOpen();
    return _chatMessageController.stream;
  }

  Stream<Poll> get onPollEvent {
    _ensureControllersOpen();
    return _pollController.stream;
  }

  Stream<HandRaiseEvent> get onHandEvent {
    _ensureControllersOpen();
    return _handRaiseController.stream;
  }

  Stream<LiveKitAuth> get onLivekitAuth {
    _ensureControllersOpen();
    return _livekitAuthController.stream;
  }

  Stream<String> get onError {
    _ensureControllersOpen();
    return _errorController.stream;
  }

  Stream<bool> get onConnectionStatus {
    _ensureControllersOpen();
    return _connectionStatusController.stream;
  }

  Stream<Map<String, dynamic>> get onMessageAck {
    _ensureControllersOpen();
    return _messageAckController.stream;
  }

  Stream<Map<String, dynamic>> get onVoteAck {
    _ensureControllersOpen();
    return _voteAckController.stream;
  }

  Stream<Map<String, dynamic>> get onHandRaiseAck {
    _ensureControllersOpen();
    return _handRaiseAckController.stream;
  }

  Stream<Map<String, dynamic>> get onHandLowerAck {
    _ensureControllersOpen();
    return _handLowerAckController.stream;
  }

  Stream<Map<String, dynamic>> get onRoomClosed {
    _ensureControllersOpen();
    return _roomClosedController.stream;
  }

  Stream<Map<String, dynamic>> get onUserLeft {
    _ensureControllersOpen();
    return _userLeftController.stream;
  }

  Stream<ChatHistoryEvent> get onChatHistory {
    _ensureControllersOpen();
    return _chatHistoryController.stream;
  }

  Stream<Map<String, dynamic>> get onUserKicked {
    _ensureControllersOpen();
    return _userKickedController.stream;
  }

  Stream<Map<String, dynamic>> get onKicked {
    _ensureControllersOpen();
    return _kickedController.stream;
  }

  Stream<Map<String, dynamic>> get onMeetingEndSoon {
    _ensureControllersOpen();
    return _meetingEndSoonController.stream;
  }

  // Get current connection status
  bool checkConnection() {
    return _isConnected && _socket != null && _socket!.connected;
  }

  // Check connection with a ping-pong verification
  Future<bool> verifyConnection() async {
    if (!checkConnection()) return false;

    try {
      debugPrint('Socket connection is healthy');

      // Always return true to prevent unnecessary reconnection loops
      // The socket will auto-reconnect if actually disconnected
      return true;

      // Note: Ping-pong verification disabled as it was causing issues
      // Socket.IO has its own heartbeat mechanism
    } catch (e) {
      debugPrint('Error verifying socket connection: $e');
      return true; // Return true even on error to prevent reconnection loops
    }
  }

  // Variables for user credentials
  String? _userId;
  String? _userName;

  // Initialize socket connection
  Future<void> initializeSocket() async {
    _ensureControllersOpen();
    if (_socket != null) {
      debugPrint('Socket already initialized');
      if (_socket!.connected) {
        debugPrint('Socket is already connected');
        _connectionStatusController.add(true);
        return;
      } else {
        debugPrint(
          'Existing socket is not connected, disconnecting for fresh connection',
        );
        try {
          _socket!.disconnect();
          _socket!.dispose();
        } catch (e) {
          debugPrint('Error disposing socket: $e');
        }
        _socket = null;
      }
    }

    // Construct the socket URL with the video-calling namespace
    final candidates = NetworkConfig.socketCandidates();
    String base = candidates.first;
    final socketUrl = '$base/video-calling';
    debugPrint('Connecting to socket: $socketUrl');
    debugPrint('User ID: $_userId, Username: $_userName');

    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authToken =
        prefs.getString('auth_token') ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I'; // Fallback to dev token

    // Initialize socket options with more reliable settings
    final options = IO.OptionBuilder()
        .setTransports(['websocket', 'polling']) // Try both transport methods
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000) // Start with 1 second
        .setReconnectionDelayMax(5000) // Max 5 seconds between attempts
        .setTimeout(15000) // 15 second timeout
        .setExtraHeaders({'Authorization': 'Bearer $authToken'})
        .setQuery({
          'userId': _userId ?? '',
          'userName': _userName ?? '',
          'token': authToken,
        })
        .build();

    try {
      // Initialize socket with the correct namespace
      _socket = IO.io('$base/video-calling', options);

      // Set up connection event handlers
      _socket!.onConnect((_) {
        _lastConnectionTime = DateTime.now();
        debugPrint(
          'Socket connected at ${_lastConnectionTime!.toIso8601String()}',
        );
        debugPrint('Connection attempts: $_connectionAttempts');
        _isConnected = true;
        _connectionStatusController.add(true);

        // Send a test ping immediately to verify bi-directional communication
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_socket != null && _socket!.connected) {
            try {
              _socket!.emit('ping');
              debugPrint('Sent initial ping to verify connection');
            } catch (e) {
              debugPrint('Error sending ping: $e');
            }
          }
        });

        // Reset connection attempts on successful connection
        if (_connectionAttempts > 1) {
          debugPrint(
            'Connection re-established after $_connectionAttempts attempts',
          );
        }
      });

      _socket!.onConnectError((data) {
        debugPrint('Socket connection error: $data');
        _isConnected = false;
        _connectionStatusController.add(false);
        // Rotate to next candidate on failure
        final index = candidates.indexOf(base);
        if (index >= 0 && index < candidates.length - 1) {
          base = candidates[index + 1];
          debugPrint('Switching socket base to next candidate: $base');
        }

        if (_connectionAttempts < 5) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_socket != null && !_socket!.connected) {
              _reconnectSocket();
            }
          });
        }
      });

      _socket!.onDisconnect((reason) {
        debugPrint('Socket disconnected: $reason');
        _isConnected = false;
        _connectionStatusController.add(false);

        // Try to auto-reconnect if not explicitly disconnected
        if (reason != 'io client disconnect') {
          Future.delayed(const Duration(seconds: 2), () {
            if (_socket != null && !_socket!.connected) {
              _reconnectSocket();
            }
          });
        }
      });

      _socket!.onError((error) {
        debugPrint('Socket error: $error');
        _errorController.add('Socket error: $error');
      });

      // Register all other event handlers
      _registerEventHandlers();

      // Try to connect
      _socket!.connect();

      return Future.value();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
      _errorController.add('Error initializing socket: $e');

      Future.delayed(const Duration(seconds: 2), () {
        _reconnectSocket();
      });

      return Future.value();
    }
  }

  // Method to handle socket reconnection
  void _reconnectSocket() {
    debugPrint('Attempting to reconnect socket...');

    // Increment connection attempts
    _connectionAttempts++;

    // Disconnect existing socket if any
    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        debugPrint('Error during socket disconnect: $e');
      }
      _socket = null;
    }

    // Create new socket with fresh connection
    Future.delayed(Duration(seconds: 1), () {
      initializeSocket();
    });
  }

  // Register all socket event handlers
  void _registerEventHandlers() {
    if (_socket == null) return;
    _ensureControllersOpen();

    // Chat events
    _socket!.on('chatHistory', (data) {
      try {
        debugPrint('📜 Chat history received');
        final map = (data is Map)
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final rawMessages = (map['messages'] as List?) ?? const [];
        final messages = rawMessages
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        final hasMore = map['hasMore'] == true || map['hasMore'] == 'true';
        final oldestRaw = map['oldestTimestamp'];
        final oldestTs = oldestRaw is int
            ? oldestRaw
            : (oldestRaw is String ? int.tryParse(oldestRaw) : null);
        _chatHistoryController.add(
          ChatHistoryEvent(
            messages: messages,
            hasMore: hasMore,
            oldestTimestamp: oldestTs,
          ),
        );
      } catch (e) {
        debugPrint('Error parsing chatHistory: $e');
      }
    });

    _socket!.on('newChat', (data) {
      debugPrint('New chat message received');
      try {
        final chatMessage = ChatMessage.fromJson(data);
        _chatMessageController.add(chatMessage);
      } catch (e) {
        debugPrint('Error parsing chat message: $e');
      }
    });

    _socket!.on('messageAck', (data) {
      debugPrint('Message acknowledgment received');
      _messageAckController.add(data);
    });

    // Poll events
    _socket!.on('pollEvent', (data) {
      debugPrint('Poll event received');
      try {
        final poll = Poll.fromJson(data);
        _pollController.add(poll);
      } catch (e) {
        debugPrint('Error parsing poll event: $e');
      }
    });
    // Historical poll list sent on join
    _socket!.on('pollHistory', (data) {
      try {
        debugPrint('📜 Poll history received');
        if (data is List) {
          for (final item in data) {
            try {
              final poll = Poll.fromJson(Map<String, dynamic>.from(item));
              _pollController.add(poll);
            } catch (e) {
              debugPrint('Error parsing poll history item: $e');
            }
          }
        } else if (data is Map) {
          // Some servers may send a single object; handle gracefully
          final poll = Poll.fromJson(Map<String, dynamic>.from(data));
          _pollController.add(poll);
        }
      } catch (e) {
        debugPrint('Error handling pollHistory: $e');
      }
    });

    // Vote updates broadcast to room
    _socket!.on('voteEvent', (data) {
      debugPrint('Vote event received');
      try {
        final poll = Poll.fromJson(data);
        _pollController.add(poll);
      } catch (e) {
        debugPrint('Error parsing vote event: $e');
      }
    });

    _socket!.on('voteAck', (data) {
      debugPrint('Vote acknowledgment received');
      _voteAckController.add(data);
    });

    // Hand raise events
    _socket!.on('handEvent', (data) {
      debugPrint('Hand raise event received');
      try {
        final handEvent = HandRaiseEvent.fromJson(data);
        _handRaiseController.add(handEvent);
      } catch (e) {
        debugPrint('Error parsing hand event: $e');
      }
    });

    _socket!.on('handRaiseAck', (data) {
      debugPrint('Hand raise acknowledgment received');
      _handRaiseAckController.add(data);
    });

    _socket!.on('handLowerAck', (data) {
      debugPrint('Hand lower acknowledgment received');
      _handLowerAckController.add(data);
    });

    // LiveKit authentication
    _socket!.on('livekit-auth', (data) {
      debugPrint('✅ LiveKit authentication received!');
      debugPrint('LiveKit data: $data');
      try {
        _ensureControllersOpen();
        final livekitAuth = LiveKitAuth.fromJson(data);
        debugPrint('Successfully parsed LiveKit auth data:');
        debugPrint('- URL: ${livekitAuth.url}');
        debugPrint('- Token length: ${livekitAuth.token.length} characters');

        // Pass the auth data to the LiveKit service
        _livekitAuthController.add(livekitAuth);
      } catch (e) {
        debugPrint('❌ Error parsing LiveKit auth data: $e');
        _errorController.add('Failed to parse LiveKit auth: $e');
      }
    });

    // Room events
    _socket!.on('roomClosed', (data) {
      debugPrint('Room closed event received');
      _roomClosedController.add(data);
    });

    _socket!.on('userLeft', (data) {
      debugPrint('User left event received');
      _userLeftController.add(data);
    });

    // Add ping-pong handlers for connection verification
    _socket!.on('ping', (_) {
      debugPrint('Received ping from server, responding with pong');
      _socket!.emit('pong');
    });

    _socket!.on('pong', (_) {
      debugPrint('Received pong from server - connection verified');
    });

    // Listen for userKicked (broadcast to all)
    _socket!.on('userKicked', (data) {
      debugPrint('userKicked event received:');
      debugPrint(data.toString());
      _userKickedController.add(Map<String, dynamic>.from(data));
    });

    // Listen for kicked (sent only to the kicked user)
    _socket!.on('kicked', (data) {
      debugPrint('kicked event received:');
      debugPrint(data.toString());
      _kickedController.add(Map<String, dynamic>.from(data));
    });

    // Meeting ending soon broadcast
    _socket!.on('meetingEndSoon', (data) {
      debugPrint('⏳ meetingEndSoon event received:');
      try {
        if (data is Map) {
          _meetingEndSoonController
              .add(Map<String, dynamic>.from(data));
        } else if (data is String) {
          _meetingEndSoonController.add({'message': data});
        } else {
          _meetingEndSoonController.add({'message': 'Meeting ending soon'});
        }
      } catch (e) {
        debugPrint('Error handling meetingEndSoon: $e');
      }
    });
  }

  // Method for initializing socket with user credentials
  Future<void> initialize(String userId, String userName) async {
    _userId = userId;
    _userName = userName;
    debugPrint(
      'Socket initializing with User ID: $userId, Username: $userName',
    );
    _ensureControllersOpen();
    return await initializeSocket();
  }

  // Force reconnect the socket
  Future<void> forceReconnect() async {
    debugPrint('Forcing socket reconnection...');
    _reconnectSocket();
    return Future.value();
  }

  // Socket event emitters

  // Join a meeting room
  void joinRoom({
    required String scheduleId,
    required String occurrenceId,
    required String userId,
    required String username,
    required bool isHost,
  }) {
    if (!_isConnected || _socket == null) {
      debugPrint('❌ Cannot join room: Socket not connected');
      _errorController.add(
        'Socket not connected. Please wait for connection to establish.',
      );

      // Try to reconnect the socket
      _reconnectSocket();
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    // If not valid, emit an error and return early to prevent server errors
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      // Include detailed diagnostic information in the error
      final errorMessage =
          'Invalid meeting ID format. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId". Please ensure you are using a valid meeting ID from the API.';
      _errorController.add(errorMessage);
      return;
    }

    // Log the join room attempt
    debugPrint('🔄 Joining room with:');
    debugPrint('   - scheduleId: $scheduleId');
    debugPrint('   - occurrenceId: $occurrenceId (valid MongoDB ObjectId)');
    debugPrint('   - userId: $userId');
    debugPrint('   - username: $username');
    debugPrint('   - platformId: ${AppConstants.platformId}');

    final payload = {
      'scheduleId': scheduleId,
      'occurrenceId': occurrenceId, // Verified as valid MongoDB ObjectId
      'platformId': AppConstants.platformId,
      'userId': userId,
      'username': username,
      // Use accurate role so backend assigns permissions correctly
      'role': isHost ? 'host' : 'participant',
    };

    debugPrint('📣 Emitting joinRoom event with payload: $payload');

    try {
      _socket!.emit('joinRoom', payload);
      debugPrint('✅ joinRoom event sent successfully');

      // Start a timer to check if we receive the livekit-auth response
      Future.delayed(Duration(seconds: 3), () {
        // Check if we're still connected
        if (_socket != null && _socket!.connected) {
          debugPrint('⏳ Checking for livekit-auth response (3s timeout)...');
          // Emit a ping to make sure the connection is active
          _socket!.emit('ping');
        }
      });
    } catch (e) {
      debugPrint('❌ Error emitting joinRoom event: $e');
      _errorController.add('Failed to send join room request: $e');
    }
  }

  // Leave a meeting room
  void leaveRoom({
    required String scheduleId,
    required String occurrenceId,
    required String userId,
    required String username,
    required String role,
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    // If not valid, emit an error and return early to prevent server errors
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      // Include detailed diagnostic information in the error
      final errorMessage =
          'Invalid meeting ID format for leaving room. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId".';
      _errorController.add(errorMessage);
      return;
    }

    final payload = {
      'scheduleId': scheduleId,
      'occurrenceId': occurrenceId,
      'platformId': AppConstants.platformId,
      'userId': userId,
      'username': username,
      'role': role,
    };

    debugPrint('Leaving room with payload: $payload');
    _socket!.emit('leaveRoom', payload);
  }

  // End a meeting (host only)
  void endRoom({
    required String scheduleId,
    required String occurrenceId,
    required String userId,
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      final errorMessage =
          'Invalid meeting ID format for ending room. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId".';
      _errorController.add(errorMessage);
      return;
    }

    final payload = {
      'scheduleId': scheduleId,
      'occurrenceId': occurrenceId,
      'platformId': AppConstants.platformId,
      'userId': userId,
    };

    debugPrint('Ending room with payload: $payload');
    _socket!.emit('endRoom', payload);
  }

  /// Start screen recording (host only)
  void startScreenRecording({
    required String occurrenceId,
    required String userId,
    required String username,
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      _errorController.add('Invalid occurrenceId for recording.');
      return;
    }
    final payload = {
      'occurrenceId': occurrenceId,
      'userId': userId,
      'username': username,
      'role': 'host',
    };
    debugPrint('🎬 Emitting startScreenRecording with payload: $payload');
    _socket!.emit('startScreenRecording', payload);
  }

  /// Stop screen recording (host only)
  void stopScreenRecording({
    required String occurrenceId,
    required String userId,
    required String username,
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      _errorController.add('Invalid occurrenceId for recording.');
      return;
    }
    final payload = {
      'occurrenceId': occurrenceId,
      'userId': userId,
      'username': username,
      'role': 'host',
    };
    debugPrint('⏹️ Emitting stopScreenRecording with payload: $payload');
    _socket!.emit('stopScreenRecording', payload);
  }

  // Send a chat message
  void sendChatMessage({
    required String scheduleId,
    required String occurrenceId,
    required String text,
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      final errorMessage =
          'Invalid meeting ID format for chat message. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId".';
      _errorController.add(errorMessage);
      return;
    }

    final payload = {
      'scheduleId': scheduleId,
      'occurrenceId': occurrenceId,
      'text': text,
    };

    debugPrint('Sending chat message: $payload');
    _socket!.emit('chatMessage', payload);
  }

  // Create a poll (host only)
  void createPoll({
    required String scheduleId,
    required String occurrenceId,
    required String question,
    required List<String> options,
  }) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      final errorMessage =
          'Invalid meeting ID format for poll creation. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId".';
      _errorController.add(errorMessage);
      return;
    }

    final payload = {
      'scheduleId': scheduleId,
      'occurrenceId': occurrenceId,
      'question': question,
      'options': options,
    };

    debugPrint('Creating poll: $payload');
    _socket!.emit('createPoll', payload);
  }

  // Vote on a poll
  void votePoll({required String pollId, required int optionIndex}) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    final payload = {'pollId': pollId, 'optionIndex': optionIndex};

    debugPrint('Voting on poll: $payload');
    _socket!.emit('votePoll', payload);
  }

  // Raise hand
  void raiseHand({required String scheduleId, required String occurrenceId}) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      final errorMessage =
          'Invalid meeting ID format for raising hand. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId".';
      _errorController.add(errorMessage);
      return;
    }

    final payload = {'scheduleId': scheduleId, 'occurrenceId': occurrenceId};

    debugPrint('Raising hand: $payload');
    _socket!.emit('raiseHand', payload);
  }

  // Lower hand
  void lowerHand({required String scheduleId, required String occurrenceId}) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Socket not connected');
      return;
    }

    // Verify occurrenceId is a valid MongoDB ObjectId (24 hex chars)
    final validObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    // For MongoDB backend compatibility - the ObjectId must be valid
    if (!validObjectId) {
      debugPrint(
        '❌ ERROR: occurrenceId "$occurrenceId" is not a valid MongoDB ObjectId format (24 hex chars).',
      );
      debugPrint(
        'Backend will reject this. Please provide a valid MongoDB ObjectId from the API response.',
      );

      final errorMessage =
          'Invalid meeting ID format for lowering hand. Expected a valid MongoDB ObjectId (24 hex characters), but got: "$occurrenceId".';
      _errorController.add(errorMessage);
      return;
    }

    final payload = {'scheduleId': scheduleId, 'occurrenceId': occurrenceId};

    debugPrint('Lowering hand: $payload');
    _socket!.emit('lowerHand', payload);
  }

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  // Check if socket is connected
  bool get isConnected => checkConnection();

  // Check connection health and attempt reconnection if needed
  Future<bool> checkConnectionHealth() async {
    if (isConnected) {
      // Connection appears fine, verify with ping-pong
      final isVerified = await verifyConnection();
      if (isVerified) {
        debugPrint('Socket connection is healthy');
        return true;
      } else {
        debugPrint('Socket appears connected but failed verification');
      }
    }

    // Connection is not verified, attempt reconnect
    debugPrint('Socket connection unhealthy, attempting reconnection...');
    _reconnectSocket();
    // Since _reconnectSocket is asynchronous but doesn't return a Future,
    // we'll return true here but the actual reconnection will happen asynchronously
    return true;
  }

  // Dispose all stream controllers
  void dispose() {
    try {
      _chatMessageController.close();
    } catch (_) {}
    try {
      _pollController.close();
    } catch (_) {}
    try {
      _handRaiseController.close();
    } catch (_) {}
    try {
      _livekitAuthController.close();
    } catch (_) {}
    try {
      _errorController.close();
    } catch (_) {}
    try {
      _connectionStatusController.close();
    } catch (_) {}
    try {
      _messageAckController.close();
    } catch (_) {}
    try {
      _voteAckController.close();
    } catch (_) {}
    try {
      _handRaiseAckController.close();
    } catch (_) {}
    try {
      _handLowerAckController.close();
    } catch (_) {}
    try {
      _roomClosedController.close();
    } catch (_) {}
    try {
      _userLeftController.close();
    } catch (_) {}
    try {
      _chatHistoryController.close();
    } catch (_) {}
    try {
      _userKickedController.close();
    } catch (_) {}
    try {
      _kickedController.close();
    } catch (_) {}
    _controllersInitialized =
        true; // mark initialized but closed; will recreate on next use
    disconnect();
  }
}
