import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/student/student_services_menu_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/qr_scanner/qr_scanner_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';

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

  void _onLangChange() { if (mounted) setState(() {}); }

  void _onNewNotif() {
    final n = NotificationPolling.latestNew.value;
    if (n != null && mounted) {
      showInAppBanner(
        context,
        n['title']?.toString() ?? 'إشعار جديد',
        n['message']?.toString() ?? n['body']?.toString() ?? '',
        onTap: () => _navigateForNotif(n),
      );
    }
  }

  void _navigateForNotif(Map<String, dynamic> n) {
    final type = n['type']?.toString() ?? '';
    switch (type) {
      case 'assignment':
      case 'academic':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
        break;
      case 'announcement':
      case 'administrative':
        final title   = n['title']?.toString() ?? '';
        final message = n['message']?.toString() ?? '';
        final isAnnouncement = type == 'announcement';
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(
            screenTitle: isAnnouncement ? 'تفاصيل الإعلان' : 'تفاصيل الإشعار',
            announcement: {
              'title': title, 'body': message, 'content': message,
              'created_at': n['created_at'] ?? '', 'author_name': 'الإدارة',
            },
          ),
        ));
        break;
      default:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    NotificationPolling.start('/student/notifications');
    NotificationPolling.unreadCount.addListener(_onUnreadChanged);
    NotificationPolling.latestNew.addListener(_onNewNotif);
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    NotificationPolling.unreadCount.removeListener(_onUnreadChanged);
    NotificationPolling.latestNew.removeListener(_onNewNotif);
    NotificationPolling.stop();
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  // مراجعة الحضور المخزن محلياً وإرساله للسيرفر عند توفر الشبكة
  Future<void> _syncOfflineAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineScans = prefs.getStringList('offline_attendance_scans') ?? [];
      debugPrint("🔍 [Offline Sync] Found ${offlineScans.length} offline scans.");
      if (offlineScans.isEmpty) return;

      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        debugPrint("🔍 [Offline Sync] Token is empty, aborting.");
        return;
      }

      final dio = Dio();
      List<String> remainingScans = List.from(offlineScans);

      for (String scanStr in offlineScans) {
        try {
          final data = jsonDecode(scanStr);
          final qrToken = data['qr_token'];
          final scannedAt = data['scanned_at'];
          final faceEmbedding = data['face_embedding'];

          final url = "${ApiService().baseUrl}/student/attendance/scan";
          debugPrint("🔍 [Offline Sync] Sending scan to $url. Token: $qrToken, ScannedAt: $scannedAt");

          final res = await dio.post(
            url,
            data: {
              "qr_token": qrToken,
              "scanned_at": scannedAt,
              if (faceEmbedding != null) "face_embedding": faceEmbedding,
            },
            options: Options(headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            }),
          );

          debugPrint("🔍 [Offline Sync] Response code: ${res.statusCode}. Body: ${res.data}");
          if (res.statusCode == 200 || res.statusCode == 409 || res.data?['reject_reason'] == 'already_marked') {
            remainingScans.remove(scanStr);
          }
        } on DioException catch (e) {
          debugPrint("🔍 [Offline Sync] DioException: ${e.message}, Response: ${e.response?.data}");
          if (e.response != null) {
            remainingScans.remove(scanStr);
          }
          if (e.response == null) {
            break;
          }
        } catch (e) {
          debugPrint("🔍 [Offline Sync] Error parsing scan: $e");
          remainingScans.remove(scanStr);
        }
      }

      await prefs.setStringList('offline_attendance_scans', remainingScans);
      debugPrint("🔍 [Offline Sync] Sync cycle finished. Remaining scans: ${remainingScans.length}");
    } catch (e) {
      debugPrint("⛔️ Offline Sync Error: $e");
    }
  }

  // 🌟 الدالة الجديدة النظيفة اللي بتعتمد على الـ Service
  Future<void> _loadDashboardData() async {
    // محاولة مزامنة الحضور المخزن محلياً أولاً عند تحديث الصفحة أو الدخول إليها
    await _syncOfflineAttendance();

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    setState(() => offlineName = prefs.getString('user_name') ?? "طالب");

    // حمّل الكاش أولاً لتجنب الشاشة الفارغة
    final cached = prefs.getString('cache_student_dashboard');
    if (cached != null && dashboardData == null) {
      try {
        final c = jsonDecode(cached) as Map<String, dynamic>;
        setState(() {
          dashboardData = c;
          latestNews = c['announcements'] ?? [];
        });
      } catch (_) {}
    }

    try {
      final data = await StudentServices().getDashboardData();
      if (data != null) {
        // حفظ آخر نسخة ناجحة
        prefs.setString('cache_student_dashboard', jsonEncode(data));
        if (mounted) {
          setState(() {
            dashboardData = data;
            latestNews = data['announcements'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("⛔️ Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
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

    final isAr = AppSettings.language.value == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            Column(
              children: [
                // ─── الهيدر الثابت ───
                Container(
                  color: cardColor,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          _buildAppBar(context, isDark, textColor, displayName, avatarUrl),
                          const SizedBox(height: 14),
                          _buildSectionTitle(textColor),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                // ─── قائمة الأخبار ───
                isLoading
                    ? const Expanded(
                        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
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
                                _buildUpcomingLectureCard(upcoming, isDark),
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
                                      String rawAudience = news['target_audience']?.toString() ?? 'all';
                                      String? dept = news['department_name']?.toString();
                                      String? course = news['course_name']?.toString();

                                      String audienceTag = switch (rawAudience) {
                                        'students' => 'طلاب',
                                        'teachers' => 'معلمين',
                                        'heads'    => 'رؤساء أقسام',
                                        _          => 'الجميع',
                                      };
                                      if (dept != null && dept.isNotEmpty) {
                                        audienceTag += ' | قسم: $dept';
                                      }
                                      if (course != null && course.isNotEmpty) {
                                        audienceTag += ' | دورة: $course';
                                      }

                                      String rawType = news['type'] ?? 'general';
                                      String typeTag = rawType == 'course_specific' ? 'إعلان مقرر' : 'إعلان عام';
                                      bool isUrgent = rawAudience != 'all' || (dept != null && dept.isNotEmpty);

                                      String authorName =
                                          news['author_name'] ?? 'الإدارة';
                                      String date = (news['created_at'] ?? '')
                                          .toString()
                                          .split('T')
                                          .first;

                                      return _buildNewsCard(
                                        announcementData: Map<String, dynamic>.from(news as Map),
                                        tag: typeTag,
                                        audienceTag: audienceTag,
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
    final isAr = AppSettings.language.value == 'ar';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: isAr ? 'أهلاً، ' : 'Hello, ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                children: [
                  TextSpan(
                    text: name,
                    style: TextStyle(color: isDark ? Colors.amber : AppColors.accent),
                  ),
                ],
              ),
            ),
            Text(isAr ? 'لوحة تحكم الطالب' : 'Student Dashboard',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.amber, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentServicesMenuScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(Color textColor) {
    final isAr = AppSettings.language.value == 'ar';
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
              isAr ? 'آخر الأخبار' : 'Latest News',
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
    String? audienceTag,
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
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
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: announcementData['image_url'] != null && (announcementData['image_url'] as String).isNotEmpty
                            ? Image.network(
                                  ApiService.fixMediaUrl(announcementData['image_url'] as String?) ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, e) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradientColors,
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // 🏷️ تاغ نوع الإعلان (يمين)
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
                    // 🏷️ تاغ الفئة المستهدفة (أصفر شفاف على اليسار)
                    if (audienceTag != null && audienceTag.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            audienceTag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Noto Sans Arabic',
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
                            Icons.arrow_back_ios,
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
        ),
      ),
    );
  }
}
