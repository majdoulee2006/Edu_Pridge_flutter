import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/select_teacher_screen.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';
import 'package:flutter/material.dart';
//import '../../../core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // متغير لتحديد الفلتر المختار حالياً
  String selectedCategory = 'الكل';
  // 🌟 متغير لتخزين نص البحث 🌟
  String searchQuery = '';

  // ✅ إضافة محادثات متنوعة (جروبات + مدربين)
  final List<Map<String, dynamic>> allChats = [
    {
      'name': 'برمجة الحاسوب 1',
      'message': 'د. أحمد: تم رفع الأكواد الخاصة بمحاضرة...',
      'time': '10:30 ص',
      'unread': 0,
      'type': 'الجروبات',
      'isOnline': true,
      'isRead': false,
      'isGroup': true, // ✅ تحديد أنها مجموعة
      'image': 'https://i.pravatar.cc/150?u=ahmed1',
    },
    {
      'name': 'د. سارة الأحمد',
      'message': 'مرحباً أحمد، تفضل ما هو استفسارك؟',
      'time': '10:15 ص',
      'unread': 1,
      'type': 'المدرسين',
      'isOnline': true,
      'isRead': false,
      'isGroup': false, // ✅ محادثة فردية
      'image': 'https://i.pravatar.cc/150?u=sarah',
    },
    {
      'name': 'الرياضيات المتقدمة',
      'message': 'تم تحديد موعد الاختبار النصفي يوم الأحد...',
      'time': 'أمس',
      'unread': 0,
      'type': 'الجروبات',
      'isOnline': false,
      'isRead': true,
      'isGroup': true,
      'image': 'https://i.pravatar.cc/150?u=math',
    },
    {
      'name': 'م. خالد العلي',
      'message': 'تم استلام وظيفتك بنجاح، شكراً لك.',
      'time': 'أمس',
      'unread': 0,
      'type': 'المدرسين',
      'isOnline': false,
      'isRead': true,
      'isGroup': false,
      'image': 'https://i.pravatar.cc/150?u=khaled',
    },
    {
      'name': 'الفيزياء العامة',
      'message': 'تذكير: تسليم تقرير المختبر الثاني غداً',
      'time': 'منذ يومين',
      'unread': 2,
      'type': 'الجروبات',
      'isOnline': false,
      'isRead': false,
      'isGroup': true,
      'image': 'https://i.pravatar.cc/150?u=physics',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 🌟 منطق الفلترة (حسب التصنيف + حسب شريط البحث) 🌟
    List<Map<String, dynamic>> filteredChats = allChats.where((chat) {
      // 1. فحص التصنيف
      bool matchesCategory = false;
      if (selectedCategory == 'الكل') {
        matchesCategory = true;
      } else if (selectedCategory == 'غير مقروءة') {
        matchesCategory = chat['unread'] > 0;
      } else {
        matchesCategory = chat['type'] == selectedCategory;
      }

      // 2. فحص نص البحث
      bool matchesSearch =
          chat['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          chat['message'].toLowerCase().contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F9FC),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ),
            ),
          ),
          title: const Text(
            'الرسائل',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // شريط البحث
                _buildSearchBar(),

                // أزرار الفلترة
                _buildChatCategories(),

                // قائمة المحادثات
                Expanded(
                  child: filteredChats.isEmpty
                      ? const Center(
                          child: Text('لا توجد رسائل مطابقة للبحث أو الفلتر'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120, top: 10),
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            return _buildChatItem(filteredChats[index]);
                          },
                        ),
                ),
              ],
            ),

            Positioned(
              bottom: 110,
              right: 25,
              child: FloatingActionButton(
                heroTag: "add_msg",
                backgroundColor: const Color(0xFFEFFF00),
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.black, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectTeacherScreen(),
                    ),
                  );
                },
              ),
            ),

            // 🌟 استدعاء الشريط الموحد هنا بدلاً من الأكواد الطويلة 🌟
            CustomBottomNav(
              currentIndex: 3, // 3 = الرسائل مفعّلة
              centerButton: const StudentSpeedDial(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () {}, // نحن بالفعل هنا
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        // 🌟 تفعيل البحث الفوري عند الكتابة 🌟
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'ابحث عن مادة أو مدرس...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          suffixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildChatCategories() {
    // ✅ إضافة "المدرسين" للفلاتر لتسهيل الوصول
    final categories = ['الكل', 'غير مقروءة', 'الجروبات', 'المدرسين'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryChip(categories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFF00) : const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    bool hasUnread = chat['unread'] > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hasUnread ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: hasUnread
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(chat['image']),
            ),
            if (chat['isOnline'])
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            if (chat['isRead'])
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.done_all, color: Colors.blue, size: 16),
              ),
            Expanded(
              child: Text(
                chat['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat['time'],
              style: TextStyle(
                fontSize: 11,
                color: hasUnread
                    ? const Color(0xFFD4AC0D)
                    : Colors.grey.shade500,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFFF00),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${chat['unread']}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // 🌟 تمرير حالة isGroup لواجهة الدردشة 🌟
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                name: chat['name'],
                imageUrl: chat['image'],
                isGroup: chat['isGroup'], // تمرير هل هي مجموعة أو لا
              ),
            ),
          );
        },
      ),
    );
  }
}
