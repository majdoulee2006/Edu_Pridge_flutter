import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../widgets/boss_center_icon.dart';
import '../center_icons/leave_requests_screen.dart';

class BossNotification {
  final int id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;
  final String type;
  final int? relatedId;
  final String? leaveStatus; // pending_hod | pending_parent | approved | rejected

  BossNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isUnread = false,
    this.type = 'general',
    this.relatedId,
    this.leaveStatus,
  });

  bool get isLeaveRequest => type == 'leave_request';
  bool get isPendingLeave => isLeaveRequest && (leaveStatus == null || leaveStatus == 'pending_hod');
  bool get isResolvedLeave => isLeaveRequest && (leaveStatus == 'approved' || leaveStatus == 'pending_parent' || leaveStatus == 'rejected');
}

class BossNotificationScreen extends StatefulWidget {
  const BossNotificationScreen({super.key});

  @override
  State<BossNotificationScreen> createState() => _BossNotificationScreenState();
}

class _BossNotificationScreenState extends State<BossNotificationScreen> {
  bool _isLoading = true;
  bool _isMarkingAll = false;
  List<BossNotification> notifications = [];

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
        "${ApiService().baseUrl}/department-head/notifications",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        setState(() {
          notifications = data.map((n) {
            final type = n['type'] as String? ?? 'general';
            return BossNotification(
              id:          (n['id'] as num).toInt(),
              title:       n['title'] as String? ?? '',
              description: n['body'] as String? ?? n['message'] as String? ?? '',
              time:        n['created_at'] as String? ?? '',
              icon: type == 'leave_request'
                  ? Icons.event_busy_outlined
                  : Icons.notifications_outlined,
              iconColor: type == 'leave_request'
                  ? const Color(0xFFCCAA00)
                  : Colors.orange,
              isUnread:    n['is_read'] == false,
              type:        type,
              relatedId:   n['related_id'] != null ? (n['related_id'] as num).toInt() : null,
              leaveStatus: n['leave_status'] as String?,
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Boss Notifications Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    if (!notifications[index].isUnread) return;
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/department-head/notifications/$id/read",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final n = notifications[index];
        setState(() {
          notifications[index] = BossNotification(
            id: n.id, title: n.title, description: n.description, time: n.time,
            icon: n.icon, iconColor: n.iconColor, isUnread: false,
            type: n.type, relatedId: n.relatedId, leaveStatus: n.leaveStatus,
          );
        });
      }
    } catch (e) {
      debugPrint('⛔ Mark Read Error: $e');
    }
  }

  Future<void> _markAllRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/department-head/notifications/read-all",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() {
          notifications = notifications.map((n) => BossNotification(
            id: n.id, title: n.title, description: n.description, time: n.time,
            icon: n.icon, iconColor: n.iconColor, isUnread: false,
            type: n.type, relatedId: n.relatedId, leaveStatus: n.leaveStatus,
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Mark All Read Error: $e');
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _respondLeave(int index, String status) async {
    final n = notifications[index];
    if (n.relatedId == null) return;
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/department-head/leave-requests/${n.relatedId}/respond",
        data: {"status": status},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final newStatus = status == 'approved' ? 'pending_parent' : 'rejected';
        setState(() {
          notifications[index] = BossNotification(
            id: n.id, title: n.title, description: n.description, time: n.time,
            icon: n.icon, iconColor: n.iconColor, isUnread: false,
            type: n.type, relatedId: n.relatedId, leaveStatus: newStatus,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? 'تمت الموافقة على الطلب ✅' : 'تم رفض الطلب'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      debugPrint('⛔ Respond Leave Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، حاول مجدداً'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int get _unreadCount => notifications.where((n) => n.isUnread).length;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFCCAA00)))
                        : RefreshIndicator(
                            onRefresh: _fetchNotifications,
                            color: const Color(0xFFCCAA00),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle("الإشعارات"),
                                  if (notifications.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Center(
                                        child: Text("لا توجد إشعارات حالياً",
                                            style: TextStyle(color: Colors.grey)),
                                      ),
                                    )
                                  else
                                    ...notifications.asMap().entries.map((e) =>
                                      GestureDetector(
                                        onTap: () {
                                          _markAsRead(e.value.id, e.key);
                                          if (e.value.isLeaveRequest && e.value.isResolvedLeave) {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => const LeaveRequestsScreen()));
                                          }
                                        },
                                        child: _buildNotificationCard(e.value, cardColor, isDark, e.key),
                                      ),
                                    ),
                                  const SizedBox(height: 150),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              CustomBottomNav(
                currentIndex: 2,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const BossProfileScreen())),
                onNotificationsTap: () {},
                onMessagesTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_forward,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
          ),
          Row(
            children: [
              const Text("الإشعارات",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCAA00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_unreadCount',
                      style: const TextStyle(
                          color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen(
                    userName: "رئيس القسم", userRole: "رئيس قسم"))),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
              child: const Icon(Icons.settings_outlined, color: Colors.grey, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (_unreadCount > 0)
            _isMarkingAll
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFCCAA00)))
                : GestureDetector(
                    onTap: _markAllRead,
                    child: Text("تحديد الكل كمقروء",
                        style: TextStyle(
                            color: Colors.yellow[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BossNotification n, Color cardColor, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: n.isUnread
            ? Border.all(color: n.iconColor.withValues(alpha: 0.4), width: 1)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: n.iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(n.icon, color: n.iconColor, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(n.time,
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (n.isUnread)
                          Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(n.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(n.description,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),

          // Leave request action area
          if (n.isLeaveRequest) ...[
            const SizedBox(height: 15),
            if (n.isPendingLeave)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondLeave(index, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCCAA00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("موافقة",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondLeave(index, 'rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("رفض",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: (n.leaveStatus == 'rejected'
                          ? Colors.red
                          : Colors.green)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      n.leaveStatus == 'rejected'
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: n.leaveStatus == 'rejected' ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      n.leaveStatus == 'rejected' ? 'تم رفض الطلب' : 'تمت الموافقة على الطلب',
                      style: TextStyle(
                        color: n.leaveStatus == 'rejected' ? Colors.red : Colors.green,
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
    );
  }
}
