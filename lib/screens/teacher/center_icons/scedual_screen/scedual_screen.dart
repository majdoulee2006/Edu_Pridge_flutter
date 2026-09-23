import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';
import 'grades_entries_screen.dart';

const _yellow = Color(0xFFFFCC00);

class TeacherScheduleScreen extends StatefulWidget {
  final String? gradeReportRequestId;
  final String? targetCourseId;

  const TeacherScheduleScreen({
    super.key,
    this.gradeReportRequestId,
    this.targetCourseId,
  });

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  // ─── جدولي ───
  int selectedDayIndex = 0;
  int _todayIndex = 0;
  int _selectedLectureIndex = 0;
  bool _isLoadingSchedule = false;
  Map<String, dynamic> _scheduleData = {};
  List<Map<String, dynamic>> days = [];

  // ─── العلامات ───
  bool _isLoadingGrades = false;
  List<dynamic> _gradeEvents = [];
  List<dynamic> _myCourses = [];

  @override
  void initState() {
    super.initState();
    final startTab = widget.gradeReportRequestId != null ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: startTab)
      ..addListener(() => setState(() => _currentTab = _tabController.index));
    _currentTab = startTab;
    _generateDays();
    _fetchSchedule();
    _fetchGradeEvents();
    if (widget.gradeReportRequestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGradeRequestBanner());
    }
    _fetchMyCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showGradeRequestBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.orange.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        content: Row(
          children: [
            const Icon(Icons.grade_outlined, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'رئيس القسم يطلب تقرير علامات — أدخل العلامات ثم اضغط "إبلاغ المسؤول"',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('حسناً', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeGradeReport() async {
    final reqId = widget.gradeReportRequestId;
    if (reqId == null || reqId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await Dio().post(
        "${ApiService().baseUrl}/teacher/grade-report-requests/$reqId/complete",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إبلاغ المسؤول — التقرير جاهز'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الإرسال'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ══════════════════ جدولي ══════════════════

  void _generateDays() {
    const dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
    days = List.generate(5, (i) => {"name": dayNames[i], "dayKey": dayNames[i]});
    final now = DateTime.now();
    if (now.weekday == 7) {
      _todayIndex = 0;
    } else if (now.weekday <= 4) {
      _todayIndex = now.weekday;
    } else {
      _todayIndex = -1;
    }
    selectedDayIndex = (_todayIndex == -1) ? 0 : _todayIndex;
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoadingSchedule = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await Dio().get(
        "${ApiService().baseUrl}/teacher/schedule",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _scheduleData = Map<String, dynamic>.from(response.data['data'] ?? {});
        });
      }
    } catch (e) {
      debugPrint('Schedule Error: $e');
    } finally {
      setState(() => _isLoadingSchedule = false);
    }
  }

  // ══════════════════ العلامات ══════════════════

  Future<void> _fetchGradeEvents() async {
    setState(() => _isLoadingGrades = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/grades/events",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() => _gradeEvents = res.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('GradeEvents Error: $e');
    } finally {
      setState(() => _isLoadingGrades = false);
    }
  }

  Future<void> _fetchMyCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/courses",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() => _myCourses = res.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('MyCourses Error: $e');
    }
  }

  void _showCreateGradeSheet() {
    final formKey = GlobalKey<FormState>();
    int? selectedCourseId;
    String selectedCourseTitle = '';
    int? selectedCourseYear;
    String selectedCourseProgramName = '';
    String selectedType = 'exam';
    final titleCtrl    = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    final notesCtrl    = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay? selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final durationCtrl = TextEditingController(text: 'ساعتان');

    // ─── شفهي ───
    List<Map<String,dynamic>> _programs = [];
    int? selProgramId;
    String selProgramName = '';
    int? selYearLevel;
    bool oralAllStudents = true;
    int? selStudentId;
    String selStudentName = '';
    List<Map<String,dynamic>> _programStudents = [];
    bool _loadingStudents = false;

    const yearLabels = {1:'السنة الأولى',2:'السنة الثانية',3:'السنة الثالثة',4:'السنة الرابعة',5:'السنة الخامسة'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 16,
              left: 20,
              right: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _yellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_note_rounded, color: Colors.black87, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تقييم جديد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          Text('امتحان أو مذاكرة لمادة معينة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── نوع التقييم ──
                  const Text('نوع التقييم', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final t in [
                        {'val':'exam',  'label':'امتحان', 'icon': Icons.assignment_outlined},
                        {'val':'quiz',  'label':'مذاكرة', 'icon': Icons.quiz_outlined},
                        {'val':'oral',  'label':'شفهي',   'icon': Icons.record_voice_over_outlined},
                      ]) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              setSheet(() {
                                selectedType = t['val'] as String;

                                if (selectedType == 'exam') {
                                  durationCtrl.text = 'ساعتان';
                                } else if (selectedType == 'quiz') {
                                  durationCtrl.text = 'ساعة';
                                }
                              });
                              if (t['val'] == 'oral' && _programs.isEmpty) {
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('token') ?? '';
                                  final res = await Dio().get(
                                    "${ApiService().baseUrl}/teacher/grades/programs",
                                    options: Options(headers: {"Authorization": "Bearer $token"}),
                                  );
                                  if (res.statusCode == 200) {
                                    setSheet(() => _programs = List<Map<String,dynamic>>.from(res.data['data'] ?? []));
                                  }
                                } catch (e) {
                                  debugPrint('Programs fetch error: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('فشل تحميل الدورات: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedType == t['val'] ? _yellow : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedType == t['val'] ? _yellow : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(t['icon'] as IconData, size: 22, color: selectedType == t['val'] ? Colors.black : Colors.grey),
                                  const SizedBox(height: 4),
                                  Text(t['label'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: selectedType == t['val'] ? Colors.black : Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (t['val'] != 'oral') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── المادة (لكافة أنواع التقييم: امتحان / مذاكرة / شفهي) ──
                  const Text('المادة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: _inputDec('اختر المادة'),
                    value: selectedCourseId,
                    items: _myCourses.map((c) => DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['title'] as String? ?? ''),
                    )).toList(),
                    onChanged: (v) {
                      final course = _myCourses.firstWhere((c) => c['id'] == v, orElse: () => {});
                      setSheet(() {
                        selectedCourseId = v;
                        selectedCourseTitle = course['title'] as String? ?? '';
                        selectedCourseYear = course['year'] as int?;
                        selectedCourseProgramName = course['program_name'] as String? ?? course['level'] as String? ?? '';
                        selStudentId = null;
                        selStudentName = '';
                        _programStudents = [];
                      });
                    },
                    validator: (v) => v == null ? 'اختر المادة' : null,
                  ),
                  if (selectedCourseId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _yellow.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_outlined, size: 15, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            '${yearLabels[selectedCourseYear] ?? 'السنة ${selectedCourseYear ?? 1}'}${selectedCourseProgramName.isNotEmpty ? ' - $selectedCourseProgramName' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (selectedType == 'oral') ...[
                    // ── تطبيق على ──
                    const Text('تطبيق على', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setSheet(() { oralAllStudents = true; selStudentId = null; selStudentName = ''; }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: oralAllStudents ? _yellow : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: oralAllStudents ? _yellow : Colors.grey.shade300),
                              ),
                              child: Center(child: Text('كل الطلاب', style: TextStyle(color: oralAllStudents ? Colors.black : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              if (selectedCourseId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر المادة أولاً')));
                                return;
                              }
                              setSheet(() { oralAllStudents = false; _loadingStudents = true; });
                              final prefs = await SharedPreferences.getInstance();
                              final token = prefs.getString('token') ?? '';
                              final String fetchUrl = "${ApiService().baseUrl}/teacher/grades/program-students?course_id=$selectedCourseId";
                              final res = await Dio().get(
                                fetchUrl,
                                options: Options(headers: {"Authorization": "Bearer $token"}),
                              );
                              if (res.statusCode == 200) {
                                setSheet(() {
                                  _programStudents = List<Map<String,dynamic>>.from(res.data['data'] ?? []);
                                  _loadingStudents = false;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !oralAllStudents ? _yellow : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !oralAllStudents ? _yellow : Colors.grey.shade300),
                              ),
                              child: Center(child: Text('طالب محدد', style: TextStyle(color: !oralAllStudents ? Colors.black : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!oralAllStudents) ...[
                      const SizedBox(height: 10),
                      _loadingStudents
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _programStudents.isEmpty
                              ? Text('لا يوجد طلاب', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                              : DropdownButtonFormField<int>(
                                  decoration: _inputDec('اختر الطالب'),
                                  value: selStudentId,
                                  items: _programStudents.map((s) => DropdownMenuItem<int>(
                                    value: s['student_id'] as int,
                                    child: Text('${s['full_name']} - ${s['university_id'] ?? ''}'),
                                  )).toList(),
                                  onChanged: (v) {
                                    final st = _programStudents.firstWhere((s) => s['student_id'] == v, orElse: () => {});
                                    setSheet(() { selStudentId = v; selStudentName = st['full_name'] as String? ?? ''; });
                                  },
                                ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // ── العنوان والعلامة ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('العنوان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: titleCtrl,
                              decoration: _inputDec('مثال: امتحان نصفي'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('العلامة القصوى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: maxScoreCtrl,
                              decoration: _inputDec('100'),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              validator: (v) {
                                final d = double.tryParse(v ?? '');
                                if (d == null || d <= 0) return 'أدخل علامة صالحة';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── ملاحظات ──
                  const Text('ملاحظات (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: _inputDec('أضف ملاحظة...'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // ── التاريخ ──
                  const Text('التاريخ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setSheet(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                          const SizedBox(width: 10),
                          Text(intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(selectedDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  if (selectedType != 'oral') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // وقت الامتحان
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('وقت الامتحان (الساعة)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
                                  );
                                  if (picked != null) setSheet(() => selectedTime = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_outlined, size: 18, color: Colors.grey),
                                      const SizedBox(width: 10),
                                      Text(
                                        selectedTime == null 
                                            ? 'اختر الوقت' 
                                            : selectedTime!.format(ctx),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // مدة الامتحان
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مدة الامتحان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: durationCtrl,
                                decoration: _inputDec('مثال: ساعتان'),
                                validator: (v) => (selectedType != 'oral' && (v == null || v.trim().isEmpty)) ? 'مطلوب' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text('إنشاء التقييم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () async {
                        if (selectedType == 'oral') {
                          if (selectedCourseId == null && (selProgramId == null || selYearLevel == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر المادة أو (الدورة والسنة)')));
                            return;
                          }
                          if (!oralAllStudents && selStudentId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر الطالب')));
                            return;
                          }
                          if (titleCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل العنوان')));
                            return;
                          }
                        } else {
                          if (!formKey.currentState!.validate()) return;
                        }

                        String? timeStr;
                        if (selectedType != 'oral' && selectedTime != null) {
                          final now = DateTime.now();
                          final dt = DateTime(now.year, now.month, now.day, selectedTime!.hour, selectedTime!.minute);
                          timeStr = intl.DateFormat('hh:mm a').format(dt);
                        }

                        Navigator.pop(ctx);
                        await _createGradeEvent(
                          courseId: selectedCourseId,
                          courseTitle: selectedCourseTitle.isNotEmpty
                              ? selectedCourseTitle
                              : '$selProgramName - ${yearLabels[selYearLevel] ?? ''}',
                          type: selectedType,
                          title: titleCtrl.text.trim(),
                          maxScore: double.parse(maxScoreCtrl.text.isEmpty ? '25' : maxScoreCtrl.text),
                          date: intl.DateFormat('yyyy-MM-dd').format(selectedDate),
                          time: timeStr,
                          duration: selectedType != 'oral' ? durationCtrl.text.trim() : null,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          programId: selProgramId,
                          yearLevel: selYearLevel ?? selectedCourseYear,
                          studentId: !oralAllStudents ? selStudentId : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createGradeEvent({
    int? courseId,
    required String courseTitle,
    required String type,
    required String title,
    required double maxScore,
    required String date,
    String? time,
    String? duration,
    String? notes,
    int? programId,
    int? yearLevel,
    int? studentId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final Map<String, dynamic> body = {
        'type':      type,
        'title':     title,
        'max_score': maxScore,
        'date':      date,
        if (time != null) 'time': time,
        if (duration != null) 'duration': duration,
        if (notes != null) 'notes': notes,
      };

      if (type == 'oral') {
        if (programId != null) body['program_id'] = programId;
        if (yearLevel != null) body['year_level'] = yearLevel;
        if (courseId != null) body['course_id'] = courseId;
        if (studentId != null) body['student_id'] = studentId;
      } else {
        body['course_id'] = courseId;
      }

      final res = await Dio().post(
        "${ApiService().baseUrl}/teacher/grades/events",
        data: body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        await _fetchGradeEvents();
        if (mounted) {
          final newId = res.data['id'] as int;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GradeEntriesScreen(
                event: {
                  'id':           newId,
                  'title':        title,
                  'type':         type,
                  'max_score':    maxScore,
                  'course_title': courseTitle,
                  'notes':        notes,
                },
              ),
            ),
          );
          await _fetchGradeEvents();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['message'] as String? ?? 'حدث خطأ';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteGradeEvent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التقييم'),
        content: const Text('هل أنت متأكد من حذف هذا التقييم وجميع علاماته؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await Dio().delete(
        "${ApiService().baseUrl}/teacher/grades/events/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      await _fetchGradeEvents();
    } catch (e) {
      debugPrint('Delete grade event error: $e');
    }
  }

  // ══════════════════ Build ══════════════════

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            _currentTab == 0 ? 'جدول الحصص' : 'العلامات والتقييمات',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? _yellow : Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _yellow,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'جدول الحصص'),
            Tab(icon: Icon(Icons.grade_outlined, size: 18), text: 'التقييمات'),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(cardColor, textColor),
                _buildGradesTab(cardColor, textColor),
              ],
            ),
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════ تبويب جدولي ══════════════════

  Widget _buildScheduleTab(Color cardColor, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayKey = days.isNotEmpty ? (days[selectedDayIndex]['dayKey'] as String) : '';
    final rawList = _scheduleData[dayKey] as List? ?? [];
    final classes =
        rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final selectedDayName = days.isNotEmpty ? (days[selectedDayIndex]['name'] as String) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // شريط الأيام من اليمين لليسار (يبدأ بالأحد)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(days.length, (index) {
              return _buildDayCircle(day: days[index]['name'] as String, index: index);
            }),
          ),
        ),

        const SizedBox(height: 22),

        // ترويسة اليوم وعدد الحصص
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                days.isNotEmpty
                    ? (selectedDayIndex == _todayIndex
                        ? 'برنامج اليوم ($selectedDayName)'
                        : 'برنامج $selectedDayName')
                    : '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(25) : const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${classes.length} حصص',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // الخط الزمني وقائمة الحصص
        Expanded(
          child: _isLoadingSchedule
              ? const Center(
                  child: CircularProgressIndicator(color: _yellow),
                )
              : classes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 55,
                              color: Colors.grey.withAlpha(80),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'لا توجد حصص ليوم $selectedDayName',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: ValueKey<int>(selectedDayIndex),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                      itemCount: classes.length,
                      itemBuilder: (ctx, index) {
                        final cls = classes[index];
                        final isLast = index == classes.length - 1;
                        final isSelected = index == _selectedLectureIndex;
                        final start = cls['start_time'] as String? ?? '';
                        final end = cls['end_time'] as String? ?? '';
                        final isCurrent = _isNow(start, end);

                        final startParts = _parseTime(start);
                        final endParts = _parseTime(end);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedLectureIndex = index),
                          child: _buildTimelineItem(
                            time: startParts['time'] ?? '',
                            amPm: startParts['period'] ?? '',
                            endTime: endParts['time'],
                            endAmPm: endParts['period'],
                            isCurrentTime: isCurrent || isSelected,
                            isLast: isLast,
                            card: _buildClassCard(
                              title: cls['course_name'] as String? ?? 'مادة دراسية',
                              location: cls['room'] as String? ?? '',
                              tagText: isCurrent ? 'الآن' : 'محاضرة',
                              isActive: isSelected,
                              now: isCurrent,
                              cardColor: cardColor,
                              textColor: textColor,
                              iconIndex: index,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDayCircle({required String day, required int index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedDayIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        selectedDayIndex = index;
        _selectedLectureIndex = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 12),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? _yellow
              : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.circular(35),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _yellow.withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Center(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.black87
                  : (isDark ? Colors.grey.shade300 : Colors.grey),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String amPm,
    String? endTime,
    String? endAmPm,
    required bool isCurrentTime,
    required Widget card,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String timeLabel = time;
    String amPmLabel = amPm;
    if (endTime != null && endTime.isNotEmpty) {
      timeLabel = '$time - $endTime';
      amPmLabel = '$amPm - ${endAmPm ?? ''}'.trim();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: isCurrentTime
                    ? BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCurrentTime
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
              Text(
                amPmLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 2),
              if (!isLast) ...[
                Container(
                  width: 1.5,
                  height: 90,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: card,
          ),
        ),
      ],
    );
  }

  // ══════════════════ تبويب العلامات ══════════════════

  Widget _buildGradesTab(Color cardColor, Color textColor) {
    return Stack(
      children: [
        _isLoadingGrades
            ? const Center(child: CircularProgressIndicator(color: _yellow))
            : _gradeEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grade_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('لا توجد تقييمات بعد',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('اضغط + لإضافة امتحان أو مذاكرة',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _gradeEvents.length,
                    itemBuilder: (ctx, i) =>
                        _buildGradeEventCard(_gradeEvents[i], cardColor, textColor),
                  ),
        Positioned(
          bottom: 90,
          left: 16,
          child: FloatingActionButton(
            heroTag: 'createGrade',
            backgroundColor: _yellow,
            foregroundColor: Colors.black,
            onPressed: _showCreateGradeSheet,
            child: const Icon(Icons.add),
          ),
        ),
        if (widget.gradeReportRequestId != null)
          Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'notifyBoss',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              onPressed: _completeGradeReport,
              icon: const Icon(Icons.send_rounded),
              label: const Text('إبلاغ المسؤول', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildGradeEventCard(
      dynamic event, Color cardColor, Color textColor) {
    final type = event['type'] == 'exam' ? 'امتحان' : event['type'] == 'quiz' ? 'مذاكرة' : 'شفهي';
    final typeColor = event['type'] == 'exam' ? Colors.orange : event['type'] == 'quiz' ? Colors.blue : Colors.purple;
    // نعتبر التقييم "غير مكتمل" إذا لم يكن في بياناته علامات (نتحقق من حقل اختياري)
    final gradedCount = (event['graded_count'] as int?) ?? 0;
    final totalCount = (event['total_count'] as int?) ?? 0;
    final hasUngraded = totalCount > 0 && gradedCount < totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: hasUngraded
            ? Border.all(color: Colors.red.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(type,
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              if (hasUngraded) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$gradedCount/$totalCount',
                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(event['title'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                    ),
                    if (hasUngraded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('علامات ناقصة',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(event['course_title'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('${event['date'] ?? ''} • من ${event['max_score']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: Colors.grey),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GradeEntriesScreen(event: event),
                    ),
                  );
                  await _fetchGradeEvents();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Colors.red),
                onPressed: () => _deleteGradeEvent(event['id'] as int),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════ Helpers ══════════════════

  bool _isNow(String startTime, String endTime) {
    try {
      final now = TimeOfDay.now();
      final sp = startTime.split(':');
      final ep = endTime.split(':');
      final nowMin = now.hour * 60 + now.minute;
      final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
      final endMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
      return nowMin >= startMin && nowMin <= endMin;
    } catch (_) {
      return false;
    }
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Map<String, String> _parseTime(dynamic rawTime) {
    if (rawTime == null) return {'time': '', 'period': ''};
    final str = rawTime.toString().trim();
    if (str.isEmpty) return {'time': '', 'period': ''};

    final spaceParts = str.split(' ');
    if (spaceParts.length > 1) {
      final period = spaceParts[1].toUpperCase() == 'AM'
          ? 'ص'
          : (spaceParts[1].toUpperCase() == 'PM' ? 'م' : spaceParts[1]);
      return {'time': spaceParts[0], 'period': period};
    }

    final colonParts = str.split(':');
    if (colonParts.length >= 2) {
      final hour = int.tryParse(colonParts[0]) ?? 0;
      final minute = int.tryParse(colonParts[1]) ?? 0;
      final period = hour >= 12 ? 'م' : 'ص';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minStr = minute.toString().padLeft(2, '0');
      return {'time': '$displayHour:$minStr', 'period': period};
    }

    return {'time': str, 'period': ''};
  }

  Widget _buildClassCard({
    required String title,
    required String location,
    required String tagText,
    required bool isActive,
    required bool now,
    required Color cardColor,
    required Color textColor,
    int iconIndex = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final palette = [
      (Colors.blue, isDark ? Colors.blue.withAlpha(40) : Colors.blue.shade50),
      (Colors.purple, isDark ? Colors.purple.withAlpha(40) : Colors.purple.shade50),
      (Colors.teal, isDark ? Colors.teal.withAlpha(40) : Colors.teal.shade50),
      (Colors.amber.shade800, isDark ? Colors.amber.withAlpha(40) : Colors.amber.shade50),
    ];
    final colorScheme = palette[iconIndex % palette.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: (isActive || now)
            ? Border.all(color: _yellow, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (now) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'الآن',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(20)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tagText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.$2,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: isDark ? Colors.white70 : colorScheme.$1,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 15, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  location.isNotEmpty ? location : 'لم يتم تحديد القاعة',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
