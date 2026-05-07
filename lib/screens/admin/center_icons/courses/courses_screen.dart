import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';

// استيراد شاشات الشريط السفلي
import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/messages_screen.dart';

import 'package:edu_pridge_flutter/screens/admin/center_icons/courses/add_course.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  // دالة التنقل في الشريط السفلي
  void _navigateToNavScreen(BuildContext context, int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const AdminHomeScreen();
        break;
      case 1:
        screen = const AdminMessagesScreen();
        break;
      case 2:
        screen = const AdminNotificationsScreen();
        break;
      case 3:
        screen = const AdminProfileScreen();
        break;
      default:
        screen = const AdminHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "الدورات",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.settings_outlined, color: textColor),
            ),
          ],
        ),

        body: Stack(
          children: [
            // المحتوى الرئيسي
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // زر إضافة دورة جديدة
                  _buildActionButton(
                    "إضافة دورة جديدة",
                    Icons.add,
                    primaryYellow,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddCourseScreen(),
                        ),
                      );
                    },
                    isDark,
                  ),

                  const SizedBox(height: 15),

                  // عنوان الدورات الحالية
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "الدورات الحالية",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // قائمة الدورات
                  _buildCourseCard(
                    "تطوير الويب الشامل",
                    "12 فصل • 48 ساعة",
                    Icons.code,
                    Colors.blue.shade50,
                    isDark,
                    cardColor,
                    textColor,
                  ),
                  _buildCourseCard(
                    "الذكاء الاصطناعي التطبيقي",
                    "10 فصل • 40 ساعة",
                    Icons.psychology,
                    Colors.purple.shade50,
                    isDark,
                    cardColor,
                    textColor,
                  ),
                  _buildCourseCard(
                    "أمن المعلومات والشبكات",
                    "8 فصل • 32 ساعة",
                    Icons.security,
                    Colors.red.shade50,
                    isDark,
                    cardColor,
                    textColor,
                  ),
                  _buildCourseCard(
                    "إدارة قواعد البيانات",
                    "14 فصل • 56 ساعة",
                    Icons.storage,
                    Colors.green.shade50,
                    isDark,
                    cardColor,
                    textColor,
                  ),
                  _buildCourseCard(
                    "تصميم واجهات المستخدم",
                    "9 فصل • 36 ساعة",
                    Icons.design_services,
                    Colors.orange.shade50,
                    isDark,
                    cardColor,
                    textColor,
                  ),

                  const SizedBox(height: 160), // مسافة إضافية للشريط السفلي
                ],
              ),
            ),

            // الشريط السفلي
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNav(
                currentIndex: 0,
                centerButton: const AdminSpeedDial(),
                onHomeTap: () => _navigateToNavScreen(context, 0),
                onMessagesTap: () => _navigateToNavScreen(context, 1),
                onNotificationsTap: () => _navigateToNavScreen(context, 2),
                onProfileTap: () => _navigateToNavScreen(context, 3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== الدوال المساعدة (بدون تغيير) ======================
  Widget _buildActionButton(
      String title,
      IconData icon,
      Color bgColor,
      VoidCallback onTap,
      bool isDark, {
        Color iconColor = Colors.black,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(
      String title,
      String subtitle,
      IconData icon,
      Color iconBg,
      bool isDark,
      Color cardColor,
      Color textColor,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 22),
          ),
        ],
      ),
    );
  }
}