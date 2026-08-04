import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/models/notification_model.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/attendance/attendance_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/schedule/schedule_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/lectures/lectures_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';

import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> academicNotifications = [];
  List<AppNotification> administrativeNotifications = [];
  bool isLoading = true;
  bool _isMarkingAll = false;
  String _userName = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName  = prefs.getString('user_name') ?? '';
        _avatarUrl = prefs.getString('avatar') ?? '';
      });
    }
  }

  // 🌟 جلب الإشعارات باستخدام الـ Service النظيف
  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final data = await StudentServices().getNotifications();

      if (data != null) {
        setState(() {
          academicNotifications = (data['academic'] as List)
              .map((e) => AppNotification.fromJson(e))
              .toList();
          administrativeNotifications = (data['administrative'] as List)
              .map((e) => AppNotification.fromJson(e))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("لا توجد بيانات");
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب الإشعارات: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _navigateForNotification(BuildContext ctx, AppNotification notify) {
    final title = notify.title;
    final msg = notify.message;
    bool isLeave = notify.type == 'leave_request' ||
        title.contains('إجاز') || title.contains('أذون') || title.contains('إذن') || title.contains('القرار النهائي') ||
        msg.contains('إجاز') || msg.contains('أذون') || msg.contains('إذن');

    if (isLeave) {
      _showLeaveDetailDialog(ctx, notify);
      return;
    }

    switch (notify.type) {
      case 'announcement':
      case 'administrative':
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: {
            'title':       notify.title,
            'content':     notify.message,
            'body':        notify.message,
            'time_ago':    notify.timeAgo,
            'created_at':  notify.timeAgo,
            'author_name': 'الإدارة',
            if (notify.imageUrl != null) 'image_url': notify.imageUrl,
            if (notify.linkUrl != null) 'link_url': notify.linkUrl,
          }),
        ));
        break;
      case 'assignment':
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => AssignmentsScreen(highlightId: notify.relatedId),
        ));
        break;
      case 'lecture':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LecturesScreen()));
        break;
      case 'attendance':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
        break;
      case 'grade':
      case 'marks':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        break;
      default:
        // عرض تفاصيل الإشعار العام
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: {
            'title':       notify.title,
            'content':     notify.message,
            'body':        notify.message,
            'time_ago':    notify.timeAgo,
            'created_at':  notify.timeAgo,
            'author_name': 'الإدارة',
          }),
        ));
        break;
    }
  }

  void _showLeaveDetailDialog(BuildContext ctx, AppNotification notify) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: (notify.relatedId != null && notify.relatedId! > 0)
              ? StudentServices().getLeaveDetails(notify.relatedId!)
              : Future.value(null),
          builder: (builderCtx, snapshot) {
            final data = snapshot.data;
            final isApproved = notify.title.contains('الموافقة') || notify.title.contains('موافقة') || notify.message.contains('وافقت') || (data != null && data['status'] == 'approved');
            final isRejected = notify.title.contains('رفض') || notify.message.contains('رفض') || (data != null && data['status'] == 'rejected');

            Color headerColor = isApproved
                ? Colors.green
                : (isRejected ? Colors.red : Colors.orange);
            IconData headerIcon = isApproved
                ? Icons.check_circle_outline_rounded
                : (isRejected ? Icons.cancel_outlined : Icons.hourglass_empty_rounded);

            String titleText = notify.title.isNotEmpty
                ? notify.title
                : (isApproved ? 'تمت الموافقة على طلب الإجازة' : 'تفاصيل طلب الإجازة');

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.all(24),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: headerColor.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(headerIcon, color: headerColor, size: 54),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: headerColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data != null
                              ? (data['status_text'] ?? 'قرار إداري')
                              : (isApproved ? 'موافق عليه نهائياً من شؤون الطلاب' : (isRejected ? 'مرفوض من شؤون الطلاب' : 'قرار إداري')),
                          style: TextStyle(
                            color: headerColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: isDark ? Colors.white12 : Colors.grey.shade300),
                      const SizedBox(height: 12),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                        )
                      else ...[
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'التاريخ واليوم',
                          value: data != null
                              ? "${data['day_name'] ?? ''} - ${data['formatted_date'] ?? data['date'] ?? ''}"
                              : notify.timeAgo,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'نوع الإجازة',
                          value: data != null ? (data['type_text'] ?? data['type'] ?? 'إجازة') : 'إجازة طالب',
                          isDark: isDark,
                        ),
                        if (data != null && data['reason'] != null && data['reason'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            icon: Icons.notes_rounded,
                            label: 'السبب المرفق',
                            value: data['reason'].toString(),
                            isDark: isDark,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نص الإشعار الإداري:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notify.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'إغلاق',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                Navigator.push(
                                  ctx,
                                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCC00),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'سجل الأذونات',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFFCC00)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // 🌟 دالة تحويل الإشعار لمقروء
  Future<void> _markAsRead(AppNotification notify) async {
    if (notify.isRead) return;
    bool success = await StudentServices().markNotificationAsRead(notify.id);
    if (success) {
      setState(() {
        notify.isRead = true;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    final success = await StudentServices().markAllNotificationsAsRead();
    if (success && mounted) {
      setState(() {
        for (final n in academicNotifications) { n.isRead = true; }
        for (final n in administrativeNotifications) { n.isRead = true; }
      });
    }
    if (mounted) setState(() => _isMarkingAll = false);
  }

  int get _unreadCount =>
      academicNotifications.where((n) => !n.isRead).length +
      administrativeNotifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: isDark
                ? Theme.of(context).scaffoldBackgroundColor
                : const Color(0xFFFAFAFA),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
            ),
            title: Text(
              'الإشعارات',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_unreadCount > 0)
                _isMarkingAll
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFCC00))),
                      )
                    : TextButton(
                        onPressed: _markAllAsRead,
                        child: Text('تمييز الكل', style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold, fontSize: 12)),
                      )
              else
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen(
                      userName: _userName, userRole: 'طالب', profileImageUrl: _avatarUrl,
                    )),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: _buildCustomTabBar(isDark),
            ),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                )
              : Stack(
                  children: [
                    TabBarView(
                      children: [
                        _NotificationsListView(
                          notifications: academicNotifications,
                          onRefresh: _fetchNotifications,
                          onTapNotification: _markAsRead,
                          onNavigate: _navigateForNotification,
                        ),
                        _NotificationsListView(
                          notifications: administrativeNotifications,
                          onRefresh: _fetchNotifications,
                          onTapNotification: _markAsRead,
                          onNavigate: _navigateForNotification,
                        ),
                      ],
                    ),
                    CustomBottomNav(
                      currentIndex: 2,
                      centerButton: const CustomSpeedDialEduBridge(),
                      onHomeTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentHomeScreen(),
                        ),
                      ),
                      onProfileTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ),
                      onNotificationsTap: () {},
                      onMessagesTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MessagesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFFFFCC00),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: isDark
            ? Colors.grey.shade400
            : Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        // 🌟 التابات الأكاديمية على اليمين (index 0) والإدارية على اليسار (index 1)
        tabs: const [
          Tab(text: 'إشعارات أكاديمية'),
          Tab(text: 'إشعارات إدارية'),
        ],
        dividerColor: Colors.transparent,
      ),
    );
  }
}

class _NotificationsListView extends StatelessWidget {
  final List<AppNotification> notifications;
  final Future<void> Function() onRefresh;
  final Function(AppNotification) onTapNotification;
  final void Function(BuildContext, AppNotification)? onNavigate;

  const _NotificationsListView({
    required this.notifications,
    required this.onRefresh,
    required this.onTapNotification,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد إشعارات حالياً",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.amber,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 120,
        ),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notify = notifications[index];
          return _buildNotificationCard(context, notify);
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notify) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        onTapNotification(notify);
        onNavigate?.call(context, notify);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notify.isRead
              ? (isDark ? Theme.of(context).cardColor : Colors.white)
              : (isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50),
          borderRadius: BorderRadius.circular(20),
          border: notify.isRead
              ? null
              : Border.all(color: const Color(0xFFFFCC00), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: notify.isRead
                  ? (isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(5))
                  : const Color(0x33FFCC00),
              blurRadius: notify.isRead ? 15 : 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notify.getIconColor().withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notify.getIcon(),
                color: notify.getIconColor(),
                size: 26,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notify.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          notify.timeAgo,
                          style: TextStyle(
                            color: notify.isRead
                                ? Colors.grey.shade500
                                : Colors.amber.shade700,
                            fontSize: 11,
                            fontWeight: notify.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notify.message,
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
