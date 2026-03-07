import 'package:flutter/material.dart';
import '../../widgets/custom_speed_dial.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      extendBody: true, // مهم جداً لجعل الزر يركب فوق الشريط
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.settings_outlined, color: Colors.black),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edu-Bridge", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(width: 8),
            // رجعنا أيقونة طاقية التخرج
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
              child: const Icon(Icons.school, size: 18, color: Colors.black),
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("لوحة التحكم", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const Row(
                children: [
                  Text("مرحباً، ", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("أستاذ أحمد", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text(" 👋", style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 30),
              _buildNewsCard(),
            ],
          ),
        ),
      ),
      // هذا الجزء يضمن بقاء الزر في المنتصف وفوق شريط التنقل
      floatingActionButton: const CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildNewsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Container(height: 180, width: double.infinity, color: Colors.grey[200], child: const Icon(Icons.image, size: 40, color: Colors.grey))),
          const Padding(
            padding: EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("موعد الامتحانات النصفية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("تم تحديد مواعيد الامتحانات، يرجى مراجعة الجدول المرفق.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      notchMargin: 8,
      height: 70,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "الرئيسية", true),
          _navItem(Icons.person_outline, "الملف", false),
          const SizedBox(width: 40), // مساحة للزر
          _navItem(Icons.notifications_none, "الإشعارات", false),
          _navItem(Icons.chat_bubble_outline, "الرسائل", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: active ? Colors.black : Colors.grey),
      Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.black : Colors.grey)),
    ]);
  }
}