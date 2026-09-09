import '../services/api_service.dart';

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

  factory ChatMessage.fromJson(Map<String, dynamic> rawJson, String currentUserId) {
    Map<String, dynamic> json = rawJson;
    if (rawJson.containsKey('message_data') && rawJson['message_data'] is Map) {
      json = Map<String, dynamic>.from(rawJson['message_data'] as Map);
    }
    
    final rawMsg = json['message'];
    String msgText = '';
    if (rawMsg is String) {
      msgText = rawMsg;
    } else if (rawMsg != null) {
      msgText = rawMsg.toString();
    } else if (json['text'] != null) {
      msgText = json['text'].toString();
    }

    final rawAttachment = json['attachment']?.toString();

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      message: msgText,
      isMe: json['sender_id']?.toString() == currentUserId,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      attachment: ApiService.fixMediaUrl(rawAttachment),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      isDelivered: json['is_delivered'] == 1 || json['is_delivered'] == true,
    );
  }
}
