import 'package:flutter/material.dart';

class CreateNewScheduleScreen extends StatefulWidget {
  const CreateNewScheduleScreen({super.key});

  @override
  State<CreateNewScheduleScreen> createState() => _CreateNewScheduleScreenState();
}

class _CreateNewScheduleScreenState extends State<CreateNewScheduleScreen> {
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

  late final List<List<TextEditingController>> gridControllers;

  @override
  void initState() {
    super.initState();
    gridControllers = List.generate(
      days.length,
          (_) => List.generate(classNames.length, (_) => TextEditingController()),
    );
  }

  @override
  void dispose() {
    for (final row in gridControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void saveSchedule() {
    if (!formKey.currentState!.validate()) return;

    bool hasAnyData = false;
    for (final row in gridControllers) {
      for (final c in row) {
        if (c.text.trim().isNotEmpty) {
          hasAnyData = true;
          break;
        }
      }
      if (hasAnyData) break;
    }

    if (!hasAnyData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عبّي خلية واحدة على الأقل قبل الحفظ')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ نموذج الجدول الدراسي بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color cardColor = Theme.of(context).cardColor;
    const Color primaryYellow = Color(0xFFEFFF00);

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
            'إنشاء الجدول الدراسي',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
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
                    border: Border.all(color: primaryYellow.withOpacity(0.45)),
                  ),
                  child: Text(
                    'القالب مثل الجدول الورقي: الأيام عموديًا (الأحد - الخميس) '
                        'والشعب أفقيًا جنب بعض.\n'
                        'كل خلية: اكتب الحصص أو المواد الخاصة بهذا اليوم لهذه الشعبة.',
                    style: TextStyle(
                      color: textColor.withOpacity(0.85),
                      fontSize: 12.5,
                      fontFamily: 'Cairo',
                    ),
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
                    onPressed: saveSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'حفظ الجدول',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
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
        border: Border.all(color: Colors.grey.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerCell('اليوم', dayColWidth, primaryYellow),
              for (final name in classNames) _headerCell(name, classColWidth, primaryYellow),
            ],
          ),
          for (int dayIndex = 0; dayIndex < days.length; dayIndex++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dayCell(days[dayIndex], dayColWidth),
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
        color: primaryYellow.withOpacity(0.65),
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.35)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.35)),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _dayCell(String day, double width) {
    return Container(
      width: width,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.25)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.25)),
        ),
      ),
      child: Text(
        day,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _scheduleCell(TextEditingController controller, double width) {
    return Container(
      width: width,
      height: 110,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.25)),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.25)),
        ),
      ),
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 4,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        decoration: const InputDecoration(
          hintText: 'الحصص / المواد\n(مثال: ح1 رياضيات\nح2 برمجة...)',
          hintStyle: TextStyle(fontSize: 11, fontFamily: 'Cairo'),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
      ),
    );
  }
}
