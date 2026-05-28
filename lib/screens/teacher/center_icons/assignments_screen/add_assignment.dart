import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AddAssignmentScreen extends StatefulWidget {
  final Map<String, dynamic>? assignment;
  const AddAssignmentScreen({super.key, this.assignment});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final _titleController     = TextEditingController();
  final _descController      = TextEditingController();
  final _maxPointsController = TextEditingController(text: '100');

  List<Map<String, dynamic>> _allCourses      = [];
  List<Map<String, dynamic>> _programs        = [];
  String?                    _selectedProgramId;
  int?                       _selectedYear;
  List<Map<String, dynamic>> _filteredCourses = [];
  String?                    _selectedCourseId;

  DateTime?     _dueDate;
  TimeOfDay?    _dueTime;
  PlatformFile? _pickedFile;
  bool _isLoadingData = false;
  bool _isSaving      = false;

  bool get _isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (_isEditing) _prefill();
  }

  void _prefill() {
    final a = widget.assignment!;
    _titleController.text     = a['title']?.toString() ?? '';
    _descController.text      = a['description']?.toString() ?? '';
    _maxPointsController.text = a['max_points']?.toString() ?? '100';
    _selectedCourseId         = a['course_id']?.toString();
    final raw = a['due_date']?.toString();
    if (raw != null) {
      try {
        final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
        _dueDate = dt;
        _dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (e) {
        debugPrint('date parse: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _maxPointsController.dispose();
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

      if (results[0].statusCode == 200 && results[0].data['success'] == true) {
        _allCourses = (results[0].data['data'] as List? ?? [])
            .map((c) => <String, dynamic>{
                  'id':         c['id'].toString(),
                  'title':      c['title'].toString(),
                  'program_id': c['program_id']?.toString() ?? '',
                  'year':       (c['year'] as num?)?.toInt() ?? 1,
                })
            .toList();
      }

      if (results[1].statusCode == 200 && results[1].data['success'] == true) {
        _programs = (results[1].data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((p) => {
                  'id':   p['id'].toString(),
                  'name': p['name'].toString(),
                })
            .toList();
      }

      // في التعديل: نستنتج program_id و year من course_id
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
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
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
    if (_titleController.text.trim().isEmpty) { _snack('يرجى إدخال عنوان التمرين'); return; }
    if (_descController.text.trim().isEmpty)  { _snack('يرجى إدخال وصف التمرين');  return; }
    if (_selectedCourseId == null)            { _snack('يرجى اختيار المادة');       return; }
    if (_dueDate == null)                     { _snack('يرجى اختيار تاريخ التسليم'); return; }

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
      final prefs   = await SharedPreferences.getInstance();
      final token   = prefs.getString('token') ?? '';
      final headers = {"Authorization": "Bearer $token"};

      if (_isEditing) {
        final id = widget.assignment!['id'];
        if (_pickedFile != null && _pickedFile!.bytes != null) {
          await Dio().post(
            "${ApiService().baseUrl}/teacher/assignments/$id",
            data: FormData.fromMap({
              'course_id':   int.tryParse(_selectedCourseId!),
              'title':       _titleController.text.trim(),
              'description': _descController.text.trim(),
              'due_date':    dueDateStr,
              'max_points':  maxPoints,
              '_method':     'PUT',
              'attachment':  MultipartFile.fromBytes(_pickedFile!.bytes!,
                  filename: _pickedFile!.name,
                  contentType: DioMediaType.parse(_mime(_pickedFile!.name))),
            }),
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
        if (mounted) { _snack('✅ تم تحديث الواجب'); Navigator.pop(context, true); }
      } else {
        await Dio().post(
          "${ApiService().baseUrl}/teacher/assignments",
          data: FormData.fromMap({
            'course_id':   int.tryParse(_selectedCourseId!),
            'title':       _titleController.text.trim(),
            'description': _descController.text.trim(),
            'due_date':    dueDateStr,
            'max_points':  maxPoints,
            if (_pickedFile != null && _pickedFile!.bytes != null)
              'attachment': MultipartFile.fromBytes(_pickedFile!.bytes!,
                  filename: _pickedFile!.name,
                  contentType: DioMediaType.parse(_mime(_pickedFile!.name))),
          }),
          options: Options(headers: headers),
        );
        if (mounted) { _snack('✅ تم نشر التمرين'); Navigator.pop(context, true); }
      }
    } catch (e) {
      debugPrint('⛔ Assignment Error: $e');
      String msg = 'حدث خطأ، حاول مجدداً';
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
    'pdf'  => 'application/pdf',
    'jpg'  => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png'  => 'image/png',
    _      => 'application/octet-stream',
  };

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    const Color yellow = Color(0xFFFFCC00);
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isEditing ? 'تعديل الواجب' : 'إضافة تمرين منزلي',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان التمرين
                    _label("عنوان التمرين", textColor),
                    _field(controller: _titleController, hint: 'مثال: حل مسائل قوانين نيوتن', cardColor: cardColor, textColor: textColor),
                    const SizedBox(height: 20),

                    // وصف التمرين
                    _label("وصف ومعطيات التمرين", textColor),
                    _field(controller: _descController, hint: 'اكتب تفاصيل الواجب...', maxLines: 5, cardColor: cardColor, textColor: textColor),
                    const SizedBox(height: 20),

                    // الدورة + السنة جنب بعض
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("الدورة", textColor),
                              _dropdown(
                                hint: 'اختر الدورة',
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
                              _label("السنة الدراسية", textColor),
                              _dropdown(
                                hint: 'السنة',
                                value: _selectedYear?.toString(),
                                items: const [
                                  DropdownMenuItem(value: '1', child: Text('السنة الأولى')),
                                  DropdownMenuItem(value: '2', child: Text('السنة الثانية')),
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

                    // المادة الدراسية (مفلترة)
                    if (_selectedProgramId != null && _selectedYear != null) ...[
                      _label("المادة الدراسية", textColor),
                      _filteredCourses.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                              ),
                              child: const Center(
                                child: Text('لا توجد مواد لهذه الدورة والسنة',
                                    style: TextStyle(color: Colors.orange, fontSize: 13)),
                              ),
                            )
                          : _dropdown(
                              hint: 'اختر المادة',
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

                    // الدرجة القصوى
                    _label("الدرجة القصوى", textColor),
                    _field(controller: _maxPointsController, hint: '100', cardColor: cardColor, textColor: textColor, keyboardType: TextInputType.number),
                    const SizedBox(height: 20),

                    // تاريخ ووقت التسليم
                    Row(
                      children: [
                        Expanded(child: _pickerField(
                          label: 'تاريخ التسليم',
                          value: _dueDate == null
                              ? 'اختر تاريخاً'
                              : '${_dueDate!.year}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.day.toString().padLeft(2, '0')}',
                          icon: Icons.calendar_month_outlined,
                          onTap: _pickDate,
                          cardColor: cardColor, textColor: textColor,
                          isSelected: _dueDate != null,
                        )),
                        const SizedBox(width: 15),
                        Expanded(child: _pickerField(
                          label: 'وقت التسليم',
                          value: _dueTime == null ? '11:59 م' : _dueTime!.format(context),
                          icon: Icons.access_time,
                          onTap: _pickTime,
                          cardColor: cardColor, textColor: textColor,
                          isSelected: _dueTime != null,
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // مرفق
                    _label("مرفق (اختياري)", textColor),
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
                            Icon(
                              _pickedFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                              color: _pickedFile != null ? Colors.green : yellow,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _pickedFile != null ? _pickedFile!.name : 'اضغط لرفع ملف (PDF، صورة)',
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

  Widget _label(String text, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
  );

  Widget _field({
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

  Widget _pickerField({
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
      _label(label, textColor),
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
