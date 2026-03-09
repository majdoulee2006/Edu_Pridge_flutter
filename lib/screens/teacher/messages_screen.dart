import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../../widgets/custom_speed_dial.dart'; // تأكدي من وجود هذا الملف

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selectedFilter = "الكل";

  // قائمة الرسائل (نفس البيانات السابقة)
  final List<Map<String, dynamic>> chats = [
    {"name": "د. سمير (رئيس القسم)", "message": "يرجى تأكيد موعد اجتماع المجلس اليوم", "time": "الآن", "unreadCount": 1, "isOnline": true, "category": "الإدارة", "type": "individual"},
    {"name": "أحمد محمد (سنة 3)", "message": "دكتور، هل يمكن تأجيل تسليم المشروع؟", "time": "10:30 ص", "unreadCount": 0, "isOnline": true, "category": "الطلاب", "initials": "أ", "type": "individual"},
    {"name": "جروب الفيزياء العامة", "message": "خالد: متى موعد الاختبار؟", "time": "أمس", "unreadCount": 5, "isOnline": false, "category": "الطلاب", "type": "group"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      extendBody: true, // مهم جداً عشان الدائرة تظهر فوق المحتوى
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.settings_outlined, color: Colors.black),
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
            // شريط البحث
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
            // أزرار التصفية
            _buildFilterRow(),
            const SizedBox(height: 15),
            // القائمة
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

      // هنا السر! استدعاء نفس الدائرة الموجودة في الرئيسية
      floatingActionButton: const CustomSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // شريط التنقل بنفس الهوية البصرية
  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(), // الحفرة اللي بتقعد فيها الدائرة
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
            const SizedBox(width: 40), // فراغ للدائرة الصفراء
            _navItem(context, Icons.notifications_none, "الإشعارات", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
            _navItem(context, Icons.chat_bubble, "الرسائل", true, onTap: () {}), // الحالة النشطة هنا
          ],
        ),
      ),
    );
  }

  // باقي الـ Widgets (FilterChip و ChatTile) تبقى كما هي في الكود السابق...
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFEBF5FB),
        child: Text(chat['initials'] ?? "D", style: const TextStyle(color: Color(0xFF2E86C1))),
      ),
      title: Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(chat['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(chat['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
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