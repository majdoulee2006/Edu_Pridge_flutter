import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🌟 استيراد الشاشات لضمان عمل الروابط
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';

// 🚀 استدعاء الـ Widget الخاصة برئيس القسم (الأيقونة الوسطى)
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
      // جلب الاسم المخزن أو استخدام قيمة افتراضية
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
          bottom: false, // لضمان عدم وجود فراغ أبيض تحت الـ Nav Bar
          child: Stack(
            children: [
              // 1. المحتوى الأساسي القابل للتمرير
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15), // مسافة بسيطة جداً من الأعلى
                      _buildHeader(context, textColor, cardColor, primaryYellow),
                      const SizedBox(height: 25),
                      _buildNotificationBanner(cardColor),
                      const SizedBox(height: 25),
                      _buildSectionTitle("آخر الأخبار", textColor, primaryYellow),
                      _buildMainNewsCard(cardColor, textColor),
                      const SizedBox(height: 150), // مساحة كافية للـ Nav Bar السفلي
                    ],
                  ),
                ),
              ),

              // 2. 🚀 شريط التنقل السفلي الموحد
              CustomBottomNav(
                currentIndex: 0, // تبويب الرئيسية
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () {
                  // نحن في الرئيسية حالياً
                },
                onProfileTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const BossProfileScreen())
                  );
                },
                onNotificationsTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const BossNotificationScreen())
                  );
                },
                onMessagesTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const BossMessageScreen())
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- الهيدر العلوي مع زر الإعدادات ---
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor.withValues(alpha: 0.7))),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    text: "مرحباً، ",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                    children: [
                      TextSpan(text: _bossName, style: const TextStyle(color: Color(0xFFD4E000))),
                    ],
                  ),
                ),
                const Text("لوحة تحكم إدارة القسم", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // ⚙️ زر الإعدادات التفاعلي
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    userName: _bossName,
                    userRole: "رئيس القسم الأكاديمي",
                    profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Boss123',
                    onProfileTap: () {
                      Navigator.pop(context); // إغلاق الإعدادات
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const BossProfileScreen()),
                      );
                    },
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: const Icon(Icons.settings_outlined, color: Color(0xFFF1C40F), size: 26),
            ),
          ),
        ],
      ),
    );
  }

  // --- بنر التنبيهات الإدارية ---
  Widget _buildNotificationBanner(Color cardColor) {
    return Container(
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
          const Expanded(
            child: Text(
              "لديك 3 طلبات تسجيل مدرسين بانتظار الموافقة، يرجى مراجعتها.",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
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
          Text("عرض الكل", style: TextStyle(color: primaryYellow, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- بطاقة الخبر الرئيسية ---
  Widget _buildMainNewsCard(Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Image.network(
                'https://picsum.photos/seed/edu/400/200',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 5),
                    Text("10:00 ص", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text("تحديث جدول اجتماعات القسم",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                Text(
                  "تم نقل اجتماع الهيئة التدريسية إلى القاعة B لضمان التواجد الفعال ومناقشة الخطة الفصلية الجديدة.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}