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
      // لضمان ظهور الزر الأصفر فوق البار السفلي
      extendBody: true,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // --- الهيدر العلوي الأبيض الثابت ---
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edu-Bridge',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              Row(
                                children: const [
                                  Text('مرحباً، ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                  Text(
                                    'أستاذ أحمد',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings_outlined, color: Color(0xFFF1C40F), size: 28),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.orange.shade100,
                                  child: const Icon(Icons.person, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(2)),
                              ),
                              const SizedBox(width: 8),
                              const Text('آخر الأخبار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                          const Text('عرض الكل', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // --- قائمة الأخبار القابلة للتمرير ---
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                children: [
                  _buildNewsCard(
                    tag: 'إعلان هام',
                    title: 'تم إصدار جدول الامتحانات النهائية للفصل الدراسي الأول',
                    description: 'يرجى من جميع المعلمين مراجعة الجدول الدراسي والتأكد من توقيت الامتحانات والقاعات.',
                    time: 'منذ ساعتين',
                    headerColor: const Color(0xFFFFCC33),
                  ),
                  _buildNewsCard(
                    tag: 'نشاط طلابي',
                    title: 'ورشة عمل حول مهارات البحث العلمي',
                    description: 'ندعو جميع الطلاب المهتمين للتسجيل في ورشة العمل التي ستقام في قاعة المؤتمرات.',
                    time: 'منذ 4 ساعات',
                    headerColor: const Color(0xFF4DB6AC),
                  ),
                  const SizedBox(height: 100), // مساحة إضافية للتمرير فوق البار السفلي
                ],
              ),
            ),
          ],
        ),
      ),

      // الزر الأصفر الحقيقي
      floatingActionButton: const CustomSpeedDialEduBridge(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // شريط التنقل السفلي الموحد مع ملف البروفايل
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildNewsCard({required String tag, required String title, required String description, required String time, required Color headerColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(color: headerColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
            child: Stack(
              children: [
                Positioned(top: 15, right: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                const Center(child: Icon(Icons.image_outlined, size: 50, color: Colors.white60)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.4)),
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.black)),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
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
            // جهة اليمين
            _navItem(context, Icons.home, "الرئيسية", true, onTap: () {}),
            _navItem(context, Icons.person_outline, "الملف", false,
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),

            // فراغ للزر الأصفر
            const SizedBox(width: 40),

            // جهة اليسار
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
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}