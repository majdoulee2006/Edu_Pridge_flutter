import 'package:flutter/material.dart';

class EditOfTableScreen extends StatefulWidget {
  final Map<String, String>? initialData;

  const EditOfTableScreen({super.key, this.initialData});

  @override
  State<EditOfTableScreen> createState() => _EditOfTableScreenState();
}

class _EditOfTableScreenState extends State<EditOfTableScreen> {
  final _formKey = GlobalKey<FormState>();
  static const int _rowsCount = 10;

  late final List<TextEditingController> _sectionControllers;
  late final List<TextEditingController> _subjectControllers;
  late final List<TextEditingController> _teacherControllers;
  late final List<TextEditingController> _timeControllers;

  @override
  void initState() {
    super.initState();
    _sectionControllers = List.generate(_rowsCount, (i) {
      return TextEditingController(
        text: i == 0 ? (widget.initialData?['section'] ?? 'الشعبة ${i + 1}') : 'الشعبة ${i + 1}',
      );
    });
    _subjectControllers = List.generate(_rowsCount, (i) {
      return TextEditingController(
        text: i == 0 ? (widget.initialData?['subject'] ?? 'مادة ${i + 1}') : 'مادة ${i + 1}',
      );
    });
    _teacherControllers = List.generate(_rowsCount, (i) {
      return TextEditingController(
        text: i == 0 ? (widget.initialData?['doctor'] ?? 'الأستاذ ${i + 1}') : 'الأستاذ ${i + 1}',
      );
    });
    _timeControllers = List.generate(_rowsCount, (i) {
      return TextEditingController(
        text: i == 0 ? (widget.initialData?['time'] ?? '08:00 - 09:00') : '08:00 - 09:00',
      );
    });
  }

  @override
  void dispose() {
    for (final c in _sectionControllers) {
      c.dispose();
    }
    for (final c in _subjectControllers) {
      c.dispose();
    }
    for (final c in _teacherControllers) {
      c.dispose();
    }
    for (final c in _timeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ تعديلات الجدول الدراسي')),
    );
    Navigator.pop<Map<String, String>>(context, {
      'day': 'محدّث',
      'subject': _subjectControllers.first.text.trim(),
      'doctor': _teacherControllers.first.text.trim(),
      'time': _timeControllers.first.text.trim(),
      'hall': '-',
      'section': _sectionControllers.first.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFEFFF00);

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
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
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
                  'يمكنك تعديل بيانات الجدول الدراسي بالكامل. النموذج يحتوي 10 صفوف.',
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontSize: 12.5,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(_rowsCount, (index) => _rowCard(index, textColor)),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'حفظ التعديلات',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowCard(int index, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الصف ${index + 1}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 10),
            _input(_sectionControllers[index], 'اسم الشعبة'),
            _input(_subjectControllers[index], 'المادة'),
            _input(_teacherControllers[index], 'الأستاذ'),
            _input(_timeControllers[index], 'الوقت'),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontFamily: 'Cairo'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.35)),
          ),
        ),
      ),
    );
  }
}
