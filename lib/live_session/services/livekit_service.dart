import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';
import '../utils/network_config.dart';

// Class to hold LiveKit connection information
class LiveKitConnectionInfo {
  final String url;
  final String token;

  LiveKitConnectionInfo({required this.url, required this.token});

  @override
  String toString() {
    return 'LiveKitConnectionInfo{url: $url, token: ${token.substring(0, math.min(20, token.length))}...}';
  }
}

class LiveKitService {
  // LiveKit server URL from AppConstants
  static String get liveKitServerUrl => NetworkConfig.liveKitBaseUrl;

  // Socket.io connection for getting LiveKit tokens from AppConstants
  static String get socketUrl => NetworkConfig.socketBaseUrl;

  // Request comprehensive permissions for live meetings
  static Future<Map<Permission, PermissionStatus>>
  requestAllPermissions() async {
    try {
      debugPrint(
        '🔐 Requesting comprehensive permissions for live meetings...',
      );

      // List of all permissions needed for live meetings
      final permissions = <Permission>[
        Permission.camera,
        Permission.microphone,
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.audio,
        Permission.phone,
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.systemAlertWindow,
        Permission.location,
        Permission.locationWhenInUse,
        Permission.notification,
      ];

      // Request all permissions
      final statuses = await permissions.request();

      // Log permission results
      for (final entry in statuses.entries) {
        final permission = entry.key;
        final status = entry.value;
        debugPrint(
          '📱 ${permission.toString().split('.').last}: ${status.toString().split('.').last}',
        );
      }

      // Check critical permissions
      final cameraStatus = statuses[Permission.camera];
      final microphoneStatus = statuses[Permission.microphone];

      if (cameraStatus?.isGranted != true) {
        debugPrint(
          '⚠️ Camera permission not granted - video features may not work',
        );
      }

      if (microphoneStatus?.isGranted != true) {
        debugPrint(
          '⚠️ Microphone permission not granted - audio features may not work',
        );
      }

      // Handle special permissions for Android 11+
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _handleAndroidSpecificPermissions();
      }

      debugPrint('✅ Permission request completed');
      return statuses;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return {};
    }
  }

  // Handle Android-specific permissions
  static Future<void> _handleAndroidSpecificPermissions() async {
    try {
      // Request manage external storage for Android 11+
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      // Request system alert window for screen sharing
      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }

      // Handle notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('❌ Error handling Android-specific permissions: $e');
    }
  }

  // Check if critical permissions are granted
  static Future<bool> areCriticalPermissionsGranted() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      return cameraStatus.isGranted && microphoneStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking critical permissions: $e');
      return false;
    }
  }

  // Open app settings if permissions are denied
  static Future<void> openAppSettings() async {
    try {
      debugPrint(
        '🔧 Opening app settings for manual permission configuration...',
      );
      // Use the global function from permission_handler package
      await permission_handler.openAppSettings();
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
    }
  }

  // Socket connection status tracking
  static IO.Socket? _currentSocket;
  static bool _isSocketConnected = false;
  static DateTime? _lastConnectionTime;
  static String? _lastConnectionError;

  // Get current socket connection status
  static Map<String, dynamic> getSocketConnectionStatus() {
    return {
      'isConnected': _isSocketConnected,
      'hasSocket': _currentSocket != null,
      'socketConnected': _currentSocket?.connected ?? false,
      'lastConnectionTime': _lastConnectionTime?.toIso8601String(),
      'lastError': _lastConnectionError,
      'socketId': _currentSocket?.id,
    };
  }

  // Test socket connection manually
  static Future<Map<String, dynamic>> testSocketConnection() async {
    final startTime = DateTime.now();

    try {
      debugPrint('🧪 Testing socket connection...');

      final authToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I';

      final socket = IO.io(
        '${socketUrl}/video-calling',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .setQuery({'token': authToken})
            .build(),
      );

      final completer = Completer<Map<String, dynamic>>();

      socket.onConnect((_) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        debugPrint('✅ Test connection successful');
        debugPrint('⏱️ Connection time: ${duration.inMilliseconds}ms');

        socket.disconnect();

        if (!completer.isCompleted) {
          completer.complete({
            'success': true,
            'connected': true,
            'duration': duration.inMilliseconds,
            'socketId': socket.id,
            'message': 'Connection successful',
          });
        }
      });

      socket.onConnectError((error) {
        debugPrint('❌ Test connection failed: $error');
        if (!completer.isCompleted) {
          completer.complete({
            'success': false,
            'connected': false,
            'error': error.toString(),
            'message': 'Connection failed',
          });
        }
      });

      socket.connect();

      // Wait for result with timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          socket.disconnect();
          return {
            'success': false,
            'connected': false,
            'error': 'Connection timeout',
            'message': 'Test connection timed out',
          };
        },
      );

      return result;
    } catch (e) {
      debugPrint('💥 Test connection error: $e');
      return {
        'success': false,
        'connected': false,
        'error': e.toString(),
        'message': 'Test connection failed with exception',
      };
    }
  }

  // Print detailed socket debugging information
  static void printSocketDebugInfo() {
    final status = getSocketConnectionStatus();

    debugPrint('');
    debugPrint('=========== SOCKET DEBUG INFO ===========');
    debugPrint('📡 Socket URL: ${socketUrl}/video-calling');
    debugPrint('🔗 Is Connected: ${status['isConnected']}');
    debugPrint('📱 Has Socket Instance: ${status['hasSocket']}');
    debugPrint('⚡ Socket Connected: ${status['socketConnected']}');
    debugPrint('🆔 Socket ID: ${status['socketId'] ?? 'N/A'}');
    debugPrint('⏰ Last Connection: ${status['lastConnectionTime'] ?? 'Never'}');
    debugPrint('❌ Last Error: ${status['lastError'] ?? 'None'}');
    debugPrint('========================================');
    debugPrint('');
  }

  // Initialize the LiveKit room
  static Future<Room> initializeRoom() async {
    try {
      // Configure audio and video settings
      await LiveKitClient.initialize();

      // Create a new room instance with default options
      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultVideoPublishOptions: VideoPublishOptions(
            videoEncoding: VideoEncoding(
              maxBitrate: 2500000, // 2.5 Mbps
              maxFramerate: 30,
            ),
          ),
          defaultAudioPublishOptions: AudioPublishOptions(),
          defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
            captureScreenAudio: false,
            maxFrameRate: 30, // Only if supported by SDK
          ),
        ),
      );

      // Set up event listeners
      _setupRoomListeners(room);

      return room;
    } catch (e) {
      debugPrint('Error initializing LiveKit room: $e');
      // Return a new room instance as fallback
      return Room();
    }
  }

  // Set up room event listeners
  static void _setupRoomListeners(Room room) {
    room.createListener()
      ..on<RoomConnectedEvent>((event) {
        debugPrint('Connected to room: ${room.name}');
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('Disconnected from room: ${room.name}');
      })
      ..on<ParticipantConnectedEvent>((event) {
        debugPrint('Participant connected: ${event.participant.identity}');
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        debugPrint('Participant disconnected: ${event.participant.identity}');
      })
      ..on<TrackPublishedEvent>((event) {
        debugPrint('Track published: ${event.publication.kind}');
      })
      ..on<TrackUnpublishedEvent>((event) {
        debugPrint('Track unpublished: ${event.publication.kind}');
      });
  }

  // Connect to a LiveKit room
  static Future<Map<String, dynamic>> connectToRoomWithDetails(
    Room room,
    String token, {
    String? serverUrl,
  }) async {
    // Always prefer the configured LiveKit URL to avoid "localhost" from server
    // Normalize serverUrl: ignore if it looks like a localhost/loopback address
    String? normalizedServerUrl = serverUrl;
    if (normalizedServerUrl != null) {
      final lower = normalizedServerUrl.toLowerCase();
      if (lower.contains('localhost') ||
          lower.contains('127.0.0.1') ||
          lower.contains('10.0.2.2')) {
        debugPrint(
          '⚠️ Server provided LiveKit URL appears to be local/loopback ($normalizedServerUrl). Using configured base URL instead.',
        );
        normalizedServerUrl = null;
      }
    }

    // Priority: configured URL first, then (non-local) server URL, then other candidates
    final candidates = <String>{};
    candidates.add(liveKitServerUrl);
    if (normalizedServerUrl != null && normalizedServerUrl.isNotEmpty) {
      candidates.add(normalizedServerUrl);
    }
    candidates.addAll(NetworkConfig.liveKitCandidates());
    // Dedup preserving insertion order by converting back to list
    final urls = candidates.toList();

    try {
      debugPrint('🔗 Connecting to LiveKit. Candidates: ${urls.join(', ')}');
      debugPrint(
        '🎟️ Token first 20 chars: ${token.substring(0, math.min(20, token.length))}...',
      );

      // Try URLs in order until one connects
      Object? lastError;
      for (final originalUrl in urls) {
        // Normalize to ws/wss scheme if given http/https
        String url = originalUrl;
        if (url.startsWith('http://')) {
          url = 'ws://' + url.substring('http://'.length);
        } else if (url.startsWith('https://')) {
          url = 'wss://' + url.substring('https://'.length);
        }
        try {
          debugPrint('🔌 LiveKit: trying $url');
          await room.connect(
            url,
            token,
            connectOptions: const ConnectOptions(
              autoSubscribe: true,
              rtcConfiguration: RTCConfiguration(
                iceServers: [
                  RTCIceServer(urls: ['stun:stun.l.google.com:19302']),
                  RTCIceServer(urls: ['stun:stun1.l.google.com:19302']),
                ],
                iceTransportPolicy: RTCIceTransportPolicy.all,
                iceCandidatePoolSize: 10,
              ),
            ),
            roomOptions: const RoomOptions(
              adaptiveStream: true,
              dynacast: true,
              defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
                captureScreenAudio: false,
              ),
            ),
          );
          debugPrint(
            '✅ Successfully connected to LiveKit room: ${room.name} via $url',
          );
          return {'success': true, 'error': null};
        } catch (e) {
          debugPrint('❌ LiveKit connect failed for $url: $e');
          lastError = e;
          // Try next URL
        }
      }
      // If loop exits, all attempts failed
      throw lastError ?? Exception('All LiveKit URLs failed');
    } catch (error) {
      debugPrint('❌ Error connecting to LiveKit room: $error');

      // More specific error handling with detailed error messages
      if (error.toString().contains('invalid API key')) {
        final errorMsg =
            'LiveKit API key mismatch: Backend API key does not match LiveKit server configuration';
        debugPrint('🔑 $errorMsg');
        debugPrint(
          '   Backend API key must match LiveKit server configuration',
        );
        return {'success': false, 'error': errorMsg, 'type': 'api_key'};
      }

      if (error.toString().contains('Failed to fetch') ||
          error.toString().contains('ClientException')) {
        final errorMsg =
            'Cannot reach LiveKit server at any of: ${urls.join(', ')}';
        debugPrint('🌐 Connection Error: $errorMsg');
        debugPrint('   Check if LiveKit server is running and accessible');
        return {'success': false, 'error': errorMsg, 'type': 'connection'};
      }

      if (error.toString().contains('token')) {
        final errorMsg = 'Invalid or expired LiveKit token';
        debugPrint('🎟️ Token Error: $errorMsg');
        debugPrint('   Check token generation in backend');
        return {'success': false, 'error': errorMsg, 'type': 'token'};
      }

      // Handle WebRTC/Media connection issues
      if (error.toString().contains('MediaConnectException') ||
          error.toString().contains('ice connectivity')) {
        debugPrint('🔧 WebRTC Error: Media connection failed');
        debugPrint('   This could be due to network/firewall restrictions');

        // Try once more with different settings
        try {
          debugPrint('🔄 Retrying with fallback settings...');
          final fallbackUrl = urls.isNotEmpty ? urls.first : liveKitServerUrl;
          await room.connect(
            fallbackUrl,
            token,
            connectOptions: const ConnectOptions(
              autoSubscribe: false,
              rtcConfiguration: RTCConfiguration(
                iceServers: [
                  RTCIceServer(urls: ['stun:stun.l.google.com:19302']),
                ],
              ),
            ),
            roomOptions: const RoomOptions(
              adaptiveStream: true,
              dynacast: true,
              defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
                captureScreenAudio: false,
              ),
            ),
          );
          debugPrint('✅ Fallback connection successful!');
          return {'success': true, 'error': null};
        } catch (retryError) {
          debugPrint('❌ Fallback connection also failed: $retryError');
        }
      }

      final errorMsg = 'LiveKit connection failed: ${error.toString()}';
      debugPrint('💥 Unhandled LiveKit error: $errorMsg');
      return {'success': false, 'error': errorMsg, 'type': 'unknown'};
    }
  }

  // Backward compatible method that returns boolean
  static Future<bool> connectToRoom(
    Room room,
    String token, {
    String? serverUrl,
  }) async {
    final result = await connectToRoomWithDetails(
      room,
      token,
      serverUrl: serverUrl,
    );
    return result['success'] ?? false;
  }

  // Get a token for the LiveKit room using socket.io
  static Future<String?> getToken(
    String occurrenceId, // Occurrence ID in backend
    String participantName, // userId in backend
    bool isHost, { // determines role in backend
    String scheduleId = '', // Optional scheduleId parameter
  }) async {
    try {
      // Get the user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? participantName;
      final username = prefs.getString('user_name') ?? 'Instructor';

      // Authentication token for connecting to socket
      final authToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I';

      // Print detailed debugging information
      debugPrint('');
      debugPrint('=========== LIVEKIT CONNECTION DEBUG ===========');
      debugPrint('MEETING JOIN PARAMETERS:');
      debugPrint('occurrenceId: "$occurrenceId"');
      debugPrint('scheduleId: "$scheduleId"');
      debugPrint('userId: "$userId"');
      debugPrint('username: "$username"');
      debugPrint('platformId: "${AppConstants.platformId}"');
      debugPrint('role: "${isHost ? 'host' : 'participant'}"');
      debugPrint('==============================================');

      // Create a socket connection to get the LiveKit token
      final socket = IO.io(
        '${socketUrl}/video-calling',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .setQuery({
              'token': authToken,
              'userId': userId,
              'role': isHost ? 'host' : 'participant',
            })
            .enableForceNew()
            .build(),
      );

      // Store current socket reference for monitoring
      _currentSocket = socket;
      _lastConnectionError = null;

      final completer = Completer<String>();

      socket.onConnect((_) {
        _isSocketConnected = true;
        _lastConnectionTime = DateTime.now();
        debugPrint('✅ Connected to socket.io for LiveKit token');
        debugPrint('📡 Socket ID: ${socket.id}');
        debugPrint('🔗 Connection Status: ${getSocketConnectionStatus()}');

        // Create payload based on the API format
        final payload = {
          'scheduleId': scheduleId,
          'occurrenceId': occurrenceId,
          'userId': userId,
          'username': username,
          'platformId': AppConstants.platformId,
          'role': isHost ? 'host' : 'participant',
        };

        debugPrint('Sending joinRoom payload: $payload');

        // Join room to get LiveKit token
        socket.emit('joinRoom', payload);
      });

      // Listen for LiveKit auth token
      socket.on('livekit-auth', (data) {
        debugPrint('Received LiveKit auth: $data');
        if (data != null && data['token'] != null) {
          final token = data['token'];
          final url = data['url'] ?? liveKitServerUrl;
          debugPrint('Token received successfully');
          debugPrint('Using LiveKit server URL: $url');
          debugPrint('Token length: ${token.length}');

          // Use the URL from the server response if available
          if (url != null && url.toString().isNotEmpty) {
            debugPrint('Using server-provided LiveKit URL: $url');
          }

          completer.complete(token);
        } else {
          debugPrint('Invalid LiveKit auth data: $data');
          completer.completeError('Invalid LiveKit auth data');
        }
      });

      // Listen for join denied
      socket.on('joinDenied', (data) {
        debugPrint('Join denied: $data');
        completer.completeError(
          'Join denied: ${data['reason'] ?? "Unknown reason"}',
        );
      });

      // Listen for error events
      socket.on('error', (data) {
        debugPrint('Socket error event: $data');
        if (!completer.isCompleted) {
          completer.completeError(
            'Socket error: ${data['message'] ?? "Unknown error"}',
          );
        }
      });

      // Handle disconnect
      socket.onDisconnect((_) {
        _isSocketConnected = false;
        debugPrint('🔴 Disconnected from socket.io');
        debugPrint('📊 Final Status: ${getSocketConnectionStatus()}');
      });

      // Handle connection errors
      socket.onConnectError((error) {
        _isSocketConnected = false;
        _lastConnectionError = error.toString();
        debugPrint('❌ Socket connect error: $error');
        debugPrint('📊 Error Status: ${getSocketConnectionStatus()}');
        if (!completer.isCompleted) {
          completer.completeError('Socket connection error');
        }
      });

      // Handle general socket errors
      socket.onError((error) {
        _lastConnectionError = error.toString();
        debugPrint('⚠️ Socket error event: $error');
        debugPrint('📊 Current Status: ${getSocketConnectionStatus()}');
        if (!completer.isCompleted) {
          completer.completeError('Socket error: ${error.toString()}');
        }
      });

      // Connect to socket
      debugPrint('🔄 Attempting to connect to socket...');
      debugPrint('📡 Socket URL: ${socketUrl}/video-calling');
      socket.connect();

      // Wait for token with timeout
      return await completer.future.timeout(
        const Duration(seconds: 15), // Increased timeout
        onTimeout: () {
          debugPrint('⏱️ Token request timed out - disconnecting socket');
          debugPrint('📊 Timeout Status: ${getSocketConnectionStatus()}');
          _isSocketConnected = false;
          socket.disconnect();
          _currentSocket = null;
          throw TimeoutException('Timed out waiting for LiveKit token');
        },
      );
    } catch (error) {
      debugPrint('Error getting LiveKit token: $error');

      // Check for specific error types
      final errorStr = error.toString().toLowerCase();

      if (errorStr.contains('not found') ||
          errorStr.contains('occurrence not found')) {
        debugPrint('ERROR: The meeting ID does not exist in the database.');
        debugPrint(
          'Make sure you are using a valid occurrence ID that exists on the backend.',
        );
      }

      if (errorStr.contains('denied') || errorStr.contains('not allowed')) {
        debugPrint(
          'ERROR: Access denied. Make sure you have permission to join this meeting.',
        );
      }

      debugPrint(
        'Unable to get LiveKit token from backend. Please check your backend connection.',
      );
      return null;
    }
  }

  // Disconnect from the room
  static Future<void> disconnectFromRoom(Room room) async {
    try {
      await room.disconnect();
      await room.dispose();
    } catch (e) {
      debugPrint('Error disconnecting from room: $e');
    }
  }

  // Publish local video track
  static Future<LocalVideoTrack?> publishVideo(Room room) async {
    try {
      debugPrint('📹 Creating camera video track...');

      // Ensure comprehensive permissions on mobile platforms
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        // Request comprehensive permissions first
        final permissionStatuses = await requestAllPermissions();

        // Check critical permissions
        final cameraStatus = permissionStatuses[Permission.camera];
        final microphoneStatus = permissionStatuses[Permission.microphone];

        if (cameraStatus?.isGranted != true) {
          debugPrint('❌ Camera permission not granted');
          debugPrint('🔧 Please enable camera permission in device settings');
          return null;
        }

        if (microphoneStatus?.isGranted != true) {
          debugPrint(
            '⚠️ Microphone permission not granted - audio may not work',
          );
        }

        debugPrint('✅ Camera permissions verified');
      }

      // Create camera video track with enhanced options
      final track = await LocalVideoTrack.createCameraTrack(
        const CameraCaptureOptions(
          maxFrameRate: 30,
          cameraPosition: CameraPosition.front,
        ),
      );

      debugPrint('📹 Camera track created successfully');

      // Publish the track if we have a local participant
      if (room.localParticipant != null) {
        await room.localParticipant!.publishVideoTrack(track);

        // Force unmute the track
        await track.unmute();

        // Enable camera
        await room.localParticipant!.setCameraEnabled(true);

        debugPrint('📹 Video track published and enabled');
      }

      return track;
    } catch (error) {
      debugPrint('❌ Error publishing video: $error');
      debugPrint('💡 Try checking camera permissions in device settings');
      return null;
    }
  }

  // Publish local audio track
  static Future<LocalAudioTrack?> publishAudio(Room room) async {
    try {
      debugPrint('🎤 Creating audio track...');

      // Ensure comprehensive permissions on mobile platforms
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        // Check microphone permission specifically
        final microphoneStatus = await Permission.microphone.status;

        if (microphoneStatus.isDenied) {
          debugPrint('🔄 Requesting microphone permission...');
          final newStatus = await Permission.microphone.request();

          if (newStatus.isGranted) {
            debugPrint('✅ Microphone permission granted');
          } else {
            debugPrint('❌ Microphone permission denied');
            debugPrint(
              '🔧 Please enable microphone permission in device settings',
            );
            return null;
          }
        } else if (microphoneStatus.isGranted) {
          debugPrint('✅ Microphone permission already granted');
        } else {
          debugPrint('❌ Microphone permission permanently denied');
          debugPrint(
            '🔧 Please enable microphone permission in device settings',
          );
          return null;
        }
      }

      // Create audio track with enhanced options
      final track = await LocalAudioTrack.create(
        const AudioCaptureOptions(
          autoGainControl: true,
          echoCancellation: true,
          noiseSuppression: true,
        ),
      );

      debugPrint('🎤 Audio track created successfully');

      // Publish the track if we have a local participant
      if (room.localParticipant != null) {
        await room.localParticipant!.publishAudioTrack(track);

        // Enable microphone
        await room.localParticipant!.setMicrophoneEnabled(true);

        debugPrint('🎤 Audio track published and enabled');
      }

      return track;
    } catch (error) {
      debugPrint('❌ Error publishing audio: $error');
      debugPrint('💡 Try checking microphone permissions in device settings');
      return null;
    }
  }

  // Screen sharing functionality
  static Future<LocalVideoTrack?> publishScreenShare(Room room) async {
    try {
      debugPrint('🖥️ Starting screen share...');

      // Check for screen sharing permissions on Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Request system alert window permission for screen sharing
        final systemAlertWindowStatus =
            await Permission.systemAlertWindow.status;

        if (systemAlertWindowStatus.isDenied) {
          debugPrint('🔄 Requesting screen sharing permissions...');
          final newStatus = await Permission.systemAlertWindow.request();

          if (!newStatus.isGranted) {
            debugPrint('❌ Screen sharing permission denied');
            debugPrint(
              '🔧 Please enable "Display over other apps" in device settings',
            );
            throw Exception(
              'Screen sharing permission required. Please enable "Display over other apps" in device settings.',
            );
          }
        }

        debugPrint('✅ Screen sharing permissions verified');
      }

      // Create screen share track with conservative settings for stability
      final track = await LocalVideoTrack.createScreenShareTrack(
        const ScreenShareCaptureOptions(
          useiOSBroadcastExtension: true,
          maxFrameRate: 15, // Reduced frame rate for stability
          captureScreenAudio: false, // Disable audio capture to prevent crashes
        ),
      );

      debugPrint('🖥️ Screen share track created successfully');

      // Publish the track if we have a local participant
      if (room.localParticipant != null) {
        // Use conservative publish options for Android
        const publishOptions = VideoPublishOptions(
          videoEncoding: VideoEncoding(
            maxBitrate: 2000000, // 2 Mbps - conservative for stability
            maxFramerate: 15,
          ),
        );

        await room.localParticipant!.publishVideoTrack(
          track,
          publishOptions: publishOptions,
        );
        debugPrint('🖥️ Screen share track published');
      }

      return track;
    } catch (error) {
      debugPrint('❌ Error starting screen share: $error');
      debugPrint(
        '💡 Try enabling screen sharing permissions in device settings',
      );
      // Don't return null, propagate the error so UI can handle it
      rethrow;
    }
  }

  // Stop screen sharing
  static Future<void> stopScreenShare(
    Room room,
    LocalVideoTrack? screenTrack,
  ) async {
    try {
      debugPrint('🛑 Stopping screen share...');

      if (screenTrack != null) {
        // Stop and dispose the track - this will automatically unpublish it
        await screenTrack.stop();
        await screenTrack.dispose();
        debugPrint('🛑 Screen share stopped successfully');
      }
    } catch (error) {
      debugPrint('❌ Error stopping screen share: $error');
    }
  }

  // Mute/Unmute audio
  static Future<void> muteAudio(Room room, bool mute) async {
    try {
      if (room.localParticipant == null) return;

      // Set microphone enabled/disabled
      await room.localParticipant!.setMicrophoneEnabled(!mute);
    } catch (e) {
      debugPrint('Error toggling audio: $e');
    }
  }

  // Enable/Disable audio (alias for consistency with enableVideo)
  static Future<void> enableAudio(Room room, bool enable) async {
    try {
      if (room.localParticipant == null) return;

      // Set microphone enabled/disabled
      await room.localParticipant!.setMicrophoneEnabled(enable);
    } catch (e) {
      debugPrint('Error enabling audio: $e');
    }
  }

  // Enable/Disable video - matches JavaScript behavior
  static Future<void> enableVideo(Room room, bool enable) async {
    try {
      if (room.localParticipant == null) return;

      debugPrint('📹 ${enable ? "Enabling" : "Disabling"} video...');

      if (enable) {
        // Request permissions on mobile
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          final statuses = await [
            Permission.camera,
            Permission.microphone,
          ].request();
          if (statuses[Permission.camera]?.isGranted != true) {
            throw Exception('Camera permission not granted');
          }
        }
        // Check if we already have a video track
        final existingVideoTrack = room
            .localParticipant!
            .trackPublications
            .values
            .where(
              (pub) =>
                  pub.kind == TrackType.VIDEO &&
                  !pub.name.toLowerCase().contains('screen'),
            )
            .firstOrNull;

        if (existingVideoTrack == null) {
          // No existing track - create and publish new one
          debugPrint('📹 Creating new camera track...');
          final track = await LocalVideoTrack.createCameraTrack();
          await room.localParticipant!.publishVideoTrack(track);
          debugPrint('📹 New video track created and published');
        } else {
          // Track exists, just enable it
          debugPrint('📹 Enabling existing camera...');
          await room.localParticipant!.setCameraEnabled(true);
        }
      } else {
        // Disable camera (but keep the track for next enable)
        await room.localParticipant!.setCameraEnabled(false);
        debugPrint('📹 Camera disabled');
      }
    } catch (e) {
      debugPrint('❌ Error toggling video: $e');
      // Helpful hint for common Android emulator issue
      if (e.toString().toLowerCase().contains('camera') ||
          e.toString().toLowerCase().contains('permission')) {
        debugPrint(
          'ℹ️ Hint: On Android emulators, camera may not be available unless a virtual front/back camera is configured.',
        );
        debugPrint(
          '   Try a physical device or create an AVD with a virtual camera (or Cold Boot).',
        );
      }
      rethrow; // Let the caller handle the error
    }
  }

  // Start/Stop screen sharing
  static Future<void> toggleScreenShare(Room room, bool enable) async {
    try {
      if (room.localParticipant == null) {
        throw Exception('Local participant not initialized');
      }

      if (enable) {
        // On Android, request all required permissions for screen sharing
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          // Request system alert window permission first
          final alertWindowStatus = await Permission.systemAlertWindow.status;
          if (!alertWindowStatus.isGranted) {
            debugPrint(
              '🔄 Requesting system alert window permission for screen sharing...',
            );
            final newStatus = await Permission.systemAlertWindow.request();
            if (!newStatus.isGranted) {
              debugPrint(
                '❌ System alert window permission denied - screen sharing will not work',
              );
              throw Exception(
                'Screen sharing permission denied. Please enable "Display over other apps" in device settings.',
              );
            }
          }

          // Request notification permission for MediaProjection service
          final notificationStatus = await Permission.notification.status;
          if (!notificationStatus.isGranted) {
            debugPrint(
              '🔄 Requesting notification permission for MediaProjection...',
            );
            await Permission.notification.request();
          }
        }

        // Create and publish screen share track
        debugPrint('📺 Starting screen share...');

        final track = await LocalVideoTrack.createScreenShareTrack(
          const ScreenShareCaptureOptions(
            captureScreenAudio: false,
            maxFrameRate: 15, // Reduced for stability
            useiOSBroadcastExtension: true,
          ),
        );
        // Log actual screen share resolution (if available)
        try {
          final settings = track.mediaStreamTrack.getSettings();
          final width = settings['width'];
          final height = settings['height'];
          debugPrint(
            '🟦 Screen share capture resolution: '
            'width=${width ?? 'unknown'}, height=${height ?? 'unknown'}',
          );
        } catch (e) {
          debugPrint('Could not get screen share track settings: $e');
        }

        // Publish with explicit high-quality encoding for screen share
        const publishOptions = VideoPublishOptions(
          videoEncoding: VideoEncoding(
            // Higher bitrate to keep text crisp during motion/scroll
            maxBitrate: 3500000, // 3.5 Mbps
            maxFramerate: 30,
          ),
        );
        debugPrint(
          '📺 Publishing screen share with options: '
          'bitrate=${publishOptions.videoEncoding?.maxBitrate}, '
          'fps=${publishOptions.videoEncoding?.maxFramerate}',
        );
        await room.localParticipant!.publishVideoTrack(
          track,
          publishOptions: publishOptions,
        );
        await room.localParticipant!.setScreenShareEnabled(true);
        debugPrint('📺 Screen share track published successfully');
      } else {
        // Stop all screen share tracks
        debugPrint('📺 Stopping screen share...');
        final screenTracks = room.localParticipant!.trackPublications.values
            .where(
              (pub) =>
                  pub.kind == TrackType.VIDEO &&
                  pub.name.toLowerCase().contains('screen'),
            )
            .toList();

        for (final pub in screenTracks) {
          try {
            final videoTrack = pub.track;
            if (videoTrack is LocalVideoTrack) {
              await videoTrack.stop();
              debugPrint('📺 Stopped screen share track: ${pub.name}');
            }
          } catch (e) {
            debugPrint('Error stopping screen share track ${pub.sid}: $e');
          }
        }
        // Ensure screen share is disabled
        await room.localParticipant!.setScreenShareEnabled(false);
        debugPrint('📺 Screen share disabled');
      }
    } catch (e) {
      debugPrint('Error toggling screen share: $e');
      rethrow;
    }
  }

  // Get the current user's display name
  static Future<String> getCurrentUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'Instructor';
    } catch (e) {
      debugPrint('Error getting current user name: $e');
      return 'Instructor';
    }
  }

  // Chat-related methods

  // Send a message to the room
  static Future<bool> sendMessage(
    String occurrenceId,
    String scheduleId,
    String message,
  ) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('Send message', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
        'message': message,
      });

      return true;
    } catch (error) {
      debugPrint('Error sending message: $error');
      return false;
    }
  }

  // Create a poll
  static Future<bool> createPoll({
    required String occurrenceId,
    required String scheduleId,
    required String question,
    required List<String> options,
  }) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('createPoll', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
        'question': question,
        'options': options,
      });

      return true;
    } catch (error) {
      debugPrint('Error creating poll: $error');
      return false;
    }
  }

  // Vote in a poll
  static Future<bool> votePoll({
    required String occurrenceId,
    required String scheduleId,
    required String pollId,
    required String optionId,
  }) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('votePoll', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
        'pollId': pollId,
        'optionId': optionId,
      });

      return true;
    } catch (error) {
      debugPrint('Error voting in poll: $error');
      return false;
    }
  }

  // Raise hand
  static Future<bool> raiseHand(String occurrenceId, String scheduleId) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('raiseHand', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
      });

      return true;
    } catch (error) {
      debugPrint('Error raising hand: $error');
      return false;
    }
  }

  // Lower hand
  static Future<bool> lowerHand(String occurrenceId, String scheduleId) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('lowerHand', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
      });

      return true;
    } catch (error) {
      debugPrint('Error lowering hand: $error');
      return false;
    }
  }

  // Socket for video-calling namespace
  static IO.Socket? _videoSocket;

  // Connect to video socket
  static Future<IO.Socket> getVideoSocket() async {
    if (_videoSocket != null && _videoSocket!.connected) {
      return _videoSocket!;
    }

    // Get the user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'unknown-user';

    // Authentication token
    final authToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I';

    // Create socket connection
    _videoSocket = IO.io(
      '${socketUrl}/video-calling',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'Authorization': 'Bearer $authToken'})
          .setQuery({'token': authToken, 'userId': userId})
          .enableForceNew()
          .build(),
    );

    // Set up event listeners for debugging
    _videoSocket!.onConnect((_) => debugPrint('🔌 Connected to video socket'));
    _videoSocket!.onDisconnect(
      (_) => debugPrint('🔌 Disconnected from video socket'),
    );
    _videoSocket!.onError((e) => debugPrint('🔌 Socket error: $e'));

    // Connect the socket
    _videoSocket!.connect();

    return _videoSocket!;
  }

  // Join a video room
  static Future<Map<String, dynamic>> joinRoom({
    required String roomId,
    required String scheduleId,
    required String platformId,
    required String userId,
    String? username,
    required bool isHost,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    try {
      final socket = await getVideoSocket();

      // Set up listeners for room events
      socket.once('livekit-auth', (data) {
        debugPrint('LiveKit auth received: $data');
        completer.complete({'success': true, 'data': data});
      });

      socket.once('joinDenied', (data) {
        debugPrint('Join denied: $data');
        completer.complete({
          'success': false,
          'reason': data['reason'] ?? 'Unknown reason',
          'code': data['code'] ?? 'UNKNOWN',
        });
      });

      socket.once('error', (data) {
        debugPrint('Error joining room: $data');
        if (!completer.isCompleted) {
          completer.complete({
            'success': false,
            'reason': data['message'] ?? 'Unknown error',
          });
        }
      });

      // Get username if not provided
      if (username == null) {
        final prefs = await SharedPreferences.getInstance();
        username = prefs.getString('user_name') ?? 'User';
      }

      // Send joinRoom event with user details matching MongoDB structure
      socket.emit('joinRoom', {
        'occurrenceId': roomId,
        'scheduleId': scheduleId,
        'platformId': platformId,
        'userId': userId,
        'username': username,
        'role': isHost ? 'host' : 'participant',
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return {'success': false, 'reason': 'Request timed out'};
        },
      );
    } catch (error) {
      debugPrint('Error joining room: $error');
      return {'success': false, 'reason': 'Error: $error'};
    }
  }

  // Leave a room
  static Future<bool> leaveRoom(String occurrenceId, String scheduleId) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('leaveRoom', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
      });

      return true;
    } catch (error) {
      debugPrint('Error leaving room: $error');
      return false;
    }
  }

  // End a room (host only)
  static Future<bool> endRoom(String occurrenceId, String scheduleId) async {
    try {
      final socket = await getVideoSocket();

      socket.emit('endRoom', {
        'occurrenceId': occurrenceId,
        'scheduleId': scheduleId,
      });

      return true;
    } catch (error) {
      debugPrint('Error ending room: $error');
      return false;
    }
  }

  // Join a meeting using the occurrence data from MongoDB
  static Future<LiveKitConnectionInfo?> joinMeeting({
    required String scheduleId,
    required String occurrenceId,
    String platformId = 'miskills',
    String? userId,
    String? username,
    required bool isHost,
    Map<String, dynamic>? meetingData,
  }) async {
    debugPrint(
      '📞 Starting joinMeeting - Schedule ID: $scheduleId, Occurrence ID: $occurrenceId',
    );

    try {
      // Get user info from SharedPreferences if not provided
      if (userId == null || username == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id') ?? 'default-user';
        username = prefs.getString('user_name') ?? 'Instructor';
      }

      // If meeting data is provided, use those values instead
      if (meetingData != null) {
        // Extract values from the meeting data
        occurrenceId = meetingData['_id'] ?? occurrenceId;
        scheduleId = meetingData['scheduleId'] ?? scheduleId;
        platformId = meetingData['platformId'] ?? platformId;

        // If the current user is the host, use hostId from meeting data
        if (isHost && meetingData['hostId'] != null) {
          userId = meetingData['hostId'];
          username = meetingData['hostName'] ?? username;
        }

        debugPrint(
          '📄 Using meeting data: occurrenceId=$occurrenceId, scheduleId=$scheduleId',
        );
      }

      // Join room to get LiveKit token via socket
      final joinResult = await joinRoom(
        roomId: occurrenceId,
        scheduleId: scheduleId,
        platformId: platformId,
        userId: userId ?? 'unknown-user', // Ensure userId is not null
        username: username,
        isHost: isHost,
      );

      debugPrint('📞 Join result: $joinResult');

      if (!joinResult['success']) {
        debugPrint('❌ Failed to join meeting: ${joinResult['reason']}');
        return null;
      }

      final data = joinResult['data'];

      // Extract connection info from join result
      if (data != null && data['token'] != null && data['url'] != null) {
        final url = data['url'].toString();
        final token = data['token'].toString();

        debugPrint('🎯 LiveKit connection info received: url=$url');
        return LiveKitConnectionInfo(url: url, token: token);
      } else {
        debugPrint('❌ Invalid LiveKit data received: $data');
        return null;
      }
    } catch (error) {
      debugPrint('❌ Error joining meeting: $error');
      return null;
    }
  }

  // Test LiveKit connection
  static Future<bool> testLiveKitConnection(String roomName) async {
    try {
      debugPrint('Testing LiveKit connection for room: $roomName');

      // Get user details
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('user_id') ??
          'test-user-${DateTime.now().millisecondsSinceEpoch}';
      final username = prefs.getString('user_name') ?? 'Test User';

      // Use the new joinMeeting method
      final connectionInfo = await joinMeeting(
        scheduleId: roomName,
        occurrenceId: roomName,
        userId: userId,
        username: username,
        isHost: true,
      );

      if (connectionInfo == null) {
        debugPrint('Failed to get LiveKit connection info');
        return false;
      }

      // Initialize room
      final room = await initializeRoom();

      // Try to connect to room with the token
      final connected = await connectToRoom(room, connectionInfo.token);

      if (connected) {
        debugPrint('Successfully connected to LiveKit room: $roomName');
        // Disconnect after successful test
        await disconnectFromRoom(room);
        // Also leave room on the socket
        await leaveRoom(roomName, roomName);
        return true;
      } else {
        debugPrint('Failed to connect to LiveKit room');
        return false;
      }
    } catch (error) {
      debugPrint('Error testing LiveKit connection: $error');
      return false;
    }
  }
}
