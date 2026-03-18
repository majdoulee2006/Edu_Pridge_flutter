import 'package:flutter/material.dart';

import '../../../../widgets/custom_speed_dial.dart';
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  int selectedDayIndex = 3;

  final List<Map<String, dynamic>> days = const [
    {"name": "السبت", "day": 28},
    {"name": "الجمعة", "day": 27},
    {"name": "الخميس", "day": 26},
    {"name": "الأربعاء", "day": 25},
    {"name": "الثلاثاء", "day": 24},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.settings_outlined, color: Colors.black),
        title: const Text("جدولي", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFFF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text("جدول الحصص", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == selectedDayIndex;
                  final item = days[index];
                  return GestureDetector(
                    onTap: () => setState(() => selectedDayIndex = index),
                    child: Container(
                      width: 68,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFFF00) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item["name"], style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : const Color(0xFFF4F4F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text("${item["day"]}", style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "اليوم: الثلاثاء، 24 أكتوبر",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            _buildClassCard(
              now: true,
              title: "الفيزياء المتقدمة",
              subtitle: "الشعبة ب | قاعة 302",
              time: "10:00 - 11:30",
              icon: Icons.science_outlined,
              avatars: 24,
              actionText: null,
            ),
            _buildClassCard(
              now: false,
              title: "رياضيات 2",
              subtitle: "الشعبة أ | قاعة 105",
              time: "12:00 - 01:30",
              icon: Icons.calculate_outlined,
              avatars: 0,
              actionText: "تحضير الدرس",
            ),
            _buildClassCard(
              now: false,
              title: "ساعات مكتبية",
              subtitle: "غرفة المعلمين",
              time: "02:00 - 04:00",
              icon: Icons.coffee_outlined,
              avatars: 0,
              actionText: null,
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButton: CustomSpeedDialEduBridge(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildClassCard({
    required bool now,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required int avatars,
    String? actionText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (now)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(16)),
                  child: const Text("الآن", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              if (now) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFF4F4F2), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.black54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (avatars > 0)
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(radius: 10, backgroundColor: const Color(0xFFE3F2FD), child: const Text("أ", style: TextStyle(fontSize: 10, color: Color(0xFF2196F3)))),
                        Positioned(left: 12, child: CircleAvatar(radius: 10, backgroundColor: const Color(0xFFF3E5F5), child: const Text("م", style: TextStyle(fontSize: 10, color: Color(0xFF9C27B0))))),
                        Positioned(left: 24, child: CircleAvatar(radius: 10, backgroundColor: const Color(0xFFFFEBEE), child: const Text("س", style: TextStyle(fontSize: 10, color: Color(0xFFF44336))))),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Text("+$avatars", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              const Spacer(),
              Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(time, style: const TextStyle(color: Colors.black87)),
            ],
          ),
          if (actionText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF4F4F2), borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(actionText, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ],
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
            _navItem(context, Icons.home_outlined, "الرئيسية", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
            _navItem(context, Icons.person_outline, "الملف", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
            const SizedBox(width: 40),
            _navItem(context, Icons.notifications_none, "الإشعارات", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
            _navItem(context, Icons.chat_bubble_outline, "الرسائل", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
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

