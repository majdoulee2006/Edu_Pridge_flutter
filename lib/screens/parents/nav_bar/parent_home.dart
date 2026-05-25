import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/notification_polling.dart';
import 'package:edu_pridge_flutter/widgets/in_app_notification_banner.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsHomeScreen extends StatefulWidget {
  const ParentsHomeScreen({super.key});

  @override
  State<ParentsHomeScreen> createState() => _ParentsHomeScreenState();
}

class _ParentsHomeScreenState extends State<ParentsHomeScreen> {
  String _parentName = "جارِ التحميل...";
  int? selectedChildId;

  Future<List<dynamic>>? _childrenFuture;
  List<Map<String, dynamic>> _announcements = [];
  bool _hasUnread = false;

  void _onUnreadChanged() {
    if (mounted) setState(() => _hasUnread = NotificationPolling.unreadCount.value > 0);
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _onNewNotif() {
    final n = NotificationPolling.latestNew.value;
    if (n != null && mounted) {
      showInAppBanner(
        context,
        n['title']?.toString() ?? 'إشعار جديد',
        n['message']?.toString() ?? n['body']?.toString() ?? '',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentsNotificationsScreen())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshChildren();
    _fetchAnnouncements();
    NotificationPolling.start('/parent/notifications');
    NotificationPolling.unreadCount.addListener(_onUnreadChanged);
    NotificationPolling.latestNew.addListener(_onNewNotif);
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    NotificationPolling.unreadCount.removeListener(_onUnreadChanged);
    NotificationPolling.latestNew.removeListener(_onNewNotif);
    NotificationPolling.stop();
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _refreshChildren() {
    setState(() {
      _childrenFuture = _fetchChildrenFromServer();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentName = prefs.getString('user_name') ??
          prefs.getString('full_name') ??
          "ولي أمر";
      selectedChildId = prefs.getInt('selected_student_id');
    });
  }

  Future<List<dynamic>> _fetchChildrenFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return [];

      final res = await Dio().get(
        "${ApiService().baseUrl}/parent/children",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        return res.data['data'] as List<dynamic>? ?? [];
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في جلب الأبناء: $e");
    }
    return [];
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/parent/announcements",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _announcements = list.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في جلب الأخبار: $e");
    }
  }

  void _showAddStudentDialog() {
    TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ربط ابن جديد", textAlign: TextAlign.right),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: "أدخل الرقم الجامعي للطالب"),
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token') ?? '';
              if (token.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("خطأ: يرجى إعادة تسجيل الدخول")),
                  );
                }
                return;
              }
              try {
                await Dio().post(
                  "${ApiService().baseUrl}/parent/add-student",
                  data: {"student_code": codeController.text},
                  options: Options(headers: {
                    "Accept": "application/json",
                    "Authorization": "Bearer $token",
                  }),
                );
                if (context.mounted) Navigator.pop(context);
                _refreshChildren();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ تم ربط الابن بنجاح")),
                  );
                }
              } on DioException catch (e) {
                final msg = e.response?.data['message'] ?? "فشل الربط: تأكد من الكود";
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: AppSettings.language.value == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            Column(
              children: [
                // ─── الهيدر الثابت ───
                Container(
                  color: cardColor,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildHeader(context, textColor, cardColor),
                        const SizedBox(height: 14),
                        _buildSectionTitle(AppSettings.language.value == 'ar' ? "الأبناء" : "Children", textColor),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                // ─── المحتوى القابل للتمرير ───
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async { _refreshChildren(); await _fetchAnnouncements(); },
                    color: const Color(0xFFCCAA00),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [
                        FutureBuilder<List<dynamic>>(
                          future: _childrenFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 240,
                                child: Center(child: CircularProgressIndicator(color: Color(0xFFCCAA00))),
                              );
                            }

                            final children = snapshot.data ?? [];

                            if (children.isNotEmpty && selectedChildId == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) async {
                                final prefs = await SharedPreferences.getInstance();
                                final first = children[0];
                                setState(() => selectedChildId = first['student_id'] as int?);
                                await prefs.setInt('selected_student_id', first['student_id'] as int);
                                await prefs.setString('selected_student_name', first['full_name'] ?? "بدون اسم");
                              });
                            }

                            return SizedBox(
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                itemCount: children.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < children.length) {
                                    final child = children[index];
                                    final studentId = child['student_id'] as int?;
                                    final isSelected = selectedChildId == studentId;
                                    final gpa = child['average_grade']?.toString() ?? "0";
                                    final attendance = child['attendance_rate']?.toString() ?? "0";

                                    return GestureDetector(
                                      onTap: () async {
                                        if (!mounted) return;
                                        setState(() => selectedChildId = studentId);
                                        final messenger = ScaffoldMessenger.of(context);
                                        final prefs = await SharedPreferences.getInstance();
                                        if (studentId != null) {
                                          await prefs.setInt('selected_student_id', studentId);
                                        }
                                        await prefs.setString('selected_student_name', child['full_name'] ?? "بدون اسم");
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text("تم اختيار: ${child['full_name']}"),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: [
                                          _buildStudentCard(
                                            child['full_name'] ?? "بدون اسم",
                                            child['level'] ?? "غير محدد",
                                            gpa,
                                            attendance,
                                            cardColor,
                                            textColor,
                                            isSelected: isSelected,
                                          ),
                                          if (isSelected)
                                            const Positioned(
                                              top: 20,
                                              right: 20,
                                              child: CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Color(0xFFFFCC00),
                                                child: Icon(Icons.check, size: 16, color: Colors.black),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return _buildAddButton(cardColor);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSectionTitle(AppSettings.language.value == 'ar' ? "أخبار المعهد والفعاليات" : "News & Events", textColor),
                        _buildNewsSection(cardColor, textColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            CustomBottomNav(
              currentIndex: 0,
              hasUnread: _hasUnread,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, Color cardColor) {
    final isAr = AppSettings.language.value == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: isAr ? "أهلاً، " : "Hello, ",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                  children: [
                    TextSpan(text: _parentName, style: const TextStyle(color: Color(0xFFCCAA00))),
                  ],
                ),
              ),
              Text(isAr ? "لوحة متابعة الأبناء" : "Children Monitoring", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(userName: _parentName, userRole: "ولي أمر"))),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
              child: const Icon(Icons.settings_outlined, color: Color(0xFFF1C40F), size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String name, String level, String gpa, String attendance,
      Color cardColor, Color textColor, {bool isSelected = false}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFCC00) : const Color(0xFFE8F200).withValues(alpha: 0.3),
          width: isSelected ? 3 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 35, backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.person, size: 40, color: Colors.indigo)),
          const SizedBox(height: 12),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), textAlign: TextAlign.center),
          Text(level, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text("حضور $attendance%", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text("معدل: $gpa", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Color cardColor) {
    return GestureDetector(
      onTap: () => _showAddStudentDialog(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 65, height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
          const SizedBox(height: 8),
          const Text("إضافة", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  static const List<Color> _cardColors = [
    Color(0xFFFFCC33),
    Color(0xFF4DB6AC),
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
  ];

  Widget _buildNewsSection(Color cardColor, Color textColor) {
    if (_announcements.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Center(child: Text("لا توجد أخبار حالياً", style: TextStyle(color: textColor.withValues(alpha: 0.4)))),
      );
    }

    return Column(
      children: List.generate(_announcements.length, (i) {
        final ann = _announcements[i];
        final headerColor = _cardColors[i % _cardColors.length];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AnnouncementDetailScreen(announcement: ann))),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: const Text('إعلان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                        ),
                      ),
                      const Center(child: Icon(Icons.campaign_outlined, size: 45, color: Colors.white60)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ann['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(ann['content'] ?? ann['body'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ann['time_ago'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          Icon(Icons.arrow_back_ios_new, size: 13, color: textColor.withValues(alpha: 0.4)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
