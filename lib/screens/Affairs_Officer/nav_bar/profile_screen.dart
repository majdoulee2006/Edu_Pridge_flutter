import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';

// استيراد شاشات التعديل
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
class AffairsOfficerProfileScreen extends StatefulWidget {
  const AffairsOfficerProfileScreen({super.key});

  @override
  State<AffairsOfficerProfileScreen> createState() => _AffairsOfficerProfileScreenState();
}

class _AffairsOfficerProfileScreenState extends State<AffairsOfficerProfileScreen> {
  // بيانات موظف الشؤون
  Map<String, dynamic> officerData = {
    'name': 'محمد المحمد',
    'email': 'officer@edu.pridge',
    'phone': '0999999999',
    'birthDate': '1995-03-15',
    'gender': 'ذكر',
    'role': 'موظف شؤون',
    'lastLogin': '2026-05-21 14:30',
  };

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان SettingsScreen بالضبط
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // --- الهيدر - العنوان بالمنتصف ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Text(
                          "الملف الشخصي",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- المحتوى القابل للتمرير ---
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // --- صورة المستخدم ---
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF7043),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 70,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCC00),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: bgColor, width: 2),
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
                          ),

                          const SizedBox(height: 15),

                          // --- الاسم ---
                          Center(
                            child: Text(
                              officerData['name'],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // --- الدور والـ ID - موظف الشؤون على اليمين ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // موظف الشؤون على اليمين
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  officerData['role'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    fontFamily: 'Noto Sans Arabic',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ID على اليسار
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF555000) : const Color(0xFFFCF9D1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "ID: 2024105",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                                    fontFamily: 'Noto Sans Arabic',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // ═══════════════════════════════════════
                          // القسم الأول: البيانات الشخصية
                          // ═══════════════════════════════════════
                          _buildSectionTitle("البيانات الشخصية", subColor),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            cardColor: cardColor,
                            isDark: isDark,
                            children: [
                              _buildInfoRow(
                                icon: Icons.person_outline,
                                iconColor: Colors.orange,
                                label: 'الاسم',
                                value: officerData['name'],
                                textColor: textColor,
                                trailingIcon: Icons.lock_outline,
                              ),
                              _buildEditableRow(
                                icon: Icons.email_outlined,
                                iconColor: Colors.blue,
                                label: 'البريد الإلكتروني',
                                value: officerData['email'],
                                textColor: textColor,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const EditEmailScreen()),
                                  );
                                },
                              ),
                              _buildEditableRow(
                                icon: Icons.phone_android,
                                iconColor: Colors.green,
                                label: 'رقم الهاتف',
                                value: officerData['phone'],
                                textColor: textColor,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const EditPhoneScreen()),
                                  );
                                },
                              ),
                              _buildInfoRow(
                                icon: Icons.cake_outlined,
                                iconColor: Colors.pink,
                                label: 'تاريخ الميلاد',
                                value: officerData['birthDate'],
                                textColor: textColor,
                                trailingIcon: Icons.lock_outline,
                              ),
                              _buildInfoRow(
                                icon: Icons.male,
                                iconColor: Colors.purple,
                                label: 'الجنس',
                                value: officerData['gender'],
                                textColor: textColor,
                                trailingIcon: Icons.lock_outline,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ═══════════════════════════════════════
                          // القسم الثاني: الصلاحيات والنظام
                          // ═══════════════════════════════════════
                          _buildSectionTitle("الصلاحيات والنظام", subColor),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            cardColor: cardColor,
                            isDark: isDark,
                            children: [
                              _buildInfoRow(
                                icon: Icons.badge_outlined,
                                iconColor: Colors.teal,
                                label: 'نوع الحساب',
                                value: officerData['role'],
                                textColor: textColor,
                                trailingIcon: Icons.lock_outline,
                              ),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                iconColor: Colors.amber,
                                label: 'آخر تسجيل دخول',
                                value: officerData['lastLogin'],
                                textColor: textColor,
                                trailingIcon: Icons.lock_outline,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ═══════════════════════════════════════
                          // القسم الثالث: الإعدادات والأمان
                          // ═══════════════════════════════════════
                          _buildSectionTitle("الإعدادات والأمان", subColor),
                          const SizedBox(height: 12),
                          _buildSettingsItem(
                            cardColor: cardColor,
                            textColor: textColor,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditPasswordScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // شريط التنقل السفلي
            CustomBottomNav(
            currentIndex: 1, // Profile ✅
            centerButton: AffairsOfficerSpeedDial(),
            onHomeTap: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen()),
            );
            },
            onProfileTap: () {},
            onNotificationsTap: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen()),
            );
            },
            onMessagesTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // عنوان القسم
  Widget _buildSectionTitle(String title, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: subColor,
            fontFamily: 'Noto Sans Arabic',
          ),
        ),
      ),
    );
  }

  // بطاقة المعلومات
  Widget _buildInfoCard({
    required Color cardColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: _addDividers(children, isDark),
      ),
    );
  }

  // إضافة فواصل
  List<Widget> _addDividers(List<Widget> children, bool isDark) {
    List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            indent: 20,
            endIndent: 20,
          ),
        );
      }
    }
    return result;
  }

  // عنصر عرض فقط (غير قابل للتعديل) - مع ألوان ملونة للأيقونات
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textColor,
    required IconData trailingIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 🌟 الأيقونة الرئيسية على اليمين - ملونة
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          // النصوص في المنتصف
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
              ],
            ),
          ),
          // أيقونة القفل على اليسار
          Icon(
            trailingIcon,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  // عنصر قابل للتعديل - مع ألوان ملونة للأيقونات
  Widget _buildEditableRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 🌟 الأيقونة الرئيسية على اليمين - ملونة
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            // النصوص في المنتصف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ],
              ),
            ),
            // أيقونة التعديل على اليسار
            const Icon(
              Icons.edit,
              color: Color(0xFFFFCC00),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // عنصر الإعدادات - مع ألوان ملونة
  Widget _buildSettingsItem({
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 10),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // 🌟 الأيقونة على اليمين - ملونة حمراء
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            // النص في المنتصف
            Text(
              'تغيير كلمة المرور',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Noto Sans Arabic',
              ),
            ),
            const Spacer(),
            // السهم على اليسار (Android style)
            const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}