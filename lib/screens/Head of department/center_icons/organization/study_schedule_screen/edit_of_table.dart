import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class EditOfTableScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final int? scheduleId;

  const EditOfTableScreen({super.key, this.initialData, this.scheduleId});

  @override
  State<EditOfTableScreen> createState() => _EditOfTableScreenState();
}

class _EditOfTableScreenState extends State<EditOfTableScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dayController;
  late final TextEditingController _subjectController;
  late final TextEditingController _teacherController;
  late final TextEditingController _timeController;
  late final TextEditingController _hallController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _dayController     = TextEditingController(text: d?['day']     as String? ?? '');
    _subjectController = TextEditingController(text: d?['subject'] as String? ?? '');
    _teacherController = TextEditingController(text: d?['doctor']  as String? ?? '');
    _timeController    = TextEditingController(text: d?['time']    as String? ?? '');
    _hallController    = TextEditingController(text: d?['hall']    as String? ?? '');
  }

  @override
  void dispose() {
    _dayController.dispose();
    _subjectController.dispose();
    _teacherController.dispose();
    _timeController.dispose();
    _hallController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id = widget.scheduleId;
      if (id != null) {
        await Dio().put(
          "${ApiService().baseUrl}/department-head/schedule/$id",
          data: {
            'day':     _dayController.text.trim(),
            'subject': _subjectController.text.trim(),
            'teacher': _teacherController.text.trim(),
            'time':    _timeController.text.trim(),
            'hall':    _hallController.text.trim(),
          },
          options: Options(headers: {"Authorization": "Bearer $token"}),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حفظ تعديلات الجدول بنجاح'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⛔ Edit Schedule Error: $e');
      String msg = 'حدث خطأ، حاول مجدداً';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response!.data['message'] ?? msg;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          title: Text(
            'تعديل الجدول الدراسي',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'عدّل بيانات هذا الصف في الجدول الدراسي ثم اضغط حفظ.',
                  style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 12.5, fontFamily: 'Cairo'),
                ),
              ),
              const SizedBox(height: 14),
              _input(_dayController,     'اليوم'),
              _input(_subjectController, 'المادة'),
              _input(_teacherController, 'الأستاذ'),
              _input(_timeController,    'الوقت'),
              _input(_hallController,    'القاعة'),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('حفظ التعديلات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Cairo'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}
