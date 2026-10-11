import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';

import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/create_announcement_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/boss_services_menu_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart';
import '../../../widgets/boss_center_icon.dart';

class DeptHeadHomeScreen extends StatefulWidget {
  const DeptHeadHomeScreen({super.key});

  @override
  State<DeptHeadHomeScreen> createState() => _DeptHeadHomeScreenState();
}

class _DeptHeadHomeScreenState extends State<DeptHeadHomeScreen> {
  bool get isAr => AppSettings.language.value == 'ar';

  String _bossName = "";
  List<Map<String, dynamic>> _announcements = [];
  bool _hasUnread = false;

  static const List<Color> _cardColors = [
    Color(0xFFFFCC33),
    Color(0xFF4DB6AC),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
  ];

  void _onUnreadChanged() {
    if (mounted) setState(() => _hasUnread = NotificationPolling.unreadCount.value > 0);
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _onNewNotif() {
    if (!AppSettings.isNotificationsEnabled.value) return;
    final n = NotificationPolling.latestNew.value;
    if (n != null && mounted) {
      final isMsg = n['type'] == 'message' || n['type'] == 'chat';
      showInAppBanner(
        context,
        n['title']?.toString() ?? (isAr ? 'إشعار جديد' : 'New Notification'),
        n['message']?.toString() ?? n['body']?.toString() ?? '',
        onTap: () {
          if (isMsg) {
            final senderId = n['sender_id'] ?? n['related_id'];
            final senderName = n['sender_name'] ?? n['sender'] ?? (n['title']?.toString().replaceFirst(isAr ? 'رسالة جديدة من ' : 'New message from ', '') ?? (isAr ? 'المستخدم' : 'User'));
            final notifId = (n['id'] as num?)?.toInt() ?? 0;
            if (notifId > 0) ApiService().deleteNotification(notifId);
            if (senderId != null) ApiService().deleteChatNotifications(senderId);
            NotificationPolling.triggerFetch();
            if (senderId != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatRoomScreen(contact: {
                  'id': senderId,
                  'name': senderName,
                }),
              ));
              return;
            }
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen()));
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _bossName = isAr ? "جارِ التحميل..." : "Loading...";
    _fetchDashboard();
    NotificationPolling.start('/department-head/notifications');
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

  Future<void> _fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/dashboard",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _bossName = d['name'] as String? ?? prefs.getString('user_name') ?? (isAr ? "رئيس القسم" : "Department Head");
            _announcements = List<Map<String, dynamic>>.from(d['announcements'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('⛔ Boss Dashboard Error: $e');
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _bossName = prefs.getString('user_name') ?? (isAr ? "رئيس القسم" : "Department Head"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    const primaryYellow = Color(0xFFCCAA00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Column(
              children: [
                // ─── الهيدر الثابت ───
                Container(
                  color: cardColor,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(context, textColor, cardColor, primaryYellow),
                        const SizedBox(height: 14),
                        _buildSectionTitle(isAr ? "آخر الأخبار" : "Latest News", textColor),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // ─── قائمة الإعلانات ───
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchDashboard,
                    color: primaryYellow,
                    child: _announcements.isEmpty
                        ? Center(
                            child: Text(
                              isAr ? "لا توجد أخبار حالياً" : "No news yet",
                              style: const TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 140),
                            itemCount: _announcements.length,
                            itemBuilder: (context, i) {
                              final a = _announcements[i];
                              return _buildNewsCard(context, a, _cardColors[i % _cardColors.length], cardColor, textColor);
                            },
                          ),
                  ),
                ),
              ],
            ),

            // ─── زر نشر إعلان طائر ───
            Positioned(
              bottom: 100,
              left: isAr ? 20 : null,
              right: isAr ? null : 20,
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()))
                    .then((posted) { if (posted == true) _fetchDashboard(); }),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 28),
                ),
              ),
            ),

            CustomBottomNav(
              currentIndex: 0,
              hasUnread: _hasUnread,
              centerButton: const Boss_Center_Icon(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BossProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BossMessageScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, Color cardColor, Color primaryYellow) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: isAr ? "أهلاً، " : "Hello, ",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    children: [
                      TextSpan(text: _bossName, style: const TextStyle(color: Color(0xFFCCAA00))),
                    ],
                  ),
                ),
                Text(
                  isAr ? "لوحة تحكم إدارة القسم" : "Department Dashboard",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFFF1C40F), size: 28),
            tooltip: isAr ? "الخدمات" : "Services",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BossServicesMenuScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4, height: 24,
            decoration: BoxDecoration(color: const Color(0xFFCCAA00), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _deleteAnnouncement(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'حذف الإعلان' : 'Delete Announcement'),
          content: Text(isAr ? 'هل أنت متأكد من حذف هذا الإعلان؟' : 'Are you sure you want to delete this announcement?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final token = await _getToken();
      await Dio().delete(
        "${ApiService().baseUrl}/department-head/announcements/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم حذف الإعلان' : 'Announcement deleted'), backgroundColor: Colors.green),
        );
        _fetchDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'حدث خطأ أثناء الحذف' : 'Error deleting announcement'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditSheet(Map<String, dynamic> a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAnnouncementSheet(
        announcement: a,
        onUpdated: () { Navigator.pop(context); _fetchDashboard(); },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, dynamic> a, Color headerColor, Color cardColor, Color textColor) {
    final isMine = a['is_mine'] == true;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: a))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: (a['image_url'] as String?)?.isNotEmpty == true
                            ? Image.network(
                                    ApiService.fixMediaUrl(a['image_url'] as String?) ?? '',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, st) => _announcementPlaceholder(headerColor),
                              )
                            : _announcementPlaceholder(headerColor),
                      ),
                      Positioned(
                        top: 12,
                        left: isAr ? 12 : null,
                        right: isAr ? null : 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            _formatTargetAudience(a),
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(a['title'] as String? ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          ),
                          if (isMine)
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: textColor.withValues(alpha: 0.5), size: 20),
                              onSelected: (v) {
                                if (v == 'edit') _showEditSheet(a);
                                if (v == 'delete') _deleteAnnouncement(a['id'] as int);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(isAr ? 'تعديل' : 'Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(a['body'] as String? ?? a['content'] as String? ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr
                                ? "نشر بواسطة: ${a['author_name'] as String? ?? a['publisher_name'] as String? ?? a['created_by'] as String? ?? 'الإدارة'} • ${a['time_ago'] as String? ?? a['created_at'] as String? ?? ''}"
                                : "Posted by: ${a['author_name'] as String? ?? a['publisher_name'] as String? ?? a['created_by'] as String? ?? 'Admin'} • ${a['time_ago'] as String? ?? a['created_at'] as String? ?? ''}",
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8),
                            child: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, size: 13, color: textColor.withValues(alpha: 0.4)),
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

  Widget _announcementPlaceholder(Color headerColor) {
    return Container(
      color: headerColor,
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: isAr ? 12 : null,
            left: isAr ? null : 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text(
                isAr ? 'إعلان' : 'Notice',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
              ),
            ),
          ),
          const Center(child: Icon(Icons.campaign_outlined, size: 45, color: Colors.white60)),
        ],
      ),
    );
  }

  String _formatTargetAudience(Map<String, dynamic> data) {
    final target = data['target_audience']?.toString() ?? 'all';
    final dept = data['department_name']?.toString() ?? data['department']?.toString();
    final course = data['course_name']?.toString() ?? data['course']?.toString();

    String label = switch (target) {
      'students' => isAr ? 'طلاب' : 'Students',
      'teachers' => isAr ? 'معلمين' : 'Teachers',
      'heads'    => isAr ? 'رؤساء أقسام' : 'Dept Heads',
      _          => isAr ? 'الجميع' : 'All',
    };

    List<String> details = [];
    if (dept != null && dept.isNotEmpty) details.add(isAr ? 'قسم: $dept' : 'Dept: $dept');
    if (course != null && course.isNotEmpty) details.add(isAr ? 'دورة: $course' : 'Course: $course');

    if (details.isNotEmpty) {
      label += ' (${details.join(" | ")})';
    }
    return label;
  }
}

// ─── Edit Announcement Sheet ───────────────────────────────────────────────

class _EditAnnouncementSheet extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback onUpdated;
  const _EditAnnouncementSheet({required this.announcement, required this.onUpdated});

  @override
  State<_EditAnnouncementSheet> createState() => _EditAnnouncementSheetState();
}

class _EditAnnouncementSheetState extends State<_EditAnnouncementSheet> {
  bool get isAr => AppSettings.language.value == 'ar';

  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _linkCtrl;
  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.announcement['title']?.toString() ?? '');
    _contentCtrl = TextEditingController(text: widget.announcement['body']?.toString() ?? widget.announcement['content']?.toString() ?? '');
    _linkCtrl    = TextEditingController(text: widget.announcement['link_url']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isAr ? 'قص الصورة' : 'Crop Image',
            toolbarColor: const Color(0xFFFFCC00),
            toolbarWidgetColor: Colors.black,
            activeControlsWidgetColor: const Color(0xFFFFCC00),
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isAr ? 'قص الصورة' : 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (cropped != null) {
        setState(() => _pickedImage = File(cropped.path));
      }
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id    = widget.announcement['id'];
      debugPrint('🔧 Edit announcement id=$id url=${ApiService().baseUrl}/department-head/announcements/$id');

      final formData = FormData.fromMap({
        'title':    _titleCtrl.text.trim(),
        'content':  _contentCtrl.text.trim(),
        'link_url': _linkCtrl.text.trim(),
        if (_pickedImage != null)
          'image': await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: 'image.jpg',
          ),
      });

      await Dio().post(
        "${ApiService().baseUrl}/department-head/announcements/$id",
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) widget.onUpdated();
    } catch (e) {
      debugPrint('Edit announcement error: $e');
      String msg = isAr ? 'حدث خطأ أثناء التحديث' : 'Error updating announcement';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) { msg = d['message'].toString(); }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() => _isSaving = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    const yellow    = Color(0xFFFFCC00);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          top: 20, left: 24, right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'تعديل الإعلان' : 'Edit Announcement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),

              _field(isAr ? 'العنوان' : 'Title', _titleCtrl, isAr ? 'عنوان الإعلان' : 'Announcement title', isDark, textColor),
              const SizedBox(height: 12),
              _field(isAr ? 'المحتوى' : 'Content', _contentCtrl, isAr ? 'تفاصيل الإعلان...' : 'Announcement details...', isDark, textColor, maxLines: 4),
              const SizedBox(height: 12),
              _field(isAr ? 'الرابط (اختياري)' : 'Link (Optional)', _linkCtrl, 'https://...', isDark, textColor),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: _pickedImage != null ? 140 : 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_pickedImage!, fit: BoxFit.fill))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(isAr ? 'تغيير الصورة' : 'Change Image', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _isSaving ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(26)),
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            isAr ? 'حفظ التعديلات' : 'Save Changes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, bool isDark, Color textColor, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
