import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:flutter/material.dart';

import '../../../widgets/parents_center_icon.dart';

class ParentsMessagesScreen extends StatefulWidget {
  const ParentsMessagesScreen({super.key});

  @override
  State<ParentsMessagesScreen> createState() => _ParentsMessagesScreenState();
}

class _ParentsMessagesScreenState extends State<ParentsMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان الترتيب العربي الصحيح
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: Column(
          children: [
            _buildChatHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDateTag("اليوم"),
                  _buildReceiverMessage("السلام عليكم أستاذ، يرجى تزويدي بتقرير الأداء الشهري للطلاب."),
                  _buildSenderMessage("وعليكم السلام ورحمة الله،،"),
                  _buildSenderMessage("التقرير جاهز، سأقوم بإرساله الآن.", time: "09:42 ص", isRead: true),
                  _buildReceiverMessage("ممتاز، بانتظارك."),
                  _buildFileMessage("تقرير_أكتوبر.pdf", "2.4 MB • PDF", "09:45 ص"),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildMessageInput(),
            // مساحة إضافية لضمان عدم تداخل حقل الإدخال مع الشريط السفلي العائم
            const SizedBox(height: 110),
          ],
        ),

        floatingActionButton: const Parents_Center_Icon(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(context),

      ),
    );
  }

  // الهيدر العلوي (صورة الشخص والحالة)
  Widget _buildChatHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFF0F0F0),
                    child: Icon(Icons.person, color: Colors.grey), // استبدلها بصورة المستخدم
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text("المدير", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.black54), onPressed: () {}),
        ],
      ),
    );
  }

  // تاغ التاريخ في منتصف الشاشة
  Widget _buildDateTag(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 25),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }

  // فقاعة رسالة الطرف الآخر (أبيض مع ظل خفيف)
  Widget _buildReceiverMessage(String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 60),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
      ),
    );
  }

  // فقاعة رسالة المستخدم (أصفر فاقع)
  Widget _buildSenderMessage(String message, {String? time, bool isRead = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5, right: 60),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFFF00),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  if (isRead) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Colors.blue),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // رسالة الملف المرفق (PDF)
  Widget _buildFileMessage(String fileName, String info, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFF00),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.description, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(info, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 5),
            child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // شريط إدخال الرسالة (تصميم منحني وعائم)
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEFFF00),
              child: Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "اكتب رسالة...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey), onPressed: () {}),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.grey), onPressed: () {}),
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