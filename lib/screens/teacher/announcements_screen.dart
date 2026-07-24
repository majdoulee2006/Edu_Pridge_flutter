import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import '../shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import '../../widgets/teacher_speed_dial.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'teacher_home.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

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
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/announcements",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(
            res.data['data'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('⛔ Announcements Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAnnouncementSheet(
        onAdded: () {
          Navigator.pop(context);
          _fetchAnnouncements();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الإعلانات',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAnnouncements,
                    color: const Color(0xFFFFCC00),
                    child: _announcements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.campaign_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'لا توجد إعلانات حالياً',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'اضغط + لإضافة إعلان جديد',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                            itemCount: _announcements.length,
                            itemBuilder: (context, index) {
                              final a = _announcements[index];
                              return _buildCard(
                                context,
                                announcementData: Map<String, dynamic>.from(a),
                                title: a['title'] as String? ?? '',
                                content: a['content'] as String? ?? '',
                                timeAgo: a['time_ago'] as String? ?? '',
                                course: a['course'] as String?,
                                imageUrl: ApiService.fixMediaUrl(a['image_url'] as String?),
                                headerColor: _cardColors[index % _cardColors.length],
                                textColor: textColor,
                                cardColor: cardColor,
                              );
                            },
                          ),
                  ),

            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            onPressed: _showAddDialog,
            backgroundColor: const Color(0xFFFFCC00),
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required Map<String, dynamic> announcementData,
    required String title,
    required String content,
    required String timeAgo,
    required String? course,
    required String? imageUrl,
    required Color headerColor,
    required Color textColor,
    required Color cardColor,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(announcement: announcementData),
      )),
      child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => _headerPlaceholder(headerColor, course),
                    )
                  : _headerPlaceholder(headerColor, course),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _headerPlaceholder(Color headerColor, String? course) {
    return Container(
      color: headerColor,
      child: Stack(
        children: [
          const Center(child: Icon(Icons.campaign_outlined, size: 42, color: Colors.white70)),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text(course ?? 'إعلان عام',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAnnouncementSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddAnnouncementSheet({required this.onAdded});

  @override
  State<_AddAnnouncementSheet> createState() => _AddAnnouncementSheetState();
}

class _AddAnnouncementSheetState extends State<_AddAnnouncementSheet> {
  final _titleController   = TextEditingController();
  final _contentController = TextEditingController();

  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  bool _isCourseSpecific = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/courses",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('يرجى إدخال عنوان الإعلان');
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      _showSnack('يرجى إدخال نص الإعلان');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final body = {
        'title':     _titleController.text.trim(),
        'content':   _contentController.text.trim(),
        'type':      _isCourseSpecific ? 'course_specific' : 'general',
        if (_isCourseSpecific && _selectedCourseId != null)
          'course_id': _selectedCourseId,
      };

      await Dio().post(
        "${ApiService().baseUrl}/teacher/announcements",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) widget.onAdded();
    } catch (e) {
      debugPrint('⛔ Add Announcement Error: $e');
      String msg = 'حدث خطأ، حاول مجدداً';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          msg = (errors.values.first as List).first.toString();
        } else if (data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      if (mounted) _showSnack(msg);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    const yellow    = Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'إضافة إعلان جديد',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 20),

              _label('عنوان الإعلان', textColor),
              _textField(
                controller: _titleController,
                hint: 'أدخل عنوان الإعلان هنا',
                cardColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                textColor: textColor,
              ),
              const SizedBox(height: 16),

              _label('نص الإعلان', textColor),
              _textField(
                controller: _contentController,
                hint: 'اكتب تفاصيل الإعلان هنا...',
                cardColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                textColor: textColor,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Switch(
                    value: _isCourseSpecific,
                    onChanged: (v) => setState(() {
                      _isCourseSpecific = v;
                      if (!v) _selectedCourseId = null;
                    }),
                    activeThumbColor: yellow,
                    activeTrackColor: yellow.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text('خاص بمادة معينة',
                      style: TextStyle(color: textColor, fontSize: 14)),
                ],
              ),

              if (_isCourseSpecific) ...[
                const SizedBox(height: 12),
                _label('اختر المادة', textColor),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourseId,
                      hint: const Text('اختر المادة',
                          style: TextStyle(color: Colors.grey)),
                      isExpanded: true,
                      dropdownColor: cardColor,
                      items: _courses
                          .where((c) => c['id'] != null)
                          .map((c) => DropdownMenuItem<String>(
                                value: c['id'].toString(),
                                child: Text(c['title'] as String? ?? '',
                                    style: TextStyle(color: textColor)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCourseId = v),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _isSaving ? null : _submit,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                'نشر الإعلان',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
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

  Widget _label(String text, Color textColor) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required Color cardColor,
    required Color textColor,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
