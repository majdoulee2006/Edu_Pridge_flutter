import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  final List<Map<String, dynamic>> chats = [
    {
      "name": "د. أحمد الخالدي",
      "role": "رئيس قسم الكومبيوتر ونظم المعلومات",
      "lastMessage": "تم اعتماد الجدول الدراسي الجديد",
      "time": "10:45",
      "unread": 2,
    },
    {
      "name": "د. فاطمة الزهراء",
      "role": "رئيسة قسم الطبي",
      "lastMessage": "هل يمكنك مراجعة تقرير الطلاب؟",
      "time": "09:30",
      "unread": 0,
    },
    {
      "name": "د. محمد العتيبي",
      "role": "رئيس قسم التجاري",
      "lastMessage": "شكراً على التعميم السابق",
      "time": "أمس",
      "unread": 1,
    },
    {
      "name": "أ. خالد الشهري",
      "role": "موظف الشؤون الإدارية",
      "lastMessage": "تم إنهاء إجراءات التوظيف الجديدة",
      "time": "أمس",
      "unread": 3,
    },
    {
      "name": "د. سارة العمري",
      "role": "رئيسة قسم اللغة الإنجليزية",
      "lastMessage": "متى موعد الاجتماع القادم؟",
      "time": "أمس",
      "unread": 0,
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);

    final filteredChats = chats.where((chat) {
      return chat["name"].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          chat["role"].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "الرسائل",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // البحث
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: "ابحث في المحادثات...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // قائمة المحادثات
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return _buildChatTile(chat, cardColor, textColor);
                      },
                    ),
                  ),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 3,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminNotificationsScreen())),
              onMessagesTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF2A2A2A),
              child: Icon(Icons.person, color: Colors.white70, size: 32),
            ),

            const SizedBox(width: 12),

            // النصوص (الجزء الأهم)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat['role'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // الوقت والإشعارات
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (chat['unread'] > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFFF00),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat['unread'].toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}