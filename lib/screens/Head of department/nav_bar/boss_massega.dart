import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/Head of department/nav_bar/boss_home.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Shared
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import '../../../widgets/boss_center_icon.dart';
import '../../../services/chat_service.dart';
import '../../../widgets/chat/contact_tile_widget.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart';

class BossMessageScreen extends StatelessWidget {
  const BossMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () async { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())); return false; }, child: const BossMessageView());
  }
}

class BossMessageView extends StatefulWidget {
  const BossMessageView({super.key});

  @override
  State<BossMessageView> createState() => _BossMessageViewState();
}

class _BossMessageViewState extends State<BossMessageView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatService = context.read<ChatService>();
      chatService.fetchContacts();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) {
        chatService.initPusher(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark),
                  
                  // Main Content: Full Screen Contacts List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 90), // Space for bottom nav
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "بحث عن جهة اتصال...",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Consumer<ChatService>(
                              builder: (context, chatService, child) {
                                if (chatService.isLoadingContacts) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                                                final allContacts = chatService.contacts;
                                final dynamicContacts = allContacts.where((c) {
                                  return c['role'] == 'Administration' || (c['last_message'] != null && c['last_message'].toString().trim().isNotEmpty);
                                }).toList();

                                
                                if (dynamicContacts.isEmpty) {
                                  return const Center(child: Text('لا توجد جهات اتصال'));
                                }

                                return ListView.builder(
                                  itemCount: dynamicContacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = dynamicContacts[index];
                                    return _buildChatTile(context, contact, isDark, cardColor, textColor);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Navigation Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: CustomBottomNav(
                  currentIndex: 3,
                  centerButton: const Boss_Center_Icon(),
                  onHomeTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                  onProfileTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const BossProfileScreen())),
                  onNotificationsTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const BossNotificationScreen())),
                  onMessagesTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> contact, bool isDark, Color cardColor, Color textColor) {
    final int unreadCount = contact['unread'] ?? 0;
    final bool hasUnread = unreadCount > 0;
    final String name = contact['name'] ?? 'مستخدم غير معروف';
    final String initial = name.isNotEmpty ? name[0] : '؟';
    final String role = contact['role'] ?? '';
    final String lastMsg = (contact['last_message'] != null && contact['last_message'].toString().trim().isNotEmpty)
        ? contact['last_message']
        : 'انقر لبدء المحادثة...';
    final String time = contact['time'] ?? 'الآن';
    final String? avatarUrl = contact['image'];
    final bool isOnline = contact['is_online'] ?? false;
    final bool isRead = contact['is_read'] == true;
      final bool isMyMessage = contact['is_my_message'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: hasUnread
            ? [BoxShadow(color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        border: hasUnread ? Border.all(color: const Color(0xFFFFCC00).withAlpha(102), width: 1) : null,
      ),
      child: ListTile(
        onTap: () {
          final chatServiceInstance = context.read<ChatService>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: chatServiceInstance,
                child: ChatRoomScreen(contact: contact),
              ),
            ),
          );
        },
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      initial,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    )
                  : null,
            ),
            if (isOnline)
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
                      color: cardColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
        ),
        subtitle: Row(
          children: [
            if (isRead && !hasUnread) 
              const Padding(
                padding: EdgeInsets.only(left: 4), 
                child: Icon(Icons.done_all, color: Colors.blue, size: 16)
              ),
            Expanded(
              child: Text(
                lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  fontSize: 13,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (role.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withAlpha(38), // ~0.15 opacity
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFFCC00).withAlpha(102), // ~0.4 opacity
                    width: 0.5,
                  ),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4AC0D),
                  ),
                ),
              ),
            ],
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? (isDark ? Colors.amber.shade300 : const Color(0xFFD4AC0D)) : Colors.grey.shade500,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
          ),
          const Text("الرسائل", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Row(
            children: [
              // Broadcast icon successfully removed here!
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(userName: "أحمد عبدالله", userRole: "رئيس قسم"),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Colors.grey, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}