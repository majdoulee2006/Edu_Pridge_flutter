import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

import 'create_new_schedule.dart';
import 'edit_of_table.dart';

class TableViewScreen extends StatefulWidget {
  const TableViewScreen({super.key});

  @override
  State<TableViewScreen> createState() => _TableViewScreenState();
}

class _TableViewScreenState extends State<TableViewScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/schedule",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _rows = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('⛔ Fetch Schedule Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
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
            'عرض الجدول الدراسي',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
                  border: Border.all(color: primaryYellow.withValues(alpha: 0.35)),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                    : RefreshIndicator(
                        onRefresh: _fetchSchedule,
                        color: const Color(0xFFFFCC00),
                        child: _rows.isEmpty
                            ? ListView(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 60),
                                      child: Text(
                                        'لا يوجد جدول حتى الآن',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                itemCount: _rows.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final row = _rows[index];
                                  final scheduleId = row['id'] as int?;
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                                                color: primaryYellow.withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                row['day'] as String? ?? '',
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
                                                final refreshed = await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => EditOfTableScreen(
                                                      initialData: row,
                                                      scheduleId: scheduleId,
                                                    ),
                                                  ),
                                                );
                                                if (refreshed == true && mounted) {
                                                  _fetchSchedule();
                                                }
                                              },
                                              icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _line('المادة', row['subject'] as String? ?? '-', textColor),
                                        _line('المدرس', row['doctor'] as String? ?? row['teacher'] as String? ?? '-', textColor),
                                        _line('الوقت', row['time'] as String? ?? '-', textColor),
                                        _line('القاعة', row['hall'] as String? ?? '-', textColor),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateNewScheduleScreen()),
                    );
                    if (created == true && mounted) {
                      _fetchSchedule();
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
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
            TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: TextStyle(color: textColor.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}
