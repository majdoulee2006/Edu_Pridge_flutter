import 'package:flutter/material.dart';

import '../../../../widgets/parents_center_icon.dart';
import '../../../teacher/messages_screen.dart';
import '../../../teacher/notifications_screen.dart';
import '../../../teacher/profile_screen.dart';
import '../../../teacher/teacher_home.dart';
import '../../nav_bar/parent_home.dart';
import '../../nav_bar/parents_messages_screen.dart';
import '../../nav_bar/parents_notifications_screen.dart';
import '../../nav_bar/parents_profile_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      extendBody: true, // ضروري لبروز الانحناء

      // الجزء العلوي (AppBar)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _buildCircleBtn(Icons.settings_outlined),
        title: const Text("أذونات أحمد محمد",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          _buildCircleBtn(Icons.arrow_forward),
          const SizedBox(width: 10),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // البطاقة الأولى الكبيرة (إجازة مرضية)
          _buildDetailedCard(),

          // البطاقة الثانية (خروج مبكر)
          _buildSimpleCard("خروج مبكر", "الخميس، 16 مايو - 12:30 م", Icons.airplanemode_active, Colors.blue),

          // البطاقة الثالثة (غياب ليوم كامل)
          _buildSimpleCard("غياب ليوم كامل", "الأحد، 19 مايو 2024", Icons.calendar_month, Colors.purple),

          const SizedBox(height: 20),
          const Center(child: Text("نهاية القائمة", style: TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 100),
        ],
      ),

      floatingActionButton: const Parents_Center_Icon(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),

    );
  }

  // ميثود بناء الأزرار الدائرية في الأعلى
  Widget _buildCircleBtn(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: Icon(icon, color: Colors.black, size: 20),
    );
  }

  // بناء البطاقة المفصلة
  Widget _buildDetailedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFEFFF00), width: 2), // إطار أصفر
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusTag(),
              Row(
                children: [
                  const Text("إجازة مرضية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  Icon(Icons.medical_services, color: Colors.yellow[700]),
                ],
              ),
            ],
          ),
          const Text("الأربعاء، 15 مايو 2024", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              "سبب الإذن:\nيعاني أحمد من وعكة صحية مفاجئة (ارتفاع في درجة الحرارة) ويحتاج إلى الراحة وزيارة الطبيب.\nمرفق صورة عن التقرير الطبي المبدئي.",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _actionBtn("رفض", Colors.red, isOutlined: true)),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn("موافقة", Colors.black, color: const Color(0xFFEFFF00))),
            ],
          ),
        ],
      ),
    );
  }

  // البطاقات البسيطة
  Widget _buildSimpleCard(String title, String date, IconData icon, Color iconCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          _statusTag(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconCol.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconCol, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _statusTag() {
    return
     Align(
       alignment: Alignment.centerLeft,
       child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20)),
          child: const Text("قيد الانتظار", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),

           ),
     );
  }

  Widget _actionBtn(String label, Color textCol, {Color? color, bool isOutlined = false}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isOutlined ? Border.all(color: Colors.red.withOpacity(0.2)) : null,
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
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