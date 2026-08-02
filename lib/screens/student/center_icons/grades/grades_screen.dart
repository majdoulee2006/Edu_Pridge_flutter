import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  bool _isLoading = true;
  List<dynamic> _grades = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
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
          _errorMessage = "تعذر تحميل كشف العلامات، يرجى التحقق من الاتصال.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "كشف العلامات الأكاديمية",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "تحديث",
            onPressed: _fetchGrades,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(textColor)
              : _grades.isEmpty
                  ? _buildEmptyView(textColor)
                  : _buildGradesList(cardColor, textColor, primaryColor),
    );
  }

  Widget _buildErrorView(Color textColor) {
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
              label: const Text("إعادة المحاولة"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "لا توجد علامات مرصودة حتى الآن",
            style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesList(Color cardColor, Color textColor, Color primaryColor) {
    return RefreshIndicator(
      onRefresh: _fetchGrades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        itemBuilder: (context, index) {
          final item = _grades[index] as Map<String, dynamic>;
          final courseTitle = item['course_title'] ?? item['title'] ?? item['course_name'] ?? 'مادة غير محددة';
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
                  color: Colors.black.withOpacity(0.04),
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
                              "رمز المادة: $code",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPassed ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPassed ? "ناجح" : "راسب",
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
                    if (oral != null) _buildScoreItem("شفهي", oral, textColor),
                    if (practical != null) _buildScoreItem("عملي", practical, textColor),
                    if (midterm != null) _buildScoreItem("منتصف الفصل", midterm, textColor),
                    if (finalExam != null) _buildScoreItem("النهائي", finalExam, textColor),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "المجموع النهائي:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
