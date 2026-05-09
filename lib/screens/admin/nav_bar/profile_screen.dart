import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import '../../../core/constants/app_colors.dart';

// استيراد شاشات التعديل (نفسها المستخدمة في ملف الطالب)
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
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
  // يمكنك إضافة تحميل بيانات حقيقية لاحقاً
  Map<String, dynamic> adminData = {
    'name': 'المدير العام',
    'email': 'admin@edubridge.com',
    'phone': '+970 599 000 000',
    'role': 'Super Admin',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : AppColors.background;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          title: Text(
            'الملف الشخصي للمدير',
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

                  _buildSectionTitle('بيانات الحساب الإداري'),
                  _buildInfoCard([
                    _InfoRow(title: 'الاسم الكامل', value: adminData['name'], icon: Icons.person_outline),
                    _InfoRow(
                      title: 'البريد الإلكتروني',
                      value: adminData['email'],
                      icon: Icons.email_outlined,
                      canEdit: true,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditEmailScreen()));
                        // يمكنك إضافة تحديث البيانات هنا لاحقاً
                      },
                    ),
                    _InfoRow(
                      title: 'رقم التواصل',
                      value: adminData['phone'],
                      icon: Icons.phone_android,
                      canEdit: true,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPhoneScreen()));
                      },
                    ),
                    _InfoRow(title: 'تاريخ الميلاد', value: '1990-01-01', icon: Icons.calendar_month_outlined, isLocked: true),
                    _InfoRow(title: 'الجنس', value: 'ذكر', icon: Icons.male_outlined, isLocked: true),
                  ], cardColor, textColor, isDark),

                  _buildSectionTitle('الصلاحيات والنظام'),
                  _buildInfoCard([
                    _InfoRow(title: 'نوع الحساب', value: adminData['role'], icon: Icons.admin_panel_settings_outlined),
                    _InfoRow(title: 'آخر تسجيل دخول', value: 'اليوم، 10:30 صباحاً', icon: Icons.access_time),
                  ], cardColor, textColor, isDark),

                  _buildSectionTitle('الإعدادات والأمان'),
                  _buildSettingsItem('تغيير كلمة المرور', Icons.lock_reset, cardColor, textColor, isDark),
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
                MaterialPageRoute(builder: (context) => const AdminNotificationsScreen()),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminMessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader(Color bgColor, Color textColor, bool isDark) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber, width: 3),
          ),
          child: const Icon(Icons.admin_panel_settings, size: 70, color: Colors.amber),
        ),
        const SizedBox(height: 15),
        Text(
          'أهلاً بك، ${adminData['name']}',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        _buildChip('لوحة التحكم الكاملة', isDark ? Colors.amber.withOpacity(0.2) : const Color(0xFFFFF8E1), Colors.amber),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows, Color cardColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          bool isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            children: [
              ListTile(
                onTap: row.onTap,
                leading: Icon(row.icon, color: isDark ? Colors.amber : Colors.blueGrey),
                title: Text(row.title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(row.value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                trailing: row.canEdit
                    ? const Icon(Icons.edit_outlined, size: 20, color: Colors.amber)
                    : (row.isLocked ? const Icon(Icons.lock_outline, size: 20, color: Colors.grey) : null),
              ),
              if (!isLast)
                Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, Color cardColor, Color textColor, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPasswordScreen()));
      },
      child: Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: Icon(icon, color: textColor),
          title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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