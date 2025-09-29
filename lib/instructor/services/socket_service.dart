import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SocketService {
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Socket instance
  IO.Socket? _socket;
  bool _connected = false;

  // Stream controllers for message events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Stream controllers for typing events
  final _typingStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStatusController.stream;

  // Stream controllers for message read status events
  final _messageReadStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageReadStream =>
      _messageReadStatusController.stream;

  // Socket connection status
  bool get isConnected => _connected;

  // Stream to notify about connection status changes
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Initialize socket connection with the server
  Future<bool> initSocket() async {
    if (_socket != null && _socket!.connected && _connected) {
      //debugPrint('Socket already initialized and connected');
      return true;
    }
    _connected = false;
    try {
      // Get the authentication token
      final token = await _getAuthToken();
      if (token == null) {
        //debugPrint(
        // 'Failed to initialize socket: Authentication token not found',
        // );
        return false;
      }

      // Socket URL - use the confirmed working server
      const String mainUrl = 'http://54.82.53.11:5001';
      final List<String> socketUrls = [
        mainUrl, // Primary endpoint
        'wss://latest-backend-j9au.onrender.com', // WebSocket Secure backup
      ];

      // Try the first URL configuration
      String socketUrl = socketUrls[0];
      //debugPrint('Initializing socket connection to $socketUrl');

      // Create socket instance with options
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports([
              'websocket',
              'polling',
            ]) // Try both transport methods
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setQuery({
              'token': token,
              'userId': await _getUserId(),
              'role': 'instructor',
            })
            .enableReconnection() // Enable auto reconnection
            .setReconnectionAttempts(10) // Try to reconnect 10 times
            .setReconnectionDelay(3000) // Wait 3 seconds between attempts
            .build(),
      );

      // Set up a process to try other URLs if the first one fails
      Future.delayed(const Duration(seconds: 5), () async {
        if (!_connected && _socket != null) {
          //debugPrint('First socket URL failed, trying alternatives...');

          // Loop through alternative URLs
          for (int i = 1; i < socketUrls.length; i++) {
            if (_connected) break; // Stop if we connected successfully

            final alternativeUrl = socketUrls[i];
            //debugPrint('Trying alternative socket URL: $alternativeUrl');

            // Disconnect previous attempt
            _socket?.disconnect();

            // Create new socket with alternative URL
            _socket = IO.io(
              alternativeUrl,
              IO.OptionBuilder()
                  .setTransports(['websocket', 'polling'])
                  .disableAutoConnect()
                  .setExtraHeaders({'Authorization': 'Bearer $token'})
                  .setQuery({
                    'token': token,
                    'userId': await _getUserId(),
                    'role': 'instructor',
                  })
                  .enableReconnection()
                  .setReconnectionAttempts(5)
                  .setReconnectionDelay(3000)
                  .build(),
            );

            // Set up listeners again
            // _setupSocketListeners();

            // Try to connect
            _socket?.connect();
            //debugPrint('📡 Initiated socket connection to $socketUrl');
            // Wait to see if this URL works
            await Future.delayed(const Duration(seconds: 4));
          }
        }
      });

      // Set up event listeners
      _setupSocketListeners();

      // Connect to the server
      _socket?.connect();

      // Set up a timeout to check if we connected successfully
      Future.delayed(const Duration(seconds: 5), () {
        if (!_connected && _socket != null) {
          //debugPrint(
          //   'Socket failed to connect within timeout, reconnecting...',
          // );
          _socket?.disconnect();
          _socket?.connect();
        }
      });

      return true;
    } catch (e) {
      //debugPrint('Error initializing socket: $e');
      return false;
    }
  }

  // Set up socket event listeners
  void _setupSocketListeners() {
    // _socket?.onAny((event, data) {
    //   //debugPrint('📥 Received event: $event with data: $data');
    // });
    _socket?.onConnect((_) async {
      //debugPrint('✅ Socket Connected');

      final userId = await _getUserId();
      final userName = await _getUserName();
      // print("UserID: $userId, UserName: $userName");
      // 🔑 Authenticate with server
      final authData = {
        'userId': userId,
        'name': userName,
        'token': await _getAuthToken(),
        'role': 'instructor',
      };

      _socket?.emit('authenticate', authData);
      //debugPrint('🔑 Sent authenticate event: $authData');

      _connected = true;
      _connectionStatusController.add(true);
    });
    _socket?.on('joinedGroup', (data) {
      //debugPrint('✅ Successfully joined group: $data');
    });
    _socket?.on('joinGroupError', (error) {
      //debugPrint('❌ Failed to join group: $error');
    });
    _socket?.on('userJoined', (data) {
      //debugPrint('📢 User joined group: $data');
      if (data) {
        //debugPrint('✅ Confirmed group join for groupId: ${data['groupId']}');
      }
    });
    // print("Socket listeners set up");

    _socket?.onDisconnect((_) {
      //debugPrint('Socket Disconnected');
      _connected = false;
      _connectionStatusController.add(false);

      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_socket != null) {
          //debugPrint('Attempting to reconnect...');
          _socket?.connect();
        }
      });
    });

    _socket?.onConnectError((error) {
      //debugPrint('Socket Connection Error: $error');
      _connected = false;
      _connectionStatusController.add(false);

      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (_socket != null) {
          //debugPrint('Attempting to reconnect after error...');
          _socket?.connect();
        }
      });
    });

    _socket?.onError((error) {
      //debugPrint('Socket Error: $error');
    });

    // Listen for the primary message events

    // Listen for new messages - primary event
    _socket?.on('newMessage', (data) {
      //debugPrint('New message received: $data');
      if (data is Map) {
        _messageController.add(_normalizeMessageFormat(data));
      }
    });

    // Alternative message event as backup
    // _socket?.on('message', (data) {
    //   //debugPrint('Alternative message event received: $data');
    //   if (data is Map) {
    //     _messageController.add(_normalizeMessageFormat(data));
    //   }
    // });

    // Listen for typing events
    _socket?.on('typingStatus', (data) {
      //debugPrint('Typing event received: $data');
      // Notify about typing status through a new stream
      if (data is Map) {
        _typingStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    // Listen for message read events
    _socket?.on('messageReadReceipt', (data) {
      // //debugPrint('Message read event received: $data');
      // Update read status of messages
      if (data is Map) {
        _messageReadStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    // Single additional backup event for group messages
    // _socket?.on('group_message', (data) {
    //   //debugPrint('Group message event received: $data');
    //   if (data is Map) {
    //     _messageController.add(_normalizeMessageFormat(data));
    //   }
    // });
  }

  // Join a group chat room
  void joinGroup(String groupId) {
    if (_socket != null && _socket!.connected && _connected) {
      //debugPrint(
      //   '📡 Sending joinGroup for groupId: $groupId at ${DateTime.now()}',
      // );
      _socket?.emitWithAck(
        'joinGroup',
        {'groupId': groupId},
        ack: (data) {
          //debugPrint('📨 JoinGroup acknowledgment received: $data');
          if (data != null && data['success'] == true) {
            //debugPrint('✅ Server confirmed joinGroup: ${data['groupId']}');
          } else {
            //debugPrint('⚠️ Failed to join group: $data');
          }
        },
      );

      // Retry logic
    } else {
      //debugPrint(
      //   '❌ Cannot join group: Socket not connected (socket.connected: ${_socket?.connected}, _connected: $_connected)',
      // );
    }
  }

  // Leave a group chat room
  void leaveGroup(String groupId) {
    if (_socket != null && _connected) {
      //debugPrint('Leaving group: $groupId');

      // Use the confirmed working event name
      _socket?.emit('leaveGroup', {'groupId': groupId});
    }
  }

  // Send typing status
  void sendTypingStatus(String groupId, bool isTyping) async {
    if (_socket != null && _connected) {
      final userId = await _getUserId();
      final userName = await _getUserName();

      //debugPrint('Sending typing status: $isTyping for group $groupId');
      _socket?.emit('typing', {
        'groupId': groupId,
        'userId': userId,
        'userName': userName,
        'isTyping': isTyping,
      });
    }
  }

  // Mark message as read
  void markMessageAsRead(String messageId, String groupId) async {
    if (_socket != null && _connected) {
      final userId = await _getUserId();

      //debugPrint('Marking message $messageId as read in group $groupId');
      final readData = {
        'messageId': messageId,
        'groupId': groupId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _socket?.emit('messageRead', readData);
      //debugPrint('Sent messageRead event for message: $messageId');

      // Immediately update local stream as well for UI updates
      _messageReadStatusController.add(Map<String, dynamic>.from(readData));
    }
  }

  // Send a message to a group
  Future<void> sendGroupMessage(String groupId, String message) async {
    if (_socket == null || !_connected) {
      //debugPrint('Cannot send message: socket not connected');
      throw Exception('Socket not connected');
    }

    //debugPrint('Sending message to group $groupId: $message');

    // Get user ID from AuthService
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final userName = prefs.getString('user_name') ?? 'Instructor';

    try {
      // Use the confirmed working event name for sending messages
      const String eventName = 'sendMessage';

      final messageData = {
        'groupId': groupId,
        'content': message,
        'messageType': 'text',
        'senderId': userId,
        'senderName': userName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send with the confirmed event name
      _socket?.emit(eventName, messageData);
      //debugPrint('Emitted event: $eventName with data: $messageData');
    } catch (e) {
      //debugPrint('Error sending socket message: $e');
      throw Exception('Failed to send socket message: $e');
    }
  }

  // Normalize message format from different socket events
  Map<String, dynamic> _normalizeMessageFormat(Map data) {
    final normalized = Map<String, dynamic>.from(data);
    try {
      normalized['groupId'] ??= data['group'] ?? data['roomId'] ?? '';
      normalized['content'] ??= data['message'] ?? data['text'] ?? '';
      normalized['createdAt'] ??=
          data['timestamp'] ?? DateTime.now().toIso8601String();
      normalized['senderId'] ??= {
        '_id': data['senderId']?['_id'] ?? data['userId'] ?? 'unknown',
        'name':
            data['senderId']?['name'] ??
            data['senderName'] ??
            data['userName'] ??
            'Unknown User',
      };
      normalized['messageType'] ??= data['type'] ?? 'text';
      //debugPrint('✅ Normalized message: $normalized');
      return normalized;
    } catch (e) {
      //debugPrint('❌ Error normalizing message: $e, original data: $data');
      return normalized;
    }
  }

  // Get authentication token from shared preferences
  Future<String?> _getAuthToken() async {
    try {
      // Use the proper method from AuthService
      final token = await InstructorAuthService.getValidAccessToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }

      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      //debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  // Get user ID from shared preferences
  Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id') ?? '';
    } catch (e) {
      //debugPrint('Error getting user ID: $e');
      return '';
    }
  }

  // Get user name from shared preferences
  Future<String> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'Instructor';
    } catch (e) {
      //debugPrint('Error getting user name: $e');
      return 'Instructor';
    }
  }

  // Disconnect and dispose resources
  void dispose() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
    _messageController.close();
    _connectionStatusController.close();
    _typingStatusController.close();
    _messageReadStatusController.close();
  }
}
