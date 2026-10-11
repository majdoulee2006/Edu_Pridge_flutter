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
import 'package:qr_flutter/qr_flutter.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';

import 'package:edu_pridge_flutter/screens/student/center_icons/schedule/schedule_screen.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/ai_floating_button.dart';

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
  int _pendingScansCount = 0;
  int _rejectedScansCount = 0;
  bool _isSyncingOffline = false;

  Future<void> _checkOfflineScansCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('offline_attendance_scans') ?? [];
      final rejected = prefs.getStringList('offline_attendance_rejected') ?? [];
      if (mounted) {
        setState(() {
          _pendingScansCount = pending.length;
          _rejectedScansCount = rejected.length;
        });
      }
    } catch (_) {}
  }

  void _onUnreadChanged() {
    if (mounted) setState(() => _hasUnread = NotificationPolling.unreadCount.value > 0);
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _onNewNotif() {
    if (!AppSettings.isNotificationsEnabled.value) return;
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
    final title = n['title']?.toString() ?? '';
    final message = n['message']?.toString() ?? n['body']?.toString() ?? '';

    bool isExamGrade = type == 'grade' ||
        type == 'marks' ||
        type == 'exam' ||
        type == 'exam_grade' ||
        title.contains('علامة') ||
        title.contains('درجة') ||
        title.contains('فحص') ||
        title.contains('امتحان') ||
        message.contains('علامة') ||
        message.contains('درجة') ||
        message.contains('فحص') ||
        message.contains('امتحان');

    if (isExamGrade) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen(initialTab: 1)));
      return;
    }

    switch (type) {
      case 'message':
      case 'chat':
        final senderId = n['sender_id'] ?? n['related_id'];
        final senderName = n['sender_name'] ?? n['sender'] ?? (title.replaceFirst('رسالة جديدة من ', ''));
        final notifId = (n['id'] as num?)?.toInt() ?? 0;
        if (notifId > 0) ApiService().deleteNotification(notifId);
        if (senderId != null) ApiService().deleteChatNotifications(senderId);
        NotificationPolling.triggerFetch();
        if (senderId != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChatRoomScreen(contact: {
              'id': senderId,
              'name': senderName.isNotEmpty ? senderName : 'المستخدم',
            }),
          ));
        }
        break;
      case 'assignment':
      case 'academic':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
        break;
      case 'announcement':
      case 'administrative':
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
    _checkOfflineScansCount();
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

  // مراجعة الحضور المخزن محلياً وإرساله للسيرفر عبر نقطة الدفعة (Batch Sync)
  Future<void> _syncOfflineAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineScans = prefs.getStringList('offline_attendance_scans') ?? [];
      if (offlineScans.isEmpty) {
        await _checkOfflineScansCount();
        return;
      }

      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      final dio = Dio();
      final List<Map<String, dynamic>> payloadScans = [];
      for (var scanStr in offlineScans) {
        try {
          final data = jsonDecode(scanStr) as Map<String, dynamic>;
          payloadScans.add(data);
        } catch (_) {}
      }

      if (payloadScans.isEmpty) {
        await prefs.setStringList('offline_attendance_scans', []);
        await _checkOfflineScansCount();
        return;
      }

      final url = "${ApiService().baseUrl}/student/attendance/sync";
      final res = await dio.post(
        url,
        data: {"scans": payloadScans},
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        }),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final List<dynamic> results = res.data['results'] ?? [];
        final rejectedScans = prefs.getStringList('offline_attendance_rejected') ?? [];
        final updatedRejected = List<String>.from(rejectedScans);
        final remainingScans = <String>[];
        int syncedCount = 0;
        String? lastRejectMessage;

        for (var scanMap in payloadScans) {
          final clientScanId = scanMap['client_scan_id'] ?? scanMap['qr_token'];
          final scanResult = results.firstWhere(
            (r) => (r['client_scan_id'] == clientScanId || r['qr_token'] == scanMap['qr_token']),
            orElse: () => null,
          );

          if (scanResult != null && scanResult['success'] == true) {
            syncedCount++;
          } else if (scanResult != null && scanResult['success'] == false) {
            final reason = scanResult['reject_reason'] ?? 'rejected';
            final msg = scanResult['message'] ?? 'تم رفض الحضور من السيرفر';
            lastRejectMessage = msg;
            updatedRejected.add(jsonEncode({
              'client_scan_id': clientScanId,
              'qr_token': scanMap['qr_token'],
              'scanned_at': scanMap['scanned_at'],
              'rejected_at': DateTime.now().toUtc().toIso8601String(),
              'reject_reason': reason,
              'message': msg,
            }));
          } else {
            remainingScans.add(jsonEncode(scanMap));
          }
        }

        await prefs.setStringList('offline_attendance_scans', remainingScans);
        await prefs.setStringList('offline_attendance_rejected', updatedRejected);
        await _checkOfflineScansCount();

        if (mounted) {
          if (syncedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تمت مزامنة $syncedCount مسح حضور بنجاح ✅'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          if (lastRejectMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تنبيه مزامنة: $lastRejectMessage ⚠️'),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } on DioException catch (e) {
      debugPrint("🔍 [Offline Sync DioException]: ${e.message}");
    } catch (e) {
      debugPrint("⛔️ Offline Sync Error: $e");
    } finally {
      await _checkOfflineScansCount();
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
                              _buildOfflineAttendanceBanner(isDark),
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

                                      String authorName = news['author_name'] ?? news['publisher_name'] ?? news['created_by'] ?? 'الإدارة';
                                      String date = (news['created_at'] ?? '')
                                          .toString()
                                          .split('T')
                                          .first;
                                      String timeAgo = news['time_ago'] ?? date;

                                      return _buildNewsCard(
                                        announcementData: Map<String, dynamic>.from(news as Map),
                                        tag: typeTag,
                                        audienceTag: audienceTag,
                                        title: news['title'] ?? 'بدون عنوان',
                                        description: news['content'] ?? '',
                                        time: "نشر بواسطة: $authorName • $timeAgo",
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

            // زر الذكاء الاصطناعي العائم على اليمين (EduBridge AI)
            AiFloatingButton(
              userRole: 'student',
              userName: displayName,
              bottom: 100,
              right: 20,
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

  Widget _buildOfflineAttendanceBanner(bool isDark) {
    if (_pendingScansCount == 0 && _rejectedScansCount == 0) {
      return const SizedBox.shrink();
    }

    final hasPending = _pendingScansCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasPending
            ? (isDark ? const Color(0xFF2E2408) : const Color(0xFFFFF9E6))
            : (isDark ? const Color(0xFF2E1010) : const Color(0xFFFDE8E8)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasPending ? const Color(0xFFFFCC00).withValues(alpha: 0.5) : Colors.red.shade300,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.cloud_upload_outlined : Icons.warning_amber_rounded,
            color: hasPending ? const Color(0xFFD99B00) : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending
                      ? 'حضور أوفلاين معلق ($_pendingScansCount)'
                      : 'تنبيه مزامنة الحضور',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: hasPending
                        ? (isDark ? Colors.amber.shade200 : const Color(0xFF8C6400))
                        : (isDark ? Colors.red.shade200 : Colors.red.shade900),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPending
                      ? 'محفوظ محلياً وبانتظار الإرسال للسيرفر'
                      : 'تم رفض مسح سابق من السيرفر',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (hasPending) ...[
            IconButton(
              tooltip: 'عرض رمز الإثبات للمعلم',
              icon: const Icon(Icons.qr_code_2_rounded, size: 26, color: Color(0xFFD99B00)),
              onPressed: () => _showProofQrDialog(context),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: _isSyncingOffline
                  ? null
                  : () async {
                      setState(() => _isSyncingOffline = true);
                      await _syncOfflineAttendance();
                      await _checkOfflineScansCount();
                      if (mounted) setState(() => _isSyncingOffline = false);
                    },
              icon: _isSyncingOffline
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.sync_rounded, size: 15, color: Colors.black),
              label: Text(
                _isSyncingOffline ? 'مزامنة...' : 'مزامنة الآن',
                style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('offline_attendance_rejected');
                await _checkOfflineScansCount();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showProofQrDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final rawQueue = prefs.getStringList('offline_attendance_queue') ?? [];
    if (rawQueue.isEmpty) return;

    final latestScan = jsonDecode(rawQueue.last) as Map<String, dynamic>;
    final scanId = latestScan['client_scan_id']?.toString() ?? 'SCAN-PROOF';
    final proofPayload = 'edu-bridge://proof?scan_id=$scanId';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز إثبات الحضور (المعلم)', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اعرض هذا الرمز للمعلم لمسحه وتأكيد حضورك رسمياً في الوضع الصارم',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 190,
              height: 190,
              child: QrImageView(
                data: proofPayload,
                version: QrVersions.auto,
                size: 190.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'معرف المسح: ${scanId.length > 20 ? "${scanId.substring(0, 20)}..." : scanId}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
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
                                errorBuilder: (_, _, e) => Container(
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
