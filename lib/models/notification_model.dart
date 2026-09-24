import 'package:flutter/material.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  bool isRead;
  final String timeAgo;
  final String? formattedDate;
  final String? imageUrl;
  final String? linkUrl;
  final int? relatedId;
  final int? senderId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timeAgo,
    this.formattedDate,
    this.imageUrl,
    this.linkUrl,
    this.relatedId,
    this.senderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      timeAgo: json['time_ago'] ?? '',
      formattedDate: json['formatted_date'] as String?,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      relatedId: json['related_id'] is int
          ? json['related_id'] as int
          : int.tryParse(json['related_id']?.toString() ?? ''),
      senderId: json['sender_id'] is int
          ? json['sender_id'] as int
          : int.tryParse(json['sender_id']?.toString() ?? ''),
    );
  }

  IconData getIcon() {
    switch (type) {
      case 'message':
      case 'chat':        return Icons.chat_bubble_outline;
      case 'grade':
      case 'marks':
      case 'exam_grade':
      case 'exam':        return Icons.workspace_premium_outlined;
      case 'assignment':  return Icons.assignment_outlined;
      case 'lecture':     return Icons.play_circle_outline;
      case 'schedule':
      case 'exam_schedule': return Icons.calendar_month_outlined;
      case 'attendance':  return Icons.how_to_reg_outlined;
      case 'academic':    return Icons.school_outlined;
      case 'announcement': return Icons.campaign_outlined;
      case 'leave_request': return Icons.output_rounded;
      case 'parent_summon': return Icons.notification_important_outlined;
      case 'warning':      return Icons.warning_amber_rounded;
    }
    if (title.contains('رسالة'))                           return Icons.chat_bubble_outline;
    if (title.contains('وظيفة') || title.contains('واجب')) return Icons.assignment_outlined;
    if (title.contains('جدول') || title.contains('امتحان'))  return Icons.calendar_month_outlined;
    if (title.contains('علامة') || title.contains('درجة'))  return Icons.workspace_premium_outlined;
    if (title.contains('إجاز') || title.contains('إذن'))    return Icons.output_rounded;
    if (title.contains('إعلان'))                           return Icons.campaign_outlined;
    return Icons.notifications_none_outlined;
  }

  Color getIconColor() {
    switch (type) {
      case 'message':
      case 'chat':           return Colors.lightBlueAccent;
      case 'grade':
      case 'marks':
      case 'exam_grade':
      case 'exam':           return Colors.green;
      case 'assignment':      return Colors.orange;
      case 'lecture':         return Colors.teal;
      case 'schedule':
      case 'exam_schedule':  return Colors.indigoAccent;
      case 'attendance':      return Colors.blue;
      case 'academic':        return Colors.blueAccent;
      case 'announcement':    return Colors.amber.shade800;
      case 'leave_request':   return const Color(0xFFFFCC00);
      case 'parent_summon':  return Colors.redAccent;
      case 'warning':       return Colors.deepOrange;
      case 'administrative': return Colors.purple;
    }
    return Colors.grey;
  }
}
