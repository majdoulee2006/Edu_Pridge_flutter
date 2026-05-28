import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/permissions_screen/permissions_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/reports_screen/reports_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/center_icons/performance_screen/performance_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsNotificationsScreen extends StatefulWidget {
  const ParentsNotificationsScreen({super.key});

  @override
  State<ParentsNotificationsScreen> createState() => _ParentsNotificationsScreenState();
}

class _ParentsNotificationsScreenState extends State<ParentsNotificationsScreen> {
  bool _isLoading = true;
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
      if (token.isEmpty) { setState(() => _isLoading = false); return; }
      final res = await Dio().get(
        "${ApiService().baseUrl}/parent/notifications",
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && mounted) {
        final raw = res.data;
        List list = raw is List ? raw : (raw['data'] ?? []);
        setState(() {
          _notifications = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("⛔ Parent notifications error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondLeave(int index, String status) async {
    final n = _notifications[index];
    final relatedId = n['related_id'];
    if (relatedId == null) return;
    try {
      final token = await _getToken();
      await Dio().post(
        "${ApiService().baseUrl}/parent/leave-requests/$relatedId/respond",
        data: {"status": status},
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() {
          _notifications[index] = Map<String, dynamic>.from(n)
            ..['leave_status'] = status == 'approved' ? 'approved' : 'rejected';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? 'تمت الموافقة على طلب الإجازة ✅' : 'تم رفض الطلب'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      debugPrint("⛔ Respond leave error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، حاول مجدداً'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onNotificationTap(Map<String, dynamic> n) {
    final type = n['type']?.toString() ?? '';
    switch (type) {
      case 'announcement':
      case 'administrative':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: {
            'title':       n['title']?.toString() ?? '',
            'content':     n['message']?.toString() ?? n['body']?.toString() ?? '',
            'time_ago':    n['created_at']?.toString().split('T')[0] ?? '',
            'created_at':  n['created_at']?.toString() ?? '',
            'author_name': 'الإدارة',
          }),
        ));
        break;
      case 'leave_request':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()));
        break;
      case 'report':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
        break;
      case 'attendance':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceScreen()));
        break;
    }
  }

  Map<String, dynamic> _getStyleByType(String? type) {
    switch (type?.toLowerCase()) {
      case 'report':
        return {'color': Colors.orange, 'icon': Icons.assignment_turned_in_rounded, 'label': 'تقرير أداء'};
      case 'attendance':
        return {'color': Colors.red, 'icon': Icons.person_off, 'label': 'حضور وغياب'};
      case 'leave_request':
        return {'color': Colors.blue, 'icon': Icons.description_outlined, 'label': 'طلب إجازة'};
      case 'marks':
        return {'color': Colors.amber, 'icon': Icons.grade_rounded, 'label': 'نتائج امتحانات'};
      case 'holiday':
        return {'color': Colors.green, 'icon': Icons.beach_access_rounded, 'label': 'عطلة رسمية'};
      case 'event':
        return {'color': Colors.purple, 'icon': Icons.event_available, 'label': 'فعالية مدرسية'};
      default:
        return {'color': Colors.blueGrey, 'icon': Icons.notifications_active, 'label': 'إشعار'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textColor),
        body: SizedBox.expand(
          child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: const Color(0xFFFFCC00),
                    child: _notifications.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 400,
                                child: Center(child: Text("لا توجد إشعارات حالياً", style: TextStyle(color: textColor.withValues(alpha: 0.5)))),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final n = _notifications[index];
                              return GestureDetector(
                                onTap: () => _onNotificationTap(n),
                                child: _buildNotificationCard(n, cardColor, textColor, isDark, index),
                              );
                            },
                          ),
                  ),
            CustomBottomNav(
              currentIndex: 2,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsProfileScreen())),
              onNotificationsTap: () {},
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsMessagesScreen())),
            ),
          ],
        ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("الإشعارات", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      actions: [
        IconButton(icon: Icon(Icons.arrow_forward, color: textColor), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsHomeScreen()))),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, Color cardColor, Color textColor, bool isDark, int index) {
    final style = _getStyleByType(n['type']?.toString());
    final color = style['color'] as Color;
    final isLeave = n['type'] == 'leave_request';
    final leaveStatus = n['leave_status'] as String?;
    final isPendingParent = isLeave && leaveStatus == 'pending_parent';
    final isPendingHod    = isLeave && (leaveStatus == null || leaveStatus == 'pending_hod');
    final isResolved      = isLeave && (leaveStatus == 'approved' || leaveStatus == 'rejected');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(right: 0, top: 0, bottom: 0, child: Container(width: 5, color: color)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(style['icon'] as IconData, color: color, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(n['title']?.toString() ?? "إشعار",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                _buildTimeBadge(
                                  n['created_at']?.toString().split('T')[0] ?? "--",
                                  textColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(n['message']?.toString() ?? n['body']?.toString() ?? "",
                                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
                            const SizedBox(height: 6),
                            Text(style['label'] as String,
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Leave request actions
                  if (isLeave) ...[
                    const SizedBox(height: 14),
                    if (isPendingHod)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.orange),
                            SizedBox(width: 6),
                            Text('بانتظار موافقة رئيس القسم', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )
                    else if (isPendingParent)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _respondLeave(index, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCC00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text("موافقة", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _respondLeave(index, 'rejected'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                foregroundColor: isDark ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text("رفض", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    else if (isResolved)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: (leaveStatus == 'rejected' ? Colors.red : Colors.green).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              leaveStatus == 'rejected' ? Icons.cancel_outlined : Icons.check_circle_outline,
                              size: 18,
                              color: leaveStatus == 'rejected' ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              leaveStatus == 'rejected' ? 'تم رفض الطلب' : 'تمت الموافقة على الطلب',
                              style: TextStyle(
                                color: leaveStatus == 'rejected' ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String time, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Text(time, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10)),
    );
  }
}
