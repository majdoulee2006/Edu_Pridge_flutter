import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class StudentAcademicCardScreen extends StatefulWidget {
  final String? universityId;

  const StudentAcademicCardScreen({
    super.key,
    this.universityId,
  });

  @override
  State<StudentAcademicCardScreen> createState() => _StudentAcademicCardScreenState();
}

class _StudentAcademicCardScreenState extends State<StudentAcademicCardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _cardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _fetchCardData();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchCardData() async {
    final isAr = AppSettings.language.value == 'ar';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await StudentServices().getAcademicCard(widget.universityId ?? '');
      if (mounted) {
        if (res != null && res['success'] == true) {
          setState(() {
            _cardData = res;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res?['message'] ?? (isAr ? "تعذر جلب كشف علامات الطالب بالرقم الجامعي أدناه." : "Could not retrieve student transcript.");
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = isAr ? "حدث خطأ أثناء تحميل البيانات، يرجى إعادة المحاولة." : "An error occurred while loading data, please try again.";
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            isAr ? "بطاقة كشف العلامات والأداء الأكاديمي" : "Academic Report & Performance Card",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Tajawal'),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: cardBg,
          foregroundColor: textColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: isAr ? "تحديث" : "Refresh",
              onPressed: _fetchCardData,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.accent),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? "جاري تحضير بطاقة الطالب وكشف العلامات..." : "Preparing student card and transcript...",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? _buildErrorView(textColor, isAr)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // 1. Header Student Card (بطاقة التعريف الأكاديمية)
                        _buildStudentCardHeader(cardBg, textColor, subColor, isDark, isAr),

                        const SizedBox(height: 20),

                        // 2. Grades Breakdown Table / Cards (جدول المقررات والعلامات)
                        _buildCoursesGradesSection(cardBg, textColor, subColor, isDark, isAr),

                        const SizedBox(height: 20),

                        // 3. Summary & Performance (المعدل التراكمي والحضور والغياب)
                        _buildSummarySection(cardBg, textColor, isDark, isAr),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorView(Color textColor, bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 70, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCardData,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? "إعادة المحاولة" : "Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ─── 1. Student Card Header ────────────────────────────────────────────────
  Widget _buildStudentCardHeader(Color cardBg, Color textColor, Color subColor, bool isDark, bool isAr) {
    final info = _cardData?['student_info'] ?? {};
    final studentName = info['student_name'] ?? (isAr ? 'طالب غير معرف' : 'Unidentified Student');
    final universityId = info['university_id'] ?? widget.universityId ?? '';
    final level = info['level'] ?? (isAr ? 'السنة الأولى' : 'First Year');
    final semester = info['semester'] ?? (isAr ? 'الفصل الأول والثاني' : 'First & Second Semester');
    final department = info['department'] ?? (isAr ? 'تكنولوجيا المعلومات' : 'Information Technology');
    final institution = info['institution'] ?? (isAr ? 'مؤسسة Edu Bridge الأكاديمية' : 'Edu Bridge Academic Institution');
    final issueDate = info['issue_date'] ?? '2026-08-05';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle pattern watermark
          Positioned(
            left: isAr ? -20 : null,
            right: isAr ? null : -20,
            top: -20,
            child: Icon(
              Icons.school_rounded,
              size: 140,
              color: AppColors.accent.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Institution Name & Seal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.school_rounded, color: AppColors.accent, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  institution,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr ? "بطاقة كشف العلامات والسجل الأكاديمي الرسمي" : "Official Academic Transcript & Record Card",
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? "وثيقة معتمدة" : "Certified",
                            style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),

                // Student Details Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar / Badge Icon
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 38, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? "الرقم الجامعي: " : "University ID: ",
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                              Text(
                                universityId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // academic attributes grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInfoItem(isAr ? "المستوى / السنة" : "Level / Year", level, Icons.military_tech_outlined, textColor, subColor)),
                          Expanded(child: _buildInfoItem(isAr ? "القسم / التخصص" : "Department / Major", department, Icons.domain_rounded, textColor, subColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInfoItem(isAr ? "الفصل الدراسي" : "Semester", semester, Icons.date_range_rounded, textColor, subColor)),
                          Expanded(child: _buildInfoItem(isAr ? "تاريخ الإصدار" : "Issue Date", issueDate, Icons.event_available_rounded, textColor, subColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color textColor, Color subColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: subColor)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. Courses Grades Breakdown Section ───────────────────────────────────
  Widget _buildCoursesGradesSection(Color cardBg, Color textColor, Color subColor, bool isDark, bool isAr) {
    final List courses = _cardData?['courses'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  isAr ? "كشف درجات المقررات الدراسية" : "Course Grades Transcript",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
            Text(
              isAr ? "${courses.length} مواد" : "${courses.length} Courses",
              style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  isAr ? "لا توجد علامات مرصودة لهذا الرقم الجامعي حتى الآن" : "No grades recorded for this university ID yet",
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final c = courses[index] as Map<String, dynamic>;
              final title = c['course_title'] ?? (isAr ? 'مادة دراسية' : 'Course');
              final quiz = c['quiz_score'];
              final oral = c['oral_score'];
              final finalExam = c['final_score'];
              final total = c['total_score'] ?? 0;
              final maxScore = c['max_score'] ?? 100;
              final weight = c['weight'] ?? 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title & Pass/Fail Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final rawStatus = (c['status'] ?? (total >= 50 ? 'ناجح' : 'راسب')).toString();
                            final isPassed = rawStatus == 'ناجح' || rawStatus.toLowerCase() == 'passed';
                            final statusStr = isAr 
                                ? (isPassed ? 'ناجح' : 'راسب')
                                : (isPassed ? 'Passed' : 'Failed');
                            final bgStatusColor = isPassed 
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12);
                            final textStatusColor = isPassed 
                                ? Colors.green.shade700
                                : Colors.red.shade700;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: bgStatusColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusStr,
                                style: TextStyle(
                                  color: textStatusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const Divider(height: 20),

                    // Marks Breakdown (المذاكرة - الشفهي - الامتحان)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMarkBox(isAr ? "المذاكرة / الأعمال" : "Coursework", quiz, textColor, subColor, isAr),
                        _buildMarkBox(isAr ? "الشفهي / العملي" : "Oral / Practical", oral, textColor, subColor, isAr),
                        _buildMarkBox(isAr ? "الامتحان النهائي" : "Final Exam", finalExam, textColor, subColor, isAr),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? "مجموع المادة النهائي:" : "Final Course Total:",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "$total / $maxScore",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Weight Row (التثقيل)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? "التثقيل:" : "Weight:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: subColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$weight",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMarkBox(String label, dynamic score, Color textColor, Color subColor, bool isAr) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: subColor),
        ),
        const SizedBox(height: 4),
        Text(
          score != null ? "$score" : (isAr ? "غير مرصود" : "Not Set"),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: score != null ? textColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  // ─── 3. Overall Summary & Attendance Section ──────────────────────────────
  Widget _buildSummarySection(Color cardBg, Color textColor, bool isDark, bool isAr) {
    final summary = _cardData?['summary'] ?? {};
    final double overallGpa = (summary['overall_gpa'] ?? 0).toDouble();
    final double attendanceRate = (summary['attendance_rate'] ?? 100).toDouble();
    final double absenceRate = (summary['absence_rate'] ?? 0).toDouble();
    final int totalSessions = summary['total_sessions'] ?? 0;
    final int presentCount = summary['present_count'] ?? 0;
    final int absentCount = summary['absent_count'] ?? 0;

    String gpaStatus = isAr ? "ممتاز" : "Excellent";
    Color gpaColor = Colors.green;
    if (overallGpa < 50) {
      gpaStatus = isAr ? "ضعيف" : "Poor";
      gpaColor = Colors.red;
    } else if (overallGpa < 65) {
      gpaStatus = isAr ? "مقبول" : "Pass";
      gpaColor = Colors.orange;
    } else if (overallGpa < 75) {
      gpaStatus = isAr ? "جيد" : "Good";
      gpaColor = Colors.blue;
    } else if (overallGpa < 85) {
      gpaStatus = isAr ? "جيد جداً" : "Very Good";
      gpaColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                isAr ? "الخلاصة الكلية ونسبة الحضور والغياب" : "Overall Summary & Attendance Rate",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall GPA Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gpaColor.withValues(alpha: 0.12), gpaColor.withValues(alpha: 0.05)],
                begin: isAr ? Alignment.centerRight : Alignment.centerLeft,
                end: isAr ? Alignment.centerLeft : Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gpaColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? "المعدل التراكمي العام:" : "Overall Cumulative GPA:",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "$overallGpa%",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: gpaColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: gpaColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gpaStatus,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(Icons.workspace_premium_rounded, size: 45, color: gpaColor),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Attendance & Absence Bars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isAr 
                            ? "نسبة الحضور: $attendanceRate% ($presentCount حصة)"
                            : "Attendance: $attendanceRate% ($presentCount sessions)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isAr 
                            ? "نسبة الغياب: $absenceRate% ($absentCount حصة)"
                            : "Absence: $absenceRate% ($absentCount sessions)",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: attendanceRate / 100.0,
                  minHeight: 10,
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr 
                    ? "إجمالي الجلسات والمحاضرات المرصودة: $totalSessions جلسات"
                    : "Total recorded sessions: $totalSessions sessions",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
