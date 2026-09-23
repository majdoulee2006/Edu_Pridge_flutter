import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/models/notification_model.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/attendance/attendance_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/schedule/schedule_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/assignments/assignments_screen.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/lectures/lectures_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';

import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'package:edu_pridge_flutter/widgets/official_exit_card_dialog.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/academic_card/affairs_pdf_viewer_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> notifications = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool _isMarkingAll = false;
  String _userName = '';
  String _avatarUrl = '';
  
  String currentFilter = 'all';
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _loadUserData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoading && !isLoadingMore && hasMore) {
        _fetchMoreNotifications();
      }
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName  = prefs.getString('user_name') ?? '';
        _avatarUrl = prefs.getString('avatar') ?? '';
      });
    }
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        hasMore = true;
        notifications.clear();
      });
    }
    setState(() => isLoading = true);
    try {
      final response = await StudentServices().getNotifications(page: currentPage, filter: currentFilter);
      if (response != null) {
        setState(() {
          notifications = (response['data'] as List).map((e) => AppNotification.fromJson(e)).toList();
          hasMore = response['has_more'] ?? false;
          isLoading = false;
        });
      } else {
        throw Exception("لا توجد بيانات");
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب الإشعارات: $e");
      if (mounted) {
        setState(() {
          notifications = [];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreNotifications() async {
    setState(() => isLoadingMore = true);
    currentPage++;
    try {
      final response = await StudentServices().getNotifications(page: currentPage, filter: currentFilter);
      if (response != null) {
        setState(() {
          notifications.addAll((response['data'] as List).map((e) => AppNotification.fromJson(e)).toList());
          hasMore = response['has_more'] ?? false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب المزيد من الإشعارات: $e");
      if (mounted) setState(() {
        isLoadingMore = false;
        currentPage--;
      });
    }
  }

  void _changeFilter(String filter) {
    if (currentFilter == filter) return;
    setState(() {
      currentFilter = filter;
    });
    _fetchNotifications(refresh: true);
  }

  Future<void> _openTranscriptPreview([int? studentId]) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFFCC00)),
                SizedBox(height: 16),
                Text('جاري تحميل كشف العلامات المعتمد...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    final pdfBytes = await StudentServices().fetchTranscriptPdfBytes(studentId: studentId);
    if (mounted) Navigator.pop(context);

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AffairsPdfViewerScreen(
            title: 'كشف درجات الطالب المعتمد',
            pdfBytes: pdfBytes,
            fileName: 'transcript_preview.pdf',
            bannerNotice: '⚠️ تنبيه إداري ورسمي: هذه النسخة مخصصة للمعاينة الرقمية الفورية فقط داخل التطبيق. في حال الرغبة بالحصول على النسخة الورقية الرسمية المختومة والموقعة، يتعين على الطالب مراجعة موظف شؤون الطلاب بالمعهد شخصياً.',
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحميل كشف العلامات حالياً. يرجى التحقق من اتصال الخادم.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateForNotification(BuildContext ctx, AppNotification notify) {
    final title = notify.title;
    final msg = notify.message;

    bool isTranscript = notify.type == 'transcript_shared' ||
        notify.type == 'transcript' ||
        title.contains('كشف علامات') || title.contains('كشف درجات') ||
        title.contains('كشف العلامات') || title.contains('كشف الدرجات') ||
        msg.contains('كشف علامات') || msg.contains('كشف درجات') ||
        msg.contains('كشف العلامات') || msg.contains('كشف الدرجات') ||
        (title.contains('وثيقة') && (title.contains('علامات') || msg.contains('علامات')));

    if (isTranscript) {
      _openTranscriptPreview(notify.relatedId);
      return;
    }

    bool isLeave = notify.type == 'leave_request' ||
        (notify.type != 'student_service' &&
         notify.type != 'transcript_shared' &&
         notify.type != 'transcript' &&
         (title.contains('إجاز') || title.contains('أذون') || title.contains('إذن') || title.contains('مغادرة') || title.contains('خروج') ||
          msg.contains('إجاز') || msg.contains('أذون') || msg.contains('إذن') || msg.contains('مغادرة') || msg.contains('خروج')));

    if (isLeave) {
      _showLeaveDetailDialog(ctx, notify);
      return;
    }

    // 🛠️ نوع الإشعار (notify.type) هو مصدر الحقيقة الموثوق دايماً — لازم يتفحّص
    // أولاً. كان في فحص نصّي (isExamGrade) بيدوّر عن كلمة "علامة"/"درجة" بالنص
    // وبيشتغل قبل الـ switch، فكان يخطف أي إشعار type=assignment لمجرد إنه
    // نص "تم تصحيح واجبك وحصلت على علامة: X/Y" فيه كلمة "علامة"، ويوديه
    // على جدول الامتحانات بدل صفحة الواجبات. هلق التخمين النصي صار حصراً
    // fallback لما النوع نفسه مش معروف/فاضي.
    switch (notify.type) {
      case 'announcement':
      case 'administrative':
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: {
            'title':       notify.title,
            'content':     notify.message,
            'body':        notify.message,
            'time_ago':    notify.timeAgo,
            'created_at':  notify.timeAgo,
            'author_name': 'الإدارة',
            if (notify.imageUrl != null) 'image_url': notify.imageUrl,
            if (notify.linkUrl != null) 'link_url': notify.linkUrl,
          }),
        ));
        return;
      case 'assignment':
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => AssignmentsScreen(highlightId: notify.relatedId),
        ));
        return;
      case 'lecture':
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => LecturesScreen(highlightLessonId: notify.relatedId),
        ));
        return;
      case 'attendance':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
        return;
      case 'grade':
      case 'marks':
      case 'exam':
      case 'exam_grade':
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ScheduleScreen(initialTab: 1)));
        return;
    }

    bool isExamGrade = title.contains('علامة') ||
        title.contains('درجة') ||
        title.contains('فحص') ||
        title.contains('امتحان') ||
        msg.contains('علامة') ||
        msg.contains('درجة') ||
        msg.contains('فحص') ||
        msg.contains('امتحان');

    if (isExamGrade) {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ScheduleScreen(initialTab: 1)));
      return;
    }

    // عرض تفاصيل الإشعار العام
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => AnnouncementDetailScreen(announcement: {
        'title':       notify.title,
        'content':     notify.message,
        'body':        notify.message,
        'time_ago':    notify.timeAgo,
        'created_at':  notify.timeAgo,
        'author_name': 'الإدارة',
      }),
    ));
  }

  void _showLeaveDetailDialog(BuildContext ctx, AppNotification notify) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: (notify.relatedId != null && notify.relatedId! > 0)
              ? StudentServices().getLeaveDetails(notify.relatedId!)
              : Future.value(null),
          builder: (builderCtx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
              );
            }

            final data = snapshot.data ?? {
              'id': notify.relatedId ?? 1,
              'student_name': _userName.isNotEmpty ? _userName : 'محمود غنام',
              'student_code': '202601',
              'department': 'نظم معلومات',
              'reason': notify.message,
              'status': 'approved',
              'status_text': 'تصريح خروج معتمد نهائياً - يُسمح بالمغادرة',
              'date': notify.timeAgo,
              'parent_approved': true,
              'hod_approved': true,
              'affairs_approved': true,
            };

            return OfficialExitCardDialog(
              data: data,
              notificationMessage: notify.message,
            );
          },
        );
      },
    );
  }

  // 🌟 دالة تحويل الإشعار لمقروء
  Future<void> _markAsRead(AppNotification notify) async {
    if (!notify.isRead) {
      setState(() {
        notify.isRead = true;
      });
      await StudentServices().markNotificationAsRead(notify.id);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    final success = await StudentServices().markAllNotificationsAsRead();
    if (success && mounted) {
      setState(() {
        for (final n in notifications) { n.isRead = true; }
      });
    }
    if (mounted) setState(() => _isMarkingAll = false);
  }

  int get _unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFFAFAFA),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ),
            ),
          ),
          title: Text(
            'الإشعارات',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_unreadCount > 0)
              _isMarkingAll
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFCC00))),
                    )
                  : TextButton(
                      onPressed: _markAllAsRead,
                      child: Text('تمييز الكل', style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold, fontSize: 12)),
                    )
            else
              IconButton(
                icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen(
                    userName: _userName, userRole: 'طالب', profileImageUrl: _avatarUrl,
                  )),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildFiltersBar(isDark),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        )
                      : _NotificationsListView(
                          notifications: notifications,
                          onRefresh: () => _fetchNotifications(refresh: true),
                          onTapNotification: _markAsRead,
                          onNavigate: _navigateForNotification,
                          onOpenTranscript: _openTranscriptPreview,
                          scrollController: _scrollController,
                          isLoadingMore: isLoadingMore,
                        ),
                ),
              ],
            ),
            CustomBottomNav(
              currentIndex: 2,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ),
              onNotificationsTap: () {},
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildFilterChip('الكل', 'all', isDark)),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip('أكاديمية 🎓', 'academic', isDark)),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterChip('إدارية 🏢', 'administrative', isDark)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () => _changeFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFCC00) : (isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFFCC00).withAlpha(80), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsListView extends StatelessWidget {
  final List<AppNotification> notifications;
  final Future<void> Function() onRefresh;
  final Function(AppNotification) onTapNotification;
  final void Function(BuildContext, AppNotification)? onNavigate;
  final void Function(int?)? onOpenTranscript;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const _NotificationsListView({
    required this.notifications,
    required this.onRefresh,
    required this.onTapNotification,
    required this.scrollController,
    this.isLoadingMore = false,
    this.onNavigate,
    this.onOpenTranscript,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد إشعارات حالياً",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.amber,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 120,
        ),
        itemCount: notifications.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            );
          }
          final notify = notifications[index];
          return _buildNotificationCard(context, notify);
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notify) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTranscript = notify.type == 'transcript_shared' ||
        notify.type == 'transcript' ||
        notify.title.contains('كشف علامات') ||
        notify.title.contains('كشف درجات') ||
        notify.title.contains('كشف العلامات') ||
        notify.title.contains('كشف الدرجات') ||
        notify.message.contains('كشف علامات') ||
        notify.message.contains('كشف درجات') ||
        notify.message.contains('كشف العلامات') ||
        notify.message.contains('كشف الدرجات') ||
        (notify.title.contains('وثيقة') && (notify.title.contains('علامات') || notify.message.contains('علامات')));

    return InkWell(
      onTap: () {
        onTapNotification(notify);
        onNavigate?.call(context, notify);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notify.isRead
              ? (isDark ? Theme.of(context).cardColor : Colors.white)
              : (isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50),
          borderRadius: BorderRadius.circular(20),
          border: notify.isRead
              ? null
              : Border.all(color: const Color(0xFFFFCC00), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: notify.isRead
                  ? (isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(5))
                  : const Color(0x33FFCC00),
              blurRadius: notify.isRead ? 15 : 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notify.getIconColor().withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notify.getIcon(),
                color: notify.getIconColor(),
                size: 26,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notify.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          notify.formattedDate ?? notify.timeAgo,
                          style: TextStyle(
                            color: notify.isRead
                                ? Colors.grey.shade500
                                : Colors.amber.shade700,
                            fontSize: 11,
                            fontWeight: notify.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notify.message,
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isTranscript) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            onTapNotification(notify);
                            onOpenTranscript?.call(notify.relatedId);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFCC00).withAlpha(90),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_rounded, size: 16, color: Colors.black),
                                SizedBox(width: 5),
                                Text(
                                  'مشاهدة فقط 👁️',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'معاينة رقمية رسمية',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
