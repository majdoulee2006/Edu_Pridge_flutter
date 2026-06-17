import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Shared
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart';

// Nav Bar Pages
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import '../../../widgets/parents_center_icon.dart';

// Chat Micro-Widgets & Service
import '../../../services/chat_service.dart';
import '../../../widgets/chat/contact_tile_widget.dart';

class ParentsMessagesScreen extends StatelessWidget {
  const ParentsMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatService(),
      child: const ParentsMessagesView(),
    );
  }
}

class ParentsMessagesView extends StatefulWidget {
  const ParentsMessagesView({super.key});

  @override
  State<ParentsMessagesView> createState() => _ParentsMessagesViewState();
}

class _ParentsMessagesViewState extends State<ParentsMessagesView> {
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

                          // Simplified, friendly list without search bar
                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: dynamicContacts.length,
                            itemBuilder: (context, index) {
                              final contact = dynamicContacts[index];
                              return ContactTileWidget(
                                title: contact['name'],
                                subtitle: contact['role'],
                                avatarUrl: contact['image'],
                                unreadCount: contact['unread'] ?? 0,
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
                              );
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
                  centerButton: const Parents_Center_Icon(),
                  onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
                  onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
                  onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
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
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
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