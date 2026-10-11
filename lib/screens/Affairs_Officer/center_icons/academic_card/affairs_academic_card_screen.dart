import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

class AffairsAcademicCardScreen extends StatefulWidget {
  const AffairsAcademicCardScreen({super.key});

  @override
  State<AffairsAcademicCardScreen> createState() => _AffairsAcademicCardScreenState();
}

class _AffairsAcademicCardScreenState extends State<AffairsAcademicCardScreen> {
  final AffairsServices _affairsServices = AffairsServices();

  bool _isLoadingStudents = false;
  bool _isLoadingCard = false;
  bool _isExporting = false;


  List<dynamic> _programs = [];
  List<dynamic> _students = [];
  Map<String, dynamic>? _cardData;

  int? _selectedProgramId;
  String _selectedLevel = 'الكل';
  int? _selectedStudentId;
  String? _selectedStudentName;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _levels = [
    'الكل',
    'السنة الأولى',
    'السنة الثانية',
    'السنة الثالثة',
    'السنة الرابعة',
    'السنة الخامسة',
  ];

  bool get isAr => AppSettings.language.value == 'ar';

  String _translateLevel(String lvl, bool isAr) {
    if (isAr) return lvl;
    switch (lvl) {
      case 'الكل': return 'All';
      case 'السنة الأولى': return 'First Year';
      case 'السنة الثانية': return 'Second Year';
      case 'السنة الثالثة': return 'Third Year';
      case 'السنة الرابعة': return 'Fourth Year';
      case 'السنة الخامسة': return 'Fifth Year';
      default: return lvl;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final meta = await _affairsServices.getMetadata();
    if (mounted) {
      setState(() {
        if (meta != null && meta['programs'] != null) {
          _programs = meta['programs'];
        }
      });
      _fetchStudents();
    }
  }


  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    final list = await _affairsServices.getAcademicStudents(
      programId: _selectedProgramId,
      level: _selectedLevel == 'الكل' ? null : _selectedLevel,
      search: _searchController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _students = list ?? [];
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _fetchAcademicCard(int studentId, String name) async {
    setState(() {
      _selectedStudentId = studentId;
      _selectedStudentName = name;
      _isLoadingCard = true;
      _cardData = null;
    });

    final res = await _affairsServices.getStudentAcademicCard(studentId);

    if (mounted) {
      setState(() {
        _cardData = res;
        _isLoadingCard = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedStudentId == null) return;
    setState(() => _isExporting = true);
    final res = await _affairsServices.exportAcademicCardPdf(_selectedStudentId!);
    setState(() => _isExporting = false);

    if (res != null && res['file_url'] != null) {
      final Uri url = Uri.parse(res['file_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(isAr ? 'تم إنشاء الملف: ${res['file_url']}' : 'File generated: ${res['file_url']}');
      }
    } else {
      _showSnackBar(isAr ? 'فشل تصدير ملف PDF' : 'Failed to export PDF');
    }
  }

  Future<void> _exportExcel() async {
    if (_selectedStudentId == null) return;
    setState(() => _isExporting = true);
    final res = await _affairsServices.exportAcademicCardExcel(_selectedStudentId!);
    setState(() => _isExporting = false);

    if (res != null && res['file_url'] != null) {
      final Uri url = Uri.parse(res['file_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(isAr ? 'تم إنشاء الملف: ${res['file_url']}' : 'File generated: ${res['file_url']}');
      }
    } else {
      _showSnackBar(isAr ? 'فشل تصدير ملف Excel' : 'Failed to export Excel');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFFCC00)),
    );
  }

  void _openStudentSelectionDialog(bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black;

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAr ? 'اختيار الطالب (مرتبة أبجدياً)' : 'Select Student (Alphabetical)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // حقل البحث داخل المودال
                    TextField(
                      controller: _searchController,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      onChanged: (val) async {
                        setModalState(() {});
                        await _fetchStudents();
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: isAr ? 'ابحث باسم الطالب أو الرقم الجامعي...' : 'Search by name or university ID...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFCC00)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _isLoadingStudents
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                          : _students.isEmpty
                              ? Center(
                                  child: Text(
                                    isAr ? 'لا يوجد طلاب مطابقون للفلتر الحالية' : 'No students matching current filter',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _students.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final st = _students[index];
                                    final name = st['full_name'] ?? (isAr ? 'طالب' : 'Student');
                                    final code = st['university_id'] ?? st['student_code'] ?? '';
                                    final prog = st['program_name'] ?? '';
                                    final lvl = st['level'] ?? '';

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                                        child: Text(
                                          name.isNotEmpty ? name[0] : 'S',
                                          style: const TextStyle(
                                            color: Color(0xFFFFCC00),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$code • $prog • $lvl',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _fetchAcademicCard(st['student_id'], name);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.grey.shade400 : AppColors.textGrey;

    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, lang, _) {
        final isAr = lang == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: cardColor,
              elevation: 0,
              centerTitle: true,
              title: Text(
                isAr ? "استعلام كشف العلامات" : "Academic Card Search",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                // --- بطاقة الفلاتر العلوية ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: cardColor,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // فلتر القسم / التخصص
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'القسم / التخصص' : 'Department / Program', style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: _selectedProgramId,
                                      isExpanded: true,
                                      hint: Text(isAr ? 'الكل' : 'All', style: TextStyle(fontSize: 13, color: textColor)),
                                      items: [
                                        DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text(isAr ? 'الكل' : 'All', style: const TextStyle(fontSize: 13)),
                                        ),
                                        ..._programs.map((p) {
                                          return DropdownMenuItem<int?>(
                                            value: p['id'],
                                            child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13)),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedProgramId = val;
                                        });
                                        _fetchStudents();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // فلتر الدورة / السنة الدراسية
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? 'الدورة / السنة' : 'Level / Year', style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedLevel,
                                      isExpanded: true,
                                      items: _levels.map((lvl) {
                                        return DropdownMenuItem<String>(
                                          value: lvl,
                                          child: Text(_translateLevel(lvl, isAr), style: const TextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedLevel = val;
                                          });
                                          _fetchStudents();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // زر أواختيار الطالب المفلتر
                      GestureDetector(
                        onTap: () => _openStudentSelectionDialog(isAr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_search_rounded, color: Color(0xFFFFCC00)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedStudentName ?? (isAr ? 'اضغط لاختيار الطالب (مرتبين أبجدياً)...' : 'Tap to select student (alphabetical)...'),
                                  style: TextStyle(
                                    color: _selectedStudentName != null ? textColor : subColor,
                                    fontWeight: _selectedStudentName != null ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: subColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // --- محتوى بطاقة الطالب ---
                Expanded(
                  child: _isLoadingCard
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                      : _cardData == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge_outlined, size: 64, color: subColor.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAr ? 'يرجى اختيار طالب لعرض كشف العلامات' : 'Please select a student to view academic card',
                                    style: TextStyle(color: subColor, fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : _buildAcademicCardContent(cardColor, textColor, subColor, isDark, isAr),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicCardContent(Color cardColor, Color textColor, Color subColor, bool isDark, bool isAr) {
    final student = _cardData!['student'] ?? {};
    final summary = _cardData!['summary'] ?? {};
    final List<dynamic> cards = _cardData!['academic_card'] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // ترويسة معلومات الطالب
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                child: Text(
                  (student['full_name'] as String?)?.isNotEmpty == true ? student['full_name'][0] : 'S',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFCC00)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['full_name'] ?? '',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? 'الرقم الجامعي: ${student['university_id'] ?? ''}' : 'University ID: ${student['university_id'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                    Text(
                      '${student['department']} • ${student['level']}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // بطاقات ملخص الأداء والمعدل
        Row(
          children: [
            _buildStatBadge(isAr ? 'المعدل العام' : 'Overall GPA', '${summary['average'] ?? 0}%', Colors.orange, cardColor, textColor),
            const SizedBox(width: 8),
            _buildStatBadge(isAr ? 'المواد الناجحة' : 'Passed Courses', '${summary['passed_courses'] ?? 0}', Colors.green, cardColor, textColor),
            const SizedBox(width: 8),
            _buildStatBadge(isAr ? 'لم يتم التقدم' : 'Not Attended', '${summary['not_attended'] ?? 0}', Colors.grey, cardColor, textColor),
          ],
        ),

        const SizedBox(height: 16),

        // أزرار التصدير (PDF / Excel)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(isAr ? 'تصدير PDF' : 'Export PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportExcel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.table_chart_rounded, size: 20),
                label: Text(isAr ? 'تصدير Excel' : 'Export Excel', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // جدول المواد والعلامات
        Text(
          isAr ? 'كشف درجات المواد' : 'Course Grade Sheet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 10),

        if (cards.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(isAr ? 'لا توجد مواد مسجلة للطالب في سنته الأكاديمية الحالية' : 'No courses registered for the student in current academic year', style: TextStyle(color: subColor))),
          )
        else
          ...cards.map((c) => _buildCourseGradeCard(c, cardColor, textColor, subColor, isDark, isAr)),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value, Color color, Color cardColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600), maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGradeCard(Map<String, dynamic> c, Color cardColor, Color textColor, Color subColor, bool isDark, bool isAr) {
    final String rawStatus = c['status'] ?? 'لم يتم التقدم';
    String status = isAr ? 'لم يتم التقدم' : 'Not Attended';

    Color statusBg = Colors.grey.withValues(alpha: 0.15);
    Color statusTextColor = Colors.grey;

    if (rawStatus == 'ناجح') {
      status = isAr ? 'ناجح' : 'Passed';
      statusBg = Colors.green.withValues(alpha: 0.15);
      statusTextColor = Colors.green;
    } else if (rawStatus == 'راسب') {
      status = isAr ? 'راسب' : 'Failed';
      statusBg = Colors.red.withValues(alpha: 0.15);
      statusTextColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c['title'] ?? '',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGradeCol(isAr ? 'المذاكرة' : 'Quiz', c['quiz_score'], textColor, subColor),
              _buildGradeCol(isAr ? 'عملي / شفهي' : 'Practical/Oral', c['oral_score'], textColor, subColor),
              _buildGradeCol(isAr ? 'النهائي' : 'Final', c['final_score'], textColor, subColor),
              _buildGradeCol(isAr ? 'المجموع' : 'Total', c['total_score'], textColor, subColor, isTotal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCol(String label, dynamic val, Color textColor, Color subColor, {bool isTotal = false}) {
    final String valStr = val != null ? val.toString() : '-';

    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: subColor)),
        const SizedBox(height: 4),
        Text(
          valStr,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFFFFCC00) : textColor,
          ),
        ),
      ],
    );
  }
}
