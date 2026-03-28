import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// استيراد الشاشات والقطع اللازمة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsHomeScreen extends StatefulWidget {
  const ParentsHomeScreen({super.key});

  @override
  State<ParentsHomeScreen> createState() => _ParentsHomeScreenState();
}

class _ParentsHomeScreenState extends State<ParentsHomeScreen> {
  // متغير لتخزين اسم ولي الأمر القادم من الباكيند
  String _parentName = "جارِ التحميل...";

  @override
  void initState() {
    super.initState();
    _loadUserData(); // استدعاء دالة جلب البيانات عند تشغيل الشاشة
  }

  // دالة لجلب الاسم المخزن في SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'user_name' هو المفتاح الذي استخدمناه في كود الـ Login
      _parentName = prefs.getString('user_name') ?? "ولي أمر";
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. المحتوى الأساسي للواجهة
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(context, textColor, cardColor),
                  const SizedBox(height: 25),
                  _buildSectionTitle("الأبناء", textColor),
                  _buildStudentsList(cardColor, textColor),
                  const SizedBox(height: 25),
                  _buildSectionTitle("أخبار المعهد والفعاليات", textColor),
                  _buildNewsCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ParentsProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen()),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ParentsMessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- الهيدر العلوي المعدل ---
  Widget _buildHeader(BuildContext context, Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edu-Bridge",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: "مرحباً، ",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                  children: [
                    // تم استبدال "محمد" بالمتغير _parentName
                    TextSpan(text: _parentName, style: const TextStyle(color: Color(0xFFD4E000))),
                  ],
                ),
              ),
              const Text("تابع آخر أخبار المعهد والأنشطة",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen(userName: _parentName, userRole: "ولي أمر")),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
              child: const Icon(Icons.settings_outlined, color: Color(0xFFF1C40F), size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const Text("عرض الكل", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStudentsList(Color cardColor, Color textColor) {
    return SizedBox(
      height: 240,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _buildStudentCard("سارة محمد", "السنة الثالثة - هندسة حاسب", "3.8", "نشط", cardColor, textColor),
          _buildStudentCard("أحمد محمد", "السنة الأولى - إدارة أعمال", "--", "إجازة", cardColor, textColor),
          _buildAddButton(cardColor),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String name, String major, String gpa, String status, Color cardColor, Color textColor) {
    return Container(
      width: 220,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFE8F200).withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 35, backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.person, size: 40, color: Colors.indigo)),
          const SizedBox(height: 12),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          Text(major, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == "نشط" ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: TextStyle(color: status == "نشط" ? Colors.green : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text("معدل: $gpa", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAddButton(Color cardColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 65, height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
          child: const Icon(Icons.add, size: 30, color: Colors.black),
        ),
        const SizedBox(height: 8),
        const Text("إضافة", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildNewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B67D1), Color(0xFF2A4B9A)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          const Positioned(
            bottom: 25, right: 25,
            child: Text("انطلاق فعاليات الأسبوع الثقافي...",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 20, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Row(children: [
                Text("هام", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                SizedBox(width: 5),
                CircleAvatar(radius: 3, backgroundColor: Colors.red)
              ]),
            ),
          )
        ],
      ),
    );
  }
}