import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
// استيراد صفحة الإعدادات من المجلد المشترك
import '../shared/settings_screen.dart';
import '../../widgets/custom_speed_dial.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // إضافة أيقونة الإعدادات وتفعيل الانتقال لصفحتها
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: const Text(
            "الإشعارات",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          // زر الرجوع للخلف
          IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              onPressed: () => Navigator.pop(context)
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildNotifCard(
                "واجب أكاديمي",
                "أحمد محمد (طالب)",
                "تم تسليم واجب الرياضيات الجديد.",
                "منذ 15 دقيقة",
                Icons.book,
                const Color(0xFFFEF9E7),
                const Color(0xFFD4AC0D)
            ),
            _buildNotifCard(
                "إشعار إداري",
                "قسم الامتحانات",
                "تم تحديث جدول الامتحانات.",
                "أمس",
                Icons.calendar_today,
                const Color(0xFFF5EEF8),
                const Color(0xFF884EA0)
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),

      // استخدام الكلاس الجديد الموحد (EduBridge) بدون const
      floatingActionButton: const CustomSpeedDialEduBridge(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildNotifCard(String type, String title, String content, String time, IconData icon, Color bg, Color text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(children: [
        CircleAvatar(backgroundColor: bg, child: Icon(icon, color: text)),
        const SizedBox(width: 15),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(content, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]
            )
        ),
        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
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
            _navItem(context, Icons.home_outlined, "الرئيسية", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
            _navItem(context, Icons.person_outline, "الملف", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
            const SizedBox(width: 40),
            _navItem(context, Icons.notifications, "الإشعارات", true, onTap: () {}),
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
                      fontWeight: active ? FontWeight.bold : FontWeight.normal
                  )
              )
            ]
        )
    );
  }
}