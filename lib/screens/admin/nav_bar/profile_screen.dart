import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import '../../../core/constants/app_colors.dart';

// استيراد شاشات التعديل (نفسها المستخدمة في ملف الطالب)
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';

// استيراد الصفحات الأخرى للتنقل
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Map<String, dynamic> adminData = {
    'name': 'المدير العام',
    'email': 'admin@edubridge.com',
    'phone': '+970 599 000 000',
    'role': 'Super Admin',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : AppColors.background;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(
            isAr ? 'الملف الشخصي للمدير' : 'Admin Profile',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAdminHeader(bgColor, textColor, isDark),
                  const SizedBox(height: 30),

                  _buildSectionTitle(
                    isAr ? 'بيانات الحساب الإداري' : 'Admin Account Info',
                  ),
                  _buildInfoCard([
                    _InfoRow(
                      title: isAr ? 'الاسم الكامل' : 'Full Name',
                      value: isAr ? (adminData['name'] ?? 'المدير العام') : 'General Manager',
                      icon: Icons.person_outline,
                    ),
                    _InfoRow(
                      title: isAr ? 'البريد الإلكتروني' : 'Email Address',
                      value: adminData['email'],
                      icon: Icons.email_outlined,
                      isLocked: true,
                    ),
                    _InfoRow(
                      title: isAr ? 'رقم التواصل' : 'Contact Number',
                      value: adminData['phone'],
                      icon: Icons.phone_android,
                      canEdit: true,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditPhoneScreen(),
                          ),
                        );
                      },
                    ),
                    _InfoRow(
                      title: isAr ? 'تاريخ الميلاد' : 'Date of Birth',
                      value: '1990-01-01',
                      icon: Icons.calendar_month_outlined,
                      isLocked: true,
                    ),
                    _InfoRow(
                      title: isAr ? 'الجنس' : 'Gender',
                      value: isAr ? 'ذكر' : 'Male',
                      icon: Icons.male_outlined,
                      isLocked: true,
                    ),
                  ], cardColor, textColor, isDark),

                  _buildSectionTitle(
                    isAr ? 'الصلاحيات والنظام' : 'Permissions & System',
                  ),
                  _buildInfoCard([
                    _InfoRow(
                      title: isAr ? 'نوع الحساب' : 'Account Type',
                      value: adminData['role'],
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                    _InfoRow(
                      title: isAr ? 'آخر تسجيل دخول' : 'Last Login',
                      value: isAr ? 'اليوم، 10:30 صباحاً' : 'Today, 10:30 AM',
                      icon: Icons.access_time,
                    ),
                  ], cardColor, textColor, isDark),

                  _buildSectionTitle(
                    isAr ? 'الإعدادات والأمان' : 'Settings & Security',
                  ),
                  _buildSettingsItem(
                    isAr ? 'تغيير كلمة المرور' : 'Change Password',
                    Icons.lock_reset,
                    cardColor,
                    textColor,
                    isDark,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
              ),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminMessagesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader(Color bgColor, Color textColor, bool isDark) {
    final displayName = isAr
        ? (adminData['name'] ?? 'المدير العام')
        : 'General Manager';

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.amber.withValues(alpha: 0.1)
                : Colors.amber.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 3),
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            size: 70,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          isAr ? 'أهلاً بك، $displayName' : 'Welcome, $displayName',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildChip(
          isAr ? 'لوحة التحكم الكاملة' : 'Full Control Panel',
          isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFFF8E1),
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    List<_InfoRow> rows,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          bool isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            children: [
              ListTile(
                onTap: row.onTap,
                leading: Icon(
                  row.icon,
                  color: isDark ? Colors.amber : Colors.blueGrey,
                ),
                title: Text(
                  row.title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                subtitle: Text(
                  row.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                trailing: row.canEdit
                    ? const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.amber,
                      )
                    : (row.isLocked
                        ? const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Colors.grey,
                          )
                        : null),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem(
    String title,
    IconData icon,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditPasswordScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          leading: Icon(icon, color: textColor),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          trailing: Icon(
            isAr ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        right: isAr ? 8 : 0,
        left: isAr ? 0 : 8,
      ),
      child: Align(
        alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final String title;
  final String value;
  final IconData icon;
  final bool canEdit;
  final bool isLocked;
  final VoidCallback? onTap;

  _InfoRow({
    required this.title,
    required this.value,
    required this.icon,
    this.canEdit = false,
    this.isLocked = false,
    this.onTap,
  });
}