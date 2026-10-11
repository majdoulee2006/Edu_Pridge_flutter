import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'corrected_responses.dart';
import '../../grading_screen/grading_screen.dart';

class AllResponsesScreen extends StatefulWidget {
  const AllResponsesScreen({super.key});

  @override
  State<AllResponsesScreen> createState() => _AllResponsesScreenState();
}

class _AllResponsesScreenState extends State<AllResponsesScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Graded
  bool _isLoading = false;
  List<Map<String, dynamic>> _allSubmissions = [];
  String _searchQuery = '';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _fetchSubmissions();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await Dio().get(
        "${ApiService().baseUrl}/teacher/submissions",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _allSubmissions = (response.data['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Submissions Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppSettings.language.value == 'ar';
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          // 1. شريط البحث
          _buildSearchBar(cardColor, textColor, isAr),

          // 2. أزرار التبديل العلوية (Filter Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterBtn(0, isAr ? "جميع الردود" : "All Responses", isDark),
                const SizedBox(width: 12),
                _buildFilterBtn(1, isAr ? "تم التصحيح" : "Graded", isDark),
              ],
            ),
          ),

          // 3. المحتوى المتغير
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedFilterIndex == 0
                  ? _buildAllResponsesListView(cardColor, textColor, isDark, isAr)
                  : CorrectedResponsesScreen(
                      submissions: _allSubmissions
                          .where((s) => s['is_graded'] == true)
                          .where((s) => _searchQuery.isEmpty ||
                              (s['student_name'] as String? ?? '')
                                  .contains(_searchQuery))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color textColor, bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
          ],
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: Colors.grey, size: 20),
            hintText: isAr ? "ابحث باسم الطالب..." : "Search by student name...",
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAllResponsesListView(
    Color cardColor,
    Color textColor,
    bool isDark,
    bool isAr,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    final filtered = _allSubmissions
        .where((s) => _searchQuery.isEmpty ||
            (s['student_name'] as String? ?? '').contains(_searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا توجد ردود' : 'No responses',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final s = filtered[index];
        final isGraded = s['is_graded'] == true;
        final statusText = isGraded
            ? (isAr ? 'تم التصحيح' : 'Graded')
            : (isAr ? 'بانتظار التصحيح' : 'Pending Grading');

        return _buildResponseSlide(
          context,
          submission:  s,
          name:        s['student_name'] as String? ?? '',
          task:        s['assignment_title'] as String? ?? '',
          date:        s['submitted_at'] as String? ?? '',
          status:      statusText,
          isCorrected: isGraded,
          cardColor:   cardColor,
          textColor:   textColor,
          isDark:      isDark,
          isAr:        isAr,
        );
      },
    );
  }

  Widget _buildResponseSlide(
    BuildContext context, {
    required Map<String, dynamic> submission,
    required String name,
    required String task,
    required String date,
    required String status,
    required bool isCorrected,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    required bool isAr,
  }) {
    Color statusMainColor = isCorrected
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);
    Color statusBgColor = statusMainColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GradingScreen(submission: submission),
              ),
            ).then((_) => _fetchSubmissions());
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // صورة الطالب أو الحرف الأول
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: statusBgColor,
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: TextStyle(
                          color: statusMainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // معلومات الطالب
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          Text(
                            task,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // الحالة
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusMainColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusMainColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          date,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isAr ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                      size: 12,
                      color: textColor.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBtn(int index, String text, bool isDark) {
    bool isActive = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFCC00)
                : (isDark ? Colors.white10 : const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
