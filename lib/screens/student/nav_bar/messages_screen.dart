import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/select_teacher_screen.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/models/chat_model.dart';

import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selectedCategory = 'الكل';
  String searchQuery = '';

  List<ChatModel> allChats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  // 🌟 مجهزة للربط مع API اللارافل
  Future<void> _fetchChats() async {
    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      allChats = [
        ChatModel(id: 1, title: 'برمجة الحاسوب 1', lastMessage: 'د. أحمد: تم رفع الأكواد الخاصة بمحاضرة...', time: '10:30 ص', unreadCount: 0, type: 'الجروبات', isOnline: true, isRead: false, isGroup: true, avatarUrl: 'https://i.pravatar.cc/150?u=ahmed1'),
        ChatModel(id: 2, title: 'د. سارة الأحمد', lastMessage: 'مرحباً أحمد، تفضل ما هو استفسارك؟', time: '10:15 ص', unreadCount: 1, type: 'المدرسين', isOnline: true, isRead: false, isGroup: false, avatarUrl: 'https://i.pravatar.cc/150?u=sarah'),
        ChatModel(id: 3, title: 'الرياضيات المتقدمة', lastMessage: 'تم تحديد موعد الاختبار النصفي يوم الأحد...', time: 'أمس', unreadCount: 0, type: 'الجروبات', isOnline: false, isRead: true, isGroup: true, avatarUrl: 'https://i.pravatar.cc/150?u=math'),
        ChatModel(id: 4, title: 'م. خالد العلي', lastMessage: 'تم استلام وظيفتك بنجاح، شكراً لك.', time: 'أمس', unreadCount: 0, type: 'المدرسين', isOnline: false, isRead: true, isGroup: false, avatarUrl: 'https://i.pravatar.cc/150?u=khaled'),
        ChatModel(id: 5, title: 'الفيزياء العامة', lastMessage: 'تذكير: تسليم تقرير المختبر الثاني غداً', time: 'منذ يومين', unreadCount: 2, type: 'الجروبات', isOnline: false, isRead: false, isGroup: true, avatarUrl: 'https://i.pravatar.cc/150?u=physics'),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<ChatModel> filteredChats = allChats.where((chat) {
      bool matchesCategory = false;
      if (selectedCategory == 'الكل') {
        matchesCategory = true;
      } else if (selectedCategory == 'غير مقروءة') {
        matchesCategory = chat.unreadCount > 0;
      } else {
        matchesCategory = chat.type == selectedCategory;
      }

      bool matchesSearch =
          chat.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              chat.lastMessage.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF7F9FC),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen())),
          ),
          title: Text('الرسائل', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildSearchBar(),
                _buildChatCategories(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                      : filteredChats.isEmpty
                      ? Center(
                    child: Text('لا توجد رسائل مطابقة للبحث أو الفلتر', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectTeacherScreen()));
                },
              ),
            ),
            CustomBottomNav(
              currentIndex: 3,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              onMessagesTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade300),
      ),
      child: TextField(
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'ابحث عن مادة أو مدرس...',
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey, fontSize: 14),
          suffixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade500 : Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildChatCategories() {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = selectedCategory == label;

    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFF00) : (isDark ? Colors.white.withAlpha(20) : const Color(0xFFEFEFEF)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool hasUnread = chat.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hasUnread ? (isDark ? Theme.of(context).cardColor : Colors.white) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: hasUnread
            ? [BoxShadow(color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              backgroundImage: NetworkImage(chat.avatarUrl),
            ),
            if (chat.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasUnread ? (isDark ? Theme.of(context).cardColor : Colors.white) : (isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF7F9FC)),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
        ),
        subtitle: Row(
          children: [
            if (chat.isRead) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.done_all, color: Colors.blue, size: 16)),
            Expanded(
              child: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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
              chat.time,
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? (isDark ? Colors.amber.shade300 : const Color(0xFFD4AC0D)) : Colors.grey.shade500,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            if (hasUnread)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                receiverId: chat.id, // 🌟 التعديل السحري هنا اللي حل المشكلة
                name: chat.title,
                imageUrl: chat.avatarUrl,
                isGroup: chat.isGroup,
              ),
            ),
          );
        },
      ),
    );
  }
}