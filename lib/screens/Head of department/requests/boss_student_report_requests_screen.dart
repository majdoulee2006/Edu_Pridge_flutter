import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class BossStudentReportRequestsScreen extends StatefulWidget {
  const BossStudentReportRequestsScreen({super.key});

  @override
  State<BossStudentReportRequestsScreen> createState() => _BossStudentReportRequestsScreenState();
}

class _BossStudentReportRequestsScreenState extends State<BossStudentReportRequestsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getHeadReportRequests();
    if (mounted) {
      setState(() {
        _requests = data ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<double>(
        valueListenable: AppSettings.fontSize,
        builder: (context, fontScale, _) => ValueListenableBuilder<String>(
          valueListenable: AppSettings.language,
          builder: (context, lang, _) {
            final isAr = lang == 'ar';
            final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
            final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : AppColors.textDark;

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
                child: Scaffold(
                  backgroundColor: bgColor,
                  appBar: AppBar(
                    backgroundColor: cardColor,
                    elevation: 0,
                    centerTitle: true,
                    title: Text(
                      isAr ? "طلبات تقارير الطلاب" : "Student Report Requests",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : _requests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    isAr ? "لا توجد طلبات تقارير حالياً" : "No report requests found",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchRequests,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _requests.length,
                                itemBuilder: (context, index) {
                                  final req = _requests[index];
                                  return _buildRequestCard(req, cardColor, textColor, isAr);
                                },
                              ),
                            ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic req, Color cardColor, Color textColor, bool isAr) {
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  req['student_name'] ?? 'طالب غير معروف',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  req['date'] ?? req['created_at'] ?? '',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (isAr ? 'ولي الأمر: ' : 'Parent: ') + (req['parent_name'] ?? ''),
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              (isAr ? 'ملاحظات: ' : 'Notes: ') + (req['notes'] ?? ''),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
