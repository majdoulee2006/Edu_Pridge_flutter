import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
// ✅ تم إضافة استدعاء واجهة تغيير كلمة المرور
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
// استدعاء الصفحات للتنقل
import 'student_home_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
// استدعاء واجهات التعديل من المجلد الجديد

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // متغير لحفظ تاريخ الميلاد وتحديثه على الشاشة
  String dob = '15 مايو 2002';

  // دالة فتح التقويم مع شرط العمر (18 سنة فما فوق)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    // حساب أقصى تاريخ مسموح (اليوم الحالي ناقص 18 سنة)
    final DateTime maxDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1950),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dob = '${picked.year}/${picked.month}/${picked.day}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ),
            ),
          ),
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(),
                  const SizedBox(height: 30),

                  _buildSectionTitle('معلومات التواصل'),
                  _buildInfoCard([
                    // الانتقال لواجهة تعديل الهاتف
                    _InfoRow(
                      title: 'رقم الهاتف',
                      value: '4567 123 050',
                      icon: Icons.phone_android,
                      isEditable: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditPhoneScreen(),
                          ),
                        );
                      },
                    ),
                    // ✅ تم تفعيل الضغط للانتقال لواجهة تعديل الإيميل
                    _InfoRow(
                      title: 'البريد الإلكتروني',
                      value: 'ahmed.ali@institute.edu',
                      icon: Icons.email,
                      isEditable: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditEmailScreen(),
                          ),
                        );
                      },
                    ),
                  ]),

                  _buildSectionTitle('البيانات الأكاديمية'),
                  _buildInfoCard([
                    _InfoRow(
                      title: 'القسم',
                      value: 'هندسة الحاسوب',
                      icon: Icons.school,
                      isEditable: false,
                    ),
                    _InfoRow(
                      title: 'السنة الدراسية / الفرع',
                      value: 'السنة الثالثة',
                      icon: Icons.account_tree_outlined,
                      isEditable: false,
                    ),
                  ]),

                  _buildSectionTitle('تفاصيل شخصية'),
                  _buildInfoCard([
                    _InfoRow(
                      title: 'تاريخ الميلاد',
                      value: dob,
                      icon: Icons.cake_outlined,
                      isEditable: true,
                      onTap: () => _selectDate(context),
                    ),
                    _InfoRow(
                      title: 'الجنس',
                      value: 'ذكر',
                      icon: Icons.people_outline,
                      isEditable: false,
                    ),
                  ]),

                  _buildSectionTitle('الإعدادات'),
                  _buildSettingsItem(),
                ],
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: _buildFloatingBottomNavBar(context),
            ),

            Positioned.fill(child: const StudentSpeedDial()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 65,
                backgroundColor: Color(0xFFFF7043),
                child: Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          'أحمد محمد علي',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChip('طالب', Colors.grey.shade100, AppColors.textGrey),
            const SizedBox(width: 8),
            _buildChip(
              'ID: 202300159',
              const Color(0xFFFCF9D1),
              AppColors.textDark,
            ),
          ],
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

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          bool isLast = entry.key == rows.length - 1;
          return InkWell(
            onTap: entry.value.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entry.value.icon,
                          color: Colors.black87,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.title,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.value.value,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        entry.value.isEditable
                            ? Icons.edit
                            : Icons.lock_outline,
                        color: entry.value.isEditable
                            ? AppColors.accent
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem() {
    return InkWell(
      // ✅ تم إضافة InkWell لتفعيل الضغط والانتقال للواجهة
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditPasswordScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Colors.black87, size: 22),
            ),
            const SizedBox(width: 15),
            const Text(
              'تغيير كلمة المرور',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            'الرئيسية',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ),
            ),
          ),
          _buildNavItem(Icons.person, 'الملف الشخصي', true, () {}),
          const SizedBox(width: 70),
          _buildNavItem(
            Icons.notifications_none,
            'الإشعارات',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          _buildNavItem(
            Icons.chat_bubble_outline,
            'المراسلات',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            ),
            badgeCount: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.textDark : Colors.grey,
                size: 26,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE57373),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.textDark : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String title;
  final String value;
  final IconData icon;
  final bool isEditable;
  final VoidCallback? onTap;

  _InfoRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.isEditable,
    this.onTap,
  });
}
