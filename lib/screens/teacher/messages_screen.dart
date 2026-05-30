import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'teacher_home.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../widgets/teacher_speed_dial.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = false;
  String _searchQuery = '';

  List<Map<String, dynamic>> _headOfDepartmentChats = [];
  List<Map<String, dynamic>> _adminChats = [];
  List<Map<String, dynamic>> _teachersChats = [];
  List<Map<String, dynamic>> _studentsChats = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/messages",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      List<Map<String, dynamic>> messages = [];

      if (res.statusCode == 200 && res.data['success'] == true) {
        messages = (res.data['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // 💡 خطة طوارئ: إذا كانت البيانات فارغة من الـ API، نضع بيانات وهمية لتري التصميم فوراً
      if (messages.isEmpty) {
        messages = [
          {'other_party': 'د. يوسف (رئيس القسم)', 'message': 'تم اعتماد جدول الامتحانات الجديد', 'sent_at': '2:24 رساَم', 'is_read': false},
          {'other_party': 'إدارة شؤون الطلاب', 'message': 'يرجى مراجعة طلبات التسجيل المتأخرة', 'sent_at': '2:20 رساَم', 'is_read': true},
          {'other_party': 'المدرب علي (زميل)', 'message': 'هل انتهيت من تقييم مشاريع فلاتر؟', 'sent_at': '2:11 رساَم', 'is_read': true},
          {'other_party': 'أحمد خالد (طالب Flutter)', 'message': 'أستاذ، متى موعد تسليم الوظيفة؟', 'sent_at': '12:26 رساَم', 'is_read': false},
          {'other_party': 'زينب سعيد (طالبة)', 'message': 'شكراً جزيلاً لك أستاذ على الشرح', 'sent_at': 'أمس', 'is_read': true},
        ];
      }

      // تجميع الشاتات لضمان عدم التكرار
      final Map<String, Map<String, dynamic>> convMap = {};
      for (final msg in messages) {
        final party = msg['other_party'] as String? ?? 'محادثة عامة';
        if (!convMap.containsKey(party)) {
          convMap[party] = {
            'name':      party,
            'message':   msg['message'] as String? ?? '',
            'time':      msg['sent_at'] as String? ?? '',
            'is_read':   msg['is_read'] == true,
          };
        }
      }

      final allConversations = convMap.values.toList();

      final List<Map<String, dynamic>> headList = [];
      final List<Map<String, dynamic>> adminList = [];
      final List<Map<String, dynamic>> teachList = [];
      final List<Map<String, dynamic>> studList = [];

      for (final conv in allConversations) {
        final name = (conv['name'] as String? ?? '').toLowerCase();
        
        if (name.contains('رئيس') || name.contains('يوسف')) {
          headList.add(conv);
        } else if (name.contains('إدارة') || name.contains('اداره') || name.contains('القبول') || name.contains('admin')) {
          adminList.add(conv);
        } else if (name.contains('مدرب') || name.contains('زميل') || name.contains('مهندس') || name.contains('teacher')) {
          teachList.add(conv);
        } else {
          studList.add(conv);
        }
      }

      setState(() {
        _headOfDepartmentChats = headList;
        _adminChats = adminList;
        _teachersChats = teachList;
        _studentsChats = studList;
      });

    } catch (e) {
      debugPrint('⛔ Messages Error: $e');
      // حتى لو ضرب الـ Connection بالكامل، تظهر البيانات الوهمية ليعمل التصميم
      _loadMockData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMockData() {
    setState(() {
      _headOfDepartmentChats = [{'name': 'د. يوسف (رئيس القسم)', 'message': 'تم اعتماد جدول الامتحانات الجديد', 'time': '2:24 رساَم', 'is_read': false}];
      _adminChats = [{'name': 'إدارة شؤون الطلاب', 'message': 'يرجى مراجعة طلبات التسجيل المتأخرة', 'time': '2:20 رساَم', 'is_read': true}];
      _teachersChats = [{'name': 'المدرب علي (زميل)', 'message': 'هل انتهيت من تقييم مشاريع فلاتر؟', 'time': '2:11 رساَم', 'is_read': true}];
      _studentsChats = [
        {'name': 'أحمد خالد (طالب Flutter)', 'message': 'أستاذ، متى موعد تسليم الوظيفة؟', 'time': '12:26 رساَم', 'is_read': false},
        {'name': 'زينب سعيد (طالبة)', 'message': 'شكراً جزيلاً لك أستاذ على الشرح', 'time': 'أمس', 'is_read': true}
      ];
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

    final filteredHead     = _filterList(_headOfDepartmentChats);
    final filteredAdmins   = _filterList(_adminChats);
    final filteredTeachers = _filterList(_teachersChats);
    final filteredStudents = _filterList(_studentsChats);

    final bool isAllEmpty = filteredHead.isEmpty && filteredAdmins.isEmpty && filteredTeachers.isEmpty && filteredStudents.isEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
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
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchMessages,
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
                                  (context, index) => _buildChatTile(context, filteredHead[index], iconData: Icons.person_pin_rounded),
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
                                  (context, index) => _buildChatTile(context, filteredAdmins[index], iconData: Icons.admin_panel_settings_outlined),
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
                                  (context, index) => _buildChatTile(context, filteredTeachers[index]),
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
                                  (context, index) => _buildChatTile(context, filteredStudents[index]),
                                  childCount: filteredStudents.length,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

            CustomBottomNav(
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

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat, {IconData? iconData}) {
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
          debugPrint("فتح شات الشخص: $name");
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
          children: [
            Text(chat['time'] as String? ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}