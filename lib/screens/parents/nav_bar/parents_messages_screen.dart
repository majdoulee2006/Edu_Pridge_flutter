import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ParentsMessagesScreen extends StatelessWidget {
  const ParentsMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsHomeScreen()));
      },
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
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

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  List<Map<String, dynamic>> _getMockActiveData(bool isAr) {
    return [
      {'id': 1, 'name': isAr ? 'أ. مريم (مدرسة اللغة العربية)' : 'Ms. Maryam (Arabic Teacher)', 'message': isAr ? 'أهلاً بك، ابنكم متفوق جداً هذا الفصل' : 'Welcome, your son is excelling this semester', 'time': isAr ? '2:24 م' : '2:24 PM', 'is_read': false, 'role': isAr ? 'مدرسة' : 'Teacher', 'raw_contact': {'id': 1, 'name': isAr ? 'أ. مريم (مدرسة اللغة العربية)' : 'Ms. Maryam (Arabic Teacher)', 'role': isAr ? 'مدرسة' : 'Teacher'}},
      {'id': 2, 'name': isAr ? 'د. يوسف (رئيس قسم الحاسوب)' : 'Dr. Youssef (CS Dept Head)', 'message': isAr ? 'تم تحديد موعد اجتماع أولياء الأمور المقبل' : 'Next parent-teacher meeting is scheduled', 'time': isAr ? '2:20 م' : '2:20 PM', 'is_read': true, 'role': isAr ? 'رئيس القسم' : 'Dept Head', 'raw_contact': {'id': 2, 'name': isAr ? 'د. يوسف (رئيس قسم الحاسوب)' : 'Dr. Youssef (CS Dept Head)', 'role': isAr ? 'رئيس القسم' : 'Dept Head'}},
      {'id': 3, 'name': isAr ? 'إدارة المدرسة' : 'School Administration', 'message': isAr ? 'يرجى استلام بطاقات النتائج الامتحانية' : 'Please receive the exam report cards', 'time': isAr ? '2:11 م' : '2:11 PM', 'is_read': true, 'role': isAr ? 'إدارة' : 'Admin', 'raw_contact': {'id': 3, 'name': isAr ? 'إدارة المدرسة' : 'School Administration', 'role': isAr ? 'إدارة' : 'Admin'}},
    ];
  }

  List<Map<String, dynamic>> _getNewContactsMockData(bool isAr) {
    return [
      {'id': 10, 'name': isAr ? 'م. خالد (مدرس الفيزياء)' : 'Eng. Khaled (Physics Teacher)', 'role': isAr ? 'مدرس' : 'Teacher', 'raw_contact': {'id': 10, 'name': isAr ? 'م. خالد (مدرس الفيزياء)' : 'Eng. Khaled (Physics Teacher)', 'role': isAr ? 'مدرس' : 'Teacher'}},
      {'id': 11, 'name': isAr ? 'أ. ريم (مدرسة الرياضيات)' : 'Ms. Reem (Math Teacher)', 'role': isAr ? 'مدرسة' : 'Teacher', 'raw_contact': {'id': 11, 'name': isAr ? 'أ. ريم (مدرسة الرياضيات)' : 'Ms. Reem (Math Teacher)', 'role': isAr ? 'مدرسة' : 'Teacher'}},
      {'id': 12, 'name': isAr ? 'الموجه التربوي' : 'Educational Supervisor', 'role': isAr ? 'إدارة' : 'Admin', 'raw_contact': {'id': 12, 'name': isAr ? 'الموجه التربوي' : 'Educational Supervisor', 'role': isAr ? 'إدارة' : 'Admin'}},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final bool isAr = AppSettings.language.value == 'ar';

    final chatService = context.watch<ChatService>();
    final isLoading = chatService.isLoadingContacts;

    final allContacts = chatService.contacts.isNotEmpty
        ? chatService.contacts
        : _getMockActiveData(isAr);

    final activeContacts = allContacts.where((c) {
      final name = (c['name']?.toString() ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark, isAr),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isAr ? "ابحث في المحادثات..." : "Search conversations...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                        : activeContacts.isEmpty
                            ? Center(
                                child: Text(
                                  isAr
                                      ? 'لا توجد محادثات مطابقة\nاضغط على (+) لبدء محادثة جديدة'
                                      : 'No matching conversations\nTap (+) to start a new chat',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: textColor.withAlpha(150)),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: activeContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = activeContacts[index];
                                  return _buildChatTile(context, contact, isDark, cardColor, textColor, chatService, isAr);
                                },
                              ),
                  ),
                ],
              ),

              CustomBottomNav(
                currentIndex: 3,
                centerButton: const ParentsCenterIcon(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
                onMessagesTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> contact, bool isDark, Color cardColor, Color textColor, ChatService chatServiceInstance, bool isAr) {
    final int unreadCount = contact['unread'] ?? 0;
    final bool isMyMessage = contact['is_my_message'] == true;
    final bool isUnread = !isMyMessage && unreadCount > 0;
    final String name    = contact['name']?.toString() ?? (isAr ? 'مستخدم غير معروف' : 'Unknown User');
    final String initial = name.isNotEmpty ? name[0] : '?';
    final String role    = contact['role']?.toString() ?? '';
    final String lastMsg = contact['message']?.toString() ?? contact['last_message']?.toString() ?? (isAr ? 'انقر لبدء المحادثة...' : 'Tap to start chatting...');
    final String time    = contact['time']?.toString() ?? (isAr ? 'الآن' : 'Now');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? const Color(0xFFFFCC00).withAlpha(120) : Colors.white10,
          width: isUnread ? 1.2 : 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final contactToPass = contact['raw_contact'] ?? contact;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: chatServiceInstance,
                child: ChatRoomScreen(contact: contactToPass),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFFFCC00).withAlpha(30),
                child: Text(initial, style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 17)),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                          ),
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00).withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFCC00).withAlpha(102), width: 0.5),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD4AC0D)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!isUnread) ...[
                          const Icon(Icons.done_all, size: 16, color: Color(0xFF34B7F1)),
                          const SizedBox(width: 4),
                        ] else ...[
                          const Icon(Icons.check, size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isUnread ? textColor.withAlpha(220) : Colors.grey,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 6),
                  if (isUnread)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
                    )
                  else
                    const SizedBox(height: 9),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
          ),
          Text(isAr ? "الرسائل" : "Messages", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFFCC00), size: 28),
                tooltip: isAr ? "محادثة جديدة" : "New Chat",
                onPressed: () => _showNewChatModal(context, context.read<ChatService>(), isAr),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
                child: Container(
                  margin: EdgeInsets.only(right: isAr ? 8 : 0, left: isAr ? 0 : 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withAlpha(50)),
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

  void _showNewChatModal(BuildContext context, ChatService chatService, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final contacts = chatService.contacts.isNotEmpty ? chatService.contacts : _getNewContactsMockData(isAr);
            final filtered = contacts.where((c) {
              final name = (c['name']?.toString() ?? '').toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();

            final cardColor = Theme.of(context).cardColor;
            final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
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
                          isAr ? 'بدء محادثة جديدة (+)' : 'Start New Chat (+)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
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
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isAr ? "ابحث عن شخص لمراسلته..." : "Search for someone to message...",
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
                          ? Center(child: Text(isAr ? 'لا توجد جهات اتصال مطابقة' : 'No matching contacts', style: const TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final contact = filtered[index];
                                final name = contact['name']?.toString() ?? (isAr ? 'مجهول' : 'Unknown');
                                final role = contact['role']?.toString() ?? '';
                                final initial = name.isNotEmpty ? name[0] : '?';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFFFCC00).withAlpha(40),
                                      child: Text(initial, style: const TextStyle(color: Color(0xFFD4AC0D), fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                    subtitle: role.isNotEmpty ? Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
                                    trailing: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFFCC00)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChangeNotifierProvider.value(
                                            value: chatService,
                                            child: ChatRoomScreen(contact: contact['raw_contact'] ?? contact),
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
              ),
            );
          },
        );
      },
    );
  }
}