class Message {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final bool hasImage;
  final int readCount;

  Message({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.hasImage = false,
    this.readCount = 0,
  });

factory Message.fromJson(Map<String, dynamic> json) {
  return Message(
    id: json['_id'] ?? json['id'] ?? '',
    groupId: json['groupId'] ?? '',
    senderId: json['senderId'] is Map ? json['senderId']['_id'] ?? json['senderId'] ?? '' : json['senderId'] ?? '',
    senderName: json['senderName'] ?? (json['senderId'] is Map ? json['senderId']['name'] ?? '' : ''),
    text: json['decryptedContent'] as String? ?? json['content'] as String? ?? json['text'] as String? ?? '',
    timestamp: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    isRead: json['isReadByCurrentUser'] ?? false,
    imageUrl: json['imageUrl'],
    hasImage: json['imageUrl'] != null,
    readCount: json['readCount'] ?? 0,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'hasImage': hasImage,
      'readCount': readCount,
    };
  }

  Message copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    bool? hasImage,
    int? readCount,
  }) {
    return Message(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      hasImage: hasImage ?? this.hasImage,
      readCount: readCount ?? this.readCount,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, sender: $senderName, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
