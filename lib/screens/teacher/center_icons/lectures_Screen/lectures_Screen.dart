import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  final _titleController = TextEditingController();
  final _descController  = TextEditingController();

  List<Map<String, dynamic>> _allCourses = [];
  List<String> _uniqueTitles = [];
  String? _selectedTitle;

  List<Map<String, dynamic>> _allPrograms     = [];
  List<Map<String, dynamic>> _filteredPrograms = [];
  String? _selectedProgramId;

  String? _selectedCourseId;
  String? _selectedYear;
  final List<String> _years = ['السنة الأولى', 'السنة الثانية'];

  PlatformFile? _pickedFile;
  bool _isLoadingCourses = false;
  bool _isSaving         = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchPrograms();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await Dio().get(
        "${ApiService().baseUrl}/teacher/courses",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final courses = (response.data['data'] as List? ?? [])
            .map((c) => <String, dynamic>{
                  'id':           c['id'].toString(),
                  'title':        c['title'].toString(),
                  'level':        c['level']?.toString() ?? '',
                  'program_id':   c['program_id']?.toString() ?? '',
                  'program_name': c['program_name']?.toString() ?? '',
                })
            .toList();
        final seen = <String>{};
        final titles = courses
            .map((c) => c['title'] as String)
            .where(seen.add)
            .toList();
        setState(() {
          _allCourses   = courses;
          _uniqueTitles = titles;
        });
      }
    } catch (e) {
      debugPrint('⛔ Courses Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _fetchPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/programs",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _allPrograms = data
                .map<Map<String, dynamic>>((p) => {
                      'id':   p['id'].toString(),
                      'name': p['name'].toString(),
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('⛔ Programs Error: $e');
    }
  }

  void _onTitleSelected(String? title) {
    if (title == null) return;
    final coursesForTitle = _allCourses.where((c) => c['title'] == title).toList();
    final autoId = coursesForTitle.length == 1 ? coursesForTitle[0]['id'] as String : null;

    setState(() {
      _selectedTitle     = title;
      _filteredPrograms  = List.from(_allPrograms);
      _selectedProgramId = null;
      _selectedCourseId  = _allPrograms.isEmpty ? autoId : null;
    });
  }

  void _onProgramSelected(String? programId) {
    if (programId == null) return;
    var match = _allCourses.firstWhere(
      (c) => c['title'] == _selectedTitle && c['program_id'] == programId,
      orElse: () => {},
    );
    if (match.isEmpty) {
      match = _allCourses.firstWhere(
        (c) => c['title'] == _selectedTitle,
        orElse: () => {},
      );
    }
    setState(() {
      _selectedProgramId = programId;
      _selectedCourseId  = match.isNotEmpty ? match['id'] as String : null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'mkv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('يرجى إدخال عنوان المحاضرة');
      return;
    }
    if (_selectedCourseId == null) {
      _showSnack('يرجى اختيار المادة');
      return;
    }
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      _showSnack('يرجى إرفاق ملف المحاضرة');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formData = FormData.fromMap({
        'title':        _titleController.text.trim(),
        'course_id':    _selectedCourseId,
        'description':  _descController.text.trim(),
        'content_file': MultipartFile.fromBytes(
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
          contentType: DioMediaType.parse(_getMimeType(_pickedFile!.name)),
        ),
      });

      await Dio().post(
        "${ApiService().baseUrl}/teacher/lessons",
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        _showSnack('✅ تم رفع المحاضرة بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⛔ Create Lesson Error: $e');
      String errorMsg = 'حدث خطأ، حاول مجدداً';
      try {
        if (e is DioException && e.response != null) {
          final status = e.response!.statusCode;
          final data   = e.response!.data;
          debugPrint('⛔ Status: $status | Data: $data');
          if (data is Map) {
            if (data['errors'] != null) {
              final errors = data['errors'] as Map;
              errorMsg = (errors.values.first as List).first.toString();
            } else if (data['message'] != null) {
              errorMsg = 'خطأ $status: ${data['message']}';
            } else {
              errorMsg = 'خطأ $status';
            }
          } else {
            errorMsg = 'خطأ $status';
          }
        }
      } catch (_) {}
      if (mounted) _showSnack(errorMsg);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => 'application/pdf',
      'mp4'  => 'video/mp4',
      'mov'  => 'video/quicktime',
      'avi'  => 'video/x-msvideo',
      'mkv'  => 'video/x-matroska',
      _      => 'application/octet-stream',
    };
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryYellow = Color(0xFFFFCC00);
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إضافة محاضرة',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
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
        body: Stack(
          children: [
            const SizedBox.expand(),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // عنوان المحاضرة
                  _buildLabel('عنوان المحاضرة', textColor),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'أدخل عنوان المحاضرة هنا',
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // المادة الدراسية
                  _buildLabel('المادة الدراسية', textColor),
                  _buildDropdown(
                    hint: 'اختر المادة',
                    value: _selectedTitle,
                    items: _uniqueTitles
                        .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                        .toList(),
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                    onChanged: _onTitleSelected,
                  ),
                  const SizedBox(height: 20),

                  // الدورة — كل برامج قسم المعلم
                  if (_selectedTitle != null && _allPrograms.isNotEmpty) ...[
                    _buildLabel('الدورة', textColor),
                    _buildDropdown(
                      hint: 'اختر الدورة',
                      value: _selectedProgramId,
                      items: _filteredPrograms
                          .map((p) => DropdownMenuItem<String>(
                                value: p['id'] as String,
                                child: Text(p['name'] as String),
                              ))
                          .toList(),
                      cardColor: cardColor,
                      textColor: textColor,
                      isDark: isDark,
                      onChanged: _onProgramSelected,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // السنة الدراسية
                  if (_selectedTitle != null) ...[
                    _buildLabel('السنة الدراسية', textColor),
                    _buildDropdown(
                      hint: 'اختر السنة',
                      value: _selectedYear,
                      items: _years
                          .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                          .toList(),
                      cardColor: cardColor,
                      textColor: textColor,
                      isDark: isDark,
                      onChanged: (val) => setState(() => _selectedYear = val),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // وصف اختياري
                  _buildLabel('الوصف (اختياري)', textColor),
                  _buildTextField(
                    controller: _descController,
                    hint: 'أدخل وصفاً للمحاضرة...',
                    maxLines: 3,
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 30),

                  // زر اختيار الملف
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(
                          color: _pickedFile != null
                              ? Colors.green
                              : primaryYellow.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_pickedFile != null
                                      ? Colors.green
                                      : primaryYellow)
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _pickedFile != null
                                  ? Icons.check_circle
                                  : Icons.attach_file,
                              color: _pickedFile != null
                                  ? Colors.green
                                  : textColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _pickedFile != null
                                  ? _pickedFile!.name
                                  : 'إرفاق ملف المحاضرة',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _pickedFile != null
                                    ? Colors.green
                                    : textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // زر الإضافة
                  GestureDetector(
                    onTap: _isSaving ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: primaryYellow,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: primaryYellow.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, color: Colors.black, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'إضافة المحاضرة',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),

            // الشريط السفلي
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textAlign: maxLines == 1 ? TextAlign.center : TextAlign.start,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBCBCBC), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    required void Function(String?)? onChanged,
  }) {
    if (_isLoadingCourses && items.isEmpty) {
      return Container(
        height: 55,
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00))),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFFBCBCBC), fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF777777)),
          items: items,
          dropdownColor: cardColor,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
