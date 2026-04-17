import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// ✅ استيراد الواجهات المساعدة
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsProfileScreen extends StatefulWidget {
  const ParentsProfileScreen({super.key});

  @override
  State<ParentsProfileScreen> createState() => _ParentsProfileScreenState();
}

class _ParentsProfileScreenState extends State<ParentsProfileScreen> {
  // متغيرات البيانات (لربطها بالعرض)
  String parentName = "أحمد محمد علي";
  String parentPhone = "050 123 4567";
  String parentEmail = "ahmed.ali@institute.edu";

  String studentName = "عمر الخالد";
  String studentDept = "هندسة الحاسوب"; // القسم
  String studentYear = "السنة الثانية"; // السنة الدراسية

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. جلب ID الأب (ولي الأمر)
    dynamic rawId = prefs.get('user_id');
    int? userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? "");

    if (userId != null) {
      try {
        var response = await Dio().get("http://127.0.0.1:8000/api/user/profile/$userId");
        if (response.statusCode == 200) {
          setState(() {
            parentName = response.data['full_name'] ?? parentName;
            parentEmail = response.data['email'] ?? parentEmail;
            parentPhone = response.data['phone'] ?? parentPhone;
          });
        }
      } catch (e) { print("فشل جلب بيانات الأب: $e"); }
    }

    // 2. جلب بيانات الطالب المختار
    int? selectedId = prefs.getInt('selected_student_id');
    if (selectedId != null) {
      try {
        // نرسل طلب للسيرفر يجلب البيانات بـ Join بين الجداول
        var res = await Dio().get("http://127.0.0.1:8000/api/student/info/$selectedId");
        if (res.statusCode == 200 && res.data != null) {
          setState(() {
            studentName = res.data['full_name'] ?? studentName;
            // ✅ هنا الربط الصحيح: القسم من خانة department الجاية من جدول الـ users
            studentDept = res.data['department'] ?? "غير محدد";
            // ✅ هنا السنة الدراسية الجاية من خانة level في جدول الـ students
            studentYear = res.data['level'] ?? "غير محدد";
          });
        }
      } catch (e) { print("فشل جلب بيانات الطالب: $e"); }
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
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildProfileHeader(textColor, parentName), // رجعنا الهيدر الأصلي
                  const SizedBox(height: 30),

                  _buildSectionTitle("معلومات التواصل", textColor),
                  _buildInfoCard(cardColor, [
                    _buildClickableRow(
                      context, "رقم الهاتف", parentPhone, Icons.phone_android_rounded, Colors.green, textColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPhoneScreen())),
                    ),
                    Divider(height: 1, color: textColor.withOpacity(0.1), indent: 20, endIndent: 20),
                    _buildClickableRow(
                      context, "البريد الإلكتروني", parentEmail, Icons.alternate_email_rounded, Colors.blue, textColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditEmailScreen())),
                    ),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("البيانات الأكاديمية (للطالب)", textColor),
                  _buildInfoCard(cardColor, [
                    _buildStaticRow("القسم", studentDept, Icons.account_balance_rounded, Colors.purple, textColor),
                    Divider(height: 1, color: textColor.withOpacity(0.1), indent: 20, endIndent: 20),
                    _buildStaticRow("السنة الدراسية", studentYear, Icons.auto_awesome_mosaic_rounded, Colors.orange, textColor),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("الأمان والإعدادات", textColor),
                  _buildClickableSettingCard(
                    "تغيير كلمة المرور", Icons.lock_reset_rounded, Colors.redAccent, cardColor, textColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPasswordScreen())),
                  ),

                  const SizedBox(height: 150),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // --- الهيدر الأصلي مع الكاميرا ---
  Widget _buildProfileHeader(Color textColor, String name) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEFFF00), width: 3)),
              child: const CircleAvatar(radius: 60, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 60, color: Colors.white)),
            ),
            const CircleAvatar(
              radius: 18, backgroundColor: Color(0xFFEFFF00),
              child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const Text("ولي أمر الطالب", style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // --- بقية الـ Widgets (InfoCard, ClickableRow, StaticRow) كما كانت في تصميمك الأصلي تماماً ---
  Widget _buildInfoCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildClickableRow(BuildContext context, String label, String value, IconData icon, Color color, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildColoredIcon(icon, color),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_note_rounded, color: color.withOpacity(0.5)),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start,
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(alignment: Alignment.centerRight,
      child: Padding(padding: const EdgeInsets.only(right: 5, bottom: 10),
        child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      title: Text("الملف الشخصي", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }
}