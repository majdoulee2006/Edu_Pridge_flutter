import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  bool _isLoading = true;
  String _teacherName = '';
  List<Map<String, dynamic>> _announcements = [];

  static const List<Color> _cardColors = [
    Color(0xFFFFCC33),
    Color(0xFF4DB6AC),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/dashboard",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        final announcements = d['recent_announcements'] as List<dynamic>? ?? [];
        setState(() {
          _teacherName   = d['teacher']?['name'] as String? ?? '';
          _announcements = announcements.map((a) => Map<String, dynamic>.from(a as Map)).toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Dashboard Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Column(
              children: [
                // ─── الهيدر ───
                Container(
                  color: cardColor,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      text: 'أهلاً، ',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                                      children: [
                                        TextSpan(
                                          text: _isLoading
                                              ? '...'
                                              : (_teacherName.isNotEmpty ? 'أستاذ $_teacherName' : 'أستاذ'),
                                          style: const TextStyle(color: Color(0xFFFFCC00)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text('لوحة تحكم المعلم',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.settings_outlined,
                                        color: Color(0xFFF1C40F), size: 28),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // عنوان القسم بدون "عرض الكل"
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFCC00),
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              Text('آخر الأخبار',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor)),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── قائمة الإعلانات ───
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                      : RefreshIndicator(
                          onRefresh: _fetchDashboard,
                          color: const Color(0xFFFFCC00),
                          child: _announcements.isEmpty
                              ? const Center(
                                  child: Text('لا توجد إعلانات حالياً',
                                      style: TextStyle(color: Colors.grey, fontSize: 15)))
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  itemCount: _announcements.length,
                                  itemBuilder: (context, index) {
                                    final a = _announcements[index];
                                    return _buildNewsCard(
                                      context,
                                      announcementData: a,
                                      tag: 'إعلان',
                                      title: a['title'] as String? ?? '',
                                      description: a['content'] as String? ?? '',
                                      time: a['created_at'] as String? ?? '',
                                      headerColor: _cardColors[index % _cardColors.length],
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),

            // ─── الشريط السفلي ───
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context, {
    required Map<String, dynamic> announcementData,
    required String tag,
    required String title,
    required String description,
    required String time,
    required Color headerColor,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: announcementData))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Text(tag,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                    ),
                  ),
                  const Center(child: Icon(Icons.image_outlined, size: 50, color: Colors.white60)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.4, color: textColor)),
                  const SizedBox(height: 10),
                  Text(description,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.arrow_back_ios_new, size: 14, color: textColor),
                      ),
                    ],
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
