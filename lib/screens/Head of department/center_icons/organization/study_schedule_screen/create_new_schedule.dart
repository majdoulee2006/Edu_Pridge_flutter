import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class CreateNewScheduleScreen extends StatefulWidget {
  const CreateNewScheduleScreen({super.key});

  @override
  State<CreateNewScheduleScreen> createState() => _CreateNewScheduleScreenState();
}

class _CreateNewScheduleScreenState extends State<CreateNewScheduleScreen> {
  bool get isAr => AppSettings.language.value == 'ar';
  void _onLangChange() { if (mounted) setState(() {}); }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final List<String> days = const [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
  ];

  final List<String> classNames = const [
    'معلوماتية 1',
    'معلوماتية 2',
    'معلوماتية 3',
    'معلوماتية 4',
  ];

  String _dayLabel(String d) {
    if (isAr) return d;
    return switch (d) {
      'الأحد' => 'Sunday',
      'الاثنين' => 'Monday',
      'الثلاثاء' => 'Tuesday',
      'الأربعاء' => 'Wednesday',
      'الخميس' => 'Thursday',
      _ => d,
    };
  }

  String _classLabel(String c) {
    if (isAr) return c;
    return c.replaceAll('معلوماتية', 'IT');
  }

  late final List<List<TextEditingController>> gridControllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    gridControllers = List.generate(
      days.length,
      (_) => List.generate(classNames.length, (_) => TextEditingController()),
    );
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    for (final row in gridControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> saveSchedule() async {
    if (!formKey.currentState!.validate()) return;

    final List<Map<String, String>> entries = [];
    for (int d = 0; d < days.length; d++) {
      for (int c = 0; c < classNames.length; c++) {
        final content = gridControllers[d][c].text.trim();
        if (content.isNotEmpty) {
          entries.add({
            'day':        days[d],
            'class_name': classNames[c],
            'content':    content,
          });
        }
      }
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'عبّي خلية واحدة على الأقل قبل الحفظ' : 'Fill at least one cell before saving')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await Dio().post(
        "${ApiService().baseUrl}/department-head/schedule",
        data: {'entries': entries},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '✅ تم حفظ الجدول الدراسي بنجاح' : '✅ Study schedule saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('⛔ Create Schedule Error: $e');
      String msg = isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, try again';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color cardColor = Theme.of(context).cardColor;
    const Color primaryYellow = Color(0xFFFFCC00);

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
            isAr ? 'إنشاء الجدول الدراسي' : 'Create Study Schedule',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        ),
        body: Form(
          key: formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryYellow.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    isAr
                        ? 'القالب مثل الجدول الورقي: الأيام عموديًا (الأحد - الخميس) '
                            'والشعب أفقيًا جنب بعض.\n'
                            'كل خلية: اكتب الحصص أو المواد الخاصة بهذا اليوم لهذه الشعبة.'
                        : 'Template matches paper schedule: Days vertically (Sun - Thu) '
                            'and classes horizontally side-by-side.\n'
                            'Each cell: Enter classes or subjects for this day and section.',
                    style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 12.5, fontFamily: 'Cairo'),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildScheduleTable(primaryYellow),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : saveSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text(
                            isAr ? 'حفظ الجدول' : 'Save Schedule',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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

  Widget _buildScheduleTable(Color primaryYellow) {
    const double dayColWidth = 110;
    const double classColWidth = 220;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerCell(isAr ? 'اليوم' : 'Day', dayColWidth, primaryYellow),
              for (final name in classNames) _headerCell(_classLabel(name), classColWidth, primaryYellow),
            ],
          ),
          for (int dayIndex = 0; dayIndex < days.length; dayIndex++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dayCell(_dayLabel(days[dayIndex]), dayColWidth),
                for (int classIndex = 0; classIndex < classNames.length; classIndex++)
                  _scheduleCell(gridControllers[dayIndex][classIndex], classColWidth),
              ],
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width, Color primaryYellow) {
    return Container(
      width: width,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryYellow.withValues(alpha: 0.65),
        border: Border(
          left: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, fontFamily: 'Cairo'),
      ),
    );
  }

  Widget _dayCell(String day, double width) {
    return Container(
      width: width,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        border: Border(
          left: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        ),
      ),
      child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    );
  }

  Widget _scheduleCell(TextEditingController controller, double width) {
    return Container(
      width: width,
      height: 110,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
        ),
      ),
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 4,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        decoration: InputDecoration(
          hintText: isAr
              ? 'الحصص / المواد\n(مثال: ح1 رياضيات\nح2 برمجة...)'
              : 'Classes / Subjects\n(e.g., P1 Math\nP2 Coding...)',
          hintStyle: const TextStyle(fontSize: 11, fontFamily: 'Cairo'),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }
}
