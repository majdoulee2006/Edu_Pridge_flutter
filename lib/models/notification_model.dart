import 'package:flutter/material.dart';

class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String timeAgo;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timeAgo,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      timeAgo: json['time_ago'] ?? '',
    );
  }

  // 🌟 الدالة اللي كانت ناقصة وعاملة مشكلة getIcon
  IconData getIcon() {
    if (title.contains('وظيفة')) return Icons.assignment_outlined;
    if (title.contains('برنامج') || title.contains('جدول')) return Icons.calendar_month_outlined;
    if (title.contains('عطلة')) return Icons.celebration_outlined;
    if (title.contains('قسط') || title.contains('اشتراك')) return Icons.payments_outlined;
    return Icons.notifications_none_outlined;
  }

  // 🌟 الدالة اللي كانت ناقصة وعاملة مشكلة getIconColor
  Color getIconColor() {
    if (type == 'academic') return Colors.blueAccent;
    if (type == 'administrative') return Colors.purple;
    return Colors.grey;
  }
}