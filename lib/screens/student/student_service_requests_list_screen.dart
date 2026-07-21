import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class StudentServiceRequestsListScreen extends StatefulWidget {
  final String serviceType; // 'mercy', 'document', 'makeup'
  final String titleAr;
  final String titleEn;
  final Widget formScreen; // الشاشة التي سيتم فتحها عند الضغط على +

  const StudentServiceRequestsListScreen({
    super.key,
    required this.serviceType,
    required this.titleAr,
    required this.titleEn,
    required this.formScreen,
  });

  @override
  State<StudentServiceRequestsListScreen> createState() => _StudentServiceRequestsListScreenState();
}

class _StudentServiceRequestsListScreenState extends State<StudentServiceRequestsListScreen> {
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
    final data = await _apiService.getStudentServiceRequests(type: widget.serviceType);
    if (mounted) {
      setState(() {
        _requests = data ?? [];
        _isLoading = false;
      });
    }
  }

  // دالة مساعدة لتحديد اللون والأيقونة حسب حالة الطلب
  Map<String, dynamic> _getStatusConfig(String status, bool isAr) {
    if (status == 'approved') {
      return {
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
        'text': isAr ? 'مقبول نهائياً' : 'Approved'
      };
    } else if (status == 'rejected' || status.contains('rejected')) {
      return {
        'color': Colors.red,
        'icon': Icons.cancel_outlined,
        'text': isAr ? 'مرفوض' : 'Rejected'
      };
    } else {
      return {
        'color': Colors.orange,
        'icon': Icons.hourglass_empty,
        'text': isAr ? 'قيد المراجعة' : 'Pending'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // يمكن ربطها بـ AppSettings للغة والوضع المظلم، سنستخدم القيم الثابتة للتوضيح هنا
    // أو يمكنك استيراد AppSettings إذا كانت متوفرة
    bool isAr = true; // يفترض أن تكون مرتبطة بـ AppSettings.language
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isAr ? widget.titleAr : widget.titleEn,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: textColor),
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
                          isAr ? "لا توجد طلبات سابقة" : "No previous requests",
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
                        final statusConfig = _getStatusConfig(req['status'], isAr);

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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusConfig['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(statusConfig['icon'], color: statusConfig['color'], size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusConfig['text'],
                                            style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      req['created_at_human'] ?? '',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  req['details'] ?? '',
                                  style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                                ),
                                if (req['admin_notes'] != null && req['admin_notes'].toString().trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(right: BorderSide(color: statusConfig['color'], width: 3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAr ? "رد الإدارة:" : "Admin Reply:",
                                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          req['admin_notes'],
                                          style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.accent,
          onPressed: () async {
            // نفتح شاشة الإضافة، وننتظر عودتها (إذا تم الإرسال نقوم بتحديث القائمة)
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.formScreen),
            );
            
            // إذا أرجعت الشاشة قيمة true، فهذا يعني أنه تم إضافة طلب بنجاح ويجب التحديث
            if (result == true || result == null) { // null للتأكيد حالياً
              _fetchRequests();
            }
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            isAr ? "طلب جديد" : "New Request",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
