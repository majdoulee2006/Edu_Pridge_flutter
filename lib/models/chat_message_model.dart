class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'].toString(),
      text: json['text'] ?? '',
      isMe: json['sender_id'].toString() == currentUserId,
      timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
