class ChatMessage {
  final String id;
  final String message;
  final String senderName;
  final DateTime timestamp;
  final bool isFromLocalUser;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderName,
    required this.timestamp,
    this.isFromLocalUser = false,
  });
}
