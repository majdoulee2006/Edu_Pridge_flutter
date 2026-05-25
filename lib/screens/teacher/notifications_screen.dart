import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/teacher/center_icons/attendance_screen/attendance_screen.dart';
import 'package:edu_pridge_flutter/screens/teacher/center_icons/assignments_screen/assignments_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/teacher/teacher_report_evaluation_screen.dart';
import '../../widgets/teacher_speed_dial.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  bool _isMarkingAll = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await Dio().get(
        "${ApiService().baseUrl}/teacher/notifications",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _notifications = (response.data['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Notifications Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    if (_notifications[index]['is_read'] == true) return;
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/teacher/notifications/$id/read",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() => _notifications[index]['is_read'] = true);
      }
    } catch (e) {
      debugPrint('⛔ Mark Read Error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/teacher/notifications/read-all",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() {
          for (final n in _notifications) {
            n['is_read'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('⛔ Mark All Read Error: $e');
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

  void _navigateForNotif(Map<String, dynamic> notif) {
    final type = notif['type'] as String?;
    switch (type) {
      case 'announcement':
      case 'new_announcement':
      case 'administrative':
        final embedded = notif['data'] is Map ? Map<String, dynamic>.from(notif['data'] as Map) : <String, dynamic>{};
        final announcement = <String, dynamic>{
          'title':       embedded['title']   ?? notif['title']   ?? '',
          'body':        embedded['body']    ?? notif['message'] ?? notif['body'] ?? '',
          'content':     embedded['content'] ?? notif['message'] ?? '',
          'time_ago':    embedded['time_ago']  ?? notif['created_at'] ?? '',
          'created_at':  notif['created_at'] ?? '',
          'author_name': embedded['author_name'] ?? notif['sender'] ?? 'الإدارة',
          ...embedded,
        };
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: announcement),
        ));
        break;
      case 'report_request':
      case 'new_report':
      case 'report':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherReportEvaluationScreen()));
        break;
      case 'leave_request':
      case 'attendance':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
        break;
      case 'academic':
      case 'assignment':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
        break;
    }
  }

  // أيقونة ولون كل نوع إشعار
  _NotifStyle _styleForType(String? type) {
    switch (type) {
      case 'academic':
        return _NotifStyle(Icons.book_outlined, const Color(0xFFFFCC00), const Color(0xFF3D3A00));
      case 'attendance':
        return _NotifStyle(Icons.how_to_reg_outlined, Colors.blue, const Color(0xFF003366));
      case 'administrative':
        return _NotifStyle(Icons.admin_panel_settings_outlined, Colors.purple, const Color(0xFF2E0047));
      case 'leave_request':
        return _NotifStyle(Icons.event_busy_outlined, Colors.red, const Color(0xFF3D0000));
      default:
        return _NotifStyle(Icons.notifications_outlined, Colors.orange, const Color(0xFF3D1A00));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor    = Theme.of(context).scaffoldBackgroundColor;
    final cardColor  = Theme.of(context).cardColor;
    final textColor  = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الإشعارات',
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          centerTitle: true,
          actions: [
            if (_unreadCount > 0)
              _isMarkingAll
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFFFCC00))),
                    )
                  : TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text('قراءة الكل',
                          style: TextStyle(
                              color: Color(0xFFFFCC00), fontSize: 12)),
                    ),
          ],
        ),
        body: Stack(
          children: [
            // force stack to fill screen so Positioned.fill works correctly
            const SizedBox.expand(),

            // المحتوى
            RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: const Color(0xFFFFCC00),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFFCC00)),
                    )
                  : _notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 64,
                                      color: Colors.grey.shade600),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'لا توجد إشعارات',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            final style =
                                _styleForType(n['type'] as String?);
                            final isRead = n['is_read'] == true;
                            return _buildNotifCard(
                              context,
                              id: n['id'] as int,
                              index: index,
                              title: n['title'] as String? ?? '',
                              message: n['message'] as String? ?? '',
                              time: n['created_at'] as String? ?? '',
                              isRead: isRead,
                              style: style,
                              cardColor: cardColor,
                              textColor: textColor,
                            );
                          },
                        ),
            ),

            // الشريط السفلي
            CustomBottomNav(
              currentIndex: 2,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () {},
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(
    BuildContext context, {
    required int id,
    required int index,
    required String title,
    required String message,
    required String time,
    required bool isRead,
    required _NotifStyle style,
    required Color cardColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        _markAsRead(id, index);
        _navigateForNotif(_notifications[index]);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: isRead
              ? null
              : Border.all(
                  color: style.color.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withValues(alpha: 0.04)
                  : style.color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة النوع
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(width: 12),

            // النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: style.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  final Color bgDark;
  const _NotifStyle(this.icon, this.color, this.bgDark);
}
