import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🌟 استيراد الشاشات الأساسية للتنقل
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';

// 🚀 استيراد الشاشات الفرعية (الأيقونة الوسطى والبانر)
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/leave_requests_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/accounts/accounts_management_screen.dart';

// 🚀 استدعاء الـ Widget الخاصة بالأيقونة الوسطى
import '../../../widgets/boss_center_icon.dart';

class DeptHeadHomeScreen extends StatefulWidget {
  const DeptHeadHomeScreen({super.key});

  @override
  State<DeptHeadHomeScreen> createState() => _DeptHeadHomeScreenState();
}

class _DeptHeadHomeScreenState extends State<DeptHeadHomeScreen> {
  String _bossName = "جارِ التحميل...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bossName = prefs.getString('user_name') ?? "رئيس القسم";
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    const primaryYellow = Color(0xFFD4E000);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // المحتوى القابل للتمرير
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
                      const SizedBox(height: 150), // مساحة للـ Nav Bar
                    ],
                  ),
                ),
              ),

              // 🚀 شريط التنقل السفلي المربوط بالكامل
              CustomBottomNav(
                currentIndex: 0, // الصفحة الرئيسية
                centerButton: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AccountsManagementScreen()),
                    );
                  },
                  child: const Boss_Center_Icon(),
                ),
                onHomeTap: () {
                  // نحن في الصفحة الرئيسية بالفعل
                },
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

  // --- Header: الترحيب وزر الإعدادات ---
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.6))),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    text: "مرحباً، ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    children: [
                      TextSpan(text: _bossName, style: const TextStyle(color: Color(0xFFD4E000))),
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

  // --- Banner: تنبيه الإجازات ---
  Widget _buildNotificationBanner(BuildContext context, Color cardColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaveRequestsScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.yellow[800], size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("لديك طلبات إجازات معلقة بانتظار الموافقة.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- News Card: الكرت الرئيسي للأخبار ---
  Widget _buildMainNewsCard(Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Image.network('https://picsum.photos/seed/edu/400/200', height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تحديث جدول اجتماعات القسم", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 5),
                Text("تم نقل اجتماع الهيئة التدريسية إلى القاعة B لمناقشة الخطة الفصلية.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          )
        ],
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
        decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Icon(icon, color: const Color(0xFFF1C40F), size: 26),
      ),
    );
  }
}