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
import 'package:edu_pridge_flutter/services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../widgets/chat/contact_tile_widget.dart';

class AffairsOfficerMessagesScreen extends StatelessWidget {
  const AffairsOfficerMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () async { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AffairsOfficerHomeScreen())); return false; }, child: const AffairsOfficerMessagesView());
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
                          
                          final allContacts = chatService.contacts;
                          final activeContacts = allContacts.where((c) {
                            return c['role'] == 'Administration' || (c['last_message'] != null && c['last_message'].toString().trim().isNotEmpty);
                          }).toList();
                          
                          if (activeContacts.isEmpty) {
                            return const Center(child: Text('لا توجد محادثات نشطة'));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: activeContacts.length,
                            itemBuilder: (context, index) {
                              final contact = activeContacts[index];
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
            Builder(builder: (_) {
              final rawAvatar = contact['image']?.toString() ?? '';
              final fixedAvatar = ApiService.fixMediaUrl(rawAvatar);
              return CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: fixedAvatar != null && fixedAvatar.isNotEmpty ? NetworkImage(fixedAvatar) : null,
                child: fixedAvatar == null || fixedAvatar.isEmpty
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      )
                    : null,
              );
            }),
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
        trailing: SizedBox(
          width: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (role.isNotEmpty)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withAlpha(38),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFFCC00).withAlpha(102),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4AC0D),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 1),
              Text(
                time,
                style: TextStyle(
                  fontSize: 9.5,
                  color: hasUnread ? (isDark ? Colors.amber.shade300 : const Color(0xFFD4AC0D)) : Colors.grey.shade500,
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (hasUnread) ...[
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ],
          ),
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
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen())),
          ),
          const Text("الرسائل", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFFCC00), size: 28),
                tooltip: "محادثة جديدة",
                onPressed: () => _showNewChatModal(context, context.read<ChatService>()),
              ),
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

  void _showNewChatModal(BuildContext context, ChatService chatService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final contacts = chatService.contacts;
            final filtered = contacts.where((c) {
              final name = (c['name'] as String? ?? '').toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();

            final cardColor = Theme.of(context).cardColor;
            final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'محادثة جديدة (+)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (val) => setModalState(() => query = val.trim()),
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "ابحث عن شخص لمراسلته...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد جهات اتصال مطابقة',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final contact = filtered[index];
                              final name = contact['name'] as String? ?? 'مجهول';
                              final role = contact['role'] as String? ?? '';
                              final initial = name.isNotEmpty ? name[0] : '؟';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFFFCC00).withAlpha(40),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFFD4AC0D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  subtitle: role.isNotEmpty
                                      ? Text(
                                          role,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        )
                                      : null,
                                  trailing: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Color(0xFFFFCC00),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChangeNotifierProvider.value(
                                          value: chatService,
                                          child: ChatRoomScreen(contact: contact),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}