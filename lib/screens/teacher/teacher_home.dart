import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import '../../widgets/teacher_speed_dial.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // زر الإعدادات (أيقونة الترس)
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
              Align(
                alignment: Alignment.centerRight,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: "مرحباً، "),
                      TextSpan(
                        text: "أستاذ أحمد",
                        style: TextStyle(color: Color(0xFF239B56)),
                      ),
                      TextSpan(text: " 👋"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "لوحة التحكم",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 30),

              // عنوان قسم الأخبار
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "آخر الأخبار والإعلانات",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "عرض الكل",
                      style: TextStyle(
                        color: Color(0xFF239B56),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // بطاقات الأخبار
              _buildNewsCard(
                title: "موعد الامتحانات النصفية",
                tag: "هام جداً",
                description:
                    "تم تحديد مواعيد الامتحانات للفصل الدراسي الأول، يرجى مراجعة الجدول المرفق.",
                time: "منذ ساعتين",
                tagColor: Colors.red,
              ),
              _buildNewsCard(
                title: "اجتماع الهيئة التدريسية",
                tag: "تنبيه هام",
                description:
                    "ندعوكم لحضور اجتماع الهيئة التدريسية يوم الخميس القادم لمناقشة الخطة الأكاديمية.",
                time: "منذ 5 ساعات",
                tagColor: Colors.orange,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      // استخدام الكلاس الموحد للزر العائم
      floatingActionButton: const CustomSpeedDialEduBridge(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String tag,
    required String description,
    required String time,
    required Color tagColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مكان الصورة (Placeholder)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  "مكان مخصص لصورة الخبر مستقبلاً",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 5),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            _navItem(context, Icons.home, "الرئيسية", true),

            // ✅ تم التصليح: الانتقال لصفحة البروفايل وليس الإعدادات
            _navItem(
              context,
              Icons.person_outline,
              "الملف",
              false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
            ),

            const SizedBox(width: 40),
            _navItem(
              context,
              Icons.notifications_none,
              "الإشعارات",
              false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
            ),
            _navItem(
              context,
              Icons.chat_bubble_outline,
              "الرسائل",
              false,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
  }) {
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
