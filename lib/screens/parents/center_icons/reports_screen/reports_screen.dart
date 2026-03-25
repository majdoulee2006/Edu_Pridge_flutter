import 'package:edu_pridge_flutter/widgets/parents_center_icon.dart';
import 'package:flutter/material.dart';

import '../../../teacher/messages_screen.dart';
import '../../../teacher/notifications_screen.dart';
import '../../../teacher/profile_screen.dart';
import '../../../teacher/teacher_home.dart';
import '../../nav_bar/parent_home.dart';
import '../../nav_bar/parents_messages_screen.dart';
import '../../nav_bar/parents_notifications_screen.dart';
import '../../nav_bar/parents_profile_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _buildRoundBtn(Icons.settings_outlined),
        title: const Text(
          "تقارير الأبناء",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          _buildRoundBtn(Icons.arrow_forward),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("اختر الابن", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // قائمة الأبناء
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStudentItem("أحمد", "assets/images/boy.png", false),
                const SizedBox(width: 20),
                _buildStudentItem("سارة", "assets/images/girl.png", true),
              ],
            ),

            const SizedBox(height: 30),
            const Text("نوع التقرير", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // بطاقة تقرير أكاديمي
            _buildReportCard(
              title: "تقرير أكاديمي",
              subtitle: "يشمل الدرجات، الحضور، والملاحظات الأكاديمية",
              icon: Icons.school,
              color: Colors.blueAccent,
              isSelected: selectedReport == "أكاديمي",
              onTap: () => setState(() => selectedReport = "أكاديمي"),
            ),

            // بطاقة تقرير سلوك
            _buildReportCard(
              title: "تقرير سلوك",
              subtitle: "يشمل الالتزام، المشاركة، والتقييم السلوكي",
              icon: Icons.psychology_outlined,
              color: Colors.purpleAccent,
              isSelected: selectedReport == "سلوك",
              onTap: () => setState(() => selectedReport = "سلوك"),
            ),

            const SizedBox(height: 20),

            // صندوق سياسة الطلب
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFEE7),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.yellowAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text("سياسة الطلب", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          "يمكنك طلب تقرير جديد لكل طالب مرة واحدة كل 15 يومًا لضمان تحديث البيانات بشكل دقيق.",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // زر طلب التقرير الكبير
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEFFF00),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("طلب التقرير", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("يتم التحديث كل 15 يومًا", style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 100), // مساحة للشريط السفلي
          ],
        ),
      ),

      floatingActionButton: const Parents_Center_Icon(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),

    );
  }

  // ويدجت أيقونات الـ AppBar الدائرية
  Widget _buildRoundBtn(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.black54, size: 20),
    );
  }

  // ويدجت اختيار الابن
  Widget _buildStudentItem(String name, String imgPath, bool isSelected) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : Colors.transparent, width: 2),
              ),
              child: const CircleAvatar(
                radius: 35,
                backgroundColor: Color(0xFFE0E0E0),
                child: Icon(Icons.person, size: 40, color: Colors.white), // استبدلها بصورة لاحقاً
              ),
            ),
            if (isSelected)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 18, color: Colors.black),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // ويدجت بطاقات التقارير
  Widget _buildReportCard({required String title, required String subtitle, required IconData icon, required Color color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : Colors.grey.withOpacity(0.2), width: 2),
        ),
        child: Row(
          children: [
            // أيقونة الاختيار الدائرية
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : Colors.grey.withOpacity(0.3), width: 2),
              ),
              child: isSelected ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // أيقونة التقرير الملونة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_outlined, "الرئيسية", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ParentsHomeScreen()
            ))
            ),
            _navItem(context, Icons.person_outline, "الملف", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen()))),
            const SizedBox(width: 40),
            _navItem(context, Icons.notifications_none, "الإشعارات", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen()))),
            _navItem(context, Icons.chat_bubble_outline, "الرسائل", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEFFF00) : Colors.grey),
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey)),
        ],
      ),
    );
  }


}