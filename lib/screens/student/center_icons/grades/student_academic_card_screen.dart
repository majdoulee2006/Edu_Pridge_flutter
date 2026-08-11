import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';

class StudentAcademicCardScreen extends StatefulWidget {
  final String universityId;

  const StudentAcademicCardScreen({
    super.key,
    required this.universityId,
  });

  @override
  State<StudentAcademicCardScreen> createState() => _StudentAcademicCardScreenState();
}

class _StudentAcademicCardScreenState extends State<StudentAcademicCardScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  Map<String, dynamic>? _cardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCardData();
  }

  Future<void> _fetchCardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await StudentServices().getAcademicCard(widget.universityId);
      if (mounted) {
        if (res != null && res['success'] == true) {
          setState(() {
            _cardData = res;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res?['message'] ?? "تعذر جلب كشف علامات الطالب بالرقم الجامعي أدناه.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "حدث خطأ أثناء تحميل البيانات، يرجى إعادة المحاولة.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    final res = await StudentServices().exportAcademicCardPdf();
    setState(() => _isExporting = false);

    if (!mounted) return;
    if (res != null && res['file_url'] != null) {
      final Uri url = Uri.parse(res['file_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء الملف: ${res['file_url']}'), backgroundColor: AppColors.accent),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تصدير ملف PDF'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F9);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "بطاقة كشف العلامات والأداء الأكاديمي",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: cardBg,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            tooltip: "تصدير PDF",
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "تحديث",
            onPressed: _fetchCardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 16),
                  Text("جاري تحضير بطاقة الطالب وكشف العلامات...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView(textColor)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // 1. Header Student Card (بطاقة التعريف الأكاديمية)
                      _buildStudentCardHeader(cardBg, textColor, subColor, isDark),

                      const SizedBox(height: 16),

                      // زر تصدير PDF
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _exportPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          icon: _isExporting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.picture_as_pdf_rounded, color: Colors.black, size: 22),
                          label: Text(
                            _isExporting ? "جاري تصدير الملف..." : "تصدير بطاقة الطالب والأداء الأكاديمي (PDF)",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Tajawal'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. Grades Breakdown Table / Cards (جدول المقررات والعلامات)
                      _buildCoursesGradesSection(cardBg, textColor, subColor, isDark),

                      const SizedBox(height: 20),

                      // 3. Summary & Performance (المعدل التراكمي والحضور والغياب)
                      _buildSummarySection(cardBg, textColor, isDark),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView(Color textColor) {
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
              label: const Text("إعادة المحاولة"),
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
  Widget _buildStudentCardHeader(Color cardBg, Color textColor, Color subColor, bool isDark) {
    final info = _cardData?['student_info'] ?? {};
    final studentName = info['student_name'] ?? 'طالب غير معرف';
    final universityId = info['university_id'] ?? widget.universityId;
    final level = info['level'] ?? 'السنة الأولى';
    final semester = info['semester'] ?? 'الفصل الأول والثاني';
    final department = info['department'] ?? 'تكنولوجيا المعلومات';
    final institution = info['institution'] ?? 'مؤسسة Edu Bridge الأكاديمية';
    final issueDate = info['issue_date'] ?? '2026-08-05';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle pattern watermark
          Positioned(
            left: -20,
            top: -20,
            child: Icon(
              Icons.school_rounded,
              size: 140,
              color: AppColors.accent.withOpacity(0.04),
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
                                  color: AppColors.accent.withOpacity(0.12),
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
                            "بطاقة كشف العلامات والسجل الأكاديمي الرسمي",
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "وثيقة معتمدة",
                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
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
                          colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
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
                              Icon(Icons.badge_outlined, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                "الرقم الجامعي: ",
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
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInfoItem("المستوى / السنة", level, Icons.military_tech_outlined, textColor, subColor)),
                          Expanded(child: _buildInfoItem("القسم / التخصص", department, Icons.domain_rounded, textColor, subColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInfoItem("الفصل الدراسي", semester, Icons.date_range_rounded, textColor, subColor)),
                          Expanded(child: _buildInfoItem("تاريخ الإصدار", issueDate, Icons.event_available_rounded, textColor, subColor)),
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
  Widget _buildCoursesGradesSection(Color cardBg, Color textColor, Color subColor, bool isDark) {
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
                  "كشف درجات المقررات الدراسية",
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
              "${courses.length} مواد",
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
                  "لا توجد علامات مرصودة لهذا الرقم الجامعي حتى الآن",
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
              final title = c['course_title'] ?? 'مادة دراسية';
              final quiz = c['quiz_score'];
              final oral = c['oral_score'];
              final finalExam = c['final_score'];
              final total = c['total_score'] ?? 0;
              final maxScore = c['max_score'] ?? 100;
              final isPassed = (c['status'] == 'ناجح') || (total >= 50);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
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
                            final statusStr = (c['status'] ?? (total >= 50 ? 'ناجح' : 'راسب')).toString();
                            Color bgStatusColor = Colors.orange.withOpacity(0.12);
                            Color textStatusColor = Colors.orange.shade800;

                            if (statusStr == 'ناجح') {
                              bgStatusColor = Colors.green.withOpacity(0.12);
                              textStatusColor = Colors.green.shade700;
                            } else if (statusStr == 'راسب') {
                              bgStatusColor = Colors.red.withOpacity(0.12);
                              textStatusColor = Colors.red.shade700;
                            }

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
                        _buildMarkBox("المذاكرة / الأعمال", quiz, textColor, subColor),
                        _buildMarkBox("الشفهي / العملي", oral, textColor, subColor),
                        _buildMarkBox("الامتحان النهائي", finalExam, textColor, subColor),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "مجموع المادة النهائي:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMarkBox(String label, dynamic score, Color textColor, Color subColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: subColor),
        ),
        const SizedBox(height: 4),
        Text(
          score != null ? "$score" : "غير مرصود",
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
  Widget _buildSummarySection(Color cardBg, Color textColor, bool isDark) {
    final summary = _cardData?['summary'] ?? {};
    final double overallGpa = (summary['overall_gpa'] ?? 0).toDouble();
    final double attendanceRate = (summary['attendance_rate'] ?? 100).toDouble();
    final double absenceRate = (summary['absence_rate'] ?? 0).toDouble();
    final int totalSessions = summary['total_sessions'] ?? 0;
    final int presentCount = summary['present_count'] ?? 0;
    final int absentCount = summary['absent_count'] ?? 0;

    String gpaStatus = "ممتاز";
    Color gpaColor = Colors.green;
    if (overallGpa < 50) {
      gpaStatus = "ضعيف";
      gpaColor = Colors.red;
    } else if (overallGpa < 65) {
      gpaStatus = "مقبول";
      gpaColor = Colors.orange;
    } else if (overallGpa < 75) {
      gpaStatus = "جيد";
      gpaColor = Colors.blue;
    } else if (overallGpa < 85) {
      gpaStatus = "جيد جداً";
      gpaColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text(
                "الخلاصة الكلية ونسبة الحضور والغياب",
                style: TextStyle(
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
                colors: [gpaColor.withOpacity(0.12), gpaColor.withOpacity(0.05)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gpaColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "المعدل التراكمي العام:",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
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
                      Text("نسبة الحضور: $attendanceRate% ($presentCount حصة)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text("نسبة الغياب: $absenceRate% ($absentCount حصة)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                  backgroundColor: Colors.red.withOpacity(0.2),
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "إجمالي الجلسات والمحاضرات المرصودة: $totalSessions جلسات",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
