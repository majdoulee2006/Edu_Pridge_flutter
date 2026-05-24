import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class TeacherReportEvaluationScreen extends StatefulWidget {
  const TeacherReportEvaluationScreen({super.key});

  @override
  State<TeacherReportEvaluationScreen> createState() => _TeacherReportEvaluationScreenState();
}

class _TeacherReportEvaluationScreenState extends State<TeacherReportEvaluationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/report-requests",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        setState(() => _requests = list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (e) {
      debugPrint('⛔ $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchAcademicStats(int requestId) async {
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/report-requests/$requestId/stats",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data'] as Map);
      }
    } catch (e) {
      debugPrint('⛔ stats: $e');
    }
    return null;
  }

  Future<void> _openBehavioralDialog(Map<String, dynamic> req) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تقييم سلوكي – ${req['student_name'] ?? ''}',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (req['course_name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('المادة: ${req['course_name']}  |  السنة: ${req['year'] ?? '—'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
                ),
              const Text('اكتب ملاحظاتك السلوكية:', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'مثال: الطالب منضبط، يشارك بفاعلية...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await _submitEvaluation(req['id'] as int, controller.text.trim());
    }
  }

  Future<void> _openAcademicDialog(Map<String, dynamic> req) async {
    // أولاً: جلب الإحصائيات
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00))),
    );
    final stats = await _fetchAcademicStats(req['id'] as int);
    if (!mounted) return;
    Navigator.pop(context); // أغلق loading

    final avgGrade    = stats?['avg_grade'];
    final attRate     = stats?['attendance_rate'];
    final present     = stats?['present'] ?? 0;
    final total       = stats?['total'] ?? 0;

    String autoText = 'تقرير أكاديمي للطالب ${req['student_name'] ?? ''}';
    if (req['course_name'] != null) autoText += ' في مادة ${req['course_name']}';
    if (req['year'] != null) autoText += ' (السنة ${req['year']})';
    autoText += '.\n';
    if (avgGrade != null) autoText += 'متوسط العلامات: $avgGrade / 100.\n';
    if (attRate != null) autoText += 'نسبة الحضور: $attRate% ($present حضور من أصل $total جلسة).';
    if (avgGrade == null && attRate == null) autoText += 'لا تتوفر بيانات أكاديمية مسجّلة حتى الآن.';

    final controller = TextEditingController(text: autoText);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تقييم أكاديمي – ${req['student_name'] ?? ''}',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقات الإحصائيات
                if (avgGrade != null || attRate != null) ...[
                  Row(
                    children: [
                      if (avgGrade != null)
                        Expanded(child: _statChip(Icons.grade_outlined, 'المعدل', '$avgGrade/100', Colors.blue)),
                      if (avgGrade != null && attRate != null) const SizedBox(width: 10),
                      if (attRate != null)
                        Expanded(child: _statChip(Icons.how_to_reg_outlined, 'الحضور', '$attRate%', Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                const Text('التقرير المُولَّد (يمكن تعديله):', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await _submitEvaluation(req['id'] as int, controller.text.trim());
    }
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: color, fontFamily: 'Cairo')),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEvaluation(int requestId, String notes) async {
    try {
      await Dio().post(
        "${ApiService().baseUrl}/teacher/report-requests/$requestId/evaluate",
        data: {'notes': notes},
        options: Options(headers: {
          "Authorization": "Bearer ${await _token()}",
          "Accept": "application/json",
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال التقييم بنجاح', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
        _fetchRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    final pending   = _requests.where((r) => r['status'] == 'pending').toList();
    final completed = _requests.where((r) => r['status'] != 'pending').toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          centerTitle: true,
          title: const Text('طلبات التقييم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
            : RefreshIndicator(
                onRefresh: _fetchRequests,
                color: const Color(0xFFFFCC00),
                child: _requests.isEmpty
                    ? const Center(child: Text('لا توجد طلبات تقييم حالياً', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')))
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          if (pending.isNotEmpty) ...[
                            _sectionTitle('معلّقة (${pending.length})', Colors.orange),
                            const SizedBox(height: 8),
                            ...pending.map((r) => _buildCard(r, cardColor, textColor, isDark, isPending: true)),
                            const SizedBox(height: 16),
                          ],
                          if (completed.isNotEmpty) ...[
                            _sectionTitle('مكتملة (${completed.length})', Colors.green),
                            const SizedBox(height: 8),
                            ...completed.map((r) => _buildCard(r, cardColor, textColor, isDark, isPending: false)),
                          ],
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> req, Color cardColor, Color textColor, bool isDark, {required bool isPending}) {
    final isBehavioral = req['report_type'] == 'behavioral';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(req['student_name'] ?? '—',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor, fontFamily: 'Cairo')),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isBehavioral ? Colors.purple : Colors.blue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isBehavioral ? 'سلوكي' : 'أكاديمي',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBehavioral ? Colors.purple : Colors.blue, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (req['course_name'] != null)
              Row(children: [
                const Icon(Icons.book_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${req['course_name']}  –  السنة ${req['year'] ?? '—'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
              ]),
            if (isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(isBehavioral ? Icons.edit_note_outlined : Icons.auto_graph_outlined, size: 18),
                  label: Text(isBehavioral ? 'كتابة تقييم سلوكي' : 'إنشاء تقييم أكاديمي',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  onPressed: () => isBehavioral ? _openBehavioralDialog(req) : _openAcademicDialog(req),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                const Text('تم إرسال التقييم', style: TextStyle(color: Colors.green, fontSize: 12, fontFamily: 'Cairo')),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
