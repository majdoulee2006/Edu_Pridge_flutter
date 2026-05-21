import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AddAssignmentScreen extends StatefulWidget {
  final Map<String, dynamic>? assignment; // null = إضافة، not null = تعديل
  const AddAssignmentScreen({super.key, this.assignment});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _titleController     = TextEditingController();
  final _descController      = TextEditingController();
  final _maxPointsController = TextEditingController(text: '100');

  List<Map<String, dynamic>> _courses = [];
  String?        _selectedCourseId;
  DateTime?      _dueDate;
  TimeOfDay?     _dueTime;
  PlatformFile?  _pickedFile;
  bool _isLoadingCourses = false;
  bool _isSaving         = false;

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    if (_isEditing) _prefill();
  }

  void _prefill() {
    final a = widget.assignment!;
    _titleController.text      = a['title']?.toString() ?? '';
    _descController.text       = a['description']?.toString() ?? '';
    _maxPointsController.text  = a['max_points']?.toString() ?? '100';
    _selectedCourseId          = a['course_id']?.toString();
    final raw = a['due_date']?.toString();
    if (raw != null) {
      try {
        final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
        _dueDate = dt;
        _dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _maxPointsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
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
        setState(() {
          _courses = (response.data['data'] as List? ?? [])
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
          // في وضع التعديل تأكد من تحديد الكورس بعد تحميل القائمة
          if (_isEditing && _selectedCourseId != null) {
            final ids = _courses.map((c) => c['id']?.toString()).toList();
            if (!ids.contains(_selectedCourseId)) _selectedCourseId = null;
          }
        });
      }
    } catch (e) {
      debugPrint('⛔ Courses Error: $e');
    } finally {
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) { _showSnack('يرجى إدخال عنوان التمرين'); return; }
    if (_descController.text.trim().isEmpty)  { _showSnack('يرجى إدخال وصف التمرين');  return; }
    if (_selectedCourseId == null)            { _showSnack('يرجى اختيار المادة');       return; }
    if (_dueDate == null)                     { _showSnack('يرجى اختيار تاريخ التسليم'); return; }

    final maxPoints  = int.tryParse(_maxPointsController.text.trim()) ?? 100;
    final time       = _dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    final dueDateStr =
        '${_dueDate!.year}-'
        '${_dueDate!.month.toString().padLeft(2, '0')}-'
        '${_dueDate!.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final headers = {"Authorization": "Bearer $token"};

      if (_isEditing) {
        // ── وضع التعديل ── PUT بدون ملف (أو مع ملف لو اختار جديد)
        final id = widget.assignment!['id'];
        if (_pickedFile != null && _pickedFile!.bytes != null) {
          final formData = FormData.fromMap({
            'course_id':   int.tryParse(_selectedCourseId!),
            'title':       _titleController.text.trim(),
            'description': _descController.text.trim(),
            'due_date':    dueDateStr,
            'max_points':  maxPoints,
            '_method':     'PUT', // Laravel method spoofing لـ FormData
            'attachment':  MultipartFile.fromBytes(
              _pickedFile!.bytes!,
              filename: _pickedFile!.name,
              contentType: DioMediaType.parse(_mimeType(_pickedFile!.name)),
            ),
          });
          await Dio().post(
            "${ApiService().baseUrl}/teacher/assignments/$id",
            data: formData,
            options: Options(headers: headers),
          );
        } else {
          await Dio().put(
            "${ApiService().baseUrl}/teacher/assignments/$id",
            data: {
              'course_id':   int.tryParse(_selectedCourseId!),
              'title':       _titleController.text.trim(),
              'description': _descController.text.trim(),
              'due_date':    dueDateStr,
              'max_points':  maxPoints,
            },
            options: Options(headers: {...headers, 'Content-Type': 'application/json'}),
          );
        }
        if (mounted) { _showSnack('✅ تم تحديث الواجب بنجاح'); Navigator.pop(context, true); }
      } else {
        // ── وضع الإضافة ── POST
        final formData = FormData.fromMap({
          'course_id':   int.tryParse(_selectedCourseId!),
          'title':       _titleController.text.trim(),
          'description': _descController.text.trim(),
          'due_date':    dueDateStr,
          'max_points':  maxPoints,
          if (_pickedFile != null && _pickedFile!.bytes != null)
            'attachment': MultipartFile.fromBytes(
              _pickedFile!.bytes!,
              filename: _pickedFile!.name,
              contentType: DioMediaType.parse(_mimeType(_pickedFile!.name)),
            ),
        });
        await Dio().post(
          "${ApiService().baseUrl}/teacher/assignments",
          data: formData,
          options: Options(headers: headers),
        );
        if (mounted) { _showSnack('✅ تم نشر التمرين بنجاح'); Navigator.pop(context, true); }
      }
    } catch (e) {
      debugPrint('⛔ Assignment Error: $e');
      String errorMsg = 'حدث خطأ، حاول مجدداً';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['errors'] != null) {
          errorMsg = ((data['errors'] as Map).values.first as List).first.toString();
        } else {
          errorMsg = data['message']?.toString() ?? errorMsg;
        }
      }
      if (mounted) _showSnack(errorMsg);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _mimeType(String filename) {
    return switch (filename.split('.').last.toLowerCase()) {
      'pdf'  => 'application/pdf',
      'jpg'  => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      'png'  => 'image/png',
      _      => 'application/octet-stream',
    };
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const Color yellow  = Color(0xFFFFCC00);
    final bgColor       = Theme.of(context).scaffoldBackgroundColor;
    final cardColor     = Theme.of(context).cardColor;
    final textColor     = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark        = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditing ? 'تعديل الواجب' : 'إضافة تمرين منزلي',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("عنوان التمرين", textColor),
              _buildField(controller: _titleController, hint: 'مثال: حل مسائل قوانين نيوتن', cardColor: cardColor, textColor: textColor),
              const SizedBox(height: 20),

              _buildLabel("وصف ومتطلبات التمرين", textColor),
              _buildField(controller: _descController, hint: 'اكتب تفاصيل الواجب...', maxLines: 5, cardColor: cardColor, textColor: textColor),
              const SizedBox(height: 20),

              _buildLabel("المادة الدراسية", textColor),
              _buildCoursesDropdown(cardColor, textColor, isDark),
              const SizedBox(height: 20),

              _buildLabel("الدرجة القصوى", textColor),
              _buildField(controller: _maxPointsController, hint: '100', cardColor: cardColor, textColor: textColor, keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _buildPickerField(
                    label: 'تاريخ التسليم',
                    value: _dueDate == null ? 'اختر تاريخاً' : '${_dueDate!.year}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.day.toString().padLeft(2, '0')}',
                    icon: Icons.calendar_month_outlined,
                    onTap: _pickDate,
                    cardColor: cardColor,
                    textColor: textColor,
                    isSelected: _dueDate != null,
                  )),
                  const SizedBox(width: 15),
                  Expanded(child: _buildPickerField(
                    label: 'وقت التسليم',
                    value: _dueTime == null ? '11:59 م' : _dueTime!.format(context),
                    icon: Icons.access_time,
                    onTap: _pickTime,
                    cardColor: cardColor,
                    textColor: textColor,
                    isSelected: _dueTime != null,
                  )),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel("مرفق (اختياري)", textColor),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _pickedFile != null ? Colors.green : yellow.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(_pickedFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                          color: _pickedFile != null ? Colors.green : yellow, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        _pickedFile != null ? _pickedFile!.name : 'اضغط لرفع ملف (PDF، صورة)',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _pickedFile != null ? Colors.green : textColor.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

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
                              _isEditing ? 'حفظ التعديلات' : 'نشر التمرين الآن',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Icon(_isEditing ? Icons.save_rounded : Icons.send_rounded, color: Colors.black, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 10, right: 4),
    child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    required Color cardColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) => Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );

  Widget _buildCoursesDropdown(Color cardColor, Color textColor, bool isDark) {
    if (_isLoadingCourses) {
      return Container(
        height: 55,
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00))),
      );
    }
    return Container(
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
          value: _selectedCourseId,
          hint: Text('اختر المادة', style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5))),
          items: () {
            final seen = <String>{};
            return _courses
                .where((c) => c['id'] != null && seen.add(c['id'].toString()))
                .map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text(c['title'] as String? ?? '', style: TextStyle(color: textColor, fontSize: 14)),
                    ))
                .toList();
          }(),
          onChanged: (val) => setState(() => _selectedCourseId = val),
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    bool isSelected = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel(label, textColor),
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: const Color(0xFFFFCC00)),
              Text(value, style: TextStyle(fontSize: 13, color: isSelected ? textColor : textColor.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    ],
  );
}
