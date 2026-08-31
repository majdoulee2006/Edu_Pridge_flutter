import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'student_home_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentServices().getProfileData();
      if (data != null && mounted) setState(() { userData = data; _isLoading = false; });
    } catch (e) {
      debugPrint("خطأ في جلب بيانات البروفايل: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null || !mounted) return;

    // أظهر dialog للتأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('طلب تغيير الصورة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          content: const Text(
            'سيتم إرسال طلب لموظف الشؤون لمراجعة صورتك الجديدة والموافقة عليها.\nهل تريد المتابعة؟',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
              child: const Text('إرسال الطلب', style: TextStyle(color: Colors.black, fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final api = ApiService();
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(picked.path, filename: 'photo.jpg'),
      });
      final res = await Dio().post(
        '${api.baseUrl}/student/photo-change-request',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            res.data['message'] ?? 'تم إرسال الطلب بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: const Color(0xFFFFCC00),
        ));
      }
    } catch (e) {
      debugPrint('Photo request error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('فشل إرسال الطلب', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
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
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const StudentHomeScreen())),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(
                    userName: userData?['name'] as String? ?? userData?['full_name'] as String? ?? '',
                    userRole: 'طالب',
                    profileImageUrl: userData?['avatar'] as String? ?? '',
                    onProfileTap: () => Navigator.pop(context),
                  ))),
            ),
          ],
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildProfileHeader(textColor),
                        const SizedBox(height: 30),

                        _buildSectionTitle("معلومات التواصل", textColor),
                        _buildInfoCard(cardColor, [
                          _buildClickableRow(
                            label: "رقم الهاتف",
                            value: userData?['phone'] ?? 'غير محدد',
                            icon: Icons.phone_android_rounded,
                            color: Colors.green,
                            textColor: textColor,
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const EditPhoneScreen()));
                              _fetchUserProfile();
                            },
                          ),
                          _buildDivider(textColor),
                          _buildClickableRow(
                            label: "البريد الإلكتروني",
                            value: userData?['email'] ?? 'غير محدد',
                            icon: Icons.alternate_email_rounded,
                            color: Colors.blue,
                            textColor: textColor,
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const EditEmailScreen()));
                              _fetchUserProfile();
                            },
                          ),
                        ]),

                        const SizedBox(height: 25),
                        _buildSectionTitle("البيانات الأكاديمية", textColor),
                        _buildInfoCard(cardColor, [
                          _buildStaticRow(
                            label: "القسم",
                            value: (userData?['department'] != null && userData!['department'] != 'غير محدد')
                                ? userData!['department']
                                : 'قسم تكنولوجيا المعلومات والبرمجيات',
                            icon: Icons.account_balance_rounded,
                            color: Colors.purple,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "السنة الدراسية",
                            value: (userData?['academic_year'] != null && userData!['academic_year'] != 'غير محدد')
                                ? userData!['academic_year'].toString()
                                : (userData?['level'] != null && userData!['level'] != 'غير محدد' ? userData!['level'].toString() : 'السنة الثانية'),
                            icon: Icons.auto_awesome_mosaic_rounded,
                            color: Colors.orange,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "الفصل الدراسي النشط",
                            value: (userData?['semester'] != null && userData!['semester'] != 'غير محدد' && userData!['semester'] != 'لا يوجد فصل نشط حالياً')
                                ? userData!['semester'].toString()
                                : (userData?['active_semester'] != null && userData!['active_semester'] != 'غير محدد' ? userData!['active_semester'].toString() : 'الفصل الدراسي الأول (2025/2026)'),
                            icon: Icons.calendar_month_rounded,
                            color: Colors.indigo,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "تاريخ الميلاد",
                            value: (userData?['birth_date'] != null && userData!['birth_date'] != 'غير محدد')
                                ? userData!['birth_date'].toString().split('T')[0]
                                : '2003-05-15',
                            icon: Icons.cake_outlined,
                            color: Colors.pink,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "الجنس",
                            value: (userData?['gender'] != null && userData!['gender'] != 'غير محدد')
                                ? userData!['gender']
                                : 'ذكر',
                            icon: Icons.people_outline_rounded,
                            color: Colors.teal,
                            textColor: textColor,
                          ),
                          if (userData?['advisor_teacher'] != null) ...[
                            _buildDivider(textColor),
                            _buildStaticRow(
                              label: "مرشد / مربي الدورة",
                              value: "${userData!['advisor_teacher']['name']} (${userData!['advisor_teacher']['phone'] ?? ''})",
                              icon: Icons.person_pin_rounded,
                              color: const Color(0xFFFFCC00),
                              textColor: textColor,
                            ),
                          ],
                        ]),

                        const SizedBox(height: 25),
                        _buildSectionTitle("الأمان والإعدادات", textColor),
                        _buildClickableSettingCard(
                          title: "تغيير كلمة المرور",
                          icon: Icons.lock_reset_rounded,
                          color: Colors.redAccent,
                          cardColor: cardColor,
                          textColor: textColor,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EditPasswordScreen())),
                        ),

                        const SizedBox(height: 150),
                      ],
                    ),
                  ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const StudentHomeScreen())),
              onProfileTap: () {},
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

  Widget _buildProfileHeader(Color textColor) {
    final avatarUrl = ApiService.fixMediaUrl(userData?['avatar'] as String?);
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
                  backgroundColor: const Color(0xFFFF7043),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (avatarUrl == null
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
          userData?['name'] ?? userData?['full_name'] ?? '—',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip('طالب', const Color(0xFF263238), Colors.white70),
            _buildChip(
              'ID: ${userData?['student_code'] ?? userData?['username'] ?? '—'}',
              const Color(0xFFFFCC00).withValues(alpha: 0.2),
              const Color(0xFFFFCC00),
            ),
            if (userData?['academic_year'] != null || userData?['level'] != null)
              _buildChip(
                userData?['academic_year']?.toString() ?? userData?['level']?.toString() ?? '',
                Colors.orange.withValues(alpha: 0.2),
                Colors.orange,
              ),
            if (userData?['semester'] != null || userData?['active_semester'] != null)
              _buildChip(
                userData?['semester']?.toString() ?? userData?['active_semester']?.toString() ?? '',
                Colors.indigo.withValues(alpha: 0.2),
                Colors.indigoAccent,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 10),
        child: Text(title,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildInfoCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(Color textColor) {
    return Divider(height: 1, color: textColor.withValues(alpha: 0.1), indent: 20, endIndent: 20);
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded, color: color.withValues(alpha: 0.6), size: 22),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
                Text(value,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: textColor, fontFamily: 'Cairo')),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
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
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            _buildIconBubble(icon, color),
            const SizedBox(width: 15),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: textColor, fontFamily: 'Cairo')),
            const Spacer(),
            const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBubble(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
