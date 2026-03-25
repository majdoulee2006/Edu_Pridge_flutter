import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:flutter/material.dart';

import '../../../widgets/parents_center_icon.dart';

class ParentsNotificationsScreen extends StatefulWidget {
  const ParentsNotificationsScreen({super.key});

  @override
  State<ParentsNotificationsScreen> createState() => _ParentsNotificationsScreenState();
}

class _ParentsNotificationsScreenState extends State<ParentsNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        appBar: _buildAppBar(context),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildSectionHeader("اليوم"),
            _buildNotificationCard(
              title: "غياب",
              time: "08:30 ص",
              content: "تم تسجيل غياب للطالب أحمد محمد عن الحصة الأولى.",
              footer: "يرجى التواصل مع المشرف",
              icon: Icons.close_rounded,
              iconColor: Colors.red,
              accentColor: Colors.red,
              showWarning: true,
            ),
            _buildEventCard(
              title: "موعد اختبار",
              subtitle: "الفيزياء التطبيقية - سارة محمد",
              time: "10:00 ص",
              date: "غداً، 15 مايو",
              location: "القاعة 4",
              icon: Icons.assignment_outlined,
              iconColor: Colors.purple,
              accentColor: Colors.purple,
            ),
            const SizedBox(height: 20),
            _buildSectionHeader("الأمس"),
            _buildNotificationCard(
              title: "فعالية جديدة",
              time: "02:15 م",
              content: "ندوة: الذكاء الاصطناعي في التعليم",
              footer: "20 مايو • مسرح المعهد",
              icon: Icons.calendar_today_outlined,
              iconColor: Colors.blue,
              accentColor: Colors.blue,
              footerIcon: Icons.location_on_outlined,
            ),
            _buildNotificationCard(
              title: "تذكير",
              time: "09:00 ص",
              content: "يرجى من أولياء الأمور الكرام تحديث بيانات الاتصال في حال حدوث أي تغييرات.",
              icon: Icons.notifications_none_outlined,
              iconColor: Colors.grey,
              accentColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 120), // مساحة للشريط السفلي
          ],
        ),

        floatingActionButton: const Parents_Center_Icon(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(context),

      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () {},
          ),
        ),
      ),
      centerTitle: true,
      title: const Text(
        "الإشعارات",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
        ],
      ),
    );
  }

  // كرت إشعار عام (غياب، ندوة، تذكير)
  Widget _buildNotificationCard({
    required String title,
    required String time,
    required String content,
    String? footer,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    bool showWarning = false,
    IconData? footerIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          // الخط الجانبي الملون
          Positioned(
            left: 0, top: 25, bottom: 25,
            child: Container(width: 5, decoration: BoxDecoration(color: accentColor, borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)))),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الأيقونة الدائرية
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _buildTimeBadge(time),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(content, style: const TextStyle(color: Colors.black87, height: 1.4)),
                      if (footer != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (showWarning) Icon(Icons.error_outline, color: iconColor, size: 16),
                            if (footerIcon != null) Icon(footerIcon, color: Colors.grey, size: 16),
                            const SizedBox(width: 5),
                            Text(footer, style: TextStyle(color: showWarning ? iconColor : Colors.grey, fontSize: 13, fontWeight: showWarning ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // كرت موعد الاختبار (تصميم خاص يحتوي على تفاصيل أكثر)
  Widget _buildEventCard({
    required String title,
    required String subtitle,
    required String time,
    required String date,
    required String location,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
  }) {
    return _buildNotificationCard(
      title: title,
      time: time,
      content: subtitle,
      icon: icon,
      iconColor: iconColor,
      accentColor: accentColor,
      footer: "$date • $location",
      footerIcon: Icons.calendar_today,
    );
  }

  Widget _buildTimeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F0), borderRadius: BorderRadius.circular(12)),
      child: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
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