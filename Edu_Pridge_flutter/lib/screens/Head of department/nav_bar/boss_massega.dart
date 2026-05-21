import 'package:flutter/material.dart';

// 🌟 استيراد الشاشات والقطع اللازمة للربط الكامل
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

// 🚀 استدعاء الـ Widget الخاصة برئيس القسم (الأيقونة الوسطى)
import '../../../widgets/boss_center_icon.dart';

class BossMessageScreen extends StatelessWidget {
  const BossMessageScreen({super.key});

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
          bottom: false,
          child: Stack(
            children: [
              // 1. محتوى الرسائل (Header + Search + List)
              Column(
                children: [
                  _buildHeader(context, isDark),
                  _buildSearchBar(cardColor, isDark),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(primaryYellow),

                          // قائمة المحادثات
                          _buildChatTile(
                            context,
                            cardColor, isDark,
                            name: "د. محمد العمري",
                            subject: "بخصوص تقرير الأداء الشهري للمدربين",
                            lastMsg: "السلام عليكم، هل يمكننا مراجعة النقاط الأخيرة في الاجتماع...",
                            time: "10:45 ص",
                            isOnline: true,
                            image: "https://api.dicebear.com/7.x/avataaars/png?seed=DrMohamed",
                            hasTimeHighlight: true,
                          ),

                          _buildChatTile(
                            context,
                            cardColor, isDark,
                            name: "أ. سارة خالد",
                            subject: "طلب إجازة اضطرارية ليوم الخميس",
                            lastMsg: "أحتاج لإذن مغادرة مبكر يوم الخميس القادم لظرف عائلي...",
                            time: "أمس",
                            image: "https://api.dicebear.com/7.x/avataaars/png?seed=Sara",
                          ),

                          _buildChatTile(
                            context,
                            cardColor, isDark,
                            name: "أ. خالد ناصر",
                            subject: "تحديث محتوى مادة الرياضيات 101",
                            lastMsg: "تم رفع الملفات الجديدة على السيرفر، يرجى الاعتماد...",
                            time: "الإثنين",
                            initials: "خ",
                            initialsBg: Colors.orange[100]!,
                          ),

                          _buildChatTile(
                            context,
                            cardColor, isDark,
                            name: "د. يوسف العلي",
                            subject: "استفسار بخصوص الميزانية",
                            lastMsg: "نحتاج لشراء بعض الأدوات للمعامل، هل الميزانية تسمح...",
                            time: "12/05",
                            image: "https://api.dicebear.com/7.x/avataaars/png?seed=Youssef",
                          ),

                          const SizedBox(height: 150), // مساحة للـ Nav Bar السفلي
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. 🚀 شريط التنقل السفلي الموحد (تم ضبط currentIndex على 3)
              CustomBottomNav(
                currentIndex: 3,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => const BossNotificationScreen())),
                onMessagesTap: () {
                  // نحن هنا بالفعل
                },
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
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
          ),
          const Text("الرسائل", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

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

  Widget _buildSearchBar(Color cardColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: const TextField(
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "ابحث عن رسالة أو مدرب...",
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(Color primaryYellow) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("المحادثات الأخيرة", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("رسالة جديدة", style: TextStyle(color: primaryYellow, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Color cardColor, bool isDark,
      {required String name, required String subject, required String lastMsg,
        required String time, String? image, String? initials, Color? initialsBg,
        bool isOnline = false, bool hasTimeHighlight = false}) {
    return GestureDetector(
      onTap: () {
        // يمكنك هنا مستقبلاً التوجه لصفحة الدردشة التفصيلية
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: initialsBg ?? Colors.grey[200],
                  backgroundImage: image != null ? NetworkImage(image) : null,
                  child: initials != null ? Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)) : null,
                ),
                if (isOnline)
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(time, style: TextStyle(
                          color: hasTimeHighlight ? const Color(0xFFD4E000) : Colors.grey,
                          fontSize: 12,
                          fontWeight: hasTimeHighlight ? FontWeight.bold : FontWeight.normal
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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