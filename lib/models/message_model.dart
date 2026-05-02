class MessageModel {
  final int id;
  final String text;
  final bool isMe; // هل أنا المرسل؟ (عشان لون الفقاعة)
  final String time;

  MessageModel({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
  });

  // مجهز للارافل (بيحسب إذا الرسالة إلي بناءً على الـ User ID)
  factory MessageModel.fromJson(Map<String, dynamic> json, int currentUserId) {
    return MessageModel(
      id: json['id'] ?? 0,
      text: json['message'] ?? '',
      isMe: json['sender_id'] == currentUserId,
      time: json['time'] ?? '',
    );
  }
}