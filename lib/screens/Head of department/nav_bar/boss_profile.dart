import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🌟 استيراد الشاشات
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/accounts/accounts_management_screen.dart';
// 🚀 إضافة استيراد صفحة الإجازات
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/leave_requests_screen.dart';

import '../../../widgets/boss_center_icon.dart';

class BossProfileScreen extends StatefulWidget {
  const BossProfileScreen({super.key});

  @override
  State<BossProfileScreen> createState() => _BossProfileScreenState();
}

class _BossProfileScreenState extends State<BossProfileScreen> {
  String _userName = "أحمد عبدالله";
  String _userRole = "رئيس القسم الأكاديمي";
  final String _email = "ahmed.abd@edubridge.com";
  final String _phone = "+966 50 123 4567";
  final String _department = "علوم الحاسب الآلي";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "أحمد عبدالله";
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    const Color primaryYellow = Color(0xFFD4E000);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTopBar(context, isDark, _userName),
                      const SizedBox(height: 10),
                      _buildProfileHeader(isDark, primaryYellow),
                      const SizedBox(height: 30),

                      // 🚀 إضافة قسم الإجازات ليدعم الرجوع للبروفايل
                      _buildSectionHeader("إجراءات سريعة"),
                      _buildInfoCard(cardColor, isDark, [
                        _buildTile(
                          Icons.event_note_rounded,
                          "طلبات الإجازة",
                          "عرض وإدارة الطلبات من البروفايل",
                          primaryYellow,
                          isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaveRequestsScreen(fromSource: "profile"),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 25),

                      _buildSectionHeader("بيانات الحساب"),
                      _buildInfoCard(cardColor, isDark, [
                        _buildTile(Icons.phone_outlined, "رقم الهاتف", _phone, primaryYellow, isDark, hasEdit: true),
                        _buildDivider(isDark),
                        _buildTile(Icons.email_outlined, "البريد الإلكتروني", _email, primaryYellow, isDark, hasEdit: true),
                        _buildDivider(isDark),
                        _buildTile(Icons.lock_outline, "كلمة المرور", "••••••••", primaryYellow, isDark, isPassword: true),
                      ]),

                      const SizedBox(height: 25),

                      _buildSectionHeader("المعلومات الشخصية"),
                      _buildInfoCard(cardColor, isDark, [
                        _buildTile(Icons.business_outlined, "القسم", _department, primaryYellow, isDark, isLocked: true),
                        _buildDivider(isDark),
                        _buildTile(Icons.calendar_today_outlined, "تاريخ الميلاد", "15 مايو 1985", primaryYellow, isDark, hasEdit: true),
                      ]),

                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),

              CustomBottomNav(
                currentIndex: 1, // التزاماً بطلبك السابق
                centerButton: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountsManagementScreen())),
                  child: const Boss_Center_Icon(),
                ),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                onProfileTap: () {},
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossNotificationScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- المكونات الداخلية المصححة ---

  Widget _buildTopBar(BuildContext context, bool isDark, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
          ),
          const Text("الملف الشخصي", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(userName: name, userRole: "رئيس القسم الأكاديمي", onProfileTap: () => Navigator.pop(context)))),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark, Color yellow) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: yellow.withValues(alpha: 0.3), width: 2)),
              child: const CircleAvatar(radius: 60, backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Boss123')),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: yellow, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.edit, size: 16, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(_userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(_userRole, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildInfoCard(Color cardColor, bool isDark, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  // 🛠️ تعديل الـ Tile ليدعم الضغط (onTap)
  Widget _buildTile(IconData icon, String label, String value, Color yellow, bool isDark,
      {bool hasEdit = false, bool isPassword = false, bool isLocked = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: yellow, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            if (isPassword) const Text("تغيير", style: TextStyle(color: Colors.grey, fontSize: 12))
            else if (isLocked) const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
            else if (onTap != null) const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey)
              else if (hasEdit) const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 70, endIndent: 20, color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1));
  }
}