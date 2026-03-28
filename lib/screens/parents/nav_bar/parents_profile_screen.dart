import 'package:flutter/material.dart';

// ✅ استيراد واجهات التعديل والـ Nav الموحد
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsProfileScreen extends StatelessWidget {
  const ParentsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف الألوان المتجاوبة مع الثيم (فاتح/داكن)
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl, // التغيير لـ RTL ليتناسب مع لغة التطبيق
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildProfileHeader(textColor),
                  const SizedBox(height: 30),

                  _buildSectionTitle("معلومات التواصل", textColor),
                  _buildInfoCard(cardColor, [
                    _buildClickableRow(
                      context,
                      "رقم الهاتف",
                      "4567 123 050",
                      Icons.phone_android_rounded,
                      Colors.green,
                      textColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPhoneScreen())),
                    ),
                    Divider(height: 1, indent: 20, endIndent: 20, color: textColor.withValues(alpha: 0.1)),
                    _buildClickableRow(
                      context,
                      "البريد الإلكتروني",
                      "ahmed.ali@institute.edu",
                      Icons.alternate_email_rounded,
                      Colors.blue,
                      textColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditEmailScreen())),
                    ),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("البيانات الأكاديمية", textColor),
                  _buildInfoCard(cardColor, [
                    _buildStaticRow("القسم", "هندسة الحاسوب", Icons.account_balance_rounded, Colors.purple, textColor),
                    Divider(height: 1, indent: 20, endIndent: 20, color: textColor.withValues(alpha: 0.1)),
                    _buildStaticRow("السنة الدراسية", "السنة الثالثة", Icons.auto_awesome_mosaic_rounded, Colors.orange, textColor),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("الأمان والإعدادات", textColor),
                  _buildClickableSettingCard(
                    "تغيير كلمة المرور",
                    Icons.lock_reset_rounded,
                    Colors.redAccent,
                    cardColor,
                    textColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPasswordScreen())),
                  ),

                  const SizedBox(height: 150), // مساحة للـ Nav Bar
                ],
              ),
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 1, // رقم صفحة الملف الشخصي
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () {}, // نحن هنا
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // --- الهيدر العلوي ---
  Widget _buildProfileHeader(Color textColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight, // تعديل مكان الكاميرا ليتناسب مع RTL
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEFFF00), width: 3),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEFFF00),
              child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text("أحمد محمد علي", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const Text("ولي أمر الطالب", style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // --- كرت المعلومات ---
  Widget _buildInfoCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  // --- صف تفاعلي ---
  Widget _buildClickableRow(BuildContext context, String label, String value, IconData icon, Color color, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildColoredIcon(icon, color),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_note_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // --- صف ثابت ---
  Widget _buildStaticRow(String label, String value, IconData icon, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildColoredIcon(icon, color),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildClickableSettingCard(String title, IconData icon, Color color, Color cardColor, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            _buildColoredIcon(icon, color),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
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

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("الملف الشخصي", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: Icon(Icons.arrow_forward, color: textColor), onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}