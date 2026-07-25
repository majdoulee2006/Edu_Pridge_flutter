import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class BossLeaveRequestsScreen extends StatefulWidget {
  const BossLeaveRequestsScreen({super.key});

  @override
  State<BossLeaveRequestsScreen> createState() => _BossLeaveRequestsScreenState();
}

class _BossLeaveRequestsScreenState extends State<BossLeaveRequestsScreen> {
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
    final data = await _apiService.getHeadLeaveRequests();
    if (mounted) {
      setState(() {
        _requests = data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _respond(int id, String status, String statusAr) async {
    bool success = await _apiService.respondHeadLeaveRequest(id, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم $statusAr بنجاح')));
      _fetchRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء تنفيذ الطلب')));
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
                      isAr ? "طلبات الإجازة" : "Leave Requests",
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
                                    isAr ? "لا توجد طلبات إجازة" : "No leave requests",
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
    bool isPending = req['status'] == 'pending';
    Color statusColor = isPending ? Colors.orange : (req['status'] == 'approved' ? Colors.green : Colors.red);
    String statusText = isPending ? (isAr ? 'قيد الانتظار' : 'Pending') : (req['status'] == 'approved' ? (isAr ? 'مقبول' : 'Approved') : (isAr ? 'مرفوض' : 'Rejected'));

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
                  req['student_name'] ?? req['user_name'] ?? 'مستخدم',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (isAr ? 'السبب: ' : 'Reason: ') + (req['reason'] ?? ''),
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              (isAr ? 'تاريخ الإجازة: ' : 'Date: ') + (req['date'] ?? ''),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _respond(req['id'], 'rejected', 'الرفض'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red),
                    child: Text(isAr ? 'رفض' : 'Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () => _respond(req['id'], 'approved', 'القبول'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green),
                    child: Text(isAr ? 'قبول' : 'Approve'),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
