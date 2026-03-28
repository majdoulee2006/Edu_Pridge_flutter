import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';

// استدعاء ملف الزر المنبثق (السبيد ديال)
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
// 🌟 استدعاء الشريط السفلي الموحد الجديد 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';

// استدعاء باقي الواجهات لضمان عمل التنقل
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب حالة الوضع الليلي والألوان المتجاوبة 🌟
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : AppColors.background;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor, // 🌟 لون متجاوب
        body: Stack(
          children: [
            // المحتوى الأساسي (الأخبار)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // تمرير الألوان لتتجاوب مع الوضع
                    _buildAppBar(context, isDark, textColor),
                    const SizedBox(height: 24),
                    _buildSectionTitle(textColor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          bottom: 100,
                        ), // مساحة للشريط السفلي
                        children: [
                          _buildNewsCard(
                            tag: 'إعلان هام',
                            title:
                                'تم إصدار جدول الامتحانات النهائية للفصل الدراسي الأول',
                            description:
                                'يرجى من جميع الطلاب مراجعة الجدول الدراسي والتأكد من توقيت الامتحانات والقاعات المخصصة.',
                            time: 'منذ ساعتين',
                            gradientColors: isDark
                                ? [Colors.amber.shade700, Colors.amber.shade900]
                                : [
                                    Colors.amber.shade300,
                                    Colors.amber.shade700,
                                  ],
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                          ),
                          _buildNewsCard(
                            tag: 'نشاط طلابي',
                            title: 'ورشة عمل حول مهارات البحث العلمي',
                            description:
                                'ندعو جميع الطلاب المهتمين للتسجيل في ورشة العمل التي ستقام في قاعة المؤتمرات يوم الخميس القادم.',
                            time: 'منذ 4 ساعات',
                            gradientColors: isDark
                                ? [Colors.teal.shade700, Colors.teal.shade900]
                                : [Colors.teal.shade200, Colors.teal.shade800],
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🌟 شريط التنقل السفلي الموحد والذكي 🌟
            CustomBottomNav(
              currentIndex: 0, // 0 = الرئيسية
              centerButton:
                  const CustomSpeedDialEduBridge(), // نمرر الزر الأصفر الخاص بالطالب
              onHomeTap: () {
                // نحن بالفعل في الرئيسية، فلا نفعل شيئاً أو يمكننا عمل Refresh
              },
              onProfileTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              onNotificationsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              onMessagesTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edu-Bridg',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor, // 🌟 لون متجاوب
              ),
            ),
            Row(
              children: [
                const Text(
                  'مرحباً، ',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'أحمد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor, // 🌟 لون متجاوب
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // ربط أيقونة الإعدادات بواجهة الإعدادات
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              child: const Icon(Icons.settings, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 12),
            // ربط صورة البروفايل بواجهة البروفايل
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.orange.shade100,
                child: Icon(
                  Icons.person,
                  color: isDark ? Colors.grey.shade400 : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'آخر الأخبار',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor, // 🌟 لون متجاوب
              ),
            ),
          ],
        ),
        const Text(
          'عرض الكل',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildNewsCard({
    required String tag,
    required String title,
    required String description,
    required String time,
    required List<Color> gradientColors,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 لون متجاوب
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // 🌟 استخدام withAlpha بدلاً من withOpacity للابتعاد عن التحذيرات
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withAlpha(150)
                        : Colors.white, // 🌟 لون متجاوب للـ Tag
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : AppColors.textDark, // 🌟 لون متجاوب
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor, // 🌟 لون متجاوب
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : AppColors.background, // 🌟 لون متجاوب
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_left,
                        size: 20,
                        color: textColor, // 🌟 لون متجاوب
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
