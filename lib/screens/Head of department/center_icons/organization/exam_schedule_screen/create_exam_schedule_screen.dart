import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class CreateExamScheduleScreen extends StatefulWidget {
  const CreateExamScheduleScreen({super.key});

  @override
  State<CreateExamScheduleScreen> createState() => _CreateExamScheduleScreenState();
}

class _CreateExamScheduleScreenState extends State<CreateExamScheduleScreen> {
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
  void dispose() {
    _courseCtrl.dispose();
    _hallCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return '${days[d.weekday % 7]}، ${d.day} ${months[d.month]} ${d.year}';
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
      _showSnack('اختر تاريخ الامتحان أولاً');
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showSnack('اختر وقت البداية والنهاية');
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
        _showSnack('✅ تم إضافة الامتحان بنجاح', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⛔ Create Exam: $e');
      String msg = 'حدث خطأ، حاول مجدداً';
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          title: Text('إضافة امتحان جديد',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── معلومات المادة ─────────────────────────────────
              _sectionTitle('معلومات المادة', Icons.book_outlined, _orange),
              const SizedBox(height: 10),
              _card(cardColor, [
                _field(
                  ctrl: _courseCtrl,
                  label: 'اسم المادة',
                  icon: Icons.school_outlined,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'أدخل اسم المادة' : null,
                ),
                const SizedBox(height: 14),
                _dropdownRow(
                  label: 'نوع الامتحان',
                  value: _examType,
                  items: _examTypes,
                  onChanged: (v) => setState(() => _examType = v!),
                  textColor: textColor,
                ),
              ]),
              const SizedBox(height: 16),

              // ── التاريخ والوقت ─────────────────────────────────
              _sectionTitle('التاريخ والوقت', Icons.schedule_outlined, _orange),
              const SizedBox(height: 10),
              _card(cardColor, [
                // تاريخ
                _pickerTile(
                  label: 'تاريخ الامتحان',
                  value: _examDate != null ? _formatDate(_examDate!) : 'اختر التاريخ',
                  icon: Icons.calendar_today_outlined,
                  hasValue: _examDate != null,
                  onTap: _pickDate,
                  textColor: textColor,
                ),
                const Divider(height: 1),
                // الفترة
                _dropdownRow(
                  label: 'الفترة',
                  value: _period,
                  items: _periods,
                  onChanged: (v) => setState(() => _period = v!),
                  textColor: textColor,
                ),
                const Divider(height: 1),
                // وقت البداية
                _pickerTile(
                  label: 'وقت البداية',
                  value: _startTime != null ? _formatTime(_startTime!) : 'اختر الوقت',
                  icon: Icons.access_time_outlined,
                  hasValue: _startTime != null,
                  onTap: () => _pickTime(true),
                  textColor: textColor,
                ),
                const Divider(height: 1),
                // وقت النهاية
                _pickerTile(
                  label: 'وقت الانتهاء',
                  value: _endTime != null ? _formatTime(_endTime!) : 'اختر الوقت',
                  icon: Icons.access_time_filled_outlined,
                  hasValue: _endTime != null,
                  onTap: () => _pickTime(false),
                  textColor: textColor,
                ),
              ]),
              const SizedBox(height: 16),

              // ── القاعة ─────────────────────────────────────────
              _sectionTitle('مكان الامتحان', Icons.location_on_outlined, _orange),
              const SizedBox(height: 10),
              _card(cardColor, [
                _field(
                  ctrl: _hallCtrl,
                  label: 'رقم القاعة / المختبر',
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
                    _isLoading ? 'جارٍ الحفظ...' : 'حفظ الامتحان',
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
          const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.75), fontFamily: 'Cairo', fontSize: 13))),
        DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 13),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
