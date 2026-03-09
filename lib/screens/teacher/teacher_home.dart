import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import '../../widgets/custom_speed_dial.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      // لضمان ظهور الشريط السفلي بشكل صحيح فوق المحتوى
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.settings_outlined, color: Colors.black),
        title: const Text(
          "Edu-Bridge",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم الترحيب
              const Text(
                "لوحة التحكم",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 5),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: "مرحباً، "),
                    TextSpan(
                      text: "أستاذ أحمد",
                      style: TextStyle(color: Color(0xFF239B56)), // اللون الأخضر كما في التصميم
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // قسم آخر الأخبار والإعلانات
              const Text(
                "آخر الأخبار والإعلانات",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // بطاقات الأخبار (يمكن تكرارها أو جعلها ListView)
              _buildNewsCard(
                title: "موعد الامتحانات النصفية",
                subtitle: "تم تحديد المواعيد الجديدة، يرجى مراجعة الجدول.",
                imagePath: "assets/images/exam_banner.png", // تأكدي من إضافة المسار في pubspec.yaml
              ),
              _buildNewsCard(
                title: "ورشة عمل تقنيات التعليم",
                subtitle: "ندعوكم لحضور ورشة العمل يوم الخميس القادم في القاعة المركزية.",
                imagePath: "assets/images/workshop.png",
              ),

              const SizedBox(height: 100), // مساحة إضافية لعدم تغطية المحتوى بالشريط السفلي
            ],
          ),
        ),
      ),

      // الزر الدائري الأوسط
      floatingActionButton: const CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // شريط التنقل السفلي المفعل بالكامل
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // بطاقة الأخبار
  Widget _buildNewsCard({required String title, required String subtitle, required String imagePath}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مكان الصورة (Placeholder)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // شريط التنقل السفلي مع الربط (Navigation)
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
            _navItem(context, Icons.home, "الرئيسية", true, onTap: () {}),
            _navItem(context, Icons.person_outline, "الملف", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
            const SizedBox(width: 40), // فراغ للـ Speed Dial
            _navItem(context, Icons.notifications_none, "الإشعارات", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
            _navItem(context, Icons.chat_bubble_outline, "الرسائل", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? const Color(0xFFEFFF00) : Colors.grey,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}