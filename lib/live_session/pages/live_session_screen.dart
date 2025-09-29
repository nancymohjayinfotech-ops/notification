import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:livekit_client/livekit_client.dart' hide ChatMessage;
import '../services/livekit_service.dart';
import '../services/video_calling_socket_service.dart' as vcss;
import '../services/meeting_service.dart';
import '../services/meeting_api_service.dart';
import '../widgets/socket_connection_indicator.dart';
import '../utils/constants.dart';
import '../utils/network_config.dart';
import 'participant_track.dart';
import '../models/chat_message.dart';

class LiveSessionScreen extends StatefulWidget {
  final String meetingTitle;
  final String meetingId; // This is the occurrenceId
  final String scheduleId; // Added scheduleId parameter
  final bool isHost;

  const LiveSessionScreen({
    super.key,
    required this.meetingTitle,
    required this.meetingId,
    this.scheduleId = '', // Default empty if not provided
    this.isHost = true,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  bool _isRecording = false;
  // Handle userKicked event (broadcast to all)
  void _handleUserKicked(Map<String, dynamic> data) {
    final targetUserId = data['targetUserId'] as String?;
    if (targetUserId == null) return;
    // Show notification to all (except the kicked user)
    if (mounted && targetUserId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A participant was removed by the host.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Handle kicked event (sent only to the kicked user)
  void _handleKicked(Map<String, dynamic> data) {
    final reason = data['reason'] ?? 'Removed by host';
    if (mounted) {
      // Remove self from participants list immediately
      setState(() {
        _participants.clear();
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Removed from Meeting'),
          content: Text(reason.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      // Also disconnect from room and socket
      _disconnectFromRoom();
      try {
        _socketService.disconnect();
      } catch (_) {}
    }
  }

  // Kick a participant from the meeting (host only)
  void _kickParticipant(ParticipantData participant) async {
    // Use the correct platformId
    const platformId = 'miskills';
    final userId = _currentUserId;
    final targetUserId = participant.userId;
    final targetUsername = participant.name;
    final scheduleId = widget.scheduleId;
    final occurrenceId = _resolvedOccurrenceId ?? widget.meetingId;
    if (userId == null || targetUserId.isEmpty) return;
    _socketService.kickUser(
      scheduleId: scheduleId,
      occurrenceId: occurrenceId,
      platformId: platformId,
      userId: userId,
      targetUserId: targetUserId,
      targetUsername: targetUsername,
    );
  }

  bool _isMicMuted = false;
  bool _isVideoOff =
      true; // Start with camera OFF like JavaScript isCamOn = false
  bool _isScreenSharing = false;
  bool _isChatOpen = false;
  bool _isPollOpen = false;
  bool _isHandRaised = false;
  bool _isParticipantsOpen = false;
  final List<PollData> _polls = [];

  // LiveKit specific variables
  bool _isConnecting = true;
  String? _errorMessage;
  Room? _room;
  List<ParticipantTrack> _participantTracks = [];
  EventsListener<RoomEvent>? _roomEvents;

  // Socket service
  final vcss.VideoCallingSocketService _socketService =
      vcss.VideoCallingSocketService();
  bool _isReconnecting = false; // Flag to track socket reconnection attempts
  final List<StreamSubscription> _subscriptions = [];

  // Chat messages
  final _chatMessages = <ChatMessage>[];
  final _textController = TextEditingController();

  // Hand raised participants
  final List<String> _raisedHandUserIds = [];

  // int _elapsedSeconds = 0; // Removed unused field
  late Timer _timer;

  // Dynamic participants list - populated from LiveKit room participants
  final List<ParticipantData> _participants = [];
  // Track which participant identities have already triggered a join notification
  final Set<String> _joinNotified = {};

  // Cache a resolved MongoDB ObjectId for occurrenceId to avoid re-fetching
  String? _resolvedOccurrenceId;
  // Cache current user id for de-duplicating own chat echoes
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Start session timer (removed _elapsedSeconds increment as it was unused)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });

    // Initialize test user credentials and then setup services
    _initializeAndSetup();
  }

  // Initialize test user and setup services
  Future<void> _initializeAndSetup() async {
    try {
      // Load network overrides (optional)
      await NetworkConfig.loadOverrides();
      // Initialize test user credentials
      await MeetingService.initializeTestUser();

      // Initialize socket service
      await _initSocketService();

      // Setup LiveKit room
      await _setupRoom();
    } catch (e) {
      print('Error during setup: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Setup failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _timer.cancel();
    } catch (_) {}
    for (final sub in _subscriptions) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    // Disconnect socket for this screen without disposing global streams
    try {
      _socketService.disconnect();
    } catch (_) {}
    // Best-effort room disconnect
    final room = _room;
    if (room != null) {
      LiveKitService.disconnectFromRoom(room);
    }
    try {
      _roomEvents?.dispose();
    } catch (_) {}
    _roomEvents = null;
    _textController.dispose();
    super.dispose();
  }

  // Initialize socket service and set up event listeners
  Future<void> _initSocketService() async {
    // Listen for userKicked (broadcast to all)
    _subscriptions.add(_socketService.onUserKicked.listen(_handleUserKicked));
    // Listen for kicked (sent only to the kicked user)
    _subscriptions.add(_socketService.onKicked.listen(_handleKicked));
    try {
      // Get user information from SharedPreferences, same as in _joinSocketRoom
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'instructor_default';
      final username = prefs.getString('user_name') ?? 'Instructor';

      // Cache for message de-duplication and general use
      _currentUserId = userId;

      // Initialize the socket connection with user credentials
      await _socketService.initialize(userId, username);

      // Set up event listeners for socket events
      _subscriptions.add(_socketService.onNewChat.listen(_handleNewChat));
      // Populate chat with history received on join
      _subscriptions.add(
        _socketService.onChatHistory.listen((history) {
          if (!mounted) return;
          setState(() {
            final existingKeys = _chatMessages
                .map(
                  (m) =>
                      '${m.senderName}_${m.timestamp.millisecondsSinceEpoch}_${m.message}',
                )
                .toSet();
            final newItems = history.messages.map(
              (m) => ChatMessage(
                id: 'hist_${m.senderId}_${m.timestamp}',
                message: m.text,
                senderName: m.senderName,
                timestamp: DateTime.fromMillisecondsSinceEpoch(m.timestamp),
                isFromLocalUser: false,
              ),
            );
            for (final item in newItems) {
              final key =
                  '${item.senderName}_${item.timestamp.millisecondsSinceEpoch}_${item.message}';
              if (!existingKeys.contains(key)) {
                _chatMessages.add(item);
              }
            }
            _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
        }),
      );
      _subscriptions.add(_socketService.onPollEvent.listen(_handlePollEvent));
      _subscriptions.add(_socketService.onHandEvent.listen(_handleHandEvent));
      _subscriptions.add(_socketService.onRoomClosed.listen(_handleRoomClosed));
      _subscriptions.add(_socketService.onUserLeft.listen(_handleUserLeft));
      _subscriptions.add(_socketService.onError.listen(_handleSocketError));

      // Meeting ending soon notification from server
      _subscriptions.add(
        _socketService.onMeetingEndSoon.listen((data) {
          final msg = (data['message'] ?? 'Meeting will end soon') as String;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }),
      );

      // Join room when the socket reports connected; also re-join after reconnects
      _subscriptions.add(
        _socketService.onConnectionStatus.listen((isConnected) {
          if (isConnected) {
            _joinSocketRoom();
          }
        }),
      );
      // If connection already established before listener attached, join now
      if (_socketService.isConnected) {
        _joinSocketRoom();
      }
    } catch (e) {
      print('Error initializing socket service: $e');
    }

    // Do not join immediately; wait for onConnectionStatus=true above
  }

  // Join the socket room
  Future<void> _joinSocketRoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'instructor_default';
      final username = prefs.getString('user_name') ?? 'Instructor';

      // IMPORTANT: The backend expects occurrenceId to be a MongoDB ObjectId
      // MongoDB ObjectIDs are 24-character hexadecimal strings

      // Get scheduleId from widget
      final scheduleId = widget.scheduleId;

      // Use cached occurrenceId if available, otherwise meetingId from widget
      String occurrenceId = _resolvedOccurrenceId ?? widget.meetingId;

      print('=== JOINING SOCKET ROOM ===');
      print('User ID: $userId');
      print('Username: $username');
      print('Initial occurrenceId from widget: $occurrenceId');
      print('ScheduleId from widget: $scheduleId');

      // If no meeting IDs provided, show error - no more hardcoded test data
      if (occurrenceId.isEmpty || scheduleId.isEmpty) {
        print('❌ ERROR: No meeting IDs provided');
        print('   - OccurrenceId: $occurrenceId');
        print('   - ScheduleId: $scheduleId');

        if (mounted) {
          setState(() {
            _isConnecting = false;
            _errorMessage =
                'Meeting IDs are required. Please provide valid meetingId and scheduleId.';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: No meeting IDs provided. Cannot join meeting without valid meetingId and scheduleId.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 8),
            ),
          );
        }
        return; // Don't proceed without proper meeting IDs
      }

      // Check if it's a valid MongoDB ObjectId format
      bool isValidObjectId =
          occurrenceId.length == 24 &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

      if (!isValidObjectId) {
        // If we have a cached resolved ID, use it directly
        if (_resolvedOccurrenceId != null &&
            _resolvedOccurrenceId!.length == 24 &&
            RegExp(r'^[0-9a-fA-F]{24}\$').hasMatch(_resolvedOccurrenceId!)) {
          occurrenceId = _resolvedOccurrenceId!;
          isValidObjectId = true;
        }
      }

      if (!isValidObjectId) {
        // If not valid, fetch the actual MongoDB ObjectId from the API
        print(
          'Fetching valid MongoDB ObjectId from API for scheduleId: $scheduleId',
        );

        // Show a loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fetching meeting details...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Try the direct API service first (more reliable)
        String? fetchedId =
            await MeetingApiService.findMeetingObjectIdByScheduleId(scheduleId);

        // If that fails, try the regular meeting service as backup
        fetchedId ??= await MeetingService.getMeetingObjectId(scheduleId);

        if (fetchedId != null && fetchedId.length == 24) {
          occurrenceId = fetchedId;
          _resolvedOccurrenceId = occurrenceId; // cache for future reconnects
          print('Successfully fetched MongoDB ObjectId: $occurrenceId');
        } else {
          // If API call fails, show an error and prevent joining with invalid ID
          print('Failed to fetch a valid MongoDB ObjectId from API');

          if (mounted) {
            setState(() {
              _isConnecting = false;
              _errorMessage =
                  'Could not find meeting with schedule ID: $scheduleId';
            });

            // Show detailed error to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: Could not fetch meeting ID for schedule: $scheduleId.\n'
                  'Please check your network connection and that the meeting exists.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    setState(() {
                      _isConnecting = true;
                      _errorMessage = null;
                    });
                    // Try again
                    _joinSocketRoom();
                  },
                ),
              ),
            );
          }

          // Return early - don't join the room with invalid ID
          return;
        }
      }

      print('=== JOINING SOCKET ROOM ===');
      print('ScheduleId: $scheduleId');
      print('OccurrenceId: $occurrenceId');
      print('UserId: $userId');
      print('Username: $username');
      print('PlatformId: ${AppConstants.platformId}');
      print('IsHost: ${widget.isHost}');
      print('==========================');

      _socketService.joinRoom(
        scheduleId: scheduleId,
        occurrenceId: occurrenceId, // Using a valid MongoDB _id
        userId: userId,
        username: username,
        isHost: widget.isHost,
      );

      // Set a timeout to check if we received LiveKit auth within a reasonable time
      Future.delayed(Duration(seconds: 10), () {
        if (mounted) {
          // Check if we're still connecting to LiveKit - if so, server may not be sending livekit-auth
          if (_isConnecting) {
            print(
              'Socket joinRoom sent, but no livekit-auth received yet. Check backend logs.',
            );

            setState(() {
              _isConnecting = false;
              _errorMessage =
                  'Connection timeout. Please check if the meeting exists and try again.';
            });

            // Show a helpful message to the developer
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Meeting connection timeout. Please check backend logs and try again.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    setState(() {
                      _isConnecting = true;
                      _errorMessage = null;
                    });
                    _joinSocketRoom();
                  },
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      print('Error joining socket room: $e');

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Error: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle new chat message from socket
  void _handleNewChat(vcss.ChatMessage message) {
    // Skip echo of our own message (we already add it locally on send)
    if (_currentUserId != null && message.senderId == _currentUserId) {
      return;
    }
    setState(() {
      _chatMessages.add(
        ChatMessage(
          id: 'socket_${message.senderId}_${message.timestamp}',
          message: message.text,
          senderName: message.senderName,
          timestamp: DateTime.fromMillisecondsSinceEpoch(message.timestamp),
          isFromLocalUser: false,
        ),
      );
    });
  }

  // Handle poll event from socket
  void _handlePollEvent(vcss.Poll pollEvent) {
    // Convert from socket Poll model to our PollData model
    final pollData = PollData(
      id: pollEvent.id,
      question: pollEvent.question,
      options: pollEvent.options
          .map((option) => PollOption(text: option.text, votes: option.votes))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(pollEvent.createdAt),
      isActive: pollEvent.isActive,
    );

    // Update or add the poll
    setState(() {
      final existingIndex = _polls.indexWhere((p) => p.id == pollData.id);

      if (existingIndex >= 0) {
        _polls[existingIndex] = pollData;
      } else {
        _polls.add(pollData);
      }
    });
  }

  // Handle hand raise event from socket
  void _handleHandEvent(vcss.HandRaiseEvent event) {
    setState(() {
      if (event.type == 'handRaised') {
        if (!_raisedHandUserIds.contains(event.userId)) {
          _raisedHandUserIds.add(event.userId);
        }

        // If this is the local participant, update the local hand raise state
        if (_room?.localParticipant?.identity == event.userId) {
          _isHandRaised = true;
        }
      } else if (event.type == 'handLowered') {
        _raisedHandUserIds.remove(event.userId);

        // If this is the local participant, update the local hand raise state
        if (_room?.localParticipant?.identity == event.userId) {
          _isHandRaised = false;
        }
      }
    });

    // Refresh participants to update hand raise status in the UI
    _refreshParticipants();

    // Show a brief notification for remote users
    final localId = _room?.localParticipant?.identity;
    if (mounted && event.userId != localId) {
      final isRaised = event.type == 'handRaised';
      final name = (event.username.isNotEmpty ? event.username : event.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRaised ? '$name raised their hand' : '$name lowered their hand',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle room closed event from socket
  void _handleRoomClosed(Map<String, dynamic> data) {
    // Show a dialog and navigate back to the meetings screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Meeting Ended'),
        content: Text('This meeting has been ended by the host.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Handle user left event from socket
  void _handleUserLeft(Map<String, dynamic> data) {
    print('User left event: $data');

    // Extract user information from the event
    final userId = data['userId'] as String?;
    final username = data['username'] as String?;

    if (userId != null) {
      // Remove from raised hand users
      _raisedHandUserIds.remove(userId);

      // The participant will be automatically removed from _participants
      // when _refreshParticipants is called due to LiveKit ParticipantDisconnectedEvent

      // Show notification if username is available
      if (username != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username left the meeting'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Handle socket errors
  void _handleSocketError(String errorMessage) {
    print('Socket error: $errorMessage');

    // Attempt to reconnect after a brief delay
    if (!_isReconnecting) {
      _isReconnecting = true;

      Future.delayed(Duration(seconds: 3), () async {
        print('Attempting to reconnect socket...');
        final reconnected = await _socketService.checkConnectionHealth();

        if (reconnected) {
          print('Socket reconnected successfully');
          // Re-join the room
          _joinSocketRoom();
        } else {
          print('Socket reconnection failed');
        }

        _isReconnecting = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection error: $errorMessage'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _setupRoom() async {
    try {
      setState(() {
        _isConnecting = true;
        _errorMessage = '';
      });

      // Initialize the room
      final room = await LiveKitService.initializeRoom();

      // Note: Permission handling is automatically managed by LiveKit when we create tracks
      // No explicit permission requests needed here - they will be requested when
      // publishing video/audio tracks

      // Set up participant track listener and hold a strong reference
      try {
        _roomEvents?.dispose();
      } catch (_) {}
      _roomEvents = room.createListener()
        ..on<RoomConnectedEvent>((event) {
          print('✅ Room connected');
          _refreshParticipants();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _refreshParticipants();
          });
        })
        ..on<RoomReconnectedEvent>((event) {
          print('🔁 Room reconnected');
          _refreshParticipants();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _refreshParticipants();
          });
        })
        ..on<RoomReconnectingEvent>((event) {
          print('⚠️ Room reconnecting...');
        })
        ..on<ParticipantConnectedEvent>((event) {
          print('🎯 Participant connected: ${event.participant.identity}');
          _refreshParticipants();
          // Show in-meeting notification for remote participant joins
          _showJoinNotification(event.participant);
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) _refreshParticipants();
          });
        })
        ..on<ParticipantDisconnectedEvent>((event) {
          print('🚪 Participant disconnected: ${event.participant.identity}');
          _refreshParticipants();
          if (mounted) {
            final displayName = event.participant.name.isNotEmpty
                ? event.participant.name
                : event.participant.identity;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$displayName left the meeting'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        })
        ..on<TrackSubscribedEvent>((event) {
          print(
            '📺 Track subscribed: ${event.track.kind} from ${event.participant.identity}',
          );
          _refreshParticipants();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _refreshParticipants();
          });
        })
        ..on<TrackUnsubscribedEvent>((event) {
          print(
            '📺❌ Track unsubscribed: ${event.track.kind} from ${event.participant.identity}',
          );
          _refreshParticipants();
        })
        ..on<TrackPublishedEvent>((event) {
          print(
            '📤 Track published: ${event.publication.kind} from ${event.participant.identity}',
          );
          _refreshParticipants();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _refreshParticipants();
          });
        })
        ..on<TrackUnpublishedEvent>((event) {
          print(
            '📤❌ Track unpublished: ${event.publication.kind} from ${event.participant.identity}',
          );
          _refreshParticipants();
        })
        ..on<TrackMutedEvent>((event) {
          print(
            '🔇 Track muted: ${event.publication.kind} from ${event.participant.identity}',
          );
          _refreshParticipants();
        })
        ..on<TrackUnmutedEvent>((event) {
          print(
            '🔊 Track unmuted: ${event.publication.kind} from ${event.participant.identity}',
          );
          _refreshParticipants();
        })
        ..on<DataReceivedEvent>((event) {
          // Handle incoming data messages (chat, etc.)
          try {
            final data = utf8.decode(event.data);
            final jsonData = jsonDecode(data);

            if (jsonData['type'] == 'chat') {
              final now = DateTime.now();
              setState(() {
                _chatMessages.add(
                  ChatMessage(
                    id: 'remote-${now.millisecondsSinceEpoch}',
                    message: jsonData['message'],
                    senderName: jsonData['sender'],
                    timestamp: now,
                    isFromLocalUser: false,
                  ),
                );
              });
            }
          } catch (e) {
            print('Error parsing data message: $e');
          }
        });

      // Store the room instance for later use
      setState(() {
        _room = room;
      });

      // Listen for the LiveKit auth token from socket
      _subscriptions.add(
        _socketService.onLivekitAuth.listen((livekitAuth) async {
          print('✅ LiveKit authentication received!');
          print('LiveKit data: ${livekitAuth.toString()}');
          print('Successfully parsed LiveKit auth data:');
          print('- URL: ${livekitAuth.url}');
          print('- Token length: ${livekitAuth.token.length} characters');

          try {
            // Connect to room with token AND URL from socket using detailed method
            final connectionResult =
                await LiveKitService.connectToRoomWithDetails(
                  room,
                  livekitAuth.token,
                  serverUrl: livekitAuth.url,
                );

            if (!connectionResult['success']) {
              final errorType = connectionResult['type'] ?? 'unknown';
              final errorMessage =
                  connectionResult['error'] ?? 'Unknown LiveKit error';

              String userFriendlyMessage;
              switch (errorType) {
                case 'api_key':
                  userFriendlyMessage =
                      'Configuration Error: LiveKit API key mismatch.\n\n'
                      'The backend API key does not match the LiveKit server configuration. '
                      'Please check your server configuration.';
                  break;
                case 'token':
                  userFriendlyMessage =
                      'Token Error: Invalid or expired LiveKit token.\n\n'
                      'The meeting token is invalid. Try refreshing the page or '
                      'check with the meeting organizer.';
                  break;
                case 'connection':
                  userFriendlyMessage =
                      'Connection Error: Cannot reach LiveKit server.\n\n'
                      'The video server is not accessible. Check your internet connection '
                      'or contact support if the problem persists.';
                  break;
                default:
                  userFriendlyMessage =
                      'LiveKit Connection Error:\n$errorMessage\n\n'
                      'Please check your connection and try again.';
              }

              setState(() {
                _isConnecting = false;
                _errorMessage = userFriendlyMessage;
              });

              // Show specific error in console for debugging
              print('❌ LiveKit connection failed: $errorMessage');
              print('   Error type: $errorType');

              return;
            }

            // Only publish audio initially - video will be published when user enables camera
            // This matches the JavaScript behavior where camera starts OFF
            if (widget.isHost) {
              try {
                await LiveKitService.publishAudio(room);
                print(
                  '🎤 Audio published successfully (camera remains off initially)',
                );
              } catch (mediaError) {
                print('Error publishing audio: $mediaError');
                // Continue even if media publishing fails
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error accessing microphone. Audio features may be limited.',
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }

            setState(() {
              _isConnecting = false;
            });

            // Wait for tracks to be fully initialized
            await Future.delayed(const Duration(milliseconds: 1000));

            // Initial refresh
            _refreshParticipants();

            print(
              '🎯 Initial connection complete. Video should be visible now.',
            );

            // Additional refresh after a short delay to ensure tracks are fully published
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                print('🔄 Delayed refresh for video tracks...');
                _refreshParticipants();
              }
            });

            // Another refresh after a longer delay to catch any late track publications
            Future.delayed(Duration(milliseconds: 2000), () {
              if (mounted) {
                print('🔄 Final refresh for video tracks...');
                _refreshParticipants();
              }
            });
          } catch (e) {
            setState(() {
              _isConnecting = false;
              _errorMessage = 'Error connecting to LiveKit: $e';
            });
            print('Error connecting to LiveKit: $e');

            // Show a user-friendly message but allow the meeting to continue
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Video connection failed, but you can still use chat and other meeting features.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }),
      );

      // Handle connection timeout
      Future.delayed(const Duration(seconds: 10), () async {
        if (_isConnecting && mounted) {
          print('LiveKit connection timeout - no token received from backend');

          // Inform the user about the connection timeout
          if (mounted) {
            setState(() {
              _isConnecting = false;
              _errorMessage =
                  'Video connection timeout. Please check your backend connection.';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Video connection failed. Please make sure the backend server is running.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'An error occurred: $e';
      });
      print('Error setting up meeting: $e');
    }
  }

  void _refreshParticipants() {
    print('🔄 [DEBUG] _refreshParticipants called');
    if (_room == null) return;

    print('🔄 Refreshing participants...');
    print('   Local participant: ${_room!.localParticipant?.identity}');
    print('   Remote participants count: ${_room!.remoteParticipants.length}');

    // Helper to get the active (unmuted) video track for a participant
    VideoTrack? _activeVideoTrack(Participant p, {bool screenShare = false}) {
      for (final pub in p.trackPublications.values) {
        print(
          '    [DEBUG] _activeVideoTrack pub.kind=${pub.kind} pub.name=${pub.name} pub.track=${pub.track} muted=${pub.track?.muted}',
        );
        try {
          if (pub.kind == TrackType.VIDEO) {
            // Check if this is a screen share track by metadata or name
            final isScreen =
                pub.name.toLowerCase().contains('screen') ||
                pub.sid.toLowerCase().contains('screen');
            if (screenShare == isScreen) {
              final t = pub.track;
              // Only return if not muted, not null, and has a sid (not stopped/disposed)
              if (t is VideoTrack && !(t.muted)) {
                return t;
              }
            }
          }
        } catch (_) {}
      }
      return null;
    }

    setState(() {
      final tracks = <ParticipantTrack>[];
      final pdList = <ParticipantData>[];

      void addSingleCardForParticipant(Participant p, {bool isHost = false}) {
        print('🔄 [DEBUG] Checking participant: ${p.identity}');
        for (final pub in p.trackPublications.values) {
          print(
            '    [DEBUG] pub.kind=${pub.kind} pub.name=${pub.name} pub.track=${pub.track} muted=${pub.track?.muted}',
          );
        }
        // Priority: screen share > camera > avatar
        final screenTrack = _activeVideoTrack(p, screenShare: true);
        final camTrack = _activeVideoTrack(p, screenShare: false);
        // Only show if not muted and not ended
        if (screenTrack != null && !(screenTrack.muted)) {
          tracks.add(
            ParticipantTrack(
              participant: p,
              publication: null,
              track: screenTrack,
              isScreenShare: true,
              isHost: isHost,
            ),
          );
        } else if (camTrack != null && !(camTrack.muted)) {
          tracks.add(
            ParticipantTrack(
              participant: p,
              publication: null,
              track: camTrack,
              isScreenShare: false,
              isHost: isHost,
            ),
          );
        } else {
          // No video tracks, add a dummy ParticipantTrack for avatar fallback
          tracks.add(
            ParticipantTrack(
              participant: p,
              publication: null,
              track: null,
              isScreenShare: false,
              isHost: isHost,
            ),
          );
        }
        pdList.add(
          ParticipantData(
            name: p.name.isNotEmpty ? p.name : p.identity,
            userId: p.identity,
            isMuted: !p.isMicrophoneEnabled(),
            isVideoOff: !p.isCameraEnabled(),
            isHost: isHost,
            isHandRaised: _raisedHandUserIds.contains(p.identity),
          ),
        );
      }

      // Local participant
      final local = _room!.localParticipant;
      if (local != null) {
        addSingleCardForParticipant(local, isHost: widget.isHost);
      }
      // Remote participants
      for (final rp in _room!.remoteParticipants.values) {
        addSingleCardForParticipant(rp, isHost: false);
      }

      // Update stateful lists
      _participantTracks = tracks;
      _participants
        ..clear()
        ..addAll(pdList);
    });
  }

  // Show a SnackBar when a new (remote) participant joins, once per identity
  void _showJoinNotification(Participant participant) {
    if (!mounted) return;
    final localId = _room?.localParticipant?.identity;
    // Skip if it's the local participant or already notified
    if (participant.identity == localId ||
        _joinNotified.contains(participant.identity)) {
      return;
    }
    _joinNotified.add(participant.identity);
    final displayName = participant.name.isNotEmpty
        ? participant.name
        : participant.identity;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$displayName joined the meeting'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleVideo() async {
    if (_room == null || _room!.localParticipant == null) return;

    setState(() {
      _isVideoOff = !_isVideoOff;
    });

    try {
      // Use enableVideo which reuses existing track if present
      await LiveKitService.enableVideo(_room!, !_isVideoOff);
    } catch (_) {}

    // Always refresh immediately so UI updates for both camera and screen share
    _refreshParticipants();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _refreshParticipants();
    });
  }

  void _toggleScreenShare() async {
    if (_room == null) return;

    try {
      setState(() {
        _isScreenSharing = !_isScreenSharing;
      });

      await LiveKitService.toggleScreenShare(_room!, _isScreenSharing);

      // Always refresh immediately so UI updates for both camera and screen share
      _refreshParticipants();
      // Extra forced refresh after a short delay to ensure fallback to avatar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _refreshParticipants();
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _refreshParticipants();
      });
    } catch (error) {
      // Revert the state if screen sharing failed
      setState(() {
        _isScreenSharing = !_isScreenSharing;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screen sharing failed: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await LiveKitService.openAppSettings();
              },
            ),
          ),
        );
      }

      debugPrint('❌ Error toggling screen share: $error');
    }

    // Notify that we're screen sharing
    if (_room!.localParticipant != null) {
      _room!.localParticipant!.setMetadata(
        jsonEncode({
          'name': await LiveKitService.getCurrentUserName(),
          'isScreenSharing': _isScreenSharing,
          'isHost': widget.isHost,
        }),
      );
    }
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  void _toggleParticipants() {
    setState(() {
      _isParticipantsOpen = !_isParticipantsOpen;
      if (_isParticipantsOpen) {
        _isChatOpen = false;
        _isPollOpen = false;
      }
    });
  }

  void _sendChatMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final message = _textController.text;

    // Get the current user name
    final userName =
        await LiveKitService.getCurrentUserName() +
        (widget.isHost ? ' (Host)' : '');

    // First add the message to local chat for instant display
    final now = DateTime.now();
    setState(() {
      _chatMessages.add(
        ChatMessage(
          id: 'local-${now.millisecondsSinceEpoch}',
          message: message,
          senderName: userName,
          timestamp: now,
          isFromLocalUser: true,
        ),
      );
    });

    // Send the message through the socket service
    try {
      // Get validated occurrenceId
      final occurrenceId = await _getValidOccurrenceId();

      _socketService.sendChatMessage(
        scheduleId: widget.scheduleId,
        occurrenceId: occurrenceId,
        text: message,
      );
    } catch (e) {
      print('Error sending chat message through socket: $e');

      // If socket fails, try to send via LiveKit data channel as backup
      if (_room?.localParticipant != null) {
        try {
          final messageData = {
            'type': 'chat',
            'message': message,
            'sender': userName,
            'timestamp': now.millisecondsSinceEpoch,
          };

          // Send to all participants using reliable data channel
          await _room!.localParticipant!.publishData(
            utf8.encode(jsonEncode(messageData)),
            reliable: true,
          );
        } catch (e) {
          print('Error sending message via data channel: $e');
        }
      }
    }

    _textController.clear();
  }

  void _endMeeting() {
    if (!widget.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the host can end the meeting')),
      );
      return;
    }

    // End meeting for all: emit endRoom, disconnect socket, and prevent rejoin
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? 'instructor_default';
        final occurrenceId = await _getValidOccurrenceId();

        // Emit endRoom event
        _socketService.endRoom(
          scheduleId: widget.scheduleId,
          occurrenceId: occurrenceId,
          userId: userId,
        );

        // Disconnect from LiveKit
        await _disconnectFromRoom();

        // Disconnect socket to prevent rejoin
        try {
          _socketService.disconnect();
        } catch (_) {}

        // Pop once to go back to the meetings list
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error ending meeting: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to end meeting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }();
  }

  void _togglePoll() {
    setState(() {
      _isPollOpen = !_isPollOpen;
      if (_isPollOpen) {
        _isChatOpen = false;
      }
    });
  }

  // Helper method to get validated occurrenceId
  Future<String> _getValidOccurrenceId() async {
    String occurrenceId = widget.meetingId;

    // Check if it's a valid MongoDB ObjectId format
    bool isValidObjectId =
        occurrenceId.length == 24 &&
        RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(occurrenceId);

    if (!isValidObjectId) {
      // If not valid, fetch the actual MongoDB ObjectId from the API
      print(
        'Fetching valid MongoDB ObjectId from API for scheduleId: ${widget.scheduleId}',
      );

      // Try the direct API service first (more reliable)
      String? fetchedId =
          await MeetingApiService.findMeetingObjectIdByScheduleId(
            widget.scheduleId,
          );

      // If that fails, try the regular meeting service as backup
      fetchedId ??= await MeetingService.getMeetingObjectId(widget.scheduleId);

      if (fetchedId != null && fetchedId.length == 24) {
        occurrenceId = fetchedId;
        print('Successfully fetched MongoDB ObjectId: $occurrenceId');
      } else {
        // If API call fails, log the error but continue with original ID
        print(
          'WARNING: Failed to fetch a valid MongoDB ObjectId. Using original ID: $occurrenceId',
        );
      }
    }

    return occurrenceId;
  }

  void _toggleHandRaise() async {
    // Update UI state
    setState(() {
      _isHandRaised = !_isHandRaised;
    });

    // Also update the raised hand user IDs list for local participant
    if (_room?.localParticipant?.identity != null) {
      final localUserId = _room!.localParticipant!.identity;
      if (_isHandRaised) {
        if (!_raisedHandUserIds.contains(localUserId)) {
          _raisedHandUserIds.add(localUserId);
        }
      } else {
        _raisedHandUserIds.remove(localUserId);
      }
    }

    // Get validated occurrenceId
    final occurrenceId = await _getValidOccurrenceId();

    // Send hand raise/lower event to socket server
    if (_isHandRaised) {
      _socketService.raiseHand(
        scheduleId: widget.scheduleId,
        occurrenceId: occurrenceId,
      );
    } else {
      _socketService.lowerHand(
        scheduleId: widget.scheduleId,
        occurrenceId: occurrenceId,
      );
    }

    // Refresh participants list to update hand raise status immediately
    _refreshParticipants();

    // Show feedback to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHandRaised ? 'You raised your hand' : 'You lowered your hand',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _createPoll() {
    final TextEditingController questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Create Poll'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question',
                        hintText: 'Enter your question',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Options:'),
                    ...List.generate(
                      optionControllers.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}',
                                  hintText: 'Enter option ${index + 1}',
                                ),
                              ),
                            ),
                            if (optionControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setStateDialog(() {
                                    optionControllers.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          optionControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
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
                  onPressed: () {
                    if (questionController.text.trim().isEmpty ||
                        optionControllers.any((c) => c.text.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Question and all options must be filled',
                          ),
                        ),
                      );
                      return;
                    }

                    // Create the poll using socket service
                    _getValidOccurrenceId().then((occurrenceId) {
                      _socketService.createPoll(
                        scheduleId: widget.scheduleId,
                        occurrenceId: occurrenceId,
                        question: questionController.text.trim(),
                        options: optionControllers
                            .map((c) => c.text.trim())
                            .toList(),
                      );
                    });

                    // The poll will be received via the socket poll event handler
                    // and added to _polls automatically
                    _togglePoll();
                    Navigator.pop(context);
                  },
                  child: const Text('Create Poll'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _disconnectFromRoom() async {
    try {
      final room = _room;
      if (room != null) {
        await LiveKitService.disconnectFromRoom(room);
      }
    } catch (e) {
      print('Error disconnecting from room: $e');
    }
  }

  // String _formatTime(int seconds) {
  //   final m = (seconds ~/ 60).toString().padLeft(2, '0');
  //   final s = (seconds % 60).toString().padLeft(2, '0');
  //   return '$m:$s';
  // }

  void _toggleMute() async {
    if (_room == null) return;
    setState(() => _isMicMuted = !_isMicMuted);
    try {
      await LiveKitService.muteAudio(_room!, _isMicMuted);
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  // Removed unused participant management methods to keep codebase clean.

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    // Show loading indicator while connecting
    if (_isConnecting) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.purple),
              const SizedBox(height: 16),
              Text(
                'Connecting to meeting...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message if connection failed
    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final isDesktopOrWeb =
        kIsWeb ||
        [
          TargetPlatform.windows,
          TargetPlatform.macOS,
          TargetPlatform.linux,
        ].contains(Theme.of(context).platform);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading:
            !(isDesktopOrWeb), // Remove back button for desktop/web
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.meetingTitle),
            Text(
              'Meeting ID: ${widget.meetingId}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Socket connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SocketConnectionIndicator(
              socketService: _socketService,
              onRetry: () {
                // Re-join room on successful reconnection
                _joinSocketRoom();
              },
            ),
          ),

          // Leave/End Meeting button for instructor
          if (widget.isHost)
            TextButton.icon(
              onPressed: () => _showLeaveEndDialog(),
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text(
                'Leave',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          if (!widget.isHost)
            TextButton.icon(
              onPressed: () => _leaveMeetingAsParticipant(),
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text(
                'Leave',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          // Session timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
      body: _buildMobileLayout(),
      bottomNavigationBar: _buildBottomNavigationBar(
        isMobile,
        isDesktopOrWeb: isDesktopOrWeb,
      ),
    );
  }

  // Show dialog for instructor: Leave or End Meeting
  void _showLeaveEndDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave or End Meeting'),
        content: const Text(
          'Do you want to leave the meeting (others stay) or end the meeting for everyone?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveMeetingAsHost();
            },
            child: const Text('Leave Meeting'),
          ),
          // Only show End Meeting for host
          if (widget.isHost)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                _endMeeting();
              },
              child: const Text('End Meeting'),
            ),
        ],
      ),
    );
  }

  // Placeholder for participant leave (non-host)
  Future<void> _leaveMeetingAsParticipant() async {
    // TODO: Implement participant leave logic (disconnect, pop, etc.)
    await _disconnectFromRoom();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // Host leaves meeting but does not end it for all
  Future<void> _leaveMeetingAsHost() async {
    // 1. Get user info
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'instructor_default';
    final username = prefs.getString('user_name') ?? 'Instructor';
    final role = 'host';
    final occurrenceId = await _getValidOccurrenceId();

    // 2. Emit leaveRoom event
    _socketService.leaveRoom(
      scheduleId: widget.scheduleId,
      occurrenceId: occurrenceId,
      userId: userId,
      username: username,
      role: role,
    );

    // 3. Disconnect from LiveKit
    await _disconnectFromRoom();

    // 4. Pop to previous screen
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildMobileLayout() {
    final anySidePanelVisible =
        _isChatOpen || _isPollOpen || _isParticipantsOpen;
    if (anySidePanelVisible) {
      return Container(color: Colors.grey[900], child: _buildSidePanel());
    }

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // Find the first active screen share track (if any)
    ParticipantTrack? screenShareTrack;
    for (final pt in _participantTracks) {
      if (pt.isScreenShare && pt.track != null && !(pt.track!.muted)) {
        screenShareTrack = pt;
        break;
      }
    }

    // If screen sharing is active, show only the shared screen fullscreen (all platforms)
    if (screenShareTrack != null) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Center(child: _buildLiveKitParticipantVideo(screenShareTrack)),
      );
    }

    // No screen share: show the video grid (Android: always grid, small cards, scrollable)
    int crossAxisCount = isAndroid
        ? (width >= 900
              ? 4
              : width >= 600
              ? 3
              : width >= 400
              ? 2
              : 1)
        : (width >= 1600
              ? 4
              : width >= 1100
              ? 3
              : width >= 700
              ? 2
              : 1);
    double aspectRatio = isAndroid ? 1 : (width >= 700 ? 4 / 3 : 3 / 4);

    return Container(
      color: Colors.grey[900],
      child: Center(
        child: _participantTracks.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No video tracks found',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video Off: $_isVideoOff',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Participants: ${_participants.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (_room?.localParticipant != null)
                    Text(
                      'Local Camera: ${_room!.localParticipant!.isCameraEnabled()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: _participantTracks.length,
                itemBuilder: (context, index) {
                  final participantTrack = _participantTracks[index];
                  return _buildLiveKitParticipantVideo(participantTrack);
                },
              ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    bool isMobile, {
    bool isDesktopOrWeb = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    // Make the bar slightly larger for desktop/web, but less than before
    final minHeight = isDesktopOrWeb
        ? 44.0
        : (isAndroid ? 20.0 : (isMobile ? 28.0 : 32.0));
    final width = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    double buttonWidth = isDesktopOrWeb ? 82.0 : 82.0,
        iconSize = isDesktopOrWeb ? 22.0 : 26.0,
        fontSize = isDesktopOrWeb ? 12.0 : 12.0,
        verticalPad = isDesktopOrWeb ? 6.0 : 8.0,
        horizontalPad = isDesktopOrWeb ? 4.0 : 6.0;
    if (!isDesktopOrWeb &&
        (isAndroid || isMobile || isLandscape || width < 500)) {
      buttonWidth = 48.0;
      iconSize = 16.0;
      fontSize = 9.0;
      verticalPad = 2.0;
      horizontalPad = 2.0;
    }
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(
            top: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.fromLTRB(
          1, // left
          0, // top
          1, // right
          bottomInset > 0 ? bottomInset : 0, // bottom
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                    label: _isMicMuted ? 'Unmute' : 'Mute',
                    color: _isMicMuted ? Colors.red : cs.onSurface,
                    onPressed: _toggleMute,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                  _buildControlButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    label: _isVideoOff ? 'Start Video' : 'Stop Video',
                    color: _isVideoOff ? Colors.red : cs.onSurface,
                    onPressed: _toggleVideo,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                  _buildControlButton(
                    icon: Icons.screen_share,
                    label: 'Share',
                    color: _isScreenSharing ? Colors.green : cs.onSurface,
                    onPressed: _toggleScreenShare,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                  if (widget.isHost)
                    _buildControlButton(
                      icon: Icons.fiber_manual_record,
                      label: _isRecording ? 'Stop Rec' : 'Start Rec',
                      color: _isRecording ? Colors.red : Colors.grey[800]!,
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('user_id') ?? 'host';
                        final username = prefs.getString('user_name') ?? 'Host';
                        final occurrenceId = await _getValidOccurrenceId();
                        if (!_isRecording) {
                          _socketService.startScreenRecording(
                            occurrenceId: occurrenceId,
                            userId: userId,
                            username: username,
                          );
                          setState(() {
                            _isRecording = true;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recording started'),
                              ),
                            );
                          }
                        } else {
                          _socketService.stopScreenRecording(
                            occurrenceId: occurrenceId,
                            userId: userId,
                            username: username,
                          );
                          setState(() {
                            _isRecording = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recording stopped'),
                              ),
                            );
                          }
                        }
                      },
                      isMobile: isMobile,
                      width: buttonWidth,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      verticalPad: verticalPad,
                      horizontalPad: horizontalPad,
                    ),
                  _buildControlButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    color: _isChatOpen ? cs.primary : cs.onSurface,
                    onPressed: _toggleChat,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                  _buildControlButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Poll',
                    color: _isPollOpen ? cs.primary : cs.onSurface,
                    onPressed: _togglePoll,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                  _buildControlButton(
                    icon: Icons.front_hand_rounded,
                    label: 'Hand',
                    color: _isHandRaised ? Colors.amber : cs.onSurface,
                    onPressed: _toggleHandRaise,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                  _buildControlButton(
                    icon: Icons.people_alt_rounded,
                    label: 'People',
                    color: _isParticipantsOpen ? cs.primary : cs.onSurface,
                    onPressed: _toggleParticipants,
                    isMobile: isMobile,
                    width: buttonWidth,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    verticalPad: verticalPad,
                    horizontalPad: horizontalPad,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isMobile = false,
    double width = 82,
    double iconSize = 26,
    double fontSize = 12,
    double verticalPad = 8,
    double horizontalPad = 6,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDanger = color == Colors.red;
    final isActive = !isDanger && color != cs.onSurface;

    final bgColor = isDanger
        ? Colors.red.withOpacity(0.15)
        : isActive
        ? cs.primaryContainer.withOpacity(0.5)
        : cs.surfaceVariant.withOpacity(0.6);
    final iconColor = isDanger
        ? Colors.redAccent
        : isActive
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;
    final textColor = isDanger
        ? Colors.redAccent
        : isActive
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onPressed,
              child: Ink(
                width: width * 0.62,
                height: width * 0.62,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        (isDanger
                                ? Colors.redAccent
                                : isActive
                                ? cs.primary
                                : cs.outlineVariant)
                            .withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
            ),
            SizedBox(height: verticalPad / 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveKitParticipantVideo(ParticipantTrack participantTrack) {
    // Log the actual video resolution for screen share tracks
    final track = participantTrack.track;
    if (participantTrack.isScreenShare && track != null) {
      try {
        final settings = track.mediaStreamTrack.getSettings();
        final width = settings['width'];
        final height = settings['height'];
        debugPrint(
          '🟦 [RENDER] Screen share track resolution for ${participantTrack.participant.identity}: '
          'width=${width ?? 'unknown'}, height=${height ?? 'unknown'}',
        );
      } catch (e) {
        debugPrint('Could not get rendered screen share track settings: $e');
      }
    }
    final cs = Theme.of(context).colorScheme;

    final hasVideoTrack =
        participantTrack.track != null &&
        !(participantTrack.track?.muted ?? true);
    final isScreenShare = participantTrack.isScreenShare && hasVideoTrack;
    final isHandRaisedForThis = _raisedHandUserIds.contains(
      participantTrack.participant.identity,
    );

    // Always show instructor name if this is the instructor, else fallback to name/identity
    String displayName = participantTrack.participant.name.isNotEmpty
        ? participantTrack.participant.name
        : (participantTrack.isHost
              ? 'Instructor'
              : participantTrack.participant.identity);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade900, Colors.grey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: hasVideoTrack && participantTrack.track != null
                ? Stack(
                    children: [
                      VideoTrackRenderer(participantTrack.track!),
                      if (isScreenShare)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Screen Share',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withOpacity(0.85),
                                cs.secondary.withOpacity(0.85),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.videocam_off,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'No camera',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (isHandRaisedForThis)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.front_hand_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${participantTrack.participant.name.isNotEmpty ? participantTrack.participant.name : participantTrack.participant.identity} raised hand',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                participantTrack.participant.isMicrophoneEnabled()
                    ? const Icon(Icons.mic, color: Colors.white, size: 16)
                    : const Icon(Icons.mic_off, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Text(
                  participantTrack.participant.name.isNotEmpty
                      ? participantTrack.participant.name
                      : (participantTrack.isHost
                            ? 'Instructor'
                            : participantTrack.participant.identity),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Removed legacy placeholder participant tile renderer; desktop now uses
  // _buildLiveKitParticipantVideo with real LiveKit tracks for consistency.

  Widget _buildSidePanel() {
    if (_isChatOpen) {
      return _buildChatPanel();
    } else if (_isPollOpen) {
      return _buildPollPanel();
    } else if (_isParticipantsOpen) {
      return _buildParticipantsPanel();
    }

    // Default panel (shouldn't reach here)
    return const SizedBox();
  }

  Widget _buildParticipantsPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade700, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Participants',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_participants.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close',
                onPressed: _toggleParticipants,
              ),
            ],
          ),
        ),
        Expanded(
          child: _participants.isEmpty
              ? Center(
                  child: Text(
                    'No participants',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              : ListView.builder(
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final p = _participants[index];
                    final isMe = p.userId == _currentUserId;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p.isMuted ? Icons.mic_off : Icons.mic,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            p.isVideoOff ? Icons.videocam_off : Icons.videocam,
                            size: 14,
                            color: Colors.white70,
                          ),
                          if (p.isHost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Host',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          if (p.isHandRaised) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.front_hand_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Raised hand',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: (widget.isHost && !p.isHost && !isMe)
                          ? IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Remove from meeting',
                              onPressed: () => _kickParticipant(p),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPollPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade700, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Polls',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.isHost)
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  onPressed: _createPoll,
                  tooltip: 'Create new poll',
                ),
            ],
          ),
        ),
        Expanded(
          child: _polls.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.poll_outlined,
                        size: 64,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No polls created yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      if (widget.isHost)
                        ElevatedButton.icon(
                          onPressed: _createPoll,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Poll'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _polls.length,
                  itemBuilder: (context, index) {
                    final poll = _polls[index];
                    final totalVotes = poll.options.fold<int>(
                      0,
                      (sum, option) => sum + option.votes,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.grey[850],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    poll.question,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$totalVotes votes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...poll.options.map((option) {
                              final percentage = totalVotes > 0
                                  ? (option.votes / totalVotes) * 100
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    // Find option index and vote
                                    final optionIndex = poll.options.indexOf(
                                      option,
                                    );

                                    // Use poll.id to vote correctly
                                    final pollId = poll.id;

                                    // Send vote to socket server
                                    _socketService.votePoll(
                                      pollId: pollId,
                                      optionIndex: optionIndex,
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            option.text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: Colors.grey[700],
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.blue,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Created: ${_formatPollTime(poll.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (widget.isHost)
                                      Switch(
                                        value: poll.isActive,
                                        onChanged: (value) {
                                          setState(() {
                                            poll.isActive = value;
                                          });
                                        },
                                      ),
                                    Text(
                                      poll.isActive ? 'Active' : 'Ended',
                                      style: TextStyle(
                                        color: poll.isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatPollTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildChatPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade700, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _toggleChat,
                tooltip: 'Close Chat',
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey[900],
            child: _chatMessages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      return _ChatMessage(
                        sender: message.senderName,
                        message: message.message,
                        time:
                            '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        isHost:
                            message.senderName.toLowerCase().contains('host') ||
                            message.senderName.toLowerCase().contains(
                              'instructor',
                            ),
                      );
                    },
                  ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(
              top: BorderSide(color: Colors.grey.shade700, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[700],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Show emoji picker
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 1,
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendChatMessage,
                    iconSize: 22,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ParticipantData {
  final String name;
  final String userId;
  bool isMuted;
  bool isVideoOff;
  final bool isHost;
  bool isHandRaised;

  ParticipantData({
    required this.name,
    required this.userId,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isHost = false,
    this.isHandRaised = false,
  });
}

class PollOption {
  final String text;
  int votes;

  PollOption({required this.text, this.votes = 0});
}

class PollData {
  final String id;
  final String question;
  final List<PollOption> options;
  final DateTime createdAt;
  bool isActive;

  PollData({
    required this.id,
    required this.question,
    required this.options,
    required this.createdAt,
    this.isActive = true,
  });
}

class _ChatMessage extends StatelessWidget {
  final String sender;
  final String message;
  final String time;
  final bool isHost;

  const _ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: isHost ? Colors.blue : Colors.grey[600],
            radius: 20,
            child: Text(
              sender.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender and time
                Row(
                  children: [
                    Text(
                      sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isHost ? Colors.blue : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    if (isHost)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Host',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Message text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHost
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
