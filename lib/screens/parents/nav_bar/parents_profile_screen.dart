import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// ✅ استيراد الواجهات المساعدة
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class ParentsProfileScreen extends StatefulWidget {
  const ParentsProfileScreen({super.key});

  @override
  State<ParentsProfileScreen> createState() => _ParentsProfileScreenState();
}

class _ParentsProfileScreenState extends State<ParentsProfileScreen> {
  // متغيرات البيانات (لربطها بالعرض)
  String  parentName       = "جارِ التحميل...";
  String  parentPhone      = "غير متوفر";
  String  parentEmail      = "غير متوفر";
  String? _avatarUrl;
  bool    _uploadingAvatar = false;

  String studentName = "لم يتم تحديد ابن";
  String studentDept = "غير متوفر"; 
  String studentYear = "غير متوفر";
  String studentSemester = "غير متوفر";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // Show cached avatar immediately before API call
    final cachedAvatar = prefs.getString('parent_avatar_url');
    if (cachedAvatar != null && cachedAvatar.isNotEmpty && mounted) {
      setState(() => _avatarUrl = cachedAvatar);
    }

    // 1. جلب بيانات ولي الأمر من الـ endpoint المصادق عليه
    final token = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      try {
        var response = await Dio().get(
          "${ApiService().baseUrl}/user/profile",
          options: Options(headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          }),
        );
        if (response.statusCode == 200) {
          final d = (response.data['data'] ?? response.data) as Map<String, dynamic>;
          final rawAvatar = d['avatar'] as String?;
          String? avatarUrl;
          if (rawAvatar != null && rawAvatar.isNotEmpty) {
            avatarUrl = ApiService.fixMediaUrl(rawAvatar);
          }
          if (avatarUrl != null) {
            await prefs.setString('parent_avatar_url', avatarUrl);
          }
          if (mounted) {
            setState(() {
              parentName  = d['full_name'] ?? parentName;
              parentEmail = d['email']     ?? parentEmail;
              parentPhone = d['phone']     ?? parentPhone;
              _avatarUrl  = avatarUrl ?? _avatarUrl;
            });
          }
        }
      } catch (e) { debugPrint("فشل جلب بيانات الأب: $e"); }
    }

    // 2. جلب بيانات الطالب المختار (أو أول ابن إذا لم يكن هناك طالب مختار)
    int? selectedId = prefs.getInt('selected_student_id');
    debugPrint("🔍 [Profile] selectedId from prefs: $selectedId");
    debugPrint("🔍 [Profile] token length: ${token.length}");
    debugPrint("🔍 [Profile] baseUrl: ${ApiService().baseUrl}");

    // إذا ما في طالب محدد، نجيب أول ابن من الـ API تلقائياً
    if (selectedId == null && token.isNotEmpty) {
      try {
        final url = "${ApiService().baseUrl}/parent/children";
        debugPrint("🔍 [Profile] fetching children from: $url");
        var childRes = await Dio().get(
          url,
          options: Options(headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          }),
        );
        debugPrint("🔍 [Profile] children response: ${childRes.statusCode} - ${childRes.data}");
        if (childRes.statusCode == 200 && childRes.data != null) {
          final childrenData = childRes.data['data'] ?? childRes.data;
          final List children = childrenData is List ? childrenData : [];
          debugPrint("🔍 [Profile] children count: ${children.length}");
          if (children.isNotEmpty) {
            final first = children[0];
            debugPrint("🔍 [Profile] first child: $first");
            selectedId = first['student_id'] as int?;
            if (selectedId != null) {
              await prefs.setInt('selected_student_id', selectedId);
              await prefs.setString('selected_student_name', first['full_name'] ?? '');
            }
          }
        }
      } catch (e) { debugPrint("❌ [Profile] فشل جلب الأبناء: $e"); }
    }

    if (selectedId != null) {
      try {
        final url = "${ApiService().baseUrl}/student/info/$selectedId";
        debugPrint("🔍 [Profile] fetching student info from: $url");
        var res = await Dio().get(
          url,
          options: Options(headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          }),
        );
        debugPrint("🔍 [Profile] student info response: ${res.statusCode} - ${res.data}");
        if (res.statusCode == 200 && res.data != null) {
          if (mounted) {
            setState(() {
              studentName = res.data['full_name'] ?? studentName;
              studentDept = res.data['department'] ?? "غير محدد";
              studentYear = res.data['level'] ?? res.data['academic_year'] ?? "غير محدد";
              studentSemester = res.data['semester'] ?? res.data['active_semester'] ?? "غير محدد";
            });
          }
        }
      } catch (e) { debugPrint("❌ [Profile] فشل جلب بيانات الطالب: $e"); }
    } else {
      debugPrint("❌ [Profile] selectedId لا يزال null بعد محاولة جلب الأبناء");
    }
  }


  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().post(
        "${ApiService().baseUrl}/profile/avatar",
        data: FormData.fromMap({'avatar': await MultipartFile.fromFile(picked.path, filename: 'avatar.jpg')}),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final newUrl = ApiService.fixMediaUrl(res.data['avatar'] as String?);
        final messenger = ScaffoldMessenger.of(context);
        if (newUrl != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('parent_avatar_url', newUrl);
          if (mounted) setState(() => _avatarUrl = newUrl);
        }
        messenger.showSnackBar(const SnackBar(
          content: Text('تم تحديث الصورة الشخصية', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFFFCC00),
        ));
      }
    } catch (e) {
      debugPrint('⛔ Avatar upload: $e');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildProfileHeader(textColor, parentName), // رجعنا الهيدر الأصلي
                  const SizedBox(height: 30),

                  _buildSectionTitle("معلومات التواصل", textColor),
                  _buildInfoCard(cardColor, [
                    _buildClickableRow(
                      context, "رقم الهاتف", parentPhone, Icons.phone_android_rounded, Colors.green, textColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPhoneScreen())),
                    ),
                    Divider(height: 1, color: textColor.withValues(alpha:0.1), indent: 20, endIndent: 20),
                    _buildStaticRow("البريد الإلكتروني", parentEmail, Icons.alternate_email_rounded, Colors.blue, textColor),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("البيانات الأكاديمية لـ $studentName", textColor),
                  _buildInfoCard(cardColor, [
                    _buildStaticRow("القسم", studentDept, Icons.account_balance_rounded, Colors.purple, textColor),
                    Divider(height: 1, color: textColor.withValues(alpha:0.1), indent: 20, endIndent: 20),
                    _buildStaticRow("السنة الدراسية", studentYear, Icons.auto_awesome_mosaic_rounded, Colors.orange, textColor),
                    Divider(height: 1, color: textColor.withValues(alpha:0.1), indent: 20, endIndent: 20),
                    _buildStaticRow("الفصل الدراسي النشط", studentSemester, Icons.calendar_month_rounded, Colors.indigo, textColor),
                  ]),

                  const SizedBox(height: 25),
                  _buildSectionTitle("الأمان والإعدادات", textColor),
                  _buildClickableSettingCard(
                    "تغيير كلمة المرور", Icons.lock_reset_rounded, Colors.redAccent, cardColor, textColor,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPasswordScreen())),
                  ),

                  const SizedBox(height: 150),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // --- الهيدر الأصلي مع الكاميرا ---
  Widget _buildProfileHeader(Color textColor, String name) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFCC00), width: 3)),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (_avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null),
                ),
              ),
            ),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFCC00),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const Text("ولي أمر الطالب", style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // --- بقية الـ Widgets (InfoCard, ClickableRow, StaticRow) كما كانت في تصميمك الأصلي تماماً ---
  Widget _buildInfoCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildClickableRow(BuildContext context, String label, String value, IconData icon, Color color, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildColoredIcon(icon, color),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_note_rounded, color: color.withValues(alpha:0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow(String label, String value, IconData icon, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildColoredIcon(icon, color),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildClickableSettingCard(String title, IconData icon, Color color, Color cardColor, Color textColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            _buildColoredIcon(icon, color),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            const Spacer(),
            const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(alignment: Alignment.centerRight,
      child: Padding(padding: const EdgeInsets.only(right: 5, bottom: 10),
        child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("الملف الشخصي",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ParentsHomeScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: textColor),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SettingsScreen(
                userName: parentName,
                userRole: 'ولي أمر',
                profileImageUrl: _avatarUrl ?? '',
                onProfileTap: () => Navigator.pop(context),
              ))),
        ),
      ],
    );
  }
}