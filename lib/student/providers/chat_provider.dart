import 'package:flutter/material.dart';
import 'dart:async';
import '../services/groups_service.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final GroupsService _groupsService = GroupsService();
  final Map<String, List<Message>> _groupMessages = {};
  final Map<String, bool> _typingUsers = {};
  final Map<String, StreamController<Message>> _messageStreams = {};
  final Map<String, bool> _isLoading = {};
  final Map<String, String?> _errors = {};

  // Getters
  bool isLoading(String groupId) => _isLoading[groupId] ?? false;
  String? getError(String groupId) => _errors[groupId];

  List<Message> getGroupMessages(String groupId) {
    return _groupMessages[groupId] ?? [];
  }

  bool isUserTyping(String groupId) {
    return _typingUsers[groupId] ?? false;
  }

  Stream<Message>? getMessageStream(String groupId) {
    return _messageStreams[groupId]?.stream;
  }

  // Initialize chat for a group
  Future<void> initializeGroupChat(String groupId) async {
    if (!_groupMessages.containsKey(groupId)) {
      _groupMessages[groupId] = [];
      _messageStreams[groupId] = StreamController<Message>.broadcast();
      await _loadGroupMessages(groupId);
    }
  }

  // Load messages from API
  Future<void> _loadGroupMessages(String groupId) async {
    print("Starting to load messages for groupId: $groupId");
    _setLoading(groupId, true);
    _clearError(groupId);
    print("Loading messages for groupId: $groupId");
    try {
      final response = await _groupsService.getGroupWithMessages(groupId);

      if (response.isSuccess && response.data != null) {
        final dynamic raw = response.data;
        final Map<String, dynamic> responseData = Map<String, dynamic>.from(
          raw as Map,
        );
        print("kd vcfkjjvfk vfkj vfkj");
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          responseData['data'] as Map,
        );
        print("Data fetched for groupId $groupId: $data");
        final Map<String, dynamic> messagesSection = Map<String, dynamic>.from(
          data['messages'] ?? <String, dynamic>{},
        );
        final List<dynamic> messagesData = List<dynamic>.from(
          messagesSection['items'] ?? <dynamic>[],
        );
        final messages = messagesData
            .where((e) => e is Map)
            .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        print("Fetched ${messages.length} messages for groupId $groupId");
          _groupMessages[groupId]!.addAll(messages);
        print("Messages for groupId $messages");
        notifyListeners();
      } else {
        _setError(groupId, 'Failed to load messages');
      }
    } catch (e) {
      _setError(groupId, 'Error loading messages: ${e.toString()}');
    } finally {
      _setLoading(groupId, false);
    }
    print("Final messages for groupId $groupId: ${_groupMessages[groupId]}");
  }

  // Refresh messages
  Future<void> refreshMessages(String groupId) async {
    await _loadGroupMessages(groupId);
  }

  // Add a new message (for WebSocket updates)
  void addMessage(String groupId, Message message) {
    if (_groupMessages.containsKey(groupId)) {
      _groupMessages[groupId]!.add(message);
      _messageStreams[groupId]?.add(message); // Broadcast to stream listeners
      notifyListeners();
    }
  }

  // Send message - DISABLED (read-only chat)
  Future<void> sendMessage({
    required String groupId,
    required String text,
    String? imageUrl,
    String? fileUrl,
  }) async {
    // Chat is read-only, so this method is disabled
    return;
  }

  // Delete message - DISABLED (read-only chat)
  Future<void> deleteMessage(String groupId, String messageId) async {
    // Chat is read-only, so this method is disabled
    return;
  }

  // Edit message - DISABLED (read-only chat)
  Future<void> editMessage(
    String groupId,
    String messageId,
    String newText,
  ) async {
    // Chat is read-only, so this method is disabled
    return;
  }

  // Clear chat history - DISABLED (read-only chat)
  Future<void> clearChatHistory(String groupId) async {
    // Chat is read-only, so this method is disabled
    return;
  }

  // Mark message as read
  Future<void> markMessageAsRead(
    String groupId,
    String messageId, [
    String? userId,
  ]) async {
    try {
      final messages = _groupMessages[groupId];
      if (messages != null) {
        final messageIndex = messages.indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          messages[messageIndex] = messages[messageIndex].copyWith(
            isRead: true,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _setError(groupId, 'Failed to mark message as read: ${e.toString()}');
    }
  }

  // Set typing status
  void setTypingStatus(String groupId, bool isTyping) {
    _typingUsers[groupId] = isTyping;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(String groupId, bool loading) {
    _isLoading[groupId] = loading;
    notifyListeners();
  }

  void _setError(String groupId, String error) {
    _errors[groupId] = error;
    notifyListeners();
  }

  void _clearError(String groupId) {
    _errors.remove(groupId);
    notifyListeners();
  }

  @override
  void dispose() {
    for (var controller in _messageStreams.values) {
      controller.close();
    }
    super.dispose();
  }
}
