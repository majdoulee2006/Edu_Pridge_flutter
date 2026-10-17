import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  bool _isLoading = true;
  List<dynamic> _grades = [];
  String? _errorMessage;

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _fetchGrades();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  Future<void> _fetchGrades() async {
    final bool isAr = AppSettings.language.value == 'ar';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await StudentServices().getGrades();
      if (mounted) {
        setState(() {
          _grades = res ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = isAr
              ? "تعذر تحميل كشف العلامات، يرجى التحقق من الاتصال."
              : "Failed to load grades report, please check your connection.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? "كشف العلامات الأكاديمية" : "Academic Grades Report",
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: isAr ? "تحديث" : "Refresh",
              onPressed: _fetchGrades,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView(textColor, isAr)
                : _grades.isEmpty
                    ? _buildEmptyView(textColor, isAr)
                    : _buildGradesList(cardColor, textColor, primaryColor, isAr),
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
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchGrades,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? "إعادة المحاولة" : "Retry"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(Color textColor, bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isAr ? "لا توجد علامات مرصودة حتى الآن" : "No grades recorded yet",
            style: TextStyle(fontSize: 16, color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList(Color cardColor, Color textColor, Color primaryColor, bool isAr) {
    return RefreshIndicator(
      onRefresh: _fetchGrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        itemBuilder: (context, index) {
          final item = _grades[index] as Map<String, dynamic>;
          final courseTitle = item['course_title'] ?? item['title'] ?? item['course_name'] ?? (isAr ? 'مادة غير محددة' : 'Unspecified Course');
          final code = item['course_code'] ?? '';
          final totalScore = item['total'] ?? item['score'] ?? item['grade'] ?? 0;
          final maxScore = item['max_score'] ?? 100;
          final isPassed = (totalScore is num) ? totalScore >= (maxScore * 0.5) : true;
          
          final oral = item['oral'] ?? item['oral_score'];
          final practical = item['practical'] ?? item['practical_score'];
          final midterm = item['midterm'] ?? item['midterm_score'];
          final finalExam = item['final'] ?? item['final_score'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          if (code.toString().isNotEmpty)
                            Text(
                              "${isAr ? "رمز المادة:" : "Course Code:"} $code",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPassed ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPassed ? (isAr ? "ناجح" : "Passed") : (isAr ? "راسب" : "Failed"),
                        style: TextStyle(
                          color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (oral != null) _buildScoreItem(isAr ? "شفهي" : "Oral", oral, textColor),
                    if (practical != null) _buildScoreItem(isAr ? "عملي" : "Practical", practical, textColor),
                    if (midterm != null) _buildScoreItem(isAr ? "منتصف الفصل" : "Midterm", midterm, textColor),
                    if (finalExam != null) _buildScoreItem(isAr ? "النهائي" : "Final", finalExam, textColor),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? "المجموع النهائي:" : "Final Total:",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        "$totalScore / $maxScore",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
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
    );
  }

  Widget _buildScoreItem(String label, dynamic score, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          "$score",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }
}
