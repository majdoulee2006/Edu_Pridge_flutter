import 'package:flutter/material.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
// استيراد صفحة الإعدادات من المجلد المشترك
import '../shared/settings_screen.dart';

// 🌟 1. استدعاء الشريط الموحد 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
// 🌟 2. استدعاء زر المعلم الموحد 🌟
import '../../widgets/teacher_speed_dial.dart'; // تأكدي من وجود هذا الملف ومساره الصحيح

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
    // 🌟 جلب ألوان الثيم للـ Dark Mode 🌟
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor, // 🌟 يتجاوب مع الثيم
        elevation: 0,
        // تفعيل زر الإعدادات لينقلك لصفحة الإعدادات
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: textColor), // 🌟 يتجاوب مع الثيم
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: Text("الرسائل", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), // 🌟 يتجاوب مع الثيم
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor), // 🌟 يتجاوب مع الثيم
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      
      // 🌟 التعديل السحري: تغليف الـ Stack بـ Directionality لضمان اتجاه الشريط السفلي والمحتوى 🌟
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // 1. محتوى الشاشة الأساسي
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor), // لون النص المكتوب يتبع الثيم
                    decoration: InputDecoration(
                      hintText: "ابحث في المحادثات...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: cardColor, // 🌟 لون خلفية شريط البحث من الثيم
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                _buildFilterRow(context), // 🌟 تمرير context ليدعم الثيم
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      return _buildChatTile(context, chats[index]); // 🌟 تمرير context ليدعم الثيم
                    },
                  ),
                ),
                const SizedBox(height: 100), // مساحة لتجنب تغطية الشريط السفلي للمحادثات
              ],
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 3, // 🌟 3 = الرسائل مفعلة
              centerButton: const CustomSpeedDialEduBridge(), // زر المعلم الموحد
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ),
              onMessagesTap: () {}, // نحن في الرسائل أصلاً
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 إضافة BuildContext للدعم اللوني 🌟
  Widget _buildFilterRow(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
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
                // 🌟 إذا كان محدد يأخذ اللون الأصفر، وإلا يأخذ لون الكرت من الثيم
                color: isSelected ? const Color(0xFFEFFF00) : cardColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                label, 
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  // 🌟 النص أسود إذا كان الزر أصفر ليظهر بوضوح، وإلا يتبع الثيم
                  color: isSelected ? Colors.black : textColor,
                )
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🌟 إضافة BuildContext للدعم اللوني 🌟
  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 لون الكرت من الثيم
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFEBF5FB), // خلفية صورة الشخص
          child: Text(chat['initials'] ?? "D", style: const TextStyle(color: Color(0xFF2E86C1), fontWeight: FontWeight.bold)),
        ),
        title: Text(chat['name'], style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), // 🌟 لون الاسم من الثيم
        subtitle: Text(chat['message'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(chat['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (chat['unreadCount'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
                child: Text(chat['unreadCount'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
          ],
        ),
      ),
    );
  }
}