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
      relatedId: json['related_id'] is int ? json['related_id'] as int : null,
    );
  }

  // 🌟 الدالة اللي كانت ناقصة وعاملة مشكلة getIcon
  IconData getIcon() {
    switch (type) {
      case 'grade':       return Icons.grade_outlined;
      case 'assignment':  return Icons.assignment_outlined;
      case 'lecture':     return Icons.play_circle_outline;
      case 'attendance':  return Icons.how_to_reg_outlined;
      case 'academic':    return Icons.school_outlined;
    }
    if (title.contains('وظيفة'))   return Icons.assignment_outlined;
    if (title.contains('جدول'))    return Icons.calendar_month_outlined;
    if (title.contains('عطلة'))    return Icons.celebration_outlined;
    if (title.contains('قسط'))     return Icons.payments_outlined;
    return Icons.notifications_none_outlined;
  }

  Color getIconColor() {
    switch (type) {
      case 'grade':          return Colors.green;
      case 'assignment':     return Colors.orange;
      case 'lecture':        return Colors.teal;
      case 'attendance':     return Colors.blue;
      case 'academic':       return Colors.blueAccent;
      case 'administrative': return Colors.purple;
    }
    return Colors.grey;
  }
}
