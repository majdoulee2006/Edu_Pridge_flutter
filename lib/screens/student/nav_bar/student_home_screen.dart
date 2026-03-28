import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
// استيراد الموديل الذي أنشأناه سابقاً
import 'package:edu_pridge_flutter/models/student_data_model.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // متغير لحمل بيانات الطالب القادمة من السيرفر
  StudentDashboardModel? studentData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData(); // جلب البيانات عند فتح الشاشة
  }

  // دالة الربط مع الباكيند
  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await Dio().get(
        "http://127.0.0.1:8000/api/student/dashboard",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        setState(() {
          studentData = StudentDashboardModel.fromJson(response.data);
          isLoading = false;
        });
      }
    } catch (e) {
      print("خطأ في جلب بيانات الطالب: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : AppColors.background;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // تم تمرير بيانات الطالب للهيدر
                    _buildAppBar(context, isDark, textColor, studentData?.name ?? "جاري التحميل..."),
                    const SizedBox(height: 24),

                    // إذا كانت البيانات تحمل، نظهر مؤشر تحميل، وإلا نظهر المحتوى
                    isLoading
                        ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.amber)))
                        : Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          // كرت يعرض المحاضرة القادمة من الباكيند (اختياري)
                          if (studentData != null) _buildUpcomingLectureCard(studentData!, isDark),

                          const SizedBox(height: 20),
                          _buildSectionTitle(textColor),
                          const SizedBox(height: 16),

                          // الأخبار الثابتة كما هي في ديزاينك
                          _buildNewsCard(
                            tag: 'إعلان هام',
                            title: 'تم إصدار جدول الامتحانات النهائية',
                            description: 'يرجى مراجعة الجدول الدراسي والتأكد من التوقيت.',
                            time: 'منذ ساعتين',
                            gradientColors: isDark ? [Colors.amber.shade700, Colors.amber.shade900] : [Colors.amber.shade300, Colors.amber.shade700],
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

            CustomBottomNav(
              currentIndex: 0,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => _loadDashboardData(), // ريفريش عند الضغط
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // إضافة كرت المحاضرة القادمة (Data from Laravel)
  Widget _buildUpcomingLectureCard(StudentDashboardModel data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? Colors.blueGrey.withAlpha(50) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withAlpha(50))
      ),
      child: Row(
        children: [
          const Icon(Icons.class_outlined, color: Colors.blue, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("المحاضرة القادمة", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(data.upcomingLecture['subject'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("القاعة: ${data.upcomingLecture['room']} | الساعة: ${data.upcomingLecture['time']}", style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color textColor, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edu-Bridge', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            Row(
              children: [
                const Text('مرحباً، ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              child: const Icon(Icons.settings, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.orange.shade100,
                child: Icon(Icons.person, color: isDark ? Colors.grey.shade400 : Colors.orange),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ... باقي الميثودز (NewsCard, SectionTitle) تبقى كما هي تماماً من كودك الأصلي ...
  Widget _buildSectionTitle(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('آخر الأخبار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const Text('عرض الكل', style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildNewsCard({
    required String tag, required String title, required String description,
    required String time, required List<Color> gradientColors,
    required Color cardColor, required Color textColor, required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(colors: gradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isDark ? Colors.black.withAlpha(150) : Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : AppColors.background, shape: BoxShape.circle), child: Icon(Icons.keyboard_arrow_left, size: 20, color: textColor)),
                    Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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