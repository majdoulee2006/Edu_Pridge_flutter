import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

// 🌟 استدعاء المكونات الموحدة 🌟
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';

// استدعاء الشاشات للتنقل
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class GradingScreen extends StatefulWidget {
  final Map<String, dynamic> submission;
  const GradingScreen({super.key, required this.submission});

  @override
  State<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen> {
  final TextEditingController _gradeController    = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final grade    = widget.submission['grade'];
    final feedback = widget.submission['feedback'];
    if (grade    != null) _gradeController.text    = '$grade';
    if (feedback != null) _feedbackController.text = '$feedback';
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitGrade() async {
    final gradeVal = double.tryParse(_gradeController.text.trim());
    if (gradeVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل درجة صحيحة')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final submissionId = widget.submission['submission_id'];
      await Dio().post(
        "${ApiService().baseUrl}/teacher/assignments/$submissionId/grade",
        data: {'grade': gradeVal, 'feedback': _feedbackController.text.trim()},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ التصحيح بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('⛔ Grade Error: $e');
      String errorMsg = 'حدث خطأ، حاول مجدداً';
      try {
        if (e is DioException && e.response != null) {
          final status = e.response!.statusCode;
          final data = e.response!.data;
          String? msg;
          if (data is Map) msg = data['message']?.toString();
          errorMsg = 'خطأ $status: ${msg ?? errorMsg}';
          debugPrint('⛔ Status: $status | Data type: ${data.runtimeType}');
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الألوان
    const Color primaryYellow = Color(0xFFFFCC00);

    // جلب ألوان الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
            'تفاصيل الرد',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            const SizedBox.expand(),
            // 1. المحتوى القابل للتمرير
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // كارد معلومات الطالب
                  _buildStudentHeaderCard(context, cardColor, textColor),
                  const SizedBox(height: 20),

                  // المرفقات
                  if ((widget.submission['file_path'] as String?) != null) ...[
                    _buildSectionTitle("المرفقات", textColor),
                    _buildAttachmentItem(
                      context,
                      widget.submission['file_path'] as String,
                      "",
                      Icons.attach_file,
                      Colors.blue,
                      cardColor,
                      textColor,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 15),

                  // قسم التصحيح
                  _buildGradingSection(
                    context,
                    primaryYellow,
                    cardColor,
                    textColor,
                    isDark,
                  ),

                  const SizedBox(height: 120), // مساحة لتجنب الشريط السفلي
                ],
              ),
            ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagesScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ويجيتات البناء المحدثة ---

  Widget _buildStudentHeaderCard(
    BuildContext context,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
        border: const Border(right: BorderSide(color: Colors.orange, width: 5)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFFDEBB8),
              child: Icon(Icons.person, color: Colors.orange),
            ),
            title: Text(
              widget.submission['student_name'] as String? ?? '',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            subtitle: Text(
              widget.submission['course_name'] as String? ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const Divider(),
          const Text(
            "الواجب المطلوب",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.submission['assignment_title'] as String? ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(
    BuildContext context,
    String name,
    String size,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                Text(
                  size,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.download_for_offline_outlined,
              color: Colors.grey,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGradingSection(
    BuildContext context,
    Color btnColor,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "الدرجة المستحقة (من 100)",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gradeController,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "0",
            filled: true,
            fillColor: cardColor,
            border: inputBorder,
            enabledBorder: inputBorder,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "ملاحظات المعلم",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "اكتب ملاحظاتك للطالب هنا...",
            filled: true,
            fillColor: cardColor,
            border: inputBorder,
            enabledBorder: inputBorder,
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: btnColor.withValues(alpha: 0.4),
            ),
            onPressed: _isSaving ? null : _submitGrade,
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.black)
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.black),
                      SizedBox(width: 10),
                      Text(
                        "اعتماد وحفظ التصحيح",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
