import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';

// 🌟 استدعاء الشريط الموحد وزر المعلم 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';

// استدعاء الشاشات للتنقل من الشريط السفلي
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  int selectedDayIndex = 3;

  final List<Map<String, dynamic>> days = const [
    {"name": "السبت", "day": 28},
    {"name": "الجمعة", "day": 27},
    {"name": "الخميس", "day": 26},
    {"name": "الأربعاء", "day": 25},
    {"name": "الثلاثاء", "day": 24},
  ];

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب ألوان الثيم للـ Dark Mode 🌟
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor, // 🌟 دعم الثيم
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor, // 🌟 دعم الثيم
        elevation: 0,
        // 🌟 تفعيل زر الإعدادات بشكل صحيح 🌟
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: textColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: Text(
          "جدولي",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      // 🌟 التغليف بـ Stack و Directionality لترتيب الشريط والمحتوى 🌟
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي
            ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFFF00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "جدول الحصص",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // شريط الأيام
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedDayIndex;
                      final item = days[index];
                      return GestureDetector(
                        onTap: () => setState(() => selectedDayIndex = index),
                        child: Container(
                          width: 68,
                          decoration: BoxDecoration(
                            // 🌟 الكرت يتجاوب مع الثيم إذا لم يكن محدداً
                            color: isSelected
                                ? const Color(0xFFEFFF00)
                                : cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item["name"],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  // 🌟 الدائرة الداخلية تتجاوب مع الثيم
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  "${item["day"]}",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // عنوان اليوم
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "اليوم: الثلاثاء، 24 أكتوبر",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ), // 🌟 يتجاوب مع الثيم
                  ),
                ),
                const SizedBox(height: 12),

                // كروت الحصص
                _buildClassCard(
                  context, // 🌟 تمرير الـ context للثيم
                  now: true,
                  title: "الفيزياء المتقدمة",
                  subtitle: "الشعبة ب | قاعة 302",
                  time: "10:00 - 11:30",
                  icon: Icons.science_outlined,
                  avatars: 24,
                  actionText: null,
                ),
                _buildClassCard(
                  context,
                  now: false,
                  title: "رياضيات 2",
                  subtitle: "الشعبة أ | قاعة 105",
                  time: "12:00 - 01:30",
                  icon: Icons.calculate_outlined,
                  avatars: 0,
                  actionText: "تحضير الدرس",
                ),
                _buildClassCard(
                  context,
                  now: false,
                  title: "ساعات مكتبية",
                  subtitle: "غرفة المعلمين",
                  time: "02:00 - 04:00",
                  icon: Icons.coffee_outlined,
                  avatars: 0,
                  actionText: null,
                ),
                const SizedBox(height: 120), // مساحة لتجنب الشريط السفلي
              ],
            ),

            // 2. الشريط السفلي الموحد (متموضع في الأسفل)
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNav(
                currentIndex:
                    -1, // 🌟 -1 يعني ولا أيقونة رح تضوي لأننا جوا شاشة فرعية من الزر الأصفر
                centerButton: const CustomSpeedDialEduBridge(),
                onHomeTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherHomeScreen(),
                  ),
                ),
                onProfileTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ),
                onNotificationsTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
                onMessagesTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 تعديل الـ Widget ليدعم الثيم وتمرير الـ context 🌟
  Widget _buildClassCard(
    BuildContext context, {
    required bool now,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required int avatars,
    String? actionText,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 لون الكرت من الثيم
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (now)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFF00),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "الآن",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              if (now) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ), // 🌟 لون النص
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ), // 🌟 خلفية الأيقونة
                child: Icon(icon, color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (avatars > 0)
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFFE3F2FD),
                          child: const Text(
                            "أ",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFFF3E5F5),
                            child: const Text(
                              "م",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9C27B0),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 24,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFFFFEBEE),
                            child: const Text(
                              "س",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFF44336),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 36,
                    ), // مسافة لتجنب التداخل مع الصور المتراكبة
                    Text(
                      "+$avatars",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              const Spacer(),
              Icon(Icons.schedule, size: 18, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(time, style: TextStyle(color: textColor)), // 🌟 لون الوقت
            ],
          ),
          if (actionText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ), // 🌟 خلفية الزر
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    actionText,
                    style: TextStyle(color: textColor),
                  ), // 🌟 لون نص الزر
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
