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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                    // تمرير الـ context هنا لتمكين الانتقال من شريط العناوين
                    _buildAppBar(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(),
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
                            gradientColors: [
                              Colors.amber.shade300,
                              Colors.amber.shade700,
                            ],
                          ),
                          _buildNewsCard(
                            tag: 'نشاط طلابي',
                            title: 'ورشة عمل حول مهارات البحث العلمي',
                            description:
                                'ندعو جميع الطلاب المهتمين للتسجيل في ورشة العمل التي ستقام في قاعة المؤتمرات يوم الخميس القادم.',
                            time: 'منذ 4 ساعات',
                            gradientColors: [
                              Colors.teal.shade200,
                              Colors.teal.shade800,
                            ],
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
                  const StudentSpeedDial(), // نمرر الزر الأصفر الخاص بالطالب
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

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edu-Bridg',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Row(
              children: [
                Text(
                  'مرحباً، ',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'أحمد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
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
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.person, color: Colors.orange),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
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
            const Text(
              'آخر الأخبار',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
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
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      // تم تغيير السهم ليؤشر لليسار بشكل صحيح في الواجهة العربية
                      child: const Icon(
                        Icons.keyboard_arrow_left,
                        size: 20,
                        color: AppColors.textDark,
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
