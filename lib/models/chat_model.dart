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
  final String role;

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
    this.role = '',
  });

  // مجهز لاستقبال البيانات من اللارافل قريباً
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] ?? json['name'] ?? 'مستخدم غير معروف',
      lastMessage: (json['last_message'] != null && json['last_message'].toString().trim().isNotEmpty)
          ? json['last_message']
          : 'انقر لبدء المحادثة...',
      time: json['time'] ?? 'الآن',
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? json['unread']?.toString() ?? '') ?? 0,
      type: json['type'] ?? 'المدرسين',
      isOnline: json['is_online'] == 1 || json['is_online'] == true,
      isRead: json['is_read'] == null || json['is_read'] == 1 || json['is_read'] == true,
      isGroup: json['is_group'] == 1 || json['is_group'] == true,
      avatarUrl: json['avatar_url'] ?? json['image'] ?? '',
      role: json['role'] ?? '',
    );
  }
}