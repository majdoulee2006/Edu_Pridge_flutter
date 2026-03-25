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

class ParentsAssignmentsScreen extends StatelessWidget {
  const ParentsAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان التنسيق العربي من اليمين
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _roundBtn(Icons.settings_outlined),
          title: const Text("واجبات ومشاريع سارة ...",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [_roundBtn(Icons.arrow_forward), const SizedBox(width: 10)],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _filterChip("الكل", true),
                  _filterChip("المكتملة", false),
                  _filterChip("فائتة", false),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  // بطاقة جاري
                  _taskCard(
                    title: "مشروع تصميم واجهة",
                    subtitle: "مادة تصميم تجربة المستخدم",
                    status: "جاري",
                    progress: 0.6,
                    date: "May 2024 25",
                    icon: Icons.code,
                    iconColor: Colors.blue,
                    hasAttachment: true,
                  ),
                  // بطاقة مكتملة
                  _taskCard(
                    title: "واجب الإحصاء #3",
                    subtitle: "مادة الإحصاء والاحتمالات",
                    status: "مكتملة",
                    progress: 1.0,
                    date: "تم التسليم: أمس",
                    icon: Icons.calculate_outlined,
                    iconColor: Colors.green,
                    grade: "10/10",
                  ),
                  // بطاقة فائتة
                  _taskCard(
                    title: "بحث التاريخ المعاصر",
                    subtitle: "مادة التاريخ",
                    status: "فائتة",
                    progress: 0.0,
                    date: "استحق في May 15",
                    icon: Icons.auto_stories_outlined,
                    iconColor: Colors.purple,
                    isOverdue: true,
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: const Parents_Center_Icon(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _taskCard({
    required String title, required String subtitle, required String status,
    required double progress, required String date, required IconData icon,
    required Color iconColor, bool hasAttachment = false, String? grade, bool isOverdue = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 15),
          if (progress > 0 && progress < 1.0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress, color: Colors.blue, backgroundColor: Colors.grey[100], minHeight: 6),
            ),
            const SizedBox(height: 15),
          ],
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),

          // --- التعديل المطلوب: عكس العناصر في السطر السفلي ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. النصوص الوصفية تظهر الآن أولاً (على اليمين في RTL)
              Text(
                date,
                style: TextStyle(
                  color: isOverdue ? Colors.red : (status == "مكتملة" ? Colors.green : Colors.grey),
                  fontSize: 12,
                ),
              ),

              // 2. المرفقات أو الدرجات تظهر ثانياً (على اليسار في RTL)
              if (hasAttachment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: const [
                      Icon(Icons.attach_file, size: 14),
                      Text(" 3 مرفقات", style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              if (grade != null)
                Text(grade, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (isOverdue)
                const Text("طلب تمديد ←", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label) {
    Color bg = Colors.yellow[50]!;
    if (label == "مكتملة") bg = Colors.green[50]!;
    if (label == "فائتة") bg = Colors.red[50]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _filterChip(String label, bool isSel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: isSel ? const Color(0xFFEFFF00) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _roundBtn(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
      child: Icon(icon, color: Colors.black, size: 18),
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