import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

// 🌟 استيراد الشاشات الأساسية للتنقل
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';

// 🚀 استيراد الشاشات الفرعية (الأيقونة الوسطى والبانر)
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/leave_requests_screen.dart';

// 🚀 استدعاء الـ Widget الخاصة بالأيقونة الوسطى
import '../../../widgets/boss_center_icon.dart';

// ... (نفس الاستيرادات السابقة)

class DeptHeadHomeScreen extends StatefulWidget {
  const DeptHeadHomeScreen({super.key});

  @override
  State<DeptHeadHomeScreen> createState() => _DeptHeadHomeScreenState();
}

class _DeptHeadHomeScreenState extends State<DeptHeadHomeScreen> {
  String _bossName = "جارِ التحميل...";
  int _pendingLeaveCount = 0;
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
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
            _pendingLeaveCount = d['pending_leave_requests'] as int? ?? 0;
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
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    const primaryYellow = Color(0xFFCCAA00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      _buildHeader(context, textColor, cardColor, primaryYellow),
                      const SizedBox(height: 25),
                      _buildNotificationBanner(context, cardColor),
                      const SizedBox(height: 25),
                      _buildSectionTitle("آخر الأخبار", textColor, primaryYellow),
                      _buildMainNewsCard(cardColor, textColor),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),

              // 🚀 شريط التنقل السفلي - التعديل هنا
              CustomBottomNav(
                currentIndex: 0,
                centerButton: const Boss_Center_Icon(), // أزلنا الـ GestureDetector من هنا
                onHomeTap: () {},
                onProfileTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const BossProfileScreen()));
                },
                onNotificationsTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const BossNotificationScreen()));
                },
                onMessagesTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const BossMessageScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (بقية الدوال _buildHeader و _buildNotificationBanner تبقى كما هي في كودك الأصلي)
  Widget _buildHeader(BuildContext context, Color textColor, Color cardColor, Color primaryYellow) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edu-Bridge",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.6))),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    text: "مرحباً، ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    children: [
                      TextSpan(text: _bossName, style: const TextStyle(color: Color(0xFFCCAA00))),
                    ],
                  ),
                ),
                const Text("لوحة تحكم إدارة القسم", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _buildCircleIconButton(
            icon: Icons.settings_outlined,
            cardColor: cardColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  userName: _bossName,
                  userRole: "رئيس القسم الأكاديمي",
                  onProfileTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossProfileScreen()));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(BuildContext context, Color cardColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveRequestsScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.yellow[800], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pendingLeaveCount > 0
                    ? "لديك $_pendingLeaveCount طلب إجازة معلق بانتظار الموافقة."
                    : "لا توجد طلبات إجازة معلقة حالياً.",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMainNewsCard(Color cardColor, Color textColor) {
    if (_announcements.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: const Center(child: Text("لا توجد أخبار حالياً", style: TextStyle(color: Colors.grey))),
      );
    }
    final news = _announcements.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news['title'] as String? ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 5),
            Text(news['body'] as String? ?? news['content'] as String? ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, Color primaryYellow) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text("عرض الكل", style: TextStyle(color: primaryYellow, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required Color cardColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Icon(icon, color: const Color(0xFFF1C40F), size: 26),
      ),
    );
  }
}