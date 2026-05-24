import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/accounts/accounts_management_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import '../../../widgets/boss_center_icon.dart';

class BossProfileScreen extends StatefulWidget {
  const BossProfileScreen({super.key});

  @override
  State<BossProfileScreen> createState() => _BossProfileScreenState();
}

class _BossProfileScreenState extends State<BossProfileScreen> {
  String  _userName        = "جارِ التحميل...";
  String  _userRole        = "رئيس القسم الأكاديمي";
  String  _email           = "";
  String  _phone           = "";
  String  _department      = "";
  String  _lastLogin       = "";
  String? _avatarUrl;
  bool    _isLoading       = true;
  bool    _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Save last login if not set yet in this session
      if (prefs.getString('last_login_at') == null) {
        final now = DateTime.now();
        final formatted =
            '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        await prefs.setString('last_login_at', formatted);
      }

      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/profile",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _userName   = d['full_name']  as String? ?? d['name'] as String? ?? '';
            _email      = d['email']      as String? ?? '';
            _phone      = d['phone']      as String? ?? '';
            _department = d['department'] as String? ?? '';
            _userRole   = d['role_label'] as String? ?? "رئيس القسم الأكاديمي";
            _avatarUrl  = ApiService.fixMediaUrl(d['avatar'] as String?);
            _lastLogin  = prefs.getString('last_login_at') ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('⛔ Boss Profile Error: $e');
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userName  = prefs.getString('user_name') ?? "رئيس القسم";
          _lastLogin = prefs.getString('last_login_at') ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().post(
        "${ApiService().baseUrl}/profile/avatar",
        data: FormData.fromMap({'avatar': await MultipartFile.fromFile(picked.path, filename: 'avatar.jpg')}),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true && mounted) {
        setState(() => _avatarUrl = ApiService.fixMediaUrl(res.data['avatar'] as String?));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تحديث الصورة الشخصية', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFCCAA00),
        ));
      }
    } catch (e) {
      debugPrint('⛔ Avatar upload: $e');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = Theme.of(context).scaffoldBackgroundColor;
    final cardColor   = Theme.of(context).cardColor;
    final textColor   = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textColor, isDark),
        body: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFCCAA00)))
            else
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildProfileHeader(textColor),
                    const SizedBox(height: 30),

                    _buildSectionTitle("معلومات التواصل", textColor),
                    _buildInfoCard(cardColor, [
                      _buildClickableRow(
                        "رقم الهاتف", _phone.isNotEmpty ? _phone : "غير محدد",
                        Icons.phone_android_rounded, Colors.green, textColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPhoneScreen()))
                            .then((_) => _fetchProfile()),
                      ),
                      _buildDivider(textColor),
                      _buildClickableRow(
                        "البريد الإلكتروني", _email.isNotEmpty ? _email : "غير محدد",
                        Icons.alternate_email_rounded, Colors.blue, textColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditEmailScreen()))
                            .then((_) => _fetchProfile()),
                      ),
                    ]),

                    const SizedBox(height: 25),
                    _buildSectionTitle("المعلومات الشخصية", textColor),
                    _buildInfoCard(cardColor, [
                      _buildStaticRow(
                        "القسم", _department.isNotEmpty ? _department : "غير محدد",
                        Icons.business_outlined, Colors.purple, textColor,
                      ),
                    ]),

                    const SizedBox(height: 25),
                    _buildSectionTitle("الصلاحيات والنظام", textColor),
                    _buildInfoCard(cardColor, [
                      _buildStaticRow(
                        "نوع الحساب", "رئيس القسم",
                        Icons.manage_accounts_outlined, const Color(0xFFCCAA00), textColor,
                      ),
                      _buildDivider(textColor),
                      _buildStaticRow(
                        "آخر تسجيل دخول", _lastLogin.isNotEmpty ? _lastLogin : "غير متاح",
                        Icons.access_time_rounded, Colors.teal, textColor,
                      ),
                    ]),

                    const SizedBox(height: 25),
                    _buildSectionTitle("الإعدادات والأمان", textColor),
                    _buildInfoCard(cardColor, [
                      _buildClickableRow(
                        "كلمة المرور", "••••••••",
                        Icons.lock_reset_rounded, Colors.redAccent, textColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPasswordScreen())),
                      ),
                    ]),

                    const SizedBox(height: 150),
                  ],
                ),
              ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsManagementScreen())),
                child: const Boss_Center_Icon(),
              ),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossMessageScreen())),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("الملف الشخصي", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SettingsScreen(
              userName: _userName,
              userRole: "رئيس القسم الأكاديمي",
              onProfileTap: () => Navigator.pop(context),
            ),
          )),
        ),
      ],
    );
  }

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
                  border: Border.all(color: const Color(0xFFCCAA00), width: 3),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (_avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null),
                ),
              ),
            ),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFCCAA00),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(_userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        Text(_userRole, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
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

  Widget _buildClickableRow(String label, String value, IconData icon, Color color, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildColoredIcon(icon, color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow(String label, String value, IconData icon, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildColoredIcon(icon, color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildColoredIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _buildDivider(Color textColor) {
    return Divider(height: 1, color: textColor.withValues(alpha: 0.08), indent: 20, endIndent: 20);
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 10),
        child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }
}
