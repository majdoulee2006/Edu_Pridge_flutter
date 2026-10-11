import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    final grade    = widget.submission['grade'];
    final feedback = widget.submission['feedback'];
    if (grade    != null) _gradeController.text    = '$grade';
    if (feedback != null) _feedbackController.text = '$feedback';
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String _cleanFileName(String? filePath) {
    if (filePath == null) return '';
    String fileName = filePath.split('/').last;
    final regExp = RegExp(r'^\d+_\d+_(.*)$');
    final match = regExp.firstMatch(fileName);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    return fileName;
  }

  Future<void> _submitGrade() async {
    final isAr = AppSettings.language.value == 'ar';
    final gradeVal = double.tryParse(_gradeController.text.trim());
    if (gradeVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'أدخل درجة صحيحة' : 'Enter a valid grade')),
      );
      return;
    }
    final maxPoints = double.tryParse(widget.submission['max_points']?.toString() ?? '') ?? 100.0;
    if (gradeVal < 0 || gradeVal > maxPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'الدرجة يجب أن تكون بين 0 و ${maxPoints % 1 == 0 ? maxPoints.toInt() : maxPoints}'
                : 'Grade must be between 0 and ${maxPoints % 1 == 0 ? maxPoints.toInt() : maxPoints}',
          ),
        ),
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
          SnackBar(
            content: Text(isAr ? '✅ تم حفظ التصحيح بنجاح' : '✅ Grading saved successfully'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('⛔ Grade Error: $e');
      String errorMsg = isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, please try again';
      try {
        if (e is DioException && e.response != null) {
          final status = e.response!.statusCode;
          final data = e.response!.data;
          String? msg;
          if (data is Map) msg = data['message']?.toString();
          errorMsg = isAr ? 'خطأ $status: ${msg ?? errorMsg}' : 'Error $status: ${msg ?? errorMsg}';
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
    final isAr = AppSettings.language.value == 'ar';
    // الألوان
    const Color primaryYellow = Color(0xFFFFCC00);

    // جلب ألوان الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'تفاصيل الرد' : 'Submission Details',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: Stack(
          children: [
            // المحتوى القابل للتمرير
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentHeaderCard(context, cardColor, textColor, isDark, isAr),
                  const SizedBox(height: 15),
                  // ملاحظات/رسالة الطالب المعادة مع الحل
                  if (widget.submission['student_notes'] != null &&
                      widget.submission['student_notes'].toString().trim().isNotEmpty) ...[
                    _buildSectionTitle(isAr ? "ملاحظات الطالب مع الحل" : "Student Notes with Solution", textColor, isAr),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      child: Text(
                        widget.submission['student_notes'].toString().trim(),
                        style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  if ((widget.submission['file_path'] as String?) != null) ...[
                    _buildSectionTitle(isAr ? "الملفات والمرفقات" : "Files & Attachments", textColor, isAr),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withAlpha(20) : Colors.blue.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withAlpha(40)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_file, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'الملف المرفق من الطالب' : 'Student Attached File',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAttachmentItem(
                            context,
                            _cleanFileName(widget.submission['file_path'] as String),
                            widget.submission['file_path'] as String,
                            "",
                            Icons.insert_drive_file_rounded,
                            Colors.blue,
                            isDark ? Colors.white.withAlpha(10) : Colors.white,
                            textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  if (widget.submission['solution_text'] != null &&
                      (widget.submission['solution_text'] as String).trim().isNotEmpty) ...[
                    _buildSectionTitle(isAr ? "إجابة الطالب النصية" : "Student Written Answer", textColor, isAr),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withAlpha(20) : Colors.green.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withAlpha(40)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, color: Colors.green, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'نص الحل المكتوب:' : 'Written solution text:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(color: Colors.green.withAlpha(40)),
                          const SizedBox(height: 8),
                          Text(
                            widget.submission['solution_text'] as String,
                            style: TextStyle(color: textColor, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                  _buildGradingSection(context, primaryYellow, cardColor, textColor, isDark),
                  const SizedBox(height: 16),
                  // زر الحفظ داخل السكرول
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                      onPressed: _isSaving ? null : _submitGrade,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.black),
                                const SizedBox(width: 10),
                                Text(
                                  isAr ? 'اعتماد وحفظ التصحيح' : 'Approve & Save Grade',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // الشريط السفلي
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
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
    bool isDark,
    bool isAr,
  ) {
    final desc = widget.submission['assignment_description']?.toString() ??
        widget.submission['description']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
        border: Border(
          right: BorderSide(color: Colors.orange, width: isAr ? 5 : 0),
          left: BorderSide(color: Colors.orange, width: isAr ? 0 : 5),
        ),
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
          Text(
            isAr ? "الواجب المطلوب" : "Assignment",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.submission['assignment_title'] as String? ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (desc != null && desc.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? "معطيات / وصف التمرين:" : "Assignment Info / Description:",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc.trim(),
                    style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor, [bool isAr = true]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10, right: isAr ? 5 : 0, left: isAr ? 0 : 5),
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
    String displayName,
    String url,
    String size,
    IconData icon,
    Color iconColor,
    Color cardColor,
    Color textColor,
  ) {
    final isAr = AppSettings.language.value == 'ar';
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
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (size.isNotEmpty)
                    Text(
                      size,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.visibility_outlined,
              color: Colors.blue,
            ),
            tooltip: isAr ? 'عرض الملف' : 'View File',
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: Colors.green,
            ),
            tooltip: isAr ? 'تنزيل الملف' : 'Download File',
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
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
    final isAr = AppSettings.language.value == 'ar';
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
    );

    final maxPoints = double.tryParse(widget.submission['max_points']?.toString() ?? '') ?? 100.0;
    final currentGrade = double.tryParse(_gradeController.text.trim());
    Color activeGradeColor = textColor;
    if (currentGrade != null) {
      activeGradeColor = currentGrade < (maxPoints / 2) ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${isAr ? "الدرجة المستحقة (من " : "Earned Grade (Out of "}${widget.submission['max_points'] ?? 100})",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gradeController,
          textAlign: TextAlign.center,
          style: TextStyle(color: activeGradeColor, fontWeight: FontWeight.bold, fontSize: 18),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            String cleanVal = val;
            // حظر إدخال علامة سالبة
            if (cleanVal.contains('-')) {
              cleanVal = cleanVal.replaceAll('-', '');
              _gradeController.text = cleanVal;
              _gradeController.selection = TextSelection.fromPosition(TextPosition(offset: cleanVal.length));
            }
            final parsed = double.tryParse(cleanVal);
            if (parsed != null && parsed > maxPoints) {
              // حظر تجاوز العلامة القصوى
              final maxStr = maxPoints % 1 == 0 ? maxPoints.toInt().toString() : maxPoints.toString();
              _gradeController.text = maxStr;
              _gradeController.selection = TextSelection.fromPosition(TextPosition(offset: maxStr.length));
            }
            setState(() {});
          },
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
          isAr ? "ملاحظات المعلم" : "Teacher Feedback",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: isAr ? "اكتب ملاحظاتك للطالب هنا..." : "Write your feedback to the student here...",
            filled: true,
            fillColor: cardColor,
            border: inputBorder,
            enabledBorder: inputBorder,
          ),
        ),
      ],
    );
  }
}
