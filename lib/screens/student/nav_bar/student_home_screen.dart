import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/qr_scanner/qr_scanner_screen.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  Map<String, dynamic>? dashboardData;
  List<dynamic> latestNews = [];
  bool isLoading = true;
  String offlineName = "طالب";
  bool _hasUnread = false;

  void _onUnreadChanged() {
    if (mounted) setState(() => _hasUnread = NotificationPolling.unreadCount.value > 0);
  }

  void _onNewNotif() {
    final n = NotificationPolling.latestNew.value;
    if (n != null && mounted) {
      showInAppBanner(context, n['title']?.toString() ?? 'إشعار جديد', n['message']?.toString() ?? n['body']?.toString() ?? '');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    NotificationPolling.start('/student/notifications');
    NotificationPolling.unreadCount.addListener(_onUnreadChanged);
    NotificationPolling.latestNew.addListener(_onNewNotif);
  }

  @override
  void dispose() {
    NotificationPolling.unreadCount.removeListener(_onUnreadChanged);
    NotificationPolling.latestNew.removeListener(_onNewNotif);
    NotificationPolling.stop();
    super.dispose();
  }

  // 🌟 الدالة الجديدة النظيفة اللي بتعتمد على الـ Service
  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        offlineName = prefs.getString('user_name') ?? "طالب";
      });

      // جلب البيانات بطلب واحد من السيرفيس
      final data = await StudentServices().getDashboardData();

      if (data != null) {
        setState(() {
          dashboardData = data;
          latestNews = data['announcements'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("⛔️ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر تحميل البيانات أو انتهت الجلسة")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.scaffoldBackgroundColor
        : AppColors.background;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    // استخراج بيانات الطالب والمحاضرة
    final studentData = dashboardData?['student'];
    String displayName =
        studentData?['name'] ?? studentData?['full_name'] ?? offlineName;
    String? avatarUrl = ApiService.fixMediaUrl(studentData?['avatar'] as String?);

    Map<String, dynamic>? upcoming = dashboardData?['next_lecture'];
    bool hasLecture = upcoming != null && upcoming.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    _buildAppBar(
                      context,
                      isDark,
                      textColor,
                      displayName,
                      avatarUrl,
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                              ),
                            ),
                          )
                        : Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadDashboardData,
                              color: Colors.amber,
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 100),
                                children: [
                                                  if (hasLecture)
                                    _buildUpcomingLectureCard(upcoming!, isDark),
                                  const SizedBox(height: 20),
                                  _buildSectionTitle(textColor),
                                  const SizedBox(height: 16),

                                  if (latestNews.isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Text(
                                          "لا توجد أخبار حالياً",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else
                                    ...latestNews.map((news) {
                                      String rawType =
                                          news['type'] ?? 'general';
                                      String displayTag =
                                          rawType == 'course_specific'
                                          ? 'إعلان مقرر'
                                          : 'إعلان عام';
                                      bool isUrgent =
                                          rawType == 'course_specific';

                                      String authorName =
                                          news['author_name'] ?? 'الإدارة';
                                      String date = (news['created_at'] ?? '')
                                          .toString()
                                          .split('T')
                                          .first;

                                      return _buildNewsCard(
                                        announcementData: Map<String, dynamic>.from(news as Map),
                                        tag: displayTag,
                                        title: news['title'] ?? 'بدون عنوان',
                                        description: news['content'] ?? '',
                                        time:
                                            "${news['time_ago'] ?? date} • $authorName",
                                        gradientColors: isDark
                                            ? (isUrgent
                                                  ? [
                                                      Colors.amber.shade900,
                                                      Colors.black87,
                                                    ]
                                                  : [
                                                      Colors.teal.shade900,
                                                      Colors.black87,
                                                    ])
                                            : (isUrgent
                                                  ? [
                                                      Colors.amber.shade300,
                                                      Colors.amber.shade700,
                                                    ]
                                                  : [
                                                      Colors.teal.shade300,
                                                      Colors.teal.shade700,
                                                    ]),
                                        cardColor: cardColor,
                                        textColor: textColor,
                                        isDark: isDark,
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            // زر الكاميرا العائم لمسح QR الحضور
            Positioned(
              bottom: 100,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 28),
                ),
              ),
            ),

            CustomBottomNav(
              currentIndex: 0,
              hasUnread: _hasUnread,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => _loadDashboardData(),
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

  Widget _buildUpcomingLectureCard(Map<String, dynamic> data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey.withValues(alpha: 0.2) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: Colors.blue, size: 35),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "المحاضرة القادمة",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['course_name'] ?? data['subject'] ?? "غير محدد",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "القاعة: ${data['room'] ?? '-'} | الساعة: ${data['start_time'] ?? '-'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textColor,
    String name,
    String? avatarUrl,
  ) {
    return Row(
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
                    text: name,
                    style: TextStyle(color: isDark ? Colors.amber : AppColors.accent),
                  ),
                ],
              ),
            ),
            const Text('لوحة تحكم الطالب',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.amber),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                color: Colors.amber,
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
      ],
    );
  }

  Widget _buildNewsCard({
    required Map<String, dynamic> announcementData,
    required String tag,
    required String title,
    required String description,
    required String time,
    required List<Color> gradientColors,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: announcementData))),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
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
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tag == 'إعلان مقرر'
                          ? Colors.orange.shade900
                          : Colors.teal.shade900,
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
                    color: textColor,
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
                    Text(
                      time,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: tag == 'إعلان مقرر'
                          ? Colors.amber.shade800
                          : Colors.teal.shade800,
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
