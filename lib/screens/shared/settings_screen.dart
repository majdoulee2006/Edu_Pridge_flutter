import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/auth/login_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';

// ─── AppSettings ───────────────────────────────────────────────────────────
class AppSettings {
  static ValueNotifier<bool>   isDarkMode            = ValueNotifier(true);
  static ValueNotifier<double> fontSize              = ValueNotifier(1.0);
  static ValueNotifier<String> language              = ValueNotifier('ar');
  static ValueNotifier<bool>   isSoundsEnabled       = ValueNotifier(true);
  static ValueNotifier<bool>   isVibrationEnabled    = ValueNotifier(false);
  static ValueNotifier<bool>   isNotificationsEnabled= ValueNotifier(true);
  static ValueNotifier<Color>  primaryColor          = ValueNotifier(const Color(0xFFF2F20D));

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value             = prefs.getBool('dark_mode')             ?? true;
    fontSize.value               = prefs.getDouble('font_size')           ?? 1.0;
    language.value               = prefs.getString('language')            ?? 'ar';
    isSoundsEnabled.value        = prefs.getBool('sounds_enabled')        ?? true;
    isVibrationEnabled.value     = prefs.getBool('vibration_enabled')     ?? false;
    isNotificationsEnabled.value = prefs.getBool('notifications_enabled') ?? true;
    await syncSystemThemeFromApi();
  }

  static Future<void> syncSystemThemeFromApi() async {
    try {
      final res = await Dio().get('${ApiService().baseUrl}/system/settings');
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'];
        if (data != null && data['primary_color'] != null) {
          final hexString = data['primary_color'].toString().replaceAll('#', '');
          final colorInt = int.parse('FF$hexString', radix: 16);
          primaryColor.value = Color(colorInt);
        }
      }
    } catch (e) {
      debugPrint("System theme sync error: $e");
    }
  }

  static Future<void> setDarkMode(bool v) async {
    isDarkMode.value = v;
    (await SharedPreferences.getInstance()).setBool('dark_mode', v);
  }

  static Future<void> setFontSize(double v) async {
    fontSize.value = v;
    (await SharedPreferences.getInstance()).setDouble('font_size', v);
  }

  static Future<void> setLanguage(String v) async {
    language.value = v;
    (await SharedPreferences.getInstance()).setString('language', v);
  }

  static Future<void> setSoundsEnabled(bool v) async {
    isSoundsEnabled.value = v;
    (await SharedPreferences.getInstance()).setBool('sounds_enabled', v);
    if (v) SystemSound.play(SystemSoundType.click);
  }

  static Future<void> setVibrationEnabled(bool v) async {
    isVibrationEnabled.value = v;
    (await SharedPreferences.getInstance()).setBool('vibration_enabled', v);
    if (v) HapticFeedback.mediumImpact();
  }

  static Future<void> setNotificationsEnabled(bool v) async {
    isNotificationsEnabled.value = v;
    (await SharedPreferences.getInstance()).setBool('notifications_enabled', v);
  }

  static void triggerHaptic() {
    if (isVibrationEnabled.value) HapticFeedback.lightImpact();
  }

  static void triggerSound() {
    if (isSoundsEnabled.value) SystemSound.play(SystemSoundType.click);
  }
}

// ─── SettingsScreen ────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final String profileImageUrl;
  final VoidCallback? onProfileTap;

  const SettingsScreen({
    super.key,
    this.userName        = "",
    this.userRole        = "",
    this.profileImageUrl = '',
    this.onProfileTap,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String _userRole = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _userName  = widget.userName;
    _userRole  = widget.userRole;
    _avatarUrl = widget.profileImageUrl;
    if (_userName.isEmpty) _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _userRole = _mapRole(prefs.getString('user_role') ?? prefs.getString('role') ?? '');
      _avatarUrl = widget.profileImageUrl.isNotEmpty
          ? widget.profileImageUrl
          : (prefs.getString('avatar') ?? '');
    });
  }

  String _mapRole(String role) {
    switch (role) {
      case 'student':         return 'طالب';
      case 'teacher':         return 'معلم';
      case 'parent':          return 'ولي أمر';
      case 'department_head': return 'رئيس قسم';
      case 'affairs_officer': return 'موظف شؤون';
      default:                return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<double>(
        valueListenable: AppSettings.fontSize,
        builder: (context, fontScale, _) => ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, lang, _) {
            final isAr      = lang == 'ar';
            final bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
            final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black;
            final subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
                child: Scaffold(
                  backgroundColor: bgColor,
                  appBar: AppBar(
                    backgroundColor: cardColor,
                    elevation: 0,
                    centerTitle: true,
                    title: Text(isAr ? "الإعدادات" : "Settings",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileCard(context, cardColor, textColor, subColor, isAr),
                        const SizedBox(height: 25),

                        _sectionTitle(isAr ? "المظهر" : "Appearance", subColor),
                        _fontSizeSlider(cardColor, textColor, isAr),
                        _switchTile(
                          icon: Icons.dark_mode_outlined,
                          title: isAr ? "الوضع الداكن" : "Dark Mode",
                          value: isDark,
                          onChanged: (v) { AppSettings.setDarkMode(v); AppSettings.triggerHaptic(); },
                          cardColor: cardColor, textColor: textColor,
                        ),

                        const SizedBox(height: 25),
                        _sectionTitle(isAr ? "الإشعارات والصوت" : "Notifications & Sound", subColor),

                        ValueListenableBuilder<bool>(
                          valueListenable: AppSettings.isNotificationsEnabled,
                          builder: (_, notif, __) => _switchTile(
                            icon: Icons.notifications_none_outlined,
                            title: isAr ? "تفعيل الإشعارات" : "Notifications",
                            value: notif,
                            onChanged: (v) { AppSettings.setNotificationsEnabled(v); AppSettings.triggerHaptic(); },
                            cardColor: cardColor, textColor: textColor,
                          ),
                        ),

                        ValueListenableBuilder<bool>(
                          valueListenable: AppSettings.isSoundsEnabled,
                          builder: (_, sounds, __) => _switchTile(
                            icon: Icons.volume_up_outlined,
                            title: isAr ? "الأصوات" : "Sounds",
                            value: sounds,
                            onChanged: (v) => AppSettings.setSoundsEnabled(v),
                            cardColor: cardColor, textColor: textColor,
                          ),
                        ),

                        ValueListenableBuilder<bool>(
                          valueListenable: AppSettings.isVibrationEnabled,
                          builder: (_, vib, __) => _switchTile(
                            icon: Icons.vibration_outlined,
                            title: isAr ? "الاهتزاز" : "Vibration",
                            value: vib,
                            onChanged: (v) => AppSettings.setVibrationEnabled(v),
                            cardColor: cardColor, textColor: textColor,
                          ),
                        ),



                        const SizedBox(height: 40),
                        _appInfoSection(textColor, subColor),
                        const SizedBox(height: 30),
                        _logoutButton(context, isAr),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, Color cardColor, Color textColor, Color subColor, bool isAr) {
    return InkWell(
      onTap: widget.onProfileTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFCCAA00),
              backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(ApiService.fixMediaUrl(_avatarUrl)!) : null,
              child: _avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName.isNotEmpty ? _userName : 'مستخدم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_userRole, style: TextStyle(color: subColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(isAr ? Icons.arrow_back_ios : Icons.arrow_back, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Font Size Slider ──────────────────────────────────────────────────────
  Widget _fontSizeSlider(Color cardColor, Color textColor, bool isAr) {
    return ValueListenableBuilder<double>(
      valueListenable: AppSettings.fontSize,
      builder: (_, scale, __) => Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(children: [
              Icon(Icons.text_fields, color: textColor),
              const SizedBox(width: 10),
              Text(isAr ? "حجم الخط" : "Font Size", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ]),
            Slider(
              value: scale,
              min: 0.8, max: 1.2, divisions: 2,
              activeColor: const Color(0xFFFFCC00),
              inactiveColor: Colors.grey[300],
              onChanged: (v) => AppSettings.setFontSize(v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? "صغير" : "Small", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(isAr ? "متوسط" : "Medium", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(isAr ? "كبير" : "Large", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Switch Tile ───────────────────────────────────────────────────────────
  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        trailing: Switch(
          value: value,
          activeThumbColor: Colors.black,
          activeTrackColor: const Color(0xFFFFCC00),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── App Info ──────────────────────────────────────────────────────────────
  Widget _appInfoSection(Color textColor, Color subColor) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFCC00), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.school, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 15),
          Text("Edu-Bridge", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 1),
          Text("التطبيق الرسمي لإدارة شؤون الطلاب\nوالمحاضرات والواجبات.",
              textAlign: TextAlign.center, style: TextStyle(color: subColor, fontSize: 13, height: 1.5)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("Version 1.0.2", style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Logout Button ─────────────────────────────────────────────────────────
  Widget _logoutButton(BuildContext context, bool isAr) {
    return InkWell(
      onTap: () {
        AppSettings.triggerHaptic();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 10),
                Text(isAr ? "تسجيل الخروج" : "Logout",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
              ]),
              content: Text(isAr
                  ? "هل أنت متأكد أنك تريد تسجيل الخروج من الحساب؟"
                  : "Are you sure you want to log out?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isAr ? "لا، تراجع" : "Cancel",
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    // مسح بيانات الجلسة
                    NotificationPolling.stop();
                    await NotificationPolling.clearLastShownId();

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (token.isNotEmpty) {
                      try {
                        await Dio().post(
                          "${ApiService().baseUrl}/logout",
                          options: Options(
                            headers: {
                              "Accept": "application/json",
                              "Authorization": "Bearer $token",
                            },
                          ),
                        );
                      } catch (e) {
                        debugPrint("خطأ أثناء تسجيل الخروج من السيرفر: $e");
                      }
                    }

                    await prefs.remove('token');
                    await prefs.remove('role');
                    await prefs.remove('user_role');
                    await prefs.remove('user_id');
                    await prefs.remove('user_name');
                    await prefs.remove('parent_id');
                    await prefs.remove('selected_student_id');
                    await prefs.remove('selected_student_name');
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  child: Text(isAr ? "نعم، خروج" : "Yes, Logout",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 10),
            Text(isAr ? "تسجيل الخروج" : "Logout",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }



  Widget _sectionTitle(String title, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: subColor)),
    );
  }
}
