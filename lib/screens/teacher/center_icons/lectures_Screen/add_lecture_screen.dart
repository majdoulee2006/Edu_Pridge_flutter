import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AddLectureScreen extends StatefulWidget {
  final Map<String, dynamic>? lecture;
  const AddLectureScreen({super.key, this.lecture});

  @override
  State<AddLectureScreen> createState() => _AddLectureScreenState();
}

class _AddLectureScreenState extends State<AddLectureScreen> {
  final _titleController = TextEditingController();
  final _descController  = TextEditingController();

  // كل الكورسات
  List<Map<String, dynamic>> _allCourses = [];

  // الدورات (programs)
  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;

  // السنة: 1 أو 2
  int? _selectedYear;

  // المادة المفلترة
  List<Map<String, dynamic>> _filteredCourses = [];
  String? _selectedCourseId;

  PlatformFile? _pickedFile;
  bool _isUrlMode     = false;
  final _urlController = TextEditingController();
  bool _isLoadingData = false;
  bool _isSaving      = false;

  bool get _isEditing => widget.lecture != null;

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadData();
    if (_isEditing) _prefill();
  }

  void _prefill() {
    final l = widget.lecture!;
    _titleController.text = l['title']?.toString() ?? '';
    _descController.text  = l['description']?.toString() ?? '';
    _selectedCourseId     = l['course_id']?.toString();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final headers = {"Authorization": "Bearer $token"};

      final results = await Future.wait([
        Dio().get("${ApiService().baseUrl}/teacher/courses",  options: Options(headers: headers)),
        Dio().get("${ApiService().baseUrl}/teacher/programs", options: Options(headers: headers)),
      ]);

      final coursesRes  = results[0];
      final programsRes = results[1];

      if (coursesRes.statusCode == 200 && coursesRes.data['success'] == true) {
        _allCourses = (coursesRes.data['data'] as List? ?? [])
            .map((c) => <String, dynamic>{
                  'id':         c['id'].toString(),
                  'title':      c['title'].toString(),
                  'program_id': c['program_id']?.toString() ?? '',
                  'year':       (c['year'] as num?)?.toInt() ?? 1,
                })
            .toList();
      }

      if (programsRes.statusCode == 200 && programsRes.data['success'] == true) {
        _programs = (programsRes.data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((p) => {
                  'id':   p['id'].toString(),
                  'name': p['name'].toString(),
                })
            .toList();
      }

      // في وضع التعديل: نحدد program_id و year من الكورس المختار
      if (_isEditing && _selectedCourseId != null) {
        final match = _allCourses.firstWhere(
          (c) => c['id'] == _selectedCourseId,
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          _selectedProgramId = match['program_id'] as String?;
          _selectedYear      = match['year'] as int?;
          _applyFilter();
        }
      }
    } catch (e) {
      debugPrint('⛔ Load Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _applyFilter() {
    if (_selectedProgramId == null || _selectedYear == null) {
      setState(() { _filteredCourses = []; _selectedCourseId = null; });
      return;
    }
    final filtered = _allCourses.where((c) =>
      c['program_id'] == _selectedProgramId &&
      c['year'] == _selectedYear,
    ).toList();
    setState(() {
      _filteredCourses  = filtered;
      _selectedCourseId = filtered.any((c) => c['id'] == _selectedCourseId)
          ? _selectedCourseId
          : null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'mkv', 'doc', 'docx', 'ppt', 'pptx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submit() async {
    final isAr = AppSettings.language.value == 'ar';
    if (_titleController.text.trim().isEmpty) {
      _snack(isAr ? 'يرجى إدخال عنوان المحاضرة' : 'Please enter lecture title');
      return;
    }
    if (_selectedCourseId == null) {
      _snack(isAr ? 'يرجى اختيار المادة' : 'Please select a course');
      return;
    }

    if (!_isEditing) {
      if (_isUrlMode) {
        if (_urlController.text.trim().isEmpty) {
          _snack(isAr ? 'يرجى إدخال رابط الفيديو' : 'Please enter video URL');
          return;
        }
      } else {
        if (_pickedFile == null || _pickedFile!.bytes == null) {
          _snack(isAr ? 'يرجى إرفاق ملف المحاضرة' : 'Please attach a lecture file');
          return;
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formMap = <String, dynamic>{
        'title':       _titleController.text.trim(),
        'course_id':   _selectedCourseId,
        'description': _descController.text.trim(),
      };

      if (_isUrlMode && _urlController.text.trim().isNotEmpty) {
        formMap['video_url'] = _urlController.text.trim();
      } else if (_pickedFile != null && _pickedFile!.bytes != null) {
        formMap['content_file'] = MultipartFile.fromBytes(
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
          contentType: DioMediaType.parse(_mime(_pickedFile!.name)),
        );
      }

      final url = _isEditing
          ? "${ApiService().baseUrl}/teacher/lessons/${widget.lecture!['id']}"
          : "${ApiService().baseUrl}/teacher/lessons";

      await Dio().post(
        url,
        data: FormData.fromMap(formMap),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        _snack(_isEditing
            ? (isAr ? '✅ تم تحديث المحاضرة' : '✅ Lecture updated successfully')
            : (isAr ? '✅ تم رفع المحاضرة' : '✅ Lecture uploaded successfully'));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⛔ Lesson Error: $e');
      String msg = isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, please try again';
      if (e is DioException && e.response?.data is Map) {
        final d = e.response!.data as Map;
        msg = (d['errors'] != null)
            ? ((d['errors'] as Map).values.first as List).first.toString()
            : d['message']?.toString() ?? msg;
      }
      if (mounted) _snack(msg);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _mime(String name) => switch (name.split('.').last.toLowerCase()) {
    'pdf' => 'application/pdf',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'avi' => 'video/x-msvideo',
    'mkv' => 'video/x-matroska',
    'doc'  => 'application/msword',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt'  => 'application/vnd.ms-powerpoint',
    'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    _     => 'application/octet-stream',
  };

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    const Color yellow = Color(0xFFFFCC00);
    final isAr      = AppSettings.language.value == 'ar';
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_back : Icons.arrow_back_ios_new,
              color: textColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditing
                ? (isAr ? 'تعديل المحاضرة' : 'Edit Lecture')
                : (isAr ? 'إضافة محاضرة' : 'Add Lecture'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان المحاضرة
                    _label(isAr ? 'عنوان المحاضرة' : 'Lecture Title', textColor, isAr),
                    _field(
                      controller: _titleController,
                      hint: isAr ? 'أدخل عنوان المحاضرة' : 'Enter lecture title',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),

                    // الدورة + السنة جنب بعض
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(isAr ? 'الدورة' : 'Program', textColor, isAr),
                              _dropdown(
                                hint: isAr ? 'اختر الدورة' : 'Select Program',
                                value: _selectedProgramId,
                                items: _programs.map((p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(p['name'] as String, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                cardColor: cardColor, textColor: textColor, isDark: isDark,
                                onChanged: (val) {
                                  setState(() => _selectedProgramId = val);
                                  _applyFilter();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(isAr ? 'السنة الدراسية' : 'Academic Year', textColor, isAr),
                              _dropdown(
                                hint: isAr ? 'السنة' : 'Year',
                                value: _selectedYear?.toString(),
                                items: [
                                  DropdownMenuItem(value: '1', child: Text(isAr ? 'السنة الأولى' : 'First Year')),
                                  DropdownMenuItem(value: '2', child: Text(isAr ? 'السنة الثانية' : 'Second Year')),
                                ],
                                cardColor: cardColor, textColor: textColor, isDark: isDark,
                                onChanged: (val) {
                                  setState(() => _selectedYear = int.tryParse(val ?? ''));
                                  _applyFilter();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // المادة الدراسية (تظهر بعد اختيار الدورة والسنة)
                    if (_selectedProgramId != null && _selectedYear != null) ...[
                      _label(isAr ? 'المادة الدراسية' : 'Course', textColor, isAr),
                      _filteredCourses.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? 'لا توجد مواد لهذه الدورة والسنة' : 'No courses found for this program and year',
                                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                                ),
                              ),
                            )
                          : _dropdown(
                              hint: isAr ? 'اختر المادة' : 'Select Course',
                              value: _selectedCourseId,
                              items: _filteredCourses.map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['title'] as String),
                              )).toList(),
                              cardColor: cardColor, textColor: textColor, isDark: isDark,
                              onChanged: (val) => setState(() => _selectedCourseId = val),
                            ),
                      const SizedBox(height: 20),
                    ],

                    // الوصف
                    _label(isAr ? 'الوصف (اختياري)' : 'Description (Optional)', textColor, isAr),
                    _field(
                      controller: _descController,
                      hint: isAr ? 'أدخل وصفاً للمحاضرة...' : 'Enter lecture description...',
                      maxLines: 3,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 24),

                    // نوع المحتوى — تبديل بين ملف ورابط
                    _label(
                      _isEditing
                          ? (isAr ? 'المحتوى (اختياري)' : 'Content (Optional)')
                          : (isAr ? 'محتوى المحاضرة' : 'Lecture Content'),
                      textColor,
                      isAr,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() { _isUrlMode = false; _urlController.clear(); }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isUrlMode ? yellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.attach_file_rounded,
                                        size: 16, color: !_isUrlMode ? Colors.black : textColor.withValues(alpha: 0.5)),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr ? 'رفع ملف' : 'Upload File',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13,
                                        color: !_isUrlMode ? Colors.black : textColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() { _isUrlMode = true; _pickedFile = null; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isUrlMode ? yellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_circle_outline_rounded,
                                        size: 16, color: _isUrlMode ? Colors.black : textColor.withValues(alpha: 0.5)),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr ? 'رابط يوتيوب' : 'YouTube Link',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13,
                                        color: _isUrlMode ? Colors.black : textColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_isUrlMode) ...[
                      _field(
                        controller: _urlController,
                        hint: 'https://youtube.com/watch?v=...',
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _pickedFile != null ? Colors.green : yellow.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _pickedFile != null ? Icons.check_circle_outline : Icons.attach_file_rounded,
                                color: _pickedFile != null ? Colors.green : yellow,
                                size: 30,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _pickedFile != null
                                    ? _pickedFile!.name
                                    : (isAr
                                        ? 'اضغط لإرفاق ملف (PDF، Word، PowerPoint، فيديو)'
                                        : 'Click to attach file (PDF, Word, PPT, Video)'),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _pickedFile != null ? Colors.green : textColor.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),

                    // زر النشر
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 5,
                          shadowColor: yellow.withValues(alpha: 0.3),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isEditing
                                        ? (isAr ? 'حفظ التعديلات' : 'Save Changes')
                                        : (isAr ? 'نشر المحاضرة' : 'Publish Lecture'),
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(_isEditing ? Icons.save_rounded : Icons.upload_rounded, color: Colors.black, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _label(String text, Color textColor, bool isAr) => Padding(
    padding: EdgeInsets.only(bottom: 8, right: isAr ? 4 : 0, left: isAr ? 0 : 4),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required Color cardColor,
    required Color textColor,
  }) => Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    required void Function(String?)? onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        dropdownColor: cardColor,
        value: value,
        hint: Text(hint, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5))),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}
