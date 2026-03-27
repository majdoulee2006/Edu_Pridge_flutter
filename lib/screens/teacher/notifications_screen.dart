import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
// استيراد صفحة الإعدادات من المجلد المشترك
import '../shared/settings_screen.dart';

// 🌟 1. استدعاء الشريط الموحد 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
// 🌟 2. استدعاء زر المعلم الموحد 🌟
import '../../widgets/teacher_speed_dial.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب ألوان الثيم للـ Dark Mode 🌟
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor, // 🌟 يتجاوب مع الثيم
        elevation: 0,
        // إضافة أيقونة الإعدادات وتفعيل الانتقال لصفحتها
        leading: IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: textColor,
          ), // 🌟 يتجاوب مع الثيم
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: Text(
          "الإشعارات",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ), // 🌟 يتجاوب مع الثيم
        ),
        centerTitle: true,
        actions: [
          // زر الرجوع للخلف
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: textColor,
            ), // 🌟 يتجاوب مع الثيم
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      // 🌟 التعديل السحري: تغليف المحتوى بـ Stack والشريط الموحد 🌟
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي (الإشعارات)
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildNotifCard(
                  context, // 🌟 تمرير الـ context ليدعم الثيم
                  "واجب أكاديمي",
                  "أحمد محمد (طالب)",
                  "تم تسليم واجب الرياضيات الجديد.",
                  "منذ 15 دقيقة",
                  Icons.book,
                  const Color(0xFFFEF9E7),
                  const Color(0xFFD4AC0D),
                ),
                _buildNotifCard(
                  context,
                  "إشعار إداري",
                  "قسم الامتحانات",
                  "تم تحديث جدول الامتحانات.",
                  "أمس",
                  Icons.calendar_today,
                  const Color(0xFFF5EEF8),
                  const Color(0xFF884EA0),
                ),
                const SizedBox(
                  height: 120,
                ), // مساحة لتجنب تغطية الشريط السفلي للإشعارات
              ],
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 2, // 🌟 2 = الإشعارات مفعلة
              centerButton:
                  const CustomSpeedDialEduBridge(), // زر المعلم الموحد
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () {}, // نحن في الإشعارات أصلاً
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 إضافة BuildContext للدالة لتدعم ألوان الثيم 🌟
  Widget _buildNotifCard(
    BuildContext context,
    String type,
    String title,
    String content,
    String time,
    IconData icon,
    Color bg,
    Color text,
  ) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 لون الكرت من الثيم
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bg,
            child: Icon(icon, color: text),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: text,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ), // 🌟 لون النص من الثيم
                Text(
                  content,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
