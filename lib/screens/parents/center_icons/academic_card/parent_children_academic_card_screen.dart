import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/parent_services.dart';

class ParentChildrenAcademicCardScreen extends StatefulWidget {
  final int? initialStudentId;
  const ParentChildrenAcademicCardScreen({super.key, this.initialStudentId});

  @override
  State<ParentChildrenAcademicCardScreen> createState() => _ParentChildrenAcademicCardScreenState();
}

class _ParentChildrenAcademicCardScreenState extends State<ParentChildrenAcademicCardScreen> {
  final ParentService _parentService = ParentService();

  bool _isLoadingChildren = true;
  bool _isLoadingCard = false;

  List<dynamic> _children = [];
  Map<String, dynamic>? _selectedChild;
  Map<String, dynamic>? _cardData;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoadingChildren = true);
    final list = await _parentService.getChildren();
    if (mounted) {
      setState(() {
        _children = list;
        _isLoadingChildren = false;
      });

      if (_children.isNotEmpty) {
        // إذا كان هناك معرف مبدئي من الشاشة السابقة
        if (widget.initialStudentId != null) {
          final found = _children.firstWhere(
            (c) => (int.tryParse(c['student_id']?.toString() ?? '') == widget.initialStudentId),
            orElse: () => _children.first,
          );
          _selectChild(found);
        } else {
          _selectChild(_children.first);
        }
      }
    }
  }

  void _selectChild(Map<String, dynamic> child) {
    setState(() {
      _selectedChild = child;
    });
    final studentId = int.tryParse(child['student_id']?.toString() ?? '');
    if (studentId != null) {
      _fetchAcademicCard(studentId);
    }
  }

  Future<void> _fetchAcademicCard(int studentId) async {
    setState(() {
      _isLoadingCard = true;
      _cardData = null;
    });

    final res = await _parentService.getChildAcademicCard(studentId);

    if (mounted) {
      setState(() {
        _cardData = res;
        _isLoadingCard = false;
      });
    }
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
                isAr ? "كشف علامات الأبناء" : "Children Academic Card",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: _isLoadingChildren
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : _children.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد أبناء مرتبطون بحسابك حالياً',
                          style: TextStyle(color: subColor, fontSize: 14),
                        ),
                      )
                    : Column(
                        children: [
                          // --- منتقي الطفل (ListBox / Dropdown) ---
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: cardColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اختر أحد الأبناء:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: subColor),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<Map<String, dynamic>>(
                                      value: _selectedChild,
                                      isExpanded: true,
                                      items: _children.map((child) {
                                        final name = child['full_name'] ?? child['name'] ?? 'طالب';
                                        final level = child['level'] ?? '';
                                        final code = child['student_code'] ?? '';
                                        return DropdownMenuItem<Map<String, dynamic>>(
                                          value: child,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                                                child: Text(
                                                  name.isNotEmpty ? name[0] : 'S',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFCC00)),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  '$name ($level $code)',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          _selectChild(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // --- محتوى بطاقة علامات الطالب المحدد ---
                          Expanded(
                            child: _isLoadingCard
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                                : _cardData == null
                                    ? Center(
                                        child: Text(
                                          'تعذر جلب بطاقة العلامات للطالب',
                                          style: TextStyle(color: subColor),
                                        ),
                                      )
                                    : _buildAcademicCardContent(cardColor, textColor, subColor, isDark),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildAcademicCardContent(Color cardColor, Color textColor, Color subColor, bool isDark) {
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
                      'الرقم الجامعي: ${student['university_id'] ?? ''}',
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
            _buildStatBadge('المعدل العام', '${summary['average'] ?? 0}%', Colors.orange, cardColor, textColor),
            const SizedBox(width: 8),
            _buildStatBadge('المواد الناجحة', '${summary['passed_courses'] ?? 0}', Colors.green, cardColor, textColor),
            const SizedBox(width: 8),
            _buildStatBadge('لم يتم التقدم', '${summary['not_attended'] ?? 0}', Colors.grey, cardColor, textColor),
          ],
        ),



        const SizedBox(height: 20),

        // جدول المواد والعلامات
        Text(
          'كشف درجات المواد',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 10),

        if (cards.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('لا توجد مواد مسجلة للطالب في سنته الأكاديمية الحالية', style: TextStyle(color: subColor))),
          )
        else
          ...cards.map((c) => _buildCourseGradeCard(c, cardColor, textColor, subColor, isDark)),
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

  Widget _buildCourseGradeCard(Map<String, dynamic> c, Color cardColor, Color textColor, Color subColor, bool isDark) {
    final String status = c['status'] ?? 'لم يتم التقدم';

    Color statusBg = Colors.grey.withValues(alpha: 0.15);
    Color statusTextColor = Colors.grey;

    if (status == 'ناجح') {
      statusBg = Colors.green.withValues(alpha: 0.15);
      statusTextColor = Colors.green;
    } else if (status == 'راسب') {
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
              _buildGradeCol('المذاكرة', c['quiz_score'], textColor, subColor),
              _buildGradeCol('عملي / شفهي', c['oral_score'], textColor, subColor),
              _buildGradeCol('النهائي', c['final_score'], textColor, subColor),
              _buildGradeCol('المجموع', c['total_score'], textColor, subColor, isTotal: true),
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
