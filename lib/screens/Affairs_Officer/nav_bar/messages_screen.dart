import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Shared
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart';

// Nav Bar Pages
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';

// Chat Micro-Widgets & Service
import '../../../services/chat_service.dart';
import '../../../widgets/chat/contact_tile_widget.dart';

class AffairsOfficerMessagesScreen extends StatelessWidget {
  const AffairsOfficerMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AffairsOfficerMessagesView();
  }
}

class AffairsOfficerMessagesView extends StatefulWidget {
  const AffairsOfficerMessagesView({super.key});

  @override
  State<AffairsOfficerMessagesView> createState() => _AffairsOfficerMessagesViewState();
}

class _AffairsOfficerMessagesViewState extends State<AffairsOfficerMessagesView> {
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
                      padding: const EdgeInsets.only(bottom: 90),
                      child: Consumer<ChatService>(
                        builder: (context, chatService, child) {
                          if (chatService.isLoadingContacts) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final dynamicContacts = chatService.contacts;
                          
                          if (dynamicContacts.isEmpty) {
                            return const Center(child: Text('لا توجد جهات اتصال'));
                          }

                          // Simplified list for Affairs Officer
                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: dynamicContacts.length,
                            itemBuilder: (context, index) {
                              final contact = dynamicContacts[index];
                              return _buildChatTile(context, contact, isDark, cardColor, textColor);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: CustomBottomNav(
                  currentIndex: 3,
                  centerButton: const AffairsOfficerSpeedDial(),
                  onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen())),
                  onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AffairsOfficerProfileScreen())),
                  onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen())),
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
    final bool isRead = contact['is_read'] ?? true;

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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (role.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 4),
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
              const SizedBox(height: 5),
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
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen())),
          ),
          const Text("الرسائل", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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