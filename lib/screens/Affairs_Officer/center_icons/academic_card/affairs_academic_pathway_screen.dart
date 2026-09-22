import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'affairs_pdf_viewer_screen.dart';

class AffairsAcademicPathwayScreen extends StatefulWidget {
  const AffairsAcademicPathwayScreen({super.key});

  @override
  State<AffairsAcademicPathwayScreen> createState() => _AffairsAcademicPathwayScreenState();
}

class _AffairsAcademicPathwayScreenState extends State<AffairsAcademicPathwayScreen> {
  final AffairsServices _affairsServices = AffairsServices();

  bool _isLoading = true;
  String _currentViewMode = 'student'; // 'student' or 'course'

  // Master Data from API
  List<dynamic> _departments = [];
  List<dynamic> _programs = [];
  List<dynamic> _allCourses = [];
  List<dynamic> _allStudents = [];
  List<dynamic> _courseStudents = [];

  // Filter States
  String _selectedDepartmentId = 'all';
  String _selectedProgramId = 'all';
  String _selectedYear = 'both'; // 'both', '1', '2'
  String _selectedSemester = 'both'; // 'both', '1', '2'
  String _selectedStanding = 'all'; // 'all', 'passed', 'failed', 'supplementary'

  // Search & Navigation
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredStudents = [];
  Map<String, dynamic>? _selectedStudent;

  // Course View States
  List<dynamic> _filteredCourses = [];
  Map<String, dynamic>? _selectedCourse;
  String _courseSubFilter = 'all'; // 'all', 'pass', 'fail'

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMasterData() async {
    setState(() => _isLoading = true);
    final res = await _affairsServices.getAcademicPathwayData();

    if (res != null) {
      final data = (res['data'] is Map<String, dynamic>) ? (res['data'] as Map<String, dynamic>) : res;
      setState(() {
        _departments = data['departments'] ?? [];
        _programs = data['programs'] ?? [];
        _allCourses = data['courses'] ?? [];
        _allStudents = data['studentsList'] ?? [];
        _courseStudents = data['students'] ?? [];
        _isLoading = false;
      });
      _applyFilters();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تحميل بيانات المسار الأكاديمي. يرجى التحقق من الاتصال.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─────────────────────────── مصفوفة الفصول وحسابات المقررات الدقيقة ───────────────────────────
  static const List<Map<String, dynamic>> _canonicalSemesters = [
    {
      'key': '1_1',
      'year': 1,
      'semester_id': 1,
      'num': 1,
      'title': 'الفصل الأول',
      'yearLabel': 'السنة الأولى',
      'fullTitle': 'الفصل الأول • السنة الأولى'
    },
    {
      'key': '1_2',
      'year': 1,
      'semester_id': 2,
      'num': 2,
      'title': 'الفصل الثاني',
      'yearLabel': 'السنة الأولى',
      'fullTitle': 'الفصل الثاني • السنة الأولى'
    },
    {
      'key': '2_1',
      'year': 2,
      'semester_id': 1,
      'num': 3,
      'title': 'الفصل الثالث',
      'yearLabel': 'السنة الثانية (فصل 1)',
      'fullTitle': 'الفصل الثالث • السنة الثانية (الفصل الأول)'
    },
    {
      'key': '2_2',
      'year': 2,
      'semester_id': 2,
      'num': 4,
      'title': 'الفصل الرابع',
      'yearLabel': 'السنة الثانية (فصل 2)',
      'fullTitle': 'الفصل الرابع • السنة الثانية (الفصل الثاني)'
    },
  ];

  Map<String, dynamic> _calculateStudentData(Map<String, dynamic> s, String yearFilter, String semFilter) {
    final allCourses = (s['courses'] as List<dynamic>?) ?? [];
    final semGroups = <Map<String, dynamic>>[];
    int totalCoursesCount = 0;
    double cumHours = 0;
    double cumPoints = 0;
    final allSemGpas = <double>[];
    final passedSemGpas = <Map<String, dynamic>>[];
    final failedTitles = <String>[];

    final levelStr = s['level']?.toString() ?? '';
    final isYear1 = levelStr.contains('الأولى') || levelStr == '1' || levelStr.toLowerCase().contains('first');

    for (var semDef in _canonicalSemesters) {
      final sYear = semDef['year'] as int;
      final sSemId = semDef['semester_id'] as int;

      if (isYear1 && sYear > 1) continue;
      if (yearFilter != 'both' && sYear.toString() != yearFilter) continue;
      if (semFilter != 'both' && sSemId.toString() != semFilter) continue;

      final coursesInSem = allCourses.where((c) {
        final cYear = int.tryParse(c['year']?.toString() ?? '1') ?? 1;
        final cSem = int.tryParse(c['semester_id']?.toString() ?? '1') ?? 1;
        return cYear == sYear && cSem == sSemId;
      }).toList();

      final isClosed = isYear1 ? (sYear == 1 && sSemId == 2) : (sYear == 2 && sSemId == 2);
      final isPastCompleted = !isYear1 && (sYear == 1);
      final isCurrentActive = isYear1 ? (sYear == 1 && sSemId == 1) : (sYear == 2 && sSemId == 1);

      if (coursesInSem.isNotEmpty) {
        double sHours = 0;
        double sPoints = 0;

        final mappedCourses = coursesInSem.map((c) {
          final w = (c['weight'] is num) ? (c['weight'] as num).toDouble() : (double.tryParse(c['weight']?.toString() ?? '1') ?? 1.0);
          final safeW = w > 0 ? w : 1.0;
          totalCoursesCount++;
          sHours += safeW;

          if (isCurrentActive) {
            final rawScore = (c['score'] is num) ? (c['score'] as num).toDouble() : (double.tryParse(c['score']?.toString() ?? '0') ?? 0.0);
            final pct = rawScore.clamp(0.0, 100.0);
            final pts = double.parse((pct * safeW).toStringAsFixed(2));
            final isPass = pct >= 50;
            sPoints += pts;

            if (!isPass) {
              failedTitles.add(c['title']?.toString() ?? 'مادة');
            }

            return {
              'course_id': c['course_id'],
              'title': c['title'] ?? '-',
              'year': c['year'],
              'semester_id': c['semester_id'],
              'isClosed': false,
              'isPastCompleted': false,
              'isCurrentActive': true,
              'quiz_score': c['quiz_score'] ?? 0,
              'oral_score': c['oral_score'] ?? 0,
              'exam_score': c['exam_score'] ?? 0,
              'score': rawScore,
              'percentage': pct,
              'weight': safeW,
              'points': pts,
              'status': isPass ? 'ناجح' : 'راسب',
              'isPass': isPass,
            };
          } else if (isPastCompleted) {
            return {
              'course_id': c['course_id'],
              'title': c['title'] ?? '-',
              'year': c['year'],
              'semester_id': c['semester_id'],
              'isClosed': false,
              'isPastCompleted': true,
              'isCurrentActive': false,
              'quiz_score': '-',
              'oral_score': '-',
              'exam_score': '-',
              'score': '-',
              'percentage': '-',
              'weight': safeW,
              'points': 0.0,
              'status': 'مجتاز (السنة السابقة)',
              'isPass': true,
            };
          } else {
            final closedText = isYear1 ? 'مغلق المقرر لحين انتهاء الفصل الأول' : 'مغلق المقرر (الفصل الأخير)';
            return {
              'course_id': c['course_id'],
              'title': c['title'] ?? '-',
              'year': c['year'],
              'semester_id': c['semester_id'],
              'isClosed': true,
              'isPastCompleted': false,
              'isCurrentActive': false,
              'quiz_score': '-',
              'oral_score': '-',
              'exam_score': '-',
              'score': '-',
              'percentage': '-',
              'weight': safeW,
              'points': 0.0,
              'status': closedText,
              'isPass': null,
            };
          }
        }).toList();

        sPoints = double.parse(sPoints.toStringAsFixed(2));
        double? semGpa;
        bool isSemPassed = false;

        if (isCurrentActive) {
          semGpa = sHours > 0 ? double.parse((sPoints / sHours).toStringAsFixed(2)) : 0.0;
          allSemGpas.add(semGpa);
          isSemPassed = semGpa >= 50;
          if (isSemPassed) {
            passedSemGpas.add({
              'title': semDef['title'],
              'gpa': semGpa,
              'hours': sHours,
            });
          }
          cumHours += sHours;
          cumPoints += sPoints;
        } else if (isPastCompleted) {
          isSemPassed = true;
          cumHours += sHours;
        }

        semGroups.add({
          'semDef': semDef,
          'isClosed': isClosed,
          'isPastCompleted': isPastCompleted,
          'isCurrentActive': isCurrentActive,
          'courses': mappedCourses,
          'hours': sHours,
          'points': sPoints,
          'gpa': semGpa,
          'isPass': isSemPassed,
        });
      }
    }

    final visiblePassedCount = semGroups.where((g) => g['isPass'] == true).length;
    final totalInstitutionalPassed = isYear1 ? visiblePassedCount : (2 + passedSemGpas.length);
    final sumPassedGpas = passedSemGpas.fold<double>(0.0, (acc, cur) => acc + (cur['gpa'] as double));

    final summary = s['summary'] as Map<String, dynamic>? ?? {};
    double cumGpa = 0.0;
    if (summary['weighted_gpa'] is num) {
      cumGpa = (summary['weighted_gpa'] as num).toDouble();
    } else if (totalInstitutionalPassed > 0) {
      cumGpa = double.parse((sumPassedGpas / totalInstitutionalPassed).toStringAsFixed(2));
    }

    return {
      'semGroups': semGroups,
      'totalCoursesCount': totalCoursesCount,
      'cumHours': cumHours,
      'cumPoints': cumPoints,
      'allSemGpas': allSemGpas,
      'passedSemGpas': passedSemGpas,
      'passedSemestersCount': totalInstitutionalPassed,
      'cumGpa': cumGpa,
      'failedTitles': failedTitles,
    };
  }

  // تطبيق الفلاتر الخمسة المترابطة
  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allStudents.where((st) {
      // 1. فلتر القسم
      if (_selectedDepartmentId != 'all') {
        if (st['department_id']?.toString() != _selectedDepartmentId.toString()) return false;
      }

      // 2. فلتر البرنامج / التخصص
      if (_selectedProgramId != 'all') {
        if (st['program_id']?.toString() != _selectedProgramId.toString()) return false;
      }

      // 3. فلتر السنة الأكاديمية
      final lvl = st['level']?.toString() ?? '';
      final isYear1 = lvl.contains('الأولى') || lvl == '1' || lvl.toLowerCase().contains('first');
      final isYear2 = lvl.contains('الثانية') || lvl.contains('خريج') || lvl.contains('تكميل') || lvl == '2';

      if (_selectedYear == '1' && !isYear1) return false;
      if (_selectedYear == '2' && !isYear2) return false;

      // 4. فلتر الحالة الأكاديمية (مطابق 100% لخوارزمية الويب)
      if (_selectedStanding != 'all') {
        final summary = st['summary'] as Map<String, dynamic>? ?? {};
        final sStanding = summary['standing']?.toString().toLowerCase() ?? 'passed';
        final failedCount = (summary['failed_count'] is num) ? (summary['failed_count'] as num).toInt() : 0;
        final failedCourses = summary['failed_courses'] as List<dynamic>? ?? [];
        final hasFailed = failedCount > 0 || failedCourses.isNotEmpty;

        if (_selectedStanding == 'passed') {
          if (hasFailed || (sStanding != 'passed' && sStanding != 'graduated')) return false;
        } else if (_selectedStanding == 'failed') {
          if (!hasFailed && sStanding != 'failed' && sStanding != 'supplementary') return false;
        } else if (_selectedStanding == 'supplementary') {
          if (sStanding != 'supplementary' && !(!isYear1 && hasFailed)) return false;
        }
      }

      // 5. البحث بالاسم أو برقم القيد
      if (query.isNotEmpty) {
        final name = (st['full_name'] ?? '').toString().toLowerCase();
        final code = (st['student_code'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !code.contains(query)) return false;
      }

      return true;
    }).toList();

    // فرز المقررات للمنظور الثاني
    final filteredCourses = _allCourses.where((c) {
      if (_selectedProgramId != 'all' && c['program_id'] != null) {
        if (c['program_id']?.toString() != _selectedProgramId.toString()) return false;
      }
      if (_selectedYear != 'both') {
        if (c['year']?.toString() != _selectedYear.toString()) return false;
      }
      if (_selectedSemester != 'both') {
        if (c['semester_id']?.toString() != _selectedSemester.toString()) return false;
      }
      return true;
    }).toList();

    setState(() {
      _filteredStudents = filtered;
      _filteredCourses = filteredCourses;

      if (_filteredStudents.isNotEmpty) {
        final exists = _filteredStudents.any((s) => s['student_id'] == _selectedStudent?['student_id']);
        if (!exists) {
          _selectedStudent = _filteredStudents.first;
        }
      } else {
        _selectedStudent = null;
      }

      if (_filteredCourses.isNotEmpty) {
        final exists = _filteredCourses.any((c) => c['course_id'] == _selectedCourse?['course_id']);
        if (!exists) {
          _selectedCourse = _filteredCourses.first;
        }
      } else {
        _selectedCourse = null;
      }
    });
  }

  // احتساب مؤشرات الدفعة KPIs الحقيقية المطابقة للويب
  Map<String, dynamic> _calculateKpis() {
    final total = _filteredStudents.length;
    if (total == 0) {
      return {'count': 0, 'pass_rate': 0.0, 'max_gpa': 0.0, 'min_gpa': 0.0};
    }

    int passedCount = 0;
    double maxGpa = 0.0;
    double minGpa = 100.0;
    bool hasValidGpa = false;

    for (var s in _filteredStudents) {
      final summary = s['summary'] as Map<String, dynamic>? ?? {};
      final failedCount = (summary['failed_count'] is num) ? (summary['failed_count'] as num).toInt() : 0;
      final failedCourses = summary['failed_courses'] as List<dynamic>? ?? [];
      final isPass = (failedCount == 0 && failedCourses.isEmpty);
      if (isPass) passedCount++;

      final sCalc = _calculateStudentData(s, _selectedYear, _selectedSemester);
      final gpa = (sCalc['cumGpa'] as double?) ?? 0.0;
      if (gpa > 0) {
        if (gpa > maxGpa) maxGpa = gpa;
        if (gpa < minGpa) minGpa = gpa;
        hasValidGpa = true;
      }
    }

    final passRate = (passedCount / total) * 100;
    return {
      'count': total,
      'pass_rate': passRate,
      'max_gpa': maxGpa,
      'min_gpa': hasValidGpa ? minGpa : 0.0,
    };
  }

  // ─────────────────────────── معاينة وتصدير التقارير داخل التطبيق ───────────────────────────
  Future<void> _openCohortReport() async {
    _showLoadingDialog('جاري تجهيز محضر نتائج الدفعة الرسمي (PDF)...');

    final pdfBytes = await _affairsServices.fetchCohortPdfBytes(
      departmentId: _selectedDepartmentId,
      programId: _selectedProgramId,
      year: _selectedYear,
      semesterId: _selectedSemester,
      standing: _selectedStanding,
    );

    if (mounted) Navigator.pop(context); // إغلاق مؤشر التحميل

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AffairsPdfViewerScreen(
            title: 'محضر نتائج الدفعة الرسمي',
            pdfBytes: pdfBytes,
            fileName: 'cohort_results_${_selectedProgramId}_$_selectedYear.pdf',
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل محضر الدفعة. يرجى التحقق من اتصال الخادم.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openStudentTranscript() async {
    if (_selectedStudent == null) return;
    final studentId = _selectedStudent!['student_id'] as int;
    final studentName = _selectedStudent!['full_name'] ?? 'طالب';
    final studentCode = _selectedStudent!['student_code'] ?? '$studentId';

    _showLoadingDialog('جاري تجهيز كشف علامات الطالب ($studentName)...');

    final pdfBytes = await _affairsServices.fetchStudentTranscriptPdfBytes(studentId);

    if (mounted) Navigator.pop(context); // إغلاق مؤشر التحميل

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AffairsPdfViewerScreen(
            title: 'كشف علامات الطالب: $studentName',
            pdfBytes: pdfBytes,
            fileName: 'transcript_${studentCode}_$studentId.pdf',
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل كشف العلامات. يرجى التحقق من اتصال الخادم.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFFFFCC00)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // اعتماد القرار الأكاديمي
  Future<void> _showDecisionDialog(Map<String, dynamic> student) async {
    final sId = student['student_id'];
    String selectedDecision = 'promote_semester_2';
    final notesController = TextEditingController();

    final level = student['level']?.toString() ?? '';
    final isYear1 = level.contains('الأولى');
    final courses = (student['courses'] as List<dynamic>?) ?? [];
    final hasY1Sem2 = courses.any((c) => (c['year'] == 1 || c['year'] == null) && c['semester_id'] == 2 && c['is_closed'] != true && c['score'] != null);
    final hasY2Sem2 = courses.any((c) => c['year'] == 2 && c['semester_id'] == 2 && c['is_closed'] != true && c['score'] != null);

    if (isYear1) {
      selectedDecision = hasY1Sem2 ? 'promote_year_2' : 'promote_semester_2';
    } else {
      selectedDecision = hasY2Sem2 ? 'graduate' : 'promote_semester_4';
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: Color(0xFFFFCC00)),
              SizedBox(width: 8),
              Text('اعتماد القرار الأكاديمي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الطالب: ${student['full_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('رقم القيد: ${student['student_code'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 24),
                const Text('اختر القرار الإداري:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedDecision,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'promote_semester_2', child: Text('ترفيع إلى الفصل الثاني')),
                    DropdownMenuItem(value: 'promote_year_2', child: Text('ترفيع إلى السنة الثانية')),
                    DropdownMenuItem(value: 'promote_semester_4', child: Text('ترفيع إلى الفصل الرابع (تخرج)')),
                    DropdownMenuItem(value: 'graduate', child: Text('اعتماد التخرج النهائي 🎓')),
                    DropdownMenuItem(value: 'supplementary', child: Text('منقول بمواد / دورة تكميلية')),
                    DropdownMenuItem(value: 'repeat_year', child: Text('رسوب وإعادة السنة')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedDecision = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('ملاحظات إدارية (اختياري):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'أدخل أي ملاحظة تود توثيقها مع القرار...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                _showLoadingDialog('جاري حفظ القرار وتحديث سجل الطالب...');
                final res = await _affairsServices.updateStudentAcademicDecision(
                  studentId: sId,
                  decision: selectedDecision,
                  notes: notesController.text.trim(),
                );
                if (mounted) Navigator.pop(context);

                if (res != null && res['success'] == true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? 'تم حفظ القرار بنجاح'), backgroundColor: Colors.green),
                    );
                  }
                  _fetchMasterData();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل حفظ القرار الأكاديمي'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('تأكيد وحفظ القرار', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── واجهة المستخدم الرئيسية ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('المسار الأكاديمي الطلابي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          centerTitle: true,
          backgroundColor: cardColor,
          elevation: 1,
          actions: [
            // محضر الدفعة PDF
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openCohortReport,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.orange, size: 18),
                label: const Text(
                  'محضر الدفعة (PDF)',
                  style: TextStyle(color: Color(0xFFFFCC00), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
            : RefreshIndicator(
                color: const Color(0xFFFFCC00),
                onRefresh: _fetchMasterData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. مفتاح التبديل بين المنظورين
                      _buildViewSwitcher(cardColor, borderColor),
                      const SizedBox(height: 12),

                      // 2. كرت محددات الفرز الأكاديمي الخمسة
                      _buildFiltersCard(cardColor, borderColor),
                      const SizedBox(height: 12),

                      if (_currentViewMode == 'student') ...[
                        // 3. كرت مؤشرات الدفعة KPIs الأربعة المضغوطة بدون Overflow
                        _buildKpiRow(cardColor, borderColor),
                        const SizedBox(height: 12),

                        // 4. شريط البحث السريع عن طالب
                        _buildSearchBar(cardColor, borderColor),
                        const SizedBox(height: 12),

                        // 5. محطة اختيار الطلاب السريعة (Horizontal Chips)
                        _buildStudentSelectorHorizontal(cardColor, borderColor),
                        const SizedBox(height: 12),

                        // 6. ملف الطالب وسجل المقررات مقسمة بالفصول الدراسية
                        if (_selectedStudent != null)
                          _buildStudentWorkstationSection(cardColor, borderColor)
                        else
                          _buildEmptyDossierCard(cardColor, borderColor),
                      ] else ...[
                        // المنظور الثاني: منظور المواد والأوزان
                        _buildCourseViewSection(cardColor, borderColor),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 1. مفتاح المنظورين
  Widget _buildViewSwitcher(Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentViewMode = 'student'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentViewMode == 'student' ? const Color(0xFFFFCC00) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: _currentViewMode == 'student' ? Colors.black : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'منظور الطلاب (Workstation)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentViewMode == 'student' ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentViewMode = 'course'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentViewMode == 'course' ? const Color(0xFFFFCC00) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: _currentViewMode == 'course' ? Colors.black : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'منظور المواد (Courses)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentViewMode == 'course' ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. كرت محددات الفرز الأكاديمي
  Widget _buildFiltersCard(Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFFFFCC00), size: 18),
              SizedBox(width: 8),
              Text(
                'محددات الفرز الأكاديمي المعتمد',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // السطر 1: القسم والبرنامج
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'القسم الأكاديمي',
                  value: _selectedDepartmentId,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('جميع الأقسام')),
                    ..._departments.map((d) => DropdownMenuItem(
                          value: d['department_id'].toString(),
                          child: Text(d['name'] ?? '', overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedDepartmentId = val!;
                      _selectedProgramId = 'all';
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  label: 'التخصص / البرنامج',
                  value: _selectedProgramId,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('جميع التخصصات')),
                    ..._programs
                        .where((p) => _selectedDepartmentId == 'all' || p['department_id']?.toString() == _selectedDepartmentId)
                        .map((p) => DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text(p['name'] ?? '', overflow: TextOverflow.ellipsis),
                            )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedProgramId = val!);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // السطر 2: السنة، الفصل، والحالة
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'السنة الدراسية',
                  value: _selectedYear,
                  items: const [
                    DropdownMenuItem(value: 'both', child: Text('كلاهما')),
                    DropdownMenuItem(value: '1', child: Text('الأولى')),
                    DropdownMenuItem(value: '2', child: Text('الثانية')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedYear = val!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDropdown(
                  label: 'الفصل الدراسي',
                  value: _selectedSemester,
                  items: const [
                    DropdownMenuItem(value: 'both', child: Text('كلاهما')),
                    DropdownMenuItem(value: '1', child: Text('الأول')),
                    DropdownMenuItem(value: '2', child: Text('الثاني')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedSemester = val!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildDropdown(
                  label: 'الحالة المفروزة',
                  value: _selectedStanding,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: 'passed', child: Text('ناجحون ✅')),
                    DropdownMenuItem(value: 'failed', child: Text('راسبون ❌')),
                    DropdownMenuItem(value: 'supplementary', child: Text('تكميلي 📝')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedStanding = val!);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // 3. كرت مؤشرات الدفعة KPIs بدقة ومطابقة 100% وبدون Overflow
  Widget _buildKpiRow(Color cardColor, Color borderColor) {
    final kpis = _calculateKpis();
    final count = kpis['count'] as int;
    final passRate = (kpis['pass_rate'] as double).toStringAsFixed(1);
    final maxGpa = (kpis['max_gpa'] as double).toStringAsFixed(1);
    final minGpa = (kpis['min_gpa'] as double).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            title: 'إجمالي الطلاب',
            value: '$count',
            sub: 'مفروزون',
            color: Colors.blue,
            tag: 'COUNT',
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildKpiCard(
            title: 'نسبة النجاح',
            value: '$passRate%',
            sub: 'مستوفين',
            color: Colors.green,
            tag: 'RATE',
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildKpiCard(
            title: 'أعلى معدل',
            value: '$maxGpa%',
            sub: 'شرف',
            color: Colors.amber,
            tag: 'MAX',
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildKpiCard(
            title: 'أدنى معدل',
            value: '$minGpa%',
            sub: 'الحد الأدنى',
            color: Colors.redAccent,
            tag: 'MIN',
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required String tag,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tag,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color),
              ),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 4. شريط البحث السريع
  Widget _buildSearchBar(Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        decoration: InputDecoration(
          hintText: 'ابحث عن طالب بالاسم الكامل أو رقم القيد الجامعي...',
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFFCC00), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  // 5. محطة اختيار الطلاب السريعة
  Widget _buildStudentSelectorHorizontal(Color cardColor, Color borderColor) {
    if (_filteredStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: const Text('لا يوجد طلاب مطابقون لمعايير الفلترة الحالية', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الطلاب المفرزون (${_filteredStudents.length} طالباً)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (_selectedStudent != null)
              Text(
                'المختار: ${_selectedStudent!['full_name']}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFFFCC00), fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _filteredStudents.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final st = _filteredStudents[idx];
              final isSelected = st['student_id'] == _selectedStudent?['student_id'];
              final summary = st['summary'] as Map<String, dynamic>? ?? {};
              final failedCount = (summary['failed_count'] is num) ? (summary['failed_count'] as num).toInt() : 0;
              final isPassed = failedCount == 0;

              final sCalc = _calculateStudentData(st, _selectedYear, _selectedSemester);
              final displayGpa = (sCalc['cumGpa'] as double?) ?? 0.0;

              return InkWell(
                onTap: () => setState(() => _selectedStudent = st),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFCC00).withValues(alpha: 0.15) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFFCC00) : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: isPassed ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              st['full_name'] ?? '-',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFFFCC00) : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'قيد: ${st['student_code'] ?? '-'}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                          Text(
                            '${displayGpa.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: isPassed ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 6. ملف الطالب وسجل المقررات مفصولة بالفصول الدراسية (الـ Core المطابق للويب)
  Widget _buildStudentWorkstationSection(Color cardColor, Color borderColor) {
    final s = _selectedStudent!;
    final sCalc = _calculateStudentData(s, _selectedYear, _selectedSemester);
    final semGroups = (sCalc['semGroups'] as List<Map<String, dynamic>>?) ?? [];
    final cumGpa = (sCalc['cumGpa'] as double?) ?? 0.0;
    final cumHours = (sCalc['cumHours'] as double?) ?? 0.0;
    final totalCoursesCount = (sCalc['totalCoursesCount'] as int?) ?? 0;
    final failedTitles = (sCalc['failedTitles'] as List<String>?) ?? [];
    final passedSemCount = (sCalc['passedSemestersCount'] as int?) ?? 0;

    final summary = s['summary'] as Map<String, dynamic>? ?? {};
    final standing = summary['standing']?.toString() ?? 'passed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // أ. كرت هوية الطالب وبياناته المؤسساتية
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFFCC00),
                    child: Text(
                      (s['full_name'] ?? 'ط').toString().substring(0, 1),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['full_name'] ?? '-',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'رقم القيد: ${s['student_code'] ?? '-'} • التخصص: ${s['program_name'] ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          'المستوى: ${s['level'] ?? '-'} • المرشد: ${s['advisor_name'] ?? '-'}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildStandingBadge(standing, failedTitles.isNotEmpty),
                ],
              ),
              const Divider(height: 20),

              // أزرار الإجراءات الرسمية للطالب
              Row(
                children: [
                  // زر كشف العلامات PDF في عارض داخلي
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: _openStudentTranscript,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('كشف العلامات (PDF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // زر اعتماد القرار الأكاديمي
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showDecisionDialog(s),
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text('اعتماد القرار', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ب. عنوان سجل المقررات مقسمة بالفصول الدراسية
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.layers_rounded, color: Color(0xFFFFCC00), size: 18),
                SizedBox(width: 6),
                Text(
                  'سجل المقررات مفصولة بالفصول الدراسية',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${semGroups.length} فصول معروضة',
                style: const TextStyle(fontSize: 10, color: Color(0xFFFFCC00), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ج. كروت الفصول الدراسية المنفصلة (مقررات كل فصل + معدله المستقل)
        if (semGroups.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: const Text('لا توجد مقررات مطابقة لمعايير الفلترة المحددة لهذا الطالب', style: TextStyle(fontSize: 12, color: Colors.grey)),
          )
        else
          ...semGroups.map((group) => _buildSemesterCard(group, cardColor, borderColor)),

        const SizedBox(height: 12),

        // د. بطاقة ملخص المعدل التراكمي العام (Cumulative Summary Card)
        _buildCumulativeSummaryCard(
          cumGpa: cumGpa,
          cumHours: cumHours,
          totalCourses: totalCoursesCount,
          passedSemesters: passedSemCount,
          failedTitles: failedTitles,
          cardColor: cardColor,
          borderColor: borderColor,
        ),
      ],
    );
  }

  // كرت فصل دراسي مستقل بجدوله ومعدله
  Widget _buildSemesterCard(Map<String, dynamic> group, Color cardColor, Color borderColor) {
    final semDef = group['semDef'] as Map<String, dynamic>;
    final isClosed = group['isClosed'] as bool;
    final isPast = group['isPastCompleted'] as bool;
    final isCurrent = group['isCurrentActive'] as bool;
    final courses = (group['courses'] as List<dynamic>?) ?? [];
    final hours = group['hours'];
    final gpa = group['gpa'] as double?;

    Color badgeColor = Colors.grey;
    String badgeText = 'مغلق';
    if (isClosed) {
      badgeColor = Colors.orange;
      badgeText = 'مغلق المقرر';
    } else if (isCurrent) {
      badgeColor = Colors.green;
      badgeText = 'الفصل الساري حالياً';
    } else if (isPast) {
      badgeColor = Colors.blue;
      badgeText = 'مجتاز (السنة السابقة)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الفصل
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white.withValues(alpha: 0.03),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                  child: Text(
                    '${semDef['num']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFFFCC00)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            semDef['title'] ?? '-',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${semDef['yearLabel']} • الساعات: $hours • المقررات: ${courses.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isCurrent && gpa != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'معدل الفصل: ${gpa.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFCC00),
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                else if (isPast)
                  const Text('مجتاز بنجاح', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ],
            ),
          ),
          const Divider(height: 1),

          // جدول مقررات الفصل
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              horizontalMargin: 10,
              headingRowHeight: 32,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 40,
              headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              dataTextStyle: const TextStyle(fontSize: 11),
              columns: const [
                DataColumn(label: Text('المقرر')),
                DataColumn(label: Text('وزن')),
                DataColumn(label: Text('مذاكرة')),
                DataColumn(label: Text('شفهي')),
                DataColumn(label: Text('امتحان')),
                DataColumn(label: Text('المجموع')),
                DataColumn(label: Text('الحالة')),
              ],
              rows: courses.map((c) {
                final isPass = c['isPass'] == true;
                final isClosedCourse = c['isClosed'] == true;
                final isPastCourse = c['isPastCompleted'] == true;

                Widget statusWidget;
                if (isClosedCourse) {
                  statusWidget = const Text('مغلق', style: TextStyle(fontSize: 10, color: Colors.orange));
                } else if (isPastCourse) {
                  statusWidget = const Text('مجتاز', style: TextStyle(fontSize: 10, color: Colors.blueAccent));
                } else {
                  statusWidget = Text(
                    isPass ? 'ناجح' : 'راسب',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPass ? Colors.green : Colors.red,
                    ),
                  );
                }

                return DataRow(cells: [
                  DataCell(Text(c['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${c['weight'] ?? 1}')),
                  DataCell(Text('${c['quiz_score'] ?? '-'}')),
                  DataCell(Text('${c['oral_score'] ?? '-'}')),
                  DataCell(Text('${c['exam_score'] ?? '-'}')),
                  DataCell(Text(
                    isClosedCourse || isPastCourse ? '-' : '${c['score'] ?? 0} / 100',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  )),
                  DataCell(statusWidget),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة ملخص المعدل التراكمي العام
  Widget _buildCumulativeSummaryCard({
    required double cumGpa,
    required double cumHours,
    required int totalCourses,
    required int passedSemesters,
    required List<String> failedTitles,
    required Color cardColor,
    required Color borderColor,
  }) {
    final isAllPassed = failedTitles.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC00).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_rounded, color: Color(0xFFFFCC00), size: 20),
                  SizedBox(width: 8),
                  Text('المعدل التراكمي العام المعتمد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
              Text(
                '${cumGpa.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFCC00),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('الفصول المجتازة', '$passedSemesters'),
              _buildMiniMetric('إجمالي الساعات', '${cumHours.toInt()}'),
              _buildMiniMetric('إجمالي المقررات', '$totalCourses'),
              _buildMiniMetric('الحالة الأكاديمية', isAllPassed ? 'مستوفٍ لشروط النجاح' : 'راسب بمواد', isGreen: isAllPassed),
            ],
          ),
          if (failedTitles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'المقررات غير المجتازة: ${failedTitles.join(' • ')}',
                      style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, {bool isGreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isGreen ? Colors.greenAccent : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDossierCard(Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text('لا يوجد طالب محدد حالياً', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Text('اختر طالباً من القائمة بالأعلى لعرض سجله وتفاصيل مقرراته', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStandingBadge(String standing, bool hasFailed) {
    Color color = Colors.green;
    String text = 'ناجح ✅';

    if (standing == 'graduated') {
      color = Colors.blue;
      text = 'خريج معتمد 🎓';
    } else if (standing == 'supplementary' || (standing != 'failed' && hasFailed)) {
      color = Colors.amber;
      text = 'دورة تكميلية 📝';
    } else if (standing == 'failed' || hasFailed) {
      color = Colors.red;
      text = 'راسب ⚠️';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ─────────────────────────── المنظور الثاني: منظور المواد والأوزان ───────────────────────────
  Widget _buildCourseViewSection(Color cardColor, Color borderColor) {
    if (_filteredCourses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: const Text('لا توجد مواد مطابقة لمعايير الفلترة الحالية', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    final c = _selectedCourse ?? _filteredCourses.first;
    final enrolled = _courseStudents.where((cs) => cs['course_id'] == c['course_id']).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // قائمة المواد الأفقية
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _filteredCourses.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final crs = _filteredCourses[idx];
              final isSel = crs['course_id'] == c['course_id'];
              return InkWell(
                onTap: () => setState(() => _selectedCourse = crs),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFFCC00).withValues(alpha: 0.15) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? const Color(0xFFFFCC00) : borderColor, width: isSel ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crs['title'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFFFFCC00) : null)),
                      Text('سنة ${crs['year']} • فصل ${crs['semester_id']} • وزن: ${crs['weight']}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // بطاقة تفاصيل المادة وقائمة الطلاب المسجلين
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      Text('وزن الساعات: ${c['weight']} • سنة ${c['year']} • فصل ${c['semester_id']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${enrolled.length} طلاب مسجلون', style: const TextStyle(fontSize: 11, color: Color(0xFFFFCC00), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 20),

              // فلتر نجاح/رسوب بالمادة
              Row(
                children: [
                  _buildSubFilterChip('all', 'الكل (${enrolled.length})'),
                  const SizedBox(width: 8),
                  _buildSubFilterChip('pass', 'الناجحون'),
                  const SizedBox(width: 8),
                  _buildSubFilterChip('fail', 'الراسبون'),
                ],
              ),
              const SizedBox(height: 10),

              // جدول الطلاب بالدرجات
              if (enrolled.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا يوجد طلاب مسجلون بهذه المادة', style: TextStyle(color: Colors.grey))))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    columns: const [
                      DataColumn(label: Text('رقم القيد')),
                      DataColumn(label: Text('اسم الطالب')),
                      DataColumn(label: Text('المذاكرة')),
                      DataColumn(label: Text('الشفهي')),
                      DataColumn(label: Text('الامتحان')),
                      DataColumn(label: Text('المجموع')),
                      DataColumn(label: Text('الحالة')),
                    ],
                    rows: enrolled.where((st) {
                      final score = (st['exam_score'] is num) ? (st['exam_score'] as num).toDouble() : 0.0;
                      if (_courseSubFilter == 'pass') return score >= 50;
                      if (_courseSubFilter == 'fail') return score < 50;
                      return true;
                    }).map((st) {
                      final score = (st['exam_score'] is num) ? (st['exam_score'] as num).toDouble() : 0.0;
                      final isPass = score >= 50;
                      return DataRow(cells: [
                        DataCell(Text(st['student_code'] ?? '-', style: const TextStyle(fontFamily: 'monospace'))),
                        DataCell(Text(st['student_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text('${st['quiz_score'] ?? 0}')),
                        DataCell(Text('${st['oral_score'] ?? 0}')),
                        DataCell(Text('${st['final_exam_score'] ?? 0}')),
                        DataCell(Text('$score / 100', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                        DataCell(Text(
                          isPass ? 'ناجح' : 'راسب',
                          style: TextStyle(color: isPass ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubFilterChip(String val, String label) {
    final isSel = _courseSubFilter == val;
    return InkWell(
      onTap: () => setState(() => _courseSubFilter = val),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFFCC00) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSel ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
