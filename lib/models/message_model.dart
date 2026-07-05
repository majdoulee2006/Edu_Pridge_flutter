class MessageModel {
  final int id;
  final String message;
  final bool isMe; // هل أنا المرسل؟ (عشان لون الفقاعة)
  final String time;

  String get text => message; // For backward compatibility with existing UI

  MessageModel({
    required this.id,
    required this.message,
    required this.isMe,
    required this.time,
  });

  // مجهز للارافل (بيحسب إذا الرسالة إلي بناءً على الـ User ID)
  factory MessageModel.fromJson(Map<String, dynamic> json, int currentUserId) {
    String formattedTime = 'الآن';
    if (json['time'] != null) {
      formattedTime = json['time'];
    } else if (json['created_at'] != null) {
      try {
        final dt = DateTime.parse(json['created_at'].toString()).toLocal();
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final amPm = dt.hour >= 12 ? 'م' : 'ص';
        final minute = dt.minute.toString().padLeft(2, '0');
        formattedTime = '$hour:$minute $amPm';
      } catch (_) {}
    }

    return MessageModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      message: json['message'] ?? json['text'] ?? '',
      isMe: int.tryParse(json['sender_id']?.toString() ?? '') == currentUserId,
      time: formattedTime,
    );
  }
}