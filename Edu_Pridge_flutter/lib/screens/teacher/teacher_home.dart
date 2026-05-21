import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,

      // 🌟 التعديل هنا: التغليف صار يضم الـ Stack كاملة (المحتوى + الشريط) 🌟
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي (الهيدر + الأخبار)
            Column(
              children: [
                // --- الهيدر العلوي ---
                Container(
                  color: cardColor,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edu-Bridge',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'مرحباً، ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'أستاذ أحمد',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.settings_outlined,
                                      color: Color(0xFFF1C40F),
                                      size: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SettingsScreen(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfileScreen(),
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.orange.shade100,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFFF00),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'آخر الأخبار',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'عرض الكل',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- قائمة الأخبار ---
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    children: [
                      _buildNewsCard(
                        context,
                        tag: 'إعلان هام',
                        title:
                            'تم إصدار جدول الامتحانات النهائية للفصل الدراسي الأول',
                        description:
                            'يرجى من جميع المعلمين مراجعة الجدول الدراسي والتأكد من توقيت الامتحانات والقاعات.',
                        time: 'منذ ساعتين',
                        headerColor: const Color(0xFFFFCC33),
                      ),
                      _buildNewsCard(
                        context,
                        tag: 'نشاط طلابي',
                        title: 'ورشة عمل حول مهارات البحث العلمي',
                        description:
                            'ندعو جميع الطلاب المهتمين للتسجيل في ورشة العمل التي ستقام في قاعة المؤتمرات.',
                        time: 'منذ 4 ساعات',
                        headerColor: const Color(0xFF4DB6AC),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),

            // 2. الشريط السفلي الموحد (الآن صار مشمول بـ RTL)
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
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

  Widget _buildNewsCard(
    BuildContext context, {
    required String tag,
    required String title,
    required String description,
    required String time,
    required Color headerColor,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 50,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 14,
                        color: textColor,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
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
