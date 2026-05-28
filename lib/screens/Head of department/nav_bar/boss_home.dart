import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';

import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/create_announcement_screen.dart';
import '../../../widgets/boss_center_icon.dart';

class DeptHeadHomeScreen extends StatefulWidget {
  const DeptHeadHomeScreen({super.key});

  @override
  State<DeptHeadHomeScreen> createState() => _DeptHeadHomeScreenState();
}

class _DeptHeadHomeScreenState extends State<DeptHeadHomeScreen> {
  String _bossName = "جارِ التحميل...";
  List<Map<String, dynamic>> _announcements = [];
  bool _hasUnread = false;

  static const List<Color> _cardColors = [
    Color(0xFFFFCC33),
    Color(0xFF4DB6AC),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
  ];

  void _onUnreadChanged() {
    if (mounted) setState(() => _hasUnread = NotificationPolling.unreadCount.value > 0);
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _onNewNotif() {
    final n = NotificationPolling.latestNew.value;
    if (n != null && mounted) {
      showInAppBanner(
        context,
        n['title']?.toString() ?? 'إشعار جديد',
        n['message']?.toString() ?? n['body']?.toString() ?? '',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    NotificationPolling.start('/department-head/notifications');
    NotificationPolling.unreadCount.addListener(_onUnreadChanged);
    NotificationPolling.latestNew.addListener(_onNewNotif);
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    NotificationPolling.unreadCount.removeListener(_onUnreadChanged);
    NotificationPolling.latestNew.removeListener(_onNewNotif);
    NotificationPolling.stop();
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/dashboard",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _bossName = d['name'] as String? ?? prefs.getString('user_name') ?? "رئيس القسم";
            _announcements = List<Map<String, dynamic>>.from(d['announcements'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('⛔ Boss Dashboard Error: $e');
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _bossName = prefs.getString('user_name') ?? "رئيس القسم");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    const primaryYellow = Color(0xFFCCAA00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: AppSettings.language.value == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Column(
              children: [
                // ─── الهيدر الثابت ───
                Container(
                  color: cardColor,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(context, textColor, cardColor, primaryYellow),
                        const SizedBox(height: 14),
                        _buildSectionTitle(AppSettings.language.value == 'ar' ? "آخر الأخبار" : "Latest News", textColor),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // ─── قائمة الإعلانات ───
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchDashboard,
                    color: primaryYellow,
                    child: _announcements.isEmpty
                        ? Center(child: Text(AppSettings.language.value == 'ar' ? "لا توجد أخبار حالياً" : "No news yet", style: const TextStyle(color: Colors.grey, fontSize: 15)))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 140),
                            itemCount: _announcements.length,
                            itemBuilder: (context, i) {
                              final a = _announcements[i];
                              return _buildNewsCard(context, a, _cardColors[i % _cardColors.length], cardColor, textColor);
                            },
                          ),
                  ),
                ),
              ],
            ),

            // ─── زر نشر إعلان طائر ───
            Positioned(
              bottom: 100,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()))
                    .then((posted) { if (posted == true) _fetchDashboard(); }),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 28),
                ),
              ),
            ),

            CustomBottomNav(
              currentIndex: 0,
              hasUnread: _hasUnread,
              centerButton: const Boss_Center_Icon(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BossProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BossMessageScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, Color cardColor, Color primaryYellow) {
    final isAr = AppSettings.language.value == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: isAr ? "أهلاً، " : "Hello, ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    children: [
                      TextSpan(text: _bossName, style: const TextStyle(color: Color(0xFFCCAA00))),
                    ],
                  ),
                ),
                Text(isAr ? "لوحة تحكم إدارة القسم" : "Department Dashboard",
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildCircleIconButton(
            icon: Icons.settings_outlined,
            cardColor: cardColor,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SettingsScreen(
                userName: _bossName,
                userRole: "رئيس القسم الأكاديمي",
                onProfileTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const BossProfileScreen()));
                },
              ),
            )),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4, height: 24,
            decoration: BoxDecoration(color: const Color(0xFFCCAA00), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, dynamic> a, Color headerColor, Color cardColor, Color textColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: a))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: (a['image_url'] as String?)?.isNotEmpty == true
                  ? Image.network(
                      a['image_url'] as String,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _announcementPlaceholder(headerColor),
                    )
                  : _announcementPlaceholder(headerColor),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'] as String? ?? '',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 6),
                  Text(a['body'] as String? ?? a['content'] as String? ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(a['time_ago'] as String? ?? a['created_at'] as String? ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.arrow_back_ios_new, size: 13, color: textColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementPlaceholder(Color headerColor) {
    return Container(
      height: 150,
      width: double.infinity,
      color: headerColor,
      child: Stack(
        children: [
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const Text('إعلان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
            ),
          ),
          const Center(child: Icon(Icons.campaign_outlined, size: 45, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required Color cardColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Icon(icon, color: const Color(0xFFF1C40F), size: 26),
      ),
    );
  }
}
