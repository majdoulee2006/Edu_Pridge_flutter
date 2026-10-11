import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class CreateExamScheduleScreen extends StatefulWidget {
  const CreateExamScheduleScreen({super.key});

  @override
  State<CreateExamScheduleScreen> createState() => _CreateExamScheduleScreenState();
}

class _CreateExamScheduleScreenState extends State<CreateExamScheduleScreen> {
  bool get isAr => AppSettings.language.value == 'ar';
  void _onLangChange() { if (mounted) setState(() {}); }

  final _formKey = GlobalKey<FormState>();
  final _courseCtrl = TextEditingController();
  final _hallCtrl = TextEditingController();

  DateTime? _examDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _period = 'الفترة الصباحية';
  String _examType = 'نصف فصلي';
  bool _isLoading = false;

  static const _yellow = Color(0xFFFFCC00);
  static const _orange = Color(0xFFE65100);

  static const _periods = ['الفترة الصباحية', 'الفترة المسائية'];
  static const _examTypes = ['نصف فصلي', 'نهائي', 'عملي', 'شفهي'];

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _courseCtrl.dispose();
    _hallCtrl.dispose();
    super.dispose();
  }

  String _periodLabel(String p) => isAr ? p : (p == 'الفترة الصباحية' ? 'Morning Period' : 'Evening Period');

  String _examTypeLabel(String t) {
    if (isAr) return t;
    return switch (t) {
      'نصف فصلي' => 'Midterm',
      'نهائي' => 'Final',
      'عملي' => 'Practical',
      'شفهي' => 'Oral',
      _ => t,
    };
  }

  String _formatDate(DateTime d) {
    if (isAr) {
      const months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return '${days[d.weekday % 7]}، ${d.day} ${months[d.month]} ${d.year}';
    } else {
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return '${days[d.weekday % 7]}, ${months[d.month]} ${d.day}, ${d.year}';
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _orange, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _orange, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_examDate == null) {
      _showSnack(isAr ? 'اختر تاريخ الامتحان أولاً' : 'Select exam date first');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showSnack(isAr ? 'اختر وقت البداية والنهاية' : 'Select start and end times');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final dateStr =
          '${_examDate!.year}-${_examDate!.month.toString().padLeft(2,'0')}-${_examDate!.day.toString().padLeft(2,'0')}';

      await Dio().post(
        "${ApiService().baseUrl}/department-head/exam-schedule",
        data: {
          'course_name': _courseCtrl.text.trim(),
          'exam_date':   dateStr,
          'period':      _period,
          'start_time':  _formatTime(_startTime!),
          'end_time':    _formatTime(_endTime!),
          'hall':        _hallCtrl.text.trim(),
          'exam_type':   _examType,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        _showSnack(isAr ? '✅ تم إضافة الامتحان بنجاح' : '✅ Exam added successfully', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⛔ Create Exam: $e');
      String msg = isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, try again';
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data['message'] ?? msg).toString();
      }
      _showSnack(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isSuccess ? Colors.green : Colors.red.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          title: Text(
            isAr ? 'إضافة امتحان جديد' : 'Add New Exam',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── معلومات المادة ─────────────────────────────────
              _sectionTitle(isAr ? 'معلومات المادة' : 'Course Information', Icons.book_outlined, _orange),
              const SizedBox(height: 10),
              _card(cardColor, [
                _field(
                  ctrl: _courseCtrl,
                  label: isAr ? 'اسم المادة' : 'Course Name',
                  icon: Icons.school_outlined,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? (isAr ? 'أدخل اسم المادة' : 'Enter course name') : null,
                ),
                const SizedBox(height: 14),
                _dropdownRow(
                  label: isAr ? 'نوع الامتحان' : 'Exam Type',
                  value: _examType,
                  items: _examTypes,
                  itemLabel: _examTypeLabel,
                  onChanged: (v) => setState(() => _examType = v!),
                  textColor: textColor,
                ),
              ]),
              const SizedBox(height: 16),

              // ── التاريخ والوقت ─────────────────────────────────
              _sectionTitle(isAr ? 'التاريخ والوقت' : 'Date & Time', Icons.schedule_outlined, _orange),
              const SizedBox(height: 10),
              _card(cardColor, [
                // تاريخ
                _pickerTile(
                  label: isAr ? 'تاريخ الامتحان' : 'Exam Date',
                  value: _examDate != null ? _formatDate(_examDate!) : (isAr ? 'اختر التاريخ' : 'Select Date'),
                  icon: Icons.calendar_today_outlined,
                  hasValue: _examDate != null,
                  onTap: _pickDate,
                  textColor: textColor,
                ),
                const Divider(height: 1),
                // الفترة
                _dropdownRow(
                  label: isAr ? 'الفترة' : 'Period',
                  value: _period,
                  items: _periods,
                  itemLabel: _periodLabel,
                  onChanged: (v) => setState(() => _period = v!),
                  textColor: textColor,
                ),
                const Divider(height: 1),
                // وقت البداية
                _pickerTile(
                  label: isAr ? 'وقت البداية' : 'Start Time',
                  value: _startTime != null ? _formatTime(_startTime!) : (isAr ? 'اختر الوقت' : 'Select Time'),
                  icon: Icons.access_time_outlined,
                  hasValue: _startTime != null,
                  onTap: () => _pickTime(true),
                  textColor: textColor,
                ),
                const Divider(height: 1),
                // وقت النهاية
                _pickerTile(
                  label: isAr ? 'وقت الانتهاء' : 'End Time',
                  value: _endTime != null ? _formatTime(_endTime!) : (isAr ? 'اختر الوقت' : 'Select Time'),
                  icon: Icons.access_time_filled_outlined,
                  hasValue: _endTime != null,
                  onTap: () => _pickTime(false),
                  textColor: textColor,
                ),
              ]),
              const SizedBox(height: 16),

              // ── القاعة ─────────────────────────────────────────
              _sectionTitle(isAr ? 'مكان الامتحان' : 'Exam Location', Icons.location_on_outlined, _orange),
              const SizedBox(height: 10),
              _card(cardColor, [
                _field(
                  ctrl: _hallCtrl,
                  label: isAr ? 'رقم القاعة / المختبر' : 'Hall / Lab Number',
                  icon: Icons.door_back_door_outlined,
                ),
              ]),
              const SizedBox(height: 28),

              // ── زر الحفظ ───────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, color: Colors.black),
                  label: Text(
                    _isLoading ? (isAr ? 'جارٍ الحفظ...' : 'Saving...') : (isAr ? 'حفظ الامتحان' : 'Save Exam'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 15),
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

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
    ]);
  }

  Widget _card(Color cardColor, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: _orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _orange),
        ),
        isDense: true,
      ),
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required IconData icon,
    required bool hasValue,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Icon(icon, color: _orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.55), fontSize: 11, fontFamily: 'Cairo')),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(
                color: hasValue ? textColor : Colors.grey,
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
              )),
            ]),
          ),
          Icon(isAr ? Icons.chevron_left : Icons.chevron_right, color: Colors.grey, size: 20),
        ]),
      ),
    );
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color textColor,
    String Function(String)? itemLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.75), fontFamily: 'Cairo', fontSize: 13))),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 13),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemLabel != null ? itemLabel(e) : e))).toList(),
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
