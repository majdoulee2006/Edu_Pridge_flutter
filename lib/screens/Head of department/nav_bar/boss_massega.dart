import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return ChangeNotifierProvider(
      create: (_) => ChatService(),
      child: const BossMessageView(),
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().fetchContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    
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
                                
                                final dynamicContacts = chatService.contacts;
                                
                                if (dynamicContacts.isEmpty) {
                                  return const Center(child: Text('لا توجد جهات اتصال'));
                                }

                                return Column(
                                  children: [
                                    // Professional Header
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "جهات الاتصال المسموحة",
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "العدد الكلي: ${dynamicContacts.length}",
                                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: dynamicContacts.length,
                                        itemBuilder: (context, index) {
                                          final contact = dynamicContacts[index];
                                          return ContactTileWidget(
                                            title: contact['name'],
                                            subtitle: contact['role'],
                                            avatarUrl: contact['image'],
                                            unreadCount: contact['unread'] ?? 0,
                                            onTap: () {
                                              // Navigate to ChatRoomScreen, passing ChatService down
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
                                          );
                                        },
                                      ),
                                    ),
                                  ],
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
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