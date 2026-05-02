class ChatModel {
  final int id;
  final String title;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final String type; // 'الجروبات' أو 'المدرسين'
  final bool isOnline;
  final bool isRead;
  final bool isGroup; // لتحديد شكل واجهة المحادثة (ChatDetailScreen)
  final String avatarUrl;

  ChatModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.type,
    required this.isOnline,
    required this.isRead,
    required this.isGroup,
    this.avatarUrl = '',
  });

  // مجهز لاستقبال البيانات من اللارافل قريباً
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      lastMessage: json['last_message'] ?? '',
      time: json['time'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      type: json['type'] ?? 'المدرسين',
      isOnline: json['is_online'] == 1 || json['is_online'] == true,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      isGroup: json['is_group'] == 1 || json['is_group'] == true,
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}