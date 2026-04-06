import 'package:flutter/material.dart';

// 🌟 استيراد الشاشات والقطع اللازمة للربط الكامل
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

// 🚀 استدعاء الـ Widget الخاصة برئيس القسم (الأيقونة الوسطى)
import '../../../widgets/boss_center_icon.dart';

class BossNotificationScreen extends StatelessWidget {
  const BossNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    const Color primaryYellow = Color(0xFFD4E000);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false, // لضمان ملامسة الـ Nav Bar لأسفل الشاشة
          child: Stack(
            children: [
              // 1. المحتوى الأساسي (قائمة الإشعارات)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isDark),

                    // قسم اليوم
                    _buildSectionTitle("اليوم", hasAction: true),
                    _buildNotificationCard(
                      cardColor, isDark, primaryYellow,
                      icon: Icons.access_time_filled,
                      title: "طلب مغادرة ساعية",
                      description: "د. محمد الفهد يطلب مغادرة لمدة ساعتين لظروف خاصة.",
                      time: "منذ 5 د",
                      hasButtons: true,
                      isUnread: true,
                    ),
                    _buildNotificationCard(
                      cardColor, isDark, Colors.purple,
                      icon: Icons.calendar_month,
                      title: "طلب إجازة اعتيادية",
                      description: "أ. سارة العمر • لمدة 3 أيام تبدأ من يوم الأحد القادم الموافق 25/10",
                      time: "10:30 ص",
                      isUnread: true,
                    ),
                    _buildNotificationCard(
                      cardColor, isDark, Colors.orange,
                      icon: Icons.warning_amber_rounded,
                      title: "تنبيه إداري عاجل",
                      description: "يرجى الانتهاء من رصد درجات أعمال السنة قبل نهاية دوام اليوم.",
                      time: "08:00 ص",
                    ),

                    // قسم الأمس
                    _buildSectionTitle("الأمس"),
                    _buildNotificationCard(
                      cardColor, isDark, Colors.teal,
                      icon: Icons.groups,
                      title: "اجتماع مجلس القسم",
                      description: "تذكير بموعد الاجتماع الدوري في قاعة الاجتماعات الرئيسية.",
                      time: "01:00 م",
                    ),

                    const SizedBox(height: 150), // مساحة للـ Nav Bar السفلي
                  ],
                ),
              ),

              // 2. 🚀 شريط التنقل السفلي الموحد
              CustomBottomNav(
                currentIndex: 2, // تبويب الإشعارات
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const BossProfileScreen())),
                onNotificationsTap: () {
                  // نحن هنا بالفعل
                },
                onMessagesTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- بناء الهيدر المحدث ---
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
          ),
          const Text("الإشعارات", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          // ⚙️ زر الإعدادات المحدث لفتح شاشة الإعدادات
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(userName: "أحمد عبدالله", userRole: "رئيس قسم"),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.settings_outlined, color: Colors.grey, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasAction = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (hasAction)
            Text("تحديد الكل كمقروء",
                style: TextStyle(color: Colors.yellow[700], fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- بناء بطاقة الإشعار ---
  Widget _buildNotificationCard(Color cardColor, bool isDark, Color iconColor,
      {required IconData icon, required String title, required String description,
        required String time, bool hasButtons = false, bool isUnread = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (hasButtons) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBtn("موافقة", const Color(0xFFD4E000), Colors.black),
                const SizedBox(width: 12),
                _buildBtn("رفض", Colors.grey.withValues(alpha: 0.1), isDark ? Colors.white : Colors.black),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBtn(String text, Color bg, Color txtColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(text, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }
}