import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:flutter/material.dart';
import '../../../widgets/parents_center_icon.dart';

// تحويل الواجهة إلى StatefulWidget للتحكم في حالة الأيقونة النشطة
class ParentsHomeScreen extends StatefulWidget {
  const ParentsHomeScreen({super.key});

  @override
  State<ParentsHomeScreen> createState() => _ParentsHomeScreenState();
}

class _ParentsHomeScreenState extends State<ParentsHomeScreen> {
  // متغير لتحديد الأيقونة النشطة حالياً (0 تعني الرئيسية)
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF2),
      extendBody: true,

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("الأبناء"),
                  _buildStudentsList(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("أخبار المعهد والفعاليات"),
                  _buildNewsCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: const Parents_Center_Icon(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // تمرير السياق لبناء الناف بار
      bottomNavigationBar: _buildBottomNav(context),

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

  // --- بقية الويدجت (بدون تغيير) ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edu-Bridge", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  text: "مرحباً، ",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(text: "محمد", style: TextStyle(color: Color(0xFFD4E000))),
                  ],
                ),
              ),
              const Text("تابع آخر أخبار المعهد والأنشطة", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          _buildCircleBtn(Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("عرض الكل >", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return SizedBox(
      height: 240,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _buildStudentCard("سارة محمد", "السنة الثالثة - هندسة حاسب", "3.8", "نشط"),
          _buildStudentCard("أحمد محمد", "السنة الأولى - إدارة أعمال", "--", "إجازة"),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String name, String major, String gpa, String status) {
    return Container(
      width: 240,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFE8F200).withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE0E7FF)),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(major, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == "نشط" ? const Color(0xFFE8FCE3) : Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(status, style: TextStyle(color: status == "نشط" ? Colors.green : Colors.blue, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text("معدل: $gpa", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70, height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(color: Color(0xFFE8F200), shape: BoxShape.circle),
          child: const Icon(Icons.add, size: 35),
        ),
        const SizedBox(height: 8),
        const Text("إضافة", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildNewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF3B67D1),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        children: [
          const Positioned(
            bottom: 20, right: 20,
            child: Text("انطلاق فعاليات الأسبوع الثقافي...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 15, left: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [Text("هام", style: TextStyle(fontSize: 10)), SizedBox(width: 5), CircleAvatar(radius: 3, backgroundColor: Colors.red)]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.grey[700]),
    );
  }
}