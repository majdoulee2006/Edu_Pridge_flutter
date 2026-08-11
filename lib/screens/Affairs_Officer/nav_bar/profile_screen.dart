import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

// استيراد شاشات التعديل
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';

class AffairsOfficerProfileScreen extends StatefulWidget {
  const AffairsOfficerProfileScreen({super.key});

  @override
  State<AffairsOfficerProfileScreen> createState() => _AffairsOfficerProfileScreenState();
}

class _AffairsOfficerProfileScreenState extends State<AffairsOfficerProfileScreen> {
  final AffairsServices _affairsServices = AffairsServices();
  bool _isLoading = true;
  int _reviewedLeaves = 0;
  int _sentMessages = 0;

  Map<String, dynamic> officerData = {
    'name': 'محمد المحمد',
    'email': 'officer@edu.pridge',
    'phone': '09863548741',
    'birthDate': '1995-03-15',
    'gender': 'ذكر',
    'role': 'موظف شؤون',
    'lastLogin': 'غير متوفر',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _affairsServices.getProfile();
      if (mounted && data != null) {
        final user = data['user'] ?? data;
        setState(() {
          if (user != null) {
            officerData['name'] = (user['full_name'] != null && user['full_name'].toString().isNotEmpty)
                ? user['full_name']
                : (user['name'] ?? 'محمد المحمد');
            officerData['email'] = (user['email'] != null && user['email'].toString().isNotEmpty)
                ? user['email']
                : 'officer@edu.pridge';
            officerData['phone'] = (user['phone'] != null && user['phone'].toString().isNotEmpty)
                ? user['phone']
                : '09863548741';
            officerData['birthDate'] = user['birth_date']?.toString().split('T')[0] ?? '1995-03-15';
            officerData['gender'] = 'ذكر';
            officerData['role'] = 'موظف شؤون';
            officerData['lastLogin'] = user['last_login'] != null
                ? user['last_login'].toString().replaceFirst('T', ' ').substring(0, 16)
                : '2026-08-11 08:00';
          }
          _reviewedLeaves = data['reviewedLeaves'] ?? data['reviewed_leaves'] ?? 12;
          _sentMessages = data['sentMessages'] ?? data['sent_messages'] ?? 45;
          _isLoading = false;
        });
      } else {
        setState(() {
          officerData['name'] = 'محمد المحمد';
          officerData['email'] = 'officer@edu.pridge';
          officerData['phone'] = '09863548741';
          officerData['birthDate'] = '1995-03-15';
          officerData['gender'] = 'ذكر';
          officerData['role'] = 'موظف شؤون';
          officerData['lastLogin'] = '2026-08-11 08:00';
          _reviewedLeaves = 12;
          _sentMessages = 45;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) {
        setState(() {
          officerData['gender'] = 'ذكر';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            icon: Icon(
                              Icons.arrow_back,
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Text(
                          "الملف الشخصي",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Noto Sans Arabic'),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.settings_outlined, color: textColor, size: 22),
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => SettingsScreen(
                                  userName: officerData['name'] as String? ?? '',
                                  userRole: officerData['role'] as String? ?? 'موظف شؤون',
                                  onProfileTap: () => Navigator.pop(context),
                                ))).then((_) => _loadProfile()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- المحتوى القابل للتمرير ---
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProfile,
                            color: const Color(0xFFFFCC00),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
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
                                            color: cardColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 10,
                                              )
                                            ],
                                          ),
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFCC00),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              size: 70,
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontFamily: 'Noto Sans Arabic',
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // --- الدور والـ ID ---
                                  Center(
                                    child: Container(
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
                                  ),

                                  const SizedBox(height: 24),

                                  // --- صناديق الإحصائيات المضافة ---
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildStatBox("الإجازات المراجعة", _reviewedLeaves.toString(), Colors.blue, cardColor, textColor, subColor),
                                      const SizedBox(width: 16),
                                      _buildStatBox("الرسائل المرسلة", _sentMessages.toString(), Colors.purple, cardColor, textColor, subColor),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

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
                                      _buildInfoRow(
                                        icon: Icons.email_outlined,
                                        iconColor: Colors.blue,
                                        label: 'البريد الإلكتروني',
                                        value: officerData['email'],
                                        textColor: textColor,
                                        trailingIcon: Icons.lock_outline,
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
                                          _loadProfile();
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
                                    ).then((_) => _loadProfile()),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // شريط التنقل السفلي
            CustomBottomNav(
              currentIndex: 1, // Profile
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
              onMessagesTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerMessagesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, Color cardColor, Color textColor, Color subColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            Icon(
              label.contains("الإجازات") ? Icons.assignment_turned_in_outlined : Icons.send_rounded,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: subColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'Noto Sans Arabic',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
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
          Icon(
            trailingIcon,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
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
            const Icon(
              Icons.arrow_back,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}