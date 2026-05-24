import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';

class ReportRequestScreen extends StatefulWidget {
  const ReportRequestScreen({super.key});

  @override
  State<ReportRequestScreen> createState() => _ReportRequestScreenState();
}

class _ReportRequestScreenState extends State<ReportRequestScreen> {
  List<Map<String, dynamic>> _reportRequests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _fetchReportRequests();
  }

  Future<void> _fetchReportRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/report-requests",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true && mounted) {
        setState(() {
          _reportRequests = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('⛔ Fetch Report Requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  void _openCreateForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateReportSheet(
        onSubmitted: () {
          Navigator.pop(context);
          _fetchReportRequests();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const primaryYellow = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context, textColor, cardColor),
                  Expanded(
                    child: _isLoadingRequests
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                        : RefreshIndicator(
                            onRefresh: _fetchReportRequests,
                            color: primaryYellow,
                            child: _reportRequests.isEmpty
                                ? ListView(
                                    children: [
                                      const SizedBox(height: 80),
                                      Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade400),
                                            const SizedBox(height: 12),
                                            Text('لا توجد طلبات تقارير بعد',
                                                style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo')),
                                            const SizedBox(height: 8),
                                            Text('اضغط + لإضافة طلب جديد',
                                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontFamily: 'Cairo')),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                                    itemCount: _reportRequests.length,
                                    itemBuilder: (context, index) {
                                      final r = _reportRequests[index];
                                      return _buildReportCard(r, cardColor, textColor, isDark);
                                    },
                                  ),
                          ),
                  ),
                ],
              ),

              // زر + بنفس موقع زر الكاميرا في شاشة الطالب
              Positioned(
                bottom: 100,
                left: 20,
                child: GestureDetector(
                  onTap: _openCreateForm,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 28),
                  ),
                ),
              ),

              CustomBottomNav(
                currentIndex: 0,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r, Color cardColor, Color textColor, bool isDark) {
    final status = r['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';
    final reportType = r['report_type'] == 'academic' ? 'أداء أكاديمي' : 'سلوك وحضور';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isCompleted ? Icons.check_circle_outline : Icons.pending_outlined,
                color: isCompleted ? Colors.green : Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['student_name'] as String? ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor, fontFamily: 'Cairo')),
                const SizedBox(height: 3),
                Text('المدرب: ${r['teacher_name'] ?? ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
                if ((r['course_name'] as String?) != null) ...[
                  const SizedBox(height: 2),
                  Text('الدورة: ${r['course_name']}  |  السنة: ${r['year'] ?? '—'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  _badge(reportType, const Color(0xFFFFCC00).withValues(alpha: 0.15), const Color(0xFFAA8800)),
                  const SizedBox(width: 8),
                  _badge(isCompleted ? 'مكتمل' : 'قيد الانتظار',
                      (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                      isCompleted ? Colors.green : Colors.orange),
                ]),
                if (isCompleted && (r['notes'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('التقييم: ${r['notes']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontFamily: 'Cairo')),
  );

  Widget _buildAppBar(BuildContext context, Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleBtn(Icons.settings_outlined, cardColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(userName: "رئيس القسم", userRole: "إدارة")));
          }),
          Column(children: [
            Text("طلبات التقارير", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
            Text("سجل الطلبات المقدمة", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo')),
          ]),
          _buildCircleBtn(Icons.arrow_forward, cardColor, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
        child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
      ),
    );
  }
}

// ─── Bottom Sheet Form ────────────────────────────────────────────────────────
class _CreateReportSheet extends StatefulWidget {
  final VoidCallback onSubmitted;
  const _CreateReportSheet({required this.onSubmitted});

  @override
  State<_CreateReportSheet> createState() => _CreateReportSheetState();
}

class _CreateReportSheetState extends State<_CreateReportSheet> {
  // الخطوة الحالية
  int _step = 0; // 0=دورة 1=مدرب 2=سنة 3=طالب 4=نوع

  // الاختيارات
  String? _selectedCourse;
  String? _selectedTeacher;
  int _selectedYear = 1;
  String? _selectedStudent;
  bool _isAcademic = true;

  // البيانات
  bool _isLoadingCourses = true;
  bool _isLoadingTeachers = false;
  bool _isLoadingStudents = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _courses  = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _loadCourses() async {
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/courses",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (mounted) setState(() => _courses = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
    } catch (e) { debugPrint('⛔ $e'); }
    finally { if (mounted) setState(() => _isLoadingCourses = false); }
  }

  Future<void> _loadTeachers(String courseId) async {
    setState(() { _isLoadingTeachers = true; _teachers = []; _selectedTeacher = null; });
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/courses/$courseId/teachers",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (mounted) setState(() => _teachers = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
    } catch (e) { debugPrint('⛔ $e'); }
    finally { if (mounted) setState(() => _isLoadingTeachers = false); }
  }

  Future<void> _loadStudents(String courseId) async {
    setState(() { _isLoadingStudents = true; _students = []; _selectedStudent = null; });
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/courses/$courseId/students",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (mounted) setState(() => _students = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
    } catch (e) { debugPrint('⛔ $e'); }
    finally { if (mounted) setState(() => _isLoadingStudents = false); }
  }

  bool get _canSubmit => _selectedCourse != null && _selectedStudent != null &&
      (_isAcademic || _selectedTeacher != null);

  Future<void> _submit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال جميع الخطوات المطلوبة', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await Dio().post(
        "${ApiService().baseUrl}/department-head/report-requests",
        data: {
          'student_id':  _selectedStudent,
          'teacher_id':  _selectedTeacher,
          'report_type': _isAcademic ? 'academic' : 'behavioral',
          'course_id':   _selectedCourse,
          'year':        _selectedYear,
        },
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (mounted) {
        final msg = res.data['message'] as String? ?? '✅ تم إرسال الطلب بنجاح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
        widget.onSubmitted();
      }
    } catch (e) {
      debugPrint('⛔ Submit: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor   = isDark ? Colors.white : Colors.black;
    final fieldColor  = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F7F9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Text('طلب تقرير جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor, fontFamily: 'Cairo')),
              const SizedBox(height: 20),

              // ─── الخطوة 1: الدورة ───
              _buildSectionCard(
                step: 1, title: 'الدورة', icon: Icons.book_outlined, iconColor: Colors.teal,
                cardColor: cardColor, textColor: textColor,
                child: _isLoadingCourses
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                    : _buildDropdown(
                        hint: 'اختر الدورة',
                        value: _selectedCourse,
                        items: _courses.map((c) => DropdownMenuItem(
                          value: c['id']?.toString(),
                          child: Text(c['title'] as String? ?? '', style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 13)),
                        )).toList(),
                        onChanged: (v) {
                          setState(() { _selectedCourse = v; _step = 1; _selectedTeacher = null; _selectedStudent = null; });
                          if (v != null) { _loadTeachers(v); _loadStudents(v); }
                        },
                        fieldColor: fieldColor, textColor: textColor,
                      ),
              ),

              // ─── الخطوة 2: المدرب ───
              if (_selectedCourse != null)
                _buildSectionCard(
                  step: 2, title: 'المدرب المسؤول', icon: Icons.person_outlined, iconColor: Colors.blueAccent,
                  cardColor: cardColor, textColor: textColor,
                  child: _isLoadingTeachers
                      ? const Center(child: SizedBox(height: 32, child: CircularProgressIndicator(color: Color(0xFFFFCC00), strokeWidth: 2)))
                      : _buildDropdown(
                          hint: 'اختر المدرب',
                          value: _selectedTeacher,
                          items: _teachers.map((t) => DropdownMenuItem(
                            value: t['id']?.toString(),
                            child: Text(t['name'] as String? ?? '', style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => setState(() { _selectedTeacher = v; if (_step < 2) _step = 2; }),
                          fieldColor: fieldColor, textColor: textColor,
                        ),
                ),

              // ─── الخطوة 3: السنة ───
              if (_selectedCourse != null)
                _buildSectionCard(
                  step: 3, title: 'السنة الدراسية', icon: Icons.calendar_today_outlined, iconColor: const Color(0xFFFFCC00),
                  cardColor: cardColor, textColor: textColor,
                  child: Row(children: [
                    _yearCard(1, textColor, cardColor),
                    const SizedBox(width: 12),
                    _yearCard(2, textColor, cardColor),
                  ]),
                ),

              // ─── الخطوة 4: الطالب ───
              if (_selectedCourse != null)
                _buildSectionCard(
                  step: 4, title: 'الطالب', icon: Icons.person_search_outlined, iconColor: Colors.orange,
                  cardColor: cardColor, textColor: textColor,
                  child: _isLoadingStudents
                      ? const Center(child: SizedBox(height: 32, child: CircularProgressIndicator(color: Color(0xFFFFCC00), strokeWidth: 2)))
                      : _buildDropdown(
                          hint: 'اختر الطالب',
                          value: _selectedStudent,
                          items: _students
                              .where((s) => _selectedYear == 0 || (s['level']?.toString() == _selectedYear.toString()))
                              .map((s) => DropdownMenuItem(
                                value: s['id']?.toString(),
                                child: Text('${s['full_name']} - ${s['student_code'] ?? ''}',
                                    style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 13)),
                              )).toList(),
                          onChanged: (v) => setState(() { _selectedStudent = v; if (_step < 4) _step = 4; }),
                          fieldColor: fieldColor, textColor: textColor,
                        ),
                ),

              // ─── الخطوة 5: نوع التقرير ───
              if (_selectedCourse != null)
                _buildSectionCard(
                  step: 5, title: 'نوع التقرير', icon: Icons.assignment_outlined, iconColor: Colors.purpleAccent,
                  cardColor: cardColor, textColor: textColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _typeCard('أكاديمي', Icons.auto_graph_outlined, _isAcademic, cardColor, textColor,
                            () => setState(() => _isAcademic = true)),
                        const SizedBox(width: 12),
                        _typeCard('سلوكي', Icons.psychology_outlined, !_isAcademic, cardColor, textColor,
                            () => setState(() => _isAcademic = false)),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_isAcademic ? Colors.blue : Colors.purple).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(_isAcademic ? Icons.info_outline : Icons.edit_note_outlined,
                              size: 16, color: _isAcademic ? Colors.blue : Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isAcademic
                                  ? 'النظام يحسب المعدل ونسبة الحضور تلقائياً ويرسل التقرير لأولياء الأمر'
                                  : 'يُرسل للمدرب المسؤول ليكتب التقييم السلوكي',
                              style: TextStyle(fontSize: 11, fontFamily: 'Cairo',
                                  color: _isAcademic ? Colors.blue : Colors.purple),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 6),

              // ─── زر الإرسال ───
              if (_selectedCourse != null)
                GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity, height: 58,
                    decoration: BoxDecoration(
                      color: _canSubmit ? const Color(0xFFFFCC00) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _canSubmit ? [BoxShadow(color: const Color(0xFFFFCC00).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(
                              _isAcademic ? 'إنشاء التقرير الأكاديمي وإرساله للأهل' : 'إرسال طلب التقييم السلوكي للمدرب',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _canSubmit ? Colors.black : Colors.grey, fontFamily: 'Cairo'),
                            ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required int step, required String title, required IconData icon, required Color iconColor,
    required Widget child, required Color cardColor, required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo', color: textColor)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 6),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor))),
          ),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _buildDropdown({
    required String hint, required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required Color fieldColor, required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Theme.of(context).cardColor,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _yearCard(int year, Color textColor, Color cardColor) {
    final selected = _selectedYear == year;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedYear = year),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFCC00).withValues(alpha: 0.15) : cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFFFFCC00) : Colors.grey.withValues(alpha: 0.2), width: 2),
            boxShadow: selected ? [BoxShadow(color: const Color(0xFFFFCC00).withValues(alpha: 0.2), blurRadius: 6)] : null,
          ),
          child: Column(children: [
            Icon(Icons.calendar_today_outlined, color: selected ? const Color(0xFFFFCC00) : Colors.grey, size: 22),
            const SizedBox(height: 6),
            Text('السنة $year', style: TextStyle(fontSize: 13, color: textColor, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo')),
          ]),
        ),
      ),
    );
  }

  Widget _typeCard(String title, IconData icon, bool selected, Color cardColor, Color textColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? const Color(0xFFFFCC00) : Colors.grey.withValues(alpha: 0.2), width: 2),
            boxShadow: selected ? [BoxShadow(color: const Color(0xFFFFCC00).withValues(alpha: 0.2), blurRadius: 10)] : null,
          ),
          child: Column(children: [
            Icon(icon, color: selected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : Colors.grey, size: 26),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: textColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo')),
          ]),
        ),
      ),
    );
  }
}
