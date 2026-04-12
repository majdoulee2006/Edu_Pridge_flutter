import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
// تم إيقاف استخدام المودل هنا لتجنب أخطاء الـ Null
// import 'package:edu_pridge_flutter/models/student_data_model.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // 🌟 استبدلنا المودل بخريطة بيانات مرنة جداً لمنع الكراش
  Map<String, dynamic>? dashboardData;
  List<dynamic> latestNews = [];
  bool isLoading = true;
  String offlineName = "طالب";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      setState(() {
        offlineName = prefs.getString('user_name') ?? "طالب";
      });

      Dio dio = Dio();
      String url = "http://127.0.0.1:8000/api/student/dashboard";

      var response = await dio.get(
        url,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          var responseData = response.data['data'] ?? response.data;

          if (responseData != null) {
            // 🌟 جلب الأخبار باسم announcements أولاً لتجنب اختفائها
            latestNews = responseData['announcements'] ?? responseData['latest_news'] ?? [];

            // 🌟 حفظ البيانات بشكل مرن ومباشر
            dashboardData = responseData;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب بيانات الطالب: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر الاتصال بالسيرفر، يتم عرض البيانات المحفوظة")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : AppColors.background;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    // 🌟 استخراج الاسم بذكاء (سواء كان name أو full_name)
    String displayName = dashboardData?['name'] ?? dashboardData?['full_name'] ?? offlineName;

    // 🌟 تجهيز بيانات المحاضرة القادمة
    Map<String, dynamic>? upcoming = dashboardData?['upcoming_lecture'];
    bool hasLecture = upcoming != null && upcoming.isNotEmpty;

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
                    _buildAppBar(context, isDark, textColor, displayName),
                    const SizedBox(height: 24),
                    isLoading
                        ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.amber)))
                        : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadDashboardData,
                        color: Colors.amber,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          children: [
                            if (hasLecture)
                              _buildUpcomingLectureCard(upcoming!, isDark)
                            else
                              _buildNoLecturesCard(isDark),
                            const SizedBox(height: 20),
                            _buildSectionTitle(textColor),
                            const SizedBox(height: 16),

                            if (latestNews.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text("لا توجد أخبار حالياً", style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            else
                              ...latestNews.map((news) {
                                String rawType = news['type'] ?? 'general';
                                String displayTag = rawType == 'course_specific' ? 'إعلان مقرر' : 'إعلان عام';
                                bool isUrgent = rawType == 'course_specific';

                                return _buildNewsCard(
                                  tag: displayTag,
                                  title: news['title'] ?? 'بدون عنوان',
                                  description: news['content'] ?? '',
                                  time: news['time_ago'] ?? '',
                                  gradientColors: isDark
                                      ? (isUrgent
                                      ? [Colors.amber.shade900, Colors.black87]
                                      : [Colors.teal.shade900, Colors.black87])
                                      : (isUrgent
                                      ? [Colors.amber.shade300, Colors.amber.shade700]
                                      : [Colors.teal.shade300, Colors.teal.shade700]),
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  isDark: isDark,
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => _loadDashboardData(),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingLectureCard(Map<String, dynamic> data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: Colors.blue, size: 35),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("المحاضرة القادمة", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['subject'] ?? "غير محدد", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("القاعة: ${data['room'] ?? '-'} | الساعة: ${data['time'] ?? '-'}",
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoLecturesCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: Text("لا توجد محاضرات مجدولة اليوم", style: TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color textColor, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edu-Bridge', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.amber : AppColors.accent)),
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
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.amber),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade100,
                child: const Icon(Icons.person, color: Colors.amber),
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
            Container(width: 4, height: 24, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('آخر الأخبار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        TextButton(onPressed: () {}, child: const Text('عرض الكل', style: TextStyle(color: Colors.grey))),
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
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(colors: gradientColors, begin: Alignment.topRight, end: Alignment.bottomLeft),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tag == 'إعلان مقرر' ? Colors.orange.shade900 : Colors.teal.shade900,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: tag == 'إعلان مقرر' ? Colors.amber.shade800 : Colors.teal.shade800
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