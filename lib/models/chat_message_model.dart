class ChatMessage {
  final String id;
  String message;
  final bool isMe;
  final DateTime timestamp;
  final String? attachment; // 🌟 Added for media/voice note URL
  bool isRead;
  bool isDelivered; // 🌟 Added for read receipts

  String get text => message; // For backward compatibility with existing UI
  String get time {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final period = timestamp.hour >= 12 ? 'م' : 'ص';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  ChatMessage({
    required this.id,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.attachment,
    this.isRead = false,
    this.isDelivered = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? json['text'] ?? '',
      isMe: json['sender_id']?.toString() == currentUserId,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      attachment: json['attachment']?.toString(), // 🌟 Map attachment URL
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      isDelivered: json['is_delivered'] == 1 || json['is_delivered'] == true,
    );
  }
}
