import 'package:flutter/material.dart';

import 'create_new_schedule.dart';
import 'edit_of_table.dart';

class TableViewScreen extends StatefulWidget {
  const TableViewScreen({super.key});

  @override
  State<TableViewScreen> createState() => _TableViewScreenState();
}

class _TableViewScreenState extends State<TableViewScreen> {
  final List<Map<String, String>> _rows = [
    {
      'day': 'الأحد',
      'subject': 'تحليل نظم',
      'doctor': 'د. سامر الحسن',
      'time': '09:00 - 10:30',
      'hall': 'A-201',
    },
    {
      'day': 'الاثنين',
      'subject': 'برمجة تطبيقات',
      'doctor': 'م. رولا عيسى',
      'time': '11:00 - 12:30',
      'hall': 'B-105',
    },
    {
      'day': 'الثلاثاء',
      'subject': 'شبكات حاسوب',
      'doctor': 'د. فؤاد علي',
      'time': '13:00 - 14:30',
      'hall': 'Lab-3',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
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
            'عرض الجدول الدراسي',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryYellow.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'يمكنك مراجعة الخطة الأسبوعية، ثم إنشاء جلسة جديدة أو تعديل أي صف موجود.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12.5,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _rows.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد جدول حتى الآن',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: primaryYellow.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        row['day'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () async {
                                        final updated = await Navigator.push<Map<String, String>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditOfTableScreen(initialData: row),
                                          ),
                                        );

                                        if (updated != null && mounted) {
                                          setState(() {
                                            _rows[index] = updated;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _line('المادة', row['subject'] ?? '-', textColor),
                                _line('المدرس', row['doctor'] ?? '-', textColor),
                                _line('الوقت', row['time'] ?? '-', textColor),
                                _line('القاعة', row['hall'] ?? '-', textColor),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newRow = await Navigator.push<Map<String, String>>(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateNewScheduleScreen()),
                    );

                    if (newRow != null && mounted) {
                      setState(() {
                        _rows.add(newRow);
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'إنشاء جدول جديد',
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

  Widget _line(String title, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: textColor, fontFamily: 'Cairo'),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: textColor.withOpacity(0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
