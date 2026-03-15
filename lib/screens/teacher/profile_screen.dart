import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
// تأكد أن المسار صحيح كما في الملفات السابقة
import '../../widgets/custom_speed_dial.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.settings_outlined, color: Colors.black),
        title: const Text("الملف الشخصي", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatarSection(),
              const SizedBox(height: 15),
              const Text("أحمد العبدالله", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("أستاذ مشارك - قسم علوم الحاسب", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 30),
              _buildSectionTitle("البيانات الشخصية"),
              _buildInfoTile(Icons.phone_outlined, "رقم الهاتف", "4567 123 55 966+", true),
              _buildInfoTile(Icons.email_outlined, "البريد الإلكتروني", "ahmed@institute.edu", true),
              const SizedBox(height: 25),
              _buildSectionTitle("البيانات الأكاديمية"),
              _buildInfoTile(Icons.apartment, "القسم", "كلية علوم الحاسب", false, isLocked: true),
              _buildSpecialTile(Icons.menu_book_outlined, "المواد الدراسية", "الفصل الحالي", ["خوارزميات", "هياكل بيانات"]),
              const SizedBox(height: 30),
              _buildChangePasswordButton(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      // تم تعديل الاسم هنا وحذف const
      floatingActionButton: const CustomSpeedDialEduBridge(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEFFF00), width: 2)),
          child: const CircleAvatar(radius: 55, backgroundColor: Colors.grey),
        ),
        const CircleAvatar(radius: 14, backgroundColor: Color(0xFFEFFF00), child: Icon(Icons.edit, size: 16, color: Colors.black)),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, bool isEditable, {bool isLocked = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          if (isEditable) const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFB4B48E)),
          if (isLocked) const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFB4B48E))),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(width: 15),
          Icon(icon, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildSpecialTile(IconData icon, String title, String subTitle, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFB4B48E))),
              Text(subTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(width: 15),
            Icon(icon, color: Colors.black54),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 11)))).toList()),
        ],
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset),
            SizedBox(width: 10),
            Text("تغيير كلمة المرور", style: TextStyle(fontWeight: FontWeight.bold))
          ]
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
        alignment: Alignment.centerRight,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB4B48E)))
        )
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
            _navItem(context, Icons.person, "الملف", true, onTap: () {}),
            const SizedBox(width: 40),
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
              Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey))
            ]
        )
    );
  }
}