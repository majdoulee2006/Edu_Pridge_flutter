import 'package:flutter/material.dart';
// استيراد الشاشات والقطع الموحدة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../../widgets/parents_center_icon.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف الألوان المتجاوبة مع الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(15),
              children: [
                // البطاقة الأولى الكبيرة (إجازة مرضية)
                _buildDetailedCard(cardColor, textColor),

                // البطاقة الثانية (خروج مبكر)
                _buildSimpleCard(
                    title: "خروج مبكر",
                    date: "الخميس، 16 مايو - 12:30 م",
                    icon: Icons.directions_run_rounded,
                    iconCol: Colors.blue,
                    cardColor: cardColor,
                    textColor: textColor
                ),

                // البطاقة الثالثة (غياب ليوم كامل)
                _buildSimpleCard(
                    title: "غياب ليوم كامل",
                    date: "الأحد، 19 مايو 2024",
                    icon: Icons.calendar_month,
                    iconCol: Colors.purple,
                    cardColor: cardColor,
                    textColor: textColor
                ),

                const SizedBox(height: 20),
                Center(child: Text("نهاية القائمة", style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 12))),
                const SizedBox(height: 150), // مساحة للناف بار
              ],
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 0, // تتبع للرئيسية
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "أذونات الطالب",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // بناء البطاقة المفصلة (طلب نشط)
  Widget _buildDetailedCard(Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFEFFF00), width: 2),
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.medical_services_outlined, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text("إجازة مرضية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                ],
              ),
              _statusTag(),
            ],
          ),
          const SizedBox(height: 5),
          Text("الأربعاء، 15 مايو 2024", style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              "سبب الإذن: يعاني الطالب من وعكة صحية مفاجئة ويحتاج للراحة. مرفق صورة عن التقرير الطبي.",
              style: TextStyle(fontSize: 13, height: 1.5, color: textColor.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _actionBtn("رفض", Colors.red, isOutlined: true)),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn("موافقة", Colors.black, btnColor: const Color(0xFFEFFF00))),
            ],
          ),
        ],
      ),
    );
  }

  // البطاقات البسيطة (سجل الأذونات)
  Widget _buildSimpleCard({
    required String title,
    required String date,
    required IconData icon,
    required Color iconCol,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconCol.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconCol, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(date, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          _statusTag(),
          const SizedBox(width: 10),
          Icon(Icons.keyboard_arrow_left, color: textColor.withValues(alpha: 0.2), size: 18),
        ],
      ),
    );
  }

  Widget _statusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: const Text("قيد الانتظار", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(String label, Color textCol, {Color? btnColor, bool isOutlined = false}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: btnColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: isOutlined ? Border.all(color: textCol.withValues(alpha: 0.3)) : null,
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
      ),
    );
  }
}