import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/parents_center_icon.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart'; // سطر الاستيراد الجديد

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedStudent = "سارة";
  String selectedReport = "أكاديمي";

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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("اختر الابن", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStudentItem("سارة", Icons.girl, true, textColor),
                      const SizedBox(width: 20),
                      _buildStudentItem("أحمد", Icons.boy, false, textColor),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Text("نوع التقرير", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  _buildReportCard(
                    title: "تقرير أكاديمي",
                    subtitle: "يشمل الدرجات، الحضور، والملاحظات الأكاديمية",
                    icon: Icons.school_rounded,
                    color: Colors.blueAccent,
                    isSelected: selectedReport == "أكاديمي",
                    onTap: () => setState(() => selectedReport = "أكاديمي"),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  _buildReportCard(
                    title: "تقرير سلوك",
                    subtitle: "يشمل الالتزام، المشاركة، والتقييم السلوكي",
                    icon: Icons.psychology_outlined,
                    color: Colors.purpleAccent,
                    isSelected: selectedReport == "سلوك",
                    onTap: () => setState(() => selectedReport = "سلوك"),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 25),
                  _buildPolicyBox(textColor),
                  const SizedBox(height: 40),
                  _buildRequestButton(textColor),
                  const SizedBox(height: 150),
                ],
              ),
            ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("تقارير الأبناء", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)), // تحديث: withValues
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStudentItem(String name, IconData icon, bool isSelected, Color textColor) {
    return GestureDetector(
      onTap: () => setState(() => selectedStudent = name),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : Colors.transparent, width: 2),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: isSelected ? const Color(0xFFEFFF00).withValues(alpha: 0.1) : textColor.withValues(alpha: 0.05), // تحديث: withValues
                  child: Icon(icon, size: 40, color: isSelected ? const Color(0xFFEFFF00) : textColor.withValues(alpha: 0.3)), // تحديث: withValues
                ),
              ),
              if (isSelected)
                const Positioned(
                  bottom: 2,
                  right: 2,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xFFEFFF00),
                    child: Icon(Icons.check, size: 14, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title, required String subtitle, required IconData icon,
    required Color color, required bool isSelected, required VoidCallback onTap,
    required Color cardColor, required Color textColor
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : textColor.withValues(alpha: 0.05), width: 2), // تحديث: withValues
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), // تحديث: withValues
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5))), // تحديث: withValues
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFEFFF00), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyBox(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEE7).withValues(alpha: 0.1), // تحديث: withValues
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.2)), // تحديث: withValues
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "يمكنك طلب تقرير جديد لكل طالب مرة واحدة كل 15 يومًا لضمان دقة البيانات.",
              style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6), height: 1.4), // تحديث: withValues
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(Color textColor) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم إرسال طلب التقرير بنجاح"))
        );
      },
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFF00),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: const Color(0xFFEFFF00).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)) // تحديث: withValues
          ],
        ),
        child: Column(
          children: [
            const Text("طلب التقرير الآن", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            Text("سيصلك إشعار عند جاهزية الملف", style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))), // تحديث: withValues
          ],
        ),
      ),
    );
  }
}