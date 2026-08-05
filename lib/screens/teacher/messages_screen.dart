import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/teacher/teacher_home.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// مسارات الشاشات والويدجتس الخاصة بك
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

// مسارات الربط مع الباك إند
import 'package:edu_pridge_flutter/services/chat_service.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () async { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherHomeScreen())); return false; }, child: const MessagesView());
  }
}

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  String _searchQuery = '';

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

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((c) => (c['name']?.toString() ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // مراقبة خدمة الشات
    final chatService = context.watch<ChatService>();
    final isLoading = chatService.isLoadingContacts;

    // 💡 تصفية المحادثات النشطة فقط (الذين تحدثت معهم المعلمة سابقاً)
    final allContacts = chatService.contacts.isNotEmpty
        ? chatService.contacts
        : _getMockActiveData();

    // نأخذ فقط من لديه رسائل سابقة
    final activeContacts = allContacts.where((c) {
      if (chatService.contacts.isEmpty) return true; // mock active data
      final lastMsg = c['last_message']?.toString().trim() ?? '';
      final msg = c['message']?.toString().trim() ?? '';
      final hasLast = lastMsg.isNotEmpty;
      final hasMsg = msg.isNotEmpty && msg != 'انقر لبدء المحادثة...';
      return hasLast || hasMsg;
    }).toList();

    List<Map<String, dynamic>> headList = [];
    List<Map<String, dynamic>> adminList = [];
    List<Map<String, dynamic>> teachList = [];
    List<Map<String, dynamic>> studList = [];

    for (final contact in activeContacts) {
      final name = (contact['name']?.toString() ?? 'مجهول').toLowerCase();
      final role = (contact['role']?.toString() ?? '').toLowerCase();

      final lastMsgStr = contact['last_message']?.toString().trim() ?? '';
      final msgStr = contact['message']?.toString().trim() ?? '';

      final conv = {
        'id': contact['id'] ?? 0,
        'name': contact['name']?.toString() ?? 'مجهول',
        'message': lastMsgStr.isNotEmpty
            ? lastMsgStr
            : (msgStr.isNotEmpty ? msgStr : 'انقر لبدء المحادثة...'),
        'time': contact['time']?.toString() ?? contact['sent_at']?.toString() ?? 'الآن',
        'is_read': (contact['unread'] == null || contact['unread'] == 0) && (contact['is_read'] != false),
        'image': contact['image'],
        'raw_contact': contact,
        'role': contact['role']?.toString() ?? '',
      };

      if (name.contains('رئيس') || name.contains('يوسف') || role.contains('head')) {
        headList.add(conv);
      } else if (name.contains('إدارة') || name.contains('اداره') || name.contains('القبول') || name.contains('admin') || role.contains('admin')) {
        adminList.add(conv);
      } else if (name.contains('مدرب') || name.contains('زميل') || name.contains('مهندس') || name.contains('teacher') || role.contains('teacher')) {
        teachList.add(conv);
      } else {
        studList.add(conv);
      }
    }

    final filteredHead     = _filterList(headList);
    final filteredAdmins   = _filterList(adminList);
    final filteredTeachers = _filterList(teachList);
    final filteredStudents = _filterList(studList);

    final bool isAllEmpty = filteredHead.isEmpty && filteredAdmins.isEmpty && filteredTeachers.isEmpty && filteredStudents.isEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 20),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
        ),
        title: Text(
          "الرسائل",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFFFFCC00), size: 28),
            tooltip: "محادثة جديدة",
            onPressed: () => _showNewChatModal(context, chatService),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await context.read<ChatService>().fetchContacts();
                    },
                    color: const Color(0xFFFFCC00),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              textAlign: TextAlign.right,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                hintText: "ابحث في المحادثات السابقة...",
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (isAllEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'لا توجد محادثات سابقة حتى الآن\nاضغطي على (+) لبدء محادثة جديدة',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
                              ),
                            ),
                          )
                        else ...[
                          if (filteredHead.isNotEmpty) ...[
                            _buildSectionHeader("رئيس القسم", textColor),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildChatTile(context, filteredHead[index], chatService, iconData: Icons.person_pin_rounded),
                                  childCount: filteredHead.length,
                                ),
                              ),
                            ),
                          ],

                          if (filteredAdmins.isNotEmpty) ...[
                            _buildSectionHeader("شات الإدارة", textColor),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildChatTile(context, filteredAdmins[index], chatService, iconData: Icons.admin_panel_settings_outlined),
                                  childCount: filteredAdmins.length,
                                ),
                              ),
                            ),
                          ],

                          if (filteredTeachers.isNotEmpty) ...[
                            _buildSectionHeader("المدربين والزملاء", textColor),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildChatTile(context, filteredTeachers[index], chatService),
                                  childCount: filteredTeachers.length,
                                ),
                              ),
                            ),
                          ],

                          if (filteredStudents.isNotEmpty) ...[
                            _buildSectionHeader("محادثات الطلاب", textColor),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildChatTile(context, filteredStudents[index], chatService),
                                  childCount: filteredStudents.length,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNav(
                currentIndex: 3,
                centerButton: const CustomSpeedDialEduBridge(),
                onHomeTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                onMessagesTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
        child: Text(
          title,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 🌟 تصميم حديث وأنيق وآمن 100% ضد الأخطاء
  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat, ChatService chatServiceInstance, {IconData? iconData}) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isUnread  = chat['is_read'] != true;
    final name      = chat['name']?.toString() ?? 'مجهول';
    final initial   = name.isNotEmpty ? name[0] : '؟';
    final role      = chat['role']?.toString() ?? '';
    final message   = chat['message']?.toString() ?? '';
    final time      = chat['time']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          final contactToPass = chat['raw_contact'] ?? {
            'id': chat['id'] ?? 1,
            'name': name,
            'role': role,
          };
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
              // Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: iconData != null ? const Color(0xFFFEF9E7) : const Color(0xFFFFCC00).withAlpha(30),
                child: iconData != null
                    ? Icon(iconData, color: const Color(0xFFD4AC0D), size: 24)
                    : Text(initial, style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 17)),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle & Role
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00).withAlpha(38),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFFCC00).withAlpha(102),
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
                            message,
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

              // Time & Unread dot
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  if (isUnread)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCC00),
                        shape: BoxShape.circle,
                      ),
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

  static final List<Map<String, dynamic>> _activeMockList = [
    {'id': 1, 'name': 'د. يوسف (رئيس القسم)', 'message': 'تم اعتماد جدول الامتحانات الجديد', 'time': '2:24 م', 'is_read': true, 'role': 'رئيس القسم', 'raw_contact': {'id': 1, 'name': 'د. يوسف (رئيس القسم)', 'role': 'رئيس القسم'}},
    {'id': 2, 'name': 'إدارة شؤون الطلاب', 'message': 'يرجى مراجعة طلبات التسجيل المتأخرة', 'time': '2:20 م', 'is_read': true, 'role': 'إدارة', 'raw_contact': {'id': 2, 'name': 'إدارة شؤون الطلاب', 'role': 'إدارة'}},
    {'id': 3, 'name': 'المدرب علي (زميل)', 'message': 'هل انتهيت من تقييم مشاريع فلاتر؟', 'time': '2:11 م', 'is_read': true, 'role': 'مدرب', 'raw_contact': {'id': 3, 'name': 'المدرب علي (زميل)', 'role': 'استاذ'}},
    {'id': 4, 'name': 'أحمد خالد (طالب Flutter)', 'message': 'أستاذ، متى موعد تسليم الوظيفة؟', 'time': '12:26 م', 'is_read': false, 'role': 'طالب', 'raw_contact': {'id': 4, 'name': 'أحمد خالد (طالب Flutter)', 'role': 'طالب'}},
    {'id': 5, 'name': 'زينب سعيد (طالبة)', 'message': 'شكراً جزيلاً لك أستاذ على الشرح', 'time': 'أمس', 'is_read': true, 'role': 'طالب', 'raw_contact': {'id': 5, 'name': 'زينب سعيد (طالبة)', 'role': 'طالب'}}
  ];

  List<Map<String, dynamic>> _getMockActiveData() {
    return _activeMockList;
  }

  // جهات الاتصال الجديدة المتاحة لبدء شات جديد (عند النقر على زر +)
  List<Map<String, dynamic>> _getNewContactsMockData() {
    return [
      {'id': 10, 'name': 'د. سامر النجار (عميد الكلية)', 'role': 'إدارة', 'raw_contact': {'id': 10, 'name': 'د. سامر النجار (عميد الكلية)', 'role': 'إدارة'}},
      {'id': 11, 'name': 'م. ريم الخالد (مدرسة شبكات)', 'role': 'استاذ', 'raw_contact': {'id': 11, 'name': 'م. ريم الخالد (مدرسة شبكات)', 'role': 'استاذ'}},
      {'id': 12, 'name': 'د. هاني قاسم (رئيس قسم الحاسوب)', 'role': 'رئيس القسم', 'raw_contact': {'id': 12, 'name': 'د. هاني قاسم (رئيس قسم الحاسوب)', 'role': 'رئيس القسم'}},
      {'id': 13, 'name': 'عمر الفاروق (طالب)', 'role': 'طالب', 'raw_contact': {'id': 13, 'name': 'عمر الفاروق (طالب)', 'role': 'طالب'}},
      {'id': 14, 'name': 'سارة الأحمد (طالبة)', 'role': 'طالب', 'raw_contact': {'id': 14, 'name': 'سارة الأحمد (طالبة)', 'role': 'طالب'}},
      {'id': 15, 'name': 'مكتب الامتحانات والتنسيق', 'role': 'إدارة', 'raw_contact': {'id': 15, 'name': 'مكتب الامتحانات والتنسيق', 'role': 'إدارة'}},
    ];
  }

  // 🌟 مودال زر الزائد (+): يعرض الأشخاص غير المتحدث معهم لبدء شات جديد
  void _showNewChatModal(BuildContext context, ChatService chatService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<Map<String, dynamic>> newContacts = [];
            if (chatService.contacts.isNotEmpty) {
              newContacts = chatService.contacts.where((c) {
                final lastMsg = c['last_message']?.toString().trim() ?? '';
                final msg = c['message']?.toString().trim() ?? '';
                final hasLast = lastMsg.isNotEmpty;
                final hasMsg = msg.isNotEmpty && msg != 'انقر لبدء المحادثة...';
                return !hasLast && !hasMsg; // لم نتحدث معهم من قبل
              }).toList();

              if (newContacts.isEmpty) {
                newContacts = chatService.contacts; // إذا الجميع تم محادثتهم نعرضهم للبحث
              }
            } else {
              newContacts = _getNewContactsMockData();
            }

            final filtered = newContacts.where((c) {
              final name = (c['name']?.toString() ?? '').toLowerCase();
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
                        'بدء محادثة جديدة (+)',
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
                      hintText: "ابحث عن شخص لمراسلته أول مرة...",
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
                  const SizedBox(height: 14),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'لا يوجد أشخاص جدد لبدء محادثة',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final contact = filtered[index];
                              final name = contact['name']?.toString() ?? 'مجهول';
                              final role = contact['role']?.toString() ?? '';
                              final initial = name.isNotEmpty ? name[0] : '؟';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white10),
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: role.isNotEmpty
                                      ? Text(
                                          role,
                                          style: const TextStyle(color: Color(0xFFD4AC0D), fontSize: 12),
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
            );
          },
        );
      },
    );
  }
}