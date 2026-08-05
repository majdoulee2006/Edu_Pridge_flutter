import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'teacher_home.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/editing_screens/edit_phone_screen.dart';
import '../shared/editing_screens/edit_email_screen.dart';
import '../shared/editing_screens/edit_password_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _uploadingAvatar = false;

  String _fullName       = '';
  String _email          = '';
  String _phone          = '';
  String _specialization = '';
  String? _avatarUrl;
  List<String> _courseNames = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchProfile(), _fetchCourses()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/profile",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        _fullName       = d['full_name']      as String? ?? '';
        _email          = d['email']          as String? ?? '';
        _phone          = d['phone']          as String? ?? '';
        _specialization = d['specialization'] as String? ?? '';
        _avatarUrl      = ApiService.fixMediaUrl(d['avatar'] as String?);
      }
    } catch (e) {
      debugPrint('⛔ Profile Error: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(picked.path,
            filename: 'avatar.jpg'),
      });
      final res = await Dio().post(
        "${ApiService().baseUrl}/teacher/profile/avatar",
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() => _avatarUrl = ApiService.fixMediaUrl(res.data['avatar'] as String?));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الصورة الشخصية',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFFFFCC00),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('⛔ Avatar upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع الصورة، حاول مجدداً',
                style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
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
        final data = res.data['data'] as List<dynamic>? ?? [];
        final seen = <String>{};
        _courseNames = data
            .where((c) => c['title'] != null)
            .map((c) => c['title'].toString())
            .where(seen.add)
            .toList();
      }
    } catch (e) {
      debugPrint('⛔ Courses Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('الملف الشخصي',
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(
                    userName: _fullName,
                    userRole: _specialization.isNotEmpty ? _specialization : 'مدرس',
                    profileImageUrl: _avatarUrl ?? '',
                    onProfileTap: () => Navigator.pop(context),
                  ))),
            ),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildProfileHeader(textColor),
                        const SizedBox(height: 30),

                        // ── معلومات التواصل ──
                        _buildSectionTitle("معلومات التواصل", textColor),
                        _buildInfoCard(cardColor, [
                          _buildClickableRow(
                            label: "رقم الهاتف",
                            value: _phone.isNotEmpty ? _phone : 'غير محدد',
                            icon: Icons.phone_android_rounded,
                            color: Colors.green,
                            textColor: textColor,
                            onTap: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const EditPhoneScreen()),
                              );
                              if (result == true && mounted) _loadAll();
                            },
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "البريد الإلكتروني",
                            value: _email.isNotEmpty ? _email : 'غير محدد',
                            icon: Icons.alternate_email_rounded,
                            color: Colors.blue,
                            textColor: textColor,
                          ),
                        ]),

                        const SizedBox(height: 25),

                        // ── البيانات الأكاديمية (مقفولة) ──
                        _buildSectionTitle("البيانات الأكاديمية", textColor),
                        _buildInfoCard(cardColor, [
                          _buildStaticRow(
                            label: "التخصص",
                            value: _specialization.isNotEmpty
                                ? _specialization
                                : 'غير محدد',
                            icon: Icons.school_rounded,
                            color: Colors.purple,
                            textColor: textColor,
                          ),
                          if (_courseNames.isNotEmpty) ...[
                            _buildDivider(textColor),
                            _buildCoursesRow(textColor),
                          ],
                        ]),

                        const SizedBox(height: 25),

                        // ── الأمان والإعدادات ──
                        _buildSectionTitle("الأمان والإعدادات", textColor),
                        _buildClickableSettingCard(
                          title: "تغيير كلمة المرور",
                          icon: Icons.lock_reset_rounded,
                          color: Colors.redAccent,
                          cardColor: cardColor,
                          textColor: textColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditPasswordScreen()),
                          ),
                        ),

                        const SizedBox(height: 150),
                      ],
                    ),
                  ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────

  Widget _buildProfileHeader(Color textColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC00), width: 3),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (_avatarUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null),
                ),
              ),
            ),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFCC00),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          _fullName.isNotEmpty ? _fullName : '—',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Cairo'),
        ),
        Text(
          _specialization.isNotEmpty ? _specialization : 'مدرس',
          style: const TextStyle(
              color: Colors.grey, fontSize: 14, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 10),
        child: Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildInfoCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(Color textColor) {
    return Divider(
        height: 1,
        color: textColor.withValues(alpha: 0.1),
        indent: 20,
        endIndent: 20);
  }

  Widget _buildClickableRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildIconBubble(icon, color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Cairo')),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Cairo')),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded,
                color: color.withValues(alpha: 0.6), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildIconBubble(icon, color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Cairo')),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: 'Cairo')),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCoursesRow(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconBubble(Icons.menu_book_rounded, Colors.orange),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("المواد الدراسية",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Cairo')),
                    Text("الفصل الحالي",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontFamily: 'Cairo')),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _courseNames
                .map((name) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo')),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableSettingCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            _buildIconBubble(icon, color),
            const SizedBox(width: 15),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                    fontFamily: 'Cairo')),
            const Spacer(),
            const Icon(Icons.arrow_back,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBubble(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
