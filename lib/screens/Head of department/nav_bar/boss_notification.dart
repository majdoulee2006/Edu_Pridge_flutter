import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../widgets/boss_center_icon.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import '../center_icons/leave_requests_screen.dart';
import '../center_icons/request_reports_screen.dart';
import '../center_icons/appointments/hod_appointments_screen.dart';

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

  bool get isLeaveRequest   => type == 'leave_request';
  bool get isPendingParent  => isLeaveRequest && leaveStatus == 'pending_parent';
  bool get isPendingLeave   => isLeaveRequest && (leaveStatus == null || leaveStatus == 'pending_hod');
  bool get isResolvedLeave  => isLeaveRequest && (leaveStatus == 'approved' || leaveStatus == 'rejected');
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
    NotificationPolling.latestNew.addListener(_onNewNotif);
  }

  @override
  void dispose() {
    NotificationPolling.latestNew.removeListener(_onNewNotif);
    super.dispose();
  }

  void _onNewNotif() {
    if (mounted) _fetchNotifications();
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
                  : type == 'meeting_request'
                      ? Icons.calendar_month_outlined
                      : type == 'summon'
                          ? Icons.person_add_alt_1_outlined
                          : Icons.notifications_outlined,
              iconColor: type == 'leave_request'
                  ? const Color(0xFFCCAA00)
                  : type == 'meeting_request'
                      ? Colors.teal
                      : type == 'summon'
                          ? Colors.deepOrange
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
    if (n.relatedId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن الرد على هذا الطلب: معرف الطلب مفقود')),
        );
      }
      return;
    }
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/department-head/leave-requests/${n.relatedId}/respond",
        data: {"status": status},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final newStatus = status == 'approved' ? 'approved' : 'rejected';
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

  void _showCreateNotifSheet() {
    final titleCtrl   = TextEditingController();
    final messageCtrl = TextEditingController();
    String target = 'students';
    bool isSending = false;
    final targets = [
      {'value': 'students',          'label': 'الطلاب فقط'},
      {'value': 'students_teachers', 'label': 'الطلاب والمعلمين'},
      {'value': 'all',               'label': 'الكل'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  const Text('إرسال إشعار جديد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'عنوان الإشعار',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCCAA00), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'محتوى الإشعار',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCCAA00), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('إرسال إلى:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: targets.map((t) {
                      final isActive = target == t['value'];
                      return GestureDetector(
                        onTap: () => setSheet(() => target = t['value']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFCCAA00) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 18, color: isActive ? Colors.black : Colors.grey),
                              const SizedBox(width: 10),
                              Text(t['label']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.black : Colors.grey,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSending ? null : () async {
                        if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        setSheet(() => isSending = true);
                        try {
                          final token = await _getToken();
                          await Dio().post(
                            "${ApiService().baseUrl}/department-head/notifications/send",
                            data: {
                              'title':   titleCtrl.text.trim(),
                              'message': messageCtrl.text.trim(),
                              'target':  target,
                            },
                            options: Options(headers: {"Authorization": "Bearer $token"}),
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إرسال الإشعار بنجاح ✅'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          setSheet(() => isSending = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('حدث خطأ، حاول مجدداً'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCCAA00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isSending
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('إرسال الإشعار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                                          final n = e.value;
                                          if (n.type == 'announcement') {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => AnnouncementDetailScreen(announcement: {
                                                'title':      n.title,
                                                'content':    n.description,
                                                'time_ago':   n.time,
                                                'created_at': n.time,
                                                'author_name': 'الإدارة',
                                              }),
                                            ));
                                          } else if (n.type == 'report') {
                                            Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => const ReportRequestScreen()));
                                          } else if (n.isLeaveRequest) {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => LeaveRequestsScreen(
                                                fromSource: "notification",
                                                highlightId: n.relatedId,
                                              ),
                                            )).then((refreshed) {
                                              if (refreshed == true) _fetchNotifications();
                                            });
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
              // زر إرسال إشعار جديد
              Positioned(
                bottom: 95,
                left: 20,
                child: GestureDetector(
                  onTap: _showCreateNotifSheet,
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCAA00),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCCAA00).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 28, color: Colors.black),
                  ),
                ),
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
            icon: Icon(Icons.arrow_back,
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

  String _labelForType(String type) {
    switch (type) {
      case 'leave_request': return 'طلب إجازة';
      case 'meeting_request': return 'طلب موعد لقاء';
      case 'summon': return 'استدعاء ولي أمر';
      case 'announcement':  return 'إعلان';
      case 'report':        return 'تقرير';
      default:              return 'إشعار';
    }
  }

  Widget _buildNotificationCard(
      BossNotification n, Color cardColor, bool isDark, int index) {
    final color = n.iconColor;
    final label = _labelForType(n.type);
    final dateStr = n.time.length >= 10 ? n.time.substring(0, 10) : n.time;

    return GestureDetector(
      onTap: () {
        _markAsRead(n.id, index);
        if (n.type == 'grade_report_ready' || n.type == 'report') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportRequestScreen()));
        } else if (n.type == 'meeting_request' || n.type == 'summon') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HodAppointmentsScreen()));
        } else if (n.type == 'announcement') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(announcement: {
              'title':      n.title,
              'content':    n.description,
              'time_ago':   n.time,
              'created_at': n.time,
              'author_name': 'الإدارة',
            }),
          ));
        } else if (n.isLeaveRequest) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => LeaveRequestsScreen(
              fromSource: "notification",
              highlightId: n.relatedId,
            ),
          )).then((refreshed) {
            if (refreshed == true) _fetchNotifications();
          });
        }
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(right: 0, top: 0, bottom: 0,
                child: Container(width: 5, color: color)),
            // نقطة الإشعار غير المقروء
            if (n.isUnread)
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5722),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(n.icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(n.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(dateStr, style: TextStyle(color: color, fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(n.description,
                                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, height: 1.4)),
                            const SizedBox(height: 6),
                            Text(label,
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (n.isLeaveRequest) ...[
                    const SizedBox(height: 14),
                    if (n.isPendingParent)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.blue),
                            SizedBox(width: 6),
                            Text('بانتظار موافقة ولي الأمر', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )
                    else if (n.isPendingLeave)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _respondLeave(index, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCAA00),
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
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: (n.leaveStatus == 'rejected' ? Colors.red : Colors.green).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              n.leaveStatus == 'rejected' ? Icons.cancel_outlined : Icons.check_circle_outline,
                              size: 18,
                              color: n.leaveStatus == 'rejected' ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              n.leaveStatus == 'rejected' ? 'تم رفض الطلب' : 'تمت الموافقة على الطلب',
                              style: TextStyle(
                                color: n.leaveStatus == 'rejected' ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold, fontSize: 13,
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
    ),
    );
  }
}
