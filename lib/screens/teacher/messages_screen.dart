import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
// استيراد صفحة الإعدادات من المجلد المشترك
import '../shared/settings_screen.dart';

import '../../widgets/teacher_speed_dial.dart'; // تأكدي من وجود هذا الملف

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selectedFilter = "الكل";

  final List<Map<String, dynamic>> chats = [
    {"name": "د. سمير (رئيس القسم)", "message": "يرجى تأكيد موعد اجتماع المجلس اليوم", "time": "الآن", "unreadCount": 1, "isOnline": true, "category": "الإدارة", "type": "individual", "initials": "س"},
    {"name": "أحمد محمد (سنة 3)", "message": "دكتور، هل يمكن تأجيل تسليم المشروع؟", "time": "10:30 ص", "unreadCount": 0, "isOnline": true, "category": "الطلاب", "initials": "أ", "type": "individual"},
    {"name": "جروب الفيزياء العامة", "message": "خالد: متى موعد الاختبار؟", "time": "أمس", "unreadCount": 5, "isOnline": false, "category": "الطلاب", "initials": "ف", "type": "group"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // تفعيل زر الإعدادات لينقلك لصفحة الإعدادات
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: const Text("الرسائل", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: "ابحث في المحادثات...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            _buildFilterRow(),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  return _buildChatTile(chats[index]);
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // استخدام الكلاس الموحد (EduBridge) كما عدله الفريق
      floatingActionButton: const CustomSpeedDialEduBridge(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: ["الكل", "غير مقروءة", "الجروبات"].map((label) {
          bool isSelected = selectedFilter == label;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = label),
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFFF00) : Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFEBF5FB),
          child: Text(chat['initials'] ?? "D", style: const TextStyle(color: Color(0xFF2E86C1))),
        ),
        title: Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(chat['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(chat['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (chat['unreadCount'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
                child: Text(chat['unreadCount'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
            _navItem(context, Icons.home_outlined, "الرئيسية", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
            _navItem(context, Icons.person_outline, "الملف", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
            const SizedBox(width: 40),
            _navItem(context, Icons.notifications_none, "الإشعارات", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
            _navItem(context, Icons.chat_bubble, "الرسائل", true, onTap: () {}),
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
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}