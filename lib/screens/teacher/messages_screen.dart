import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// مسارات الشاشات والويدجتس الخاصة بك (التصميم الأصلي)
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

// مسارات الربط مع الباك إند
import 'package:edu_pridge_flutter/services/chat_service.dart';
import 'package:edu_pridge_flutter/screens/shared/chat_room_screen.dart'; // تأكدي من صحة المسار إذا اختلف

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessagesView();
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
        .where((c) => (c['name'] as String)
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

    // 💡 منطق دمج البيانات: تجهيز القوائم بناءً على المعمارية تبعتك
    List<Map<String, dynamic>> headList = [];
    List<Map<String, dynamic>> adminList = [];
    List<Map<String, dynamic>> teachList = [];
    List<Map<String, dynamic>> studList = [];

    // جلب البيانات من السيرفر، وإذا كانت فارغة نعرض البيانات الوهمية للتصميم
    final sourceContacts = chatService.contacts.isNotEmpty
        ? chatService.contacts
        : _getMockData(); 

    for (final contact in sourceContacts) {
      final name = (contact['name'] as String? ?? '').toLowerCase();
      final role = (contact['role'] as String? ?? '').toLowerCase();

      // تحويل شكل البيانات ليناسب _buildChatTile الخاص بك
      final conv = {
        'id': contact['id'] ?? 0,
        'name': contact['name'] ?? 'مجهول',
        'message': (contact['last_message'] != null && contact['last_message'].toString().trim().isNotEmpty)
            ? contact['last_message']
            : (contact['message'] != null && contact['message'].toString().trim().isNotEmpty)
                ? contact['message']
                : 'انقر لبدء المحادثة...',
        'time': contact['time'] ?? contact['sent_at'] ?? 'الآن',
        'is_read': (contact['unread'] == null || contact['unread'] == 0) && (contact['is_read'] != false),
        'image': contact['image'],
        'raw_contact': contact, // 🌟 نحتفظ بالبيانات الأصلية لتمريرها للـ ChatRoomScreen
        'role': contact['role'] ?? '',
      };

      // 💡 تصفية المحادثات الفارغة: لا نعرض جهات الاتصال التي لم تبدأ معها محادثة بعد
      // ملاحظة: نسمح للمحاكاة (Mock Data) بالمرور لتسهيل عملية التطوير/التصميم
      if (conv['message'] == 'انقر لبدء المحادثة...' && chatService.contacts.isNotEmpty) {
        continue;
      }

      // التصنيف الذكي الخاص بك
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
          icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
        ),
        title: Text(
          "الرسائل",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
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
                                hintText: "ابحث في المحادثات...",
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
                                'لا توجد رسائل',
                                style: TextStyle(color: Colors.grey, fontSize: 15),
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
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
        child: Text(
          title,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat, ChatService chatServiceInstance, {IconData? iconData}) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isUnread  = chat['is_read'] != true;
    final name      = chat['name'] as String? ?? '';
    final initial   = name.isNotEmpty ? name[0] : '؟';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isUnread ? Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.4), width: 1) : null,
      ),
      child: ListTile(
        onTap: () {
          // 🌟 الربط السحري: تمرير الـ Provider لغرفة الشات
          if (chat['raw_contact'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: chatServiceInstance,
                  child: ChatRoomScreen(contact: chat['raw_contact']),
                ),
              ),
            );
          } else {
            debugPrint("فتح شات الشخص: $name (بيانات وهمية)");
          }
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: iconData != null ? const Color(0xFFFEF9E7) : const Color(0xFFEBF5FB),
          child: iconData != null
              ? Icon(iconData, color: const Color(0xFFD4AC0D), size: 24)
              : Text(initial, style: const TextStyle(color: Color(0xFF2E86C1), fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(
          chat['message'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (chat['role'] != null && (chat['role'] as String).isNotEmpty) ...[
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
                  chat['role'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4AC0D),
                  ),
                ),
              ),
            ],
            Text(chat['time'] as String? ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (isUnread) ...[
              const SizedBox(height: 5),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // الدالة الخاصة بك لإرجاع البيانات الوهمية في حال كان السيرفر فارغ
  List<Map<String, dynamic>> _getMockData() {
    return [
      {'name': 'د. يوسف (رئيس القسم)', 'message': 'تم اعتماد جدول الامتحانات الجديد', 'time': '2:24 م', 'is_read': false},
      {'name': 'إدارة شؤون الطلاب', 'message': 'يرجى مراجعة طلبات التسجيل المتأخرة', 'time': '2:20 م', 'is_read': true},
      {'name': 'المدرب علي (زميل)', 'message': 'هل انتهيت من تقييم مشاريع فلاتر؟', 'time': '2:11 م', 'is_read': true},
      {'name': 'أحمد خالد (طالب Flutter)', 'message': 'أستاذ، متى موعد تسليم الوظيفة؟', 'time': '12:26 م', 'is_read': false},
      {'name': 'زينب سعيد (طالبة)', 'message': 'شكراً جزيلاً لك أستاذ على الشرح', 'time': 'أمس', 'is_read': true}
    ];
  }
}