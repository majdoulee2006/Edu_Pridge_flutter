import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class BossStudentServiceRequestsScreen extends StatefulWidget {
  final String requestType;
  final String titleAr;
  final String titleEn;

  const BossStudentServiceRequestsScreen({
    super.key,
    required this.requestType,
    required this.titleAr,
    required this.titleEn,
  });

  @override
  State<BossStudentServiceRequestsScreen> createState() => _BossStudentServiceRequestsScreenState();
}

class _BossStudentServiceRequestsScreenState extends State<BossStudentServiceRequestsScreen> {
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
    final data = await _apiService.getHeadStudentServiceRequests(widget.requestType);
    if (mounted) {
      setState(() {
        _requests = data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _respond(int id, String status, String statusAr, String notes) async {
    // إغلاق المودال أولاً
    Navigator.of(context).pop();

    setState(() => _isLoading = true);
    bool success = await _apiService.respondHeadStudentServiceRequest(id, status, notes: notes);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم $statusAr بنجاح')));
      _fetchRequests();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء تنفيذ الطلب')));
    }
  }

  void _showRequestDetailsDialog(dynamic req, Color cardColor, Color textColor, bool isAr) {
    bool isPending = req['hod_decision'] == 'pending' || req['hod_decision'] == null;
    TextEditingController notesController = TextEditingController(text: req['hod_notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_rounded, color: AppColors.accent, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAr ? "تفاصيل الطلب" : "Request Details",
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade500),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 10),

                  // Student Name
                  _buildDetailRow(isAr ? 'الطالب:' : 'Student:', req['student_name'] ?? '', textColor),
                  const SizedBox(height: 8),

                  // Department
                  _buildDetailRow(isAr ? 'القسم:' : 'Department:', req['department'] ?? '', textColor),
                  const SizedBox(height: 8),

                  // Specialization
                  _buildDetailRow(isAr ? 'التخصص/السنة:' : 'Specialization:', req['specialization'] ?? '', textColor),
                  const SizedBox(height: 8),

                  // University ID
                  _buildDetailRow(isAr ? 'الرقم الجامعي:' : 'University ID:', req['university_id'] ?? '', textColor),
                  const SizedBox(height: 8),
                  
                  // Date
                  _buildDetailRow(isAr ? 'التاريخ:' : 'Date:', req['date'] ?? '', textColor),
                  const SizedBox(height: 10),

                  // Details
                  Text(
                    isAr ? "نص الطلب:" : "Details:",
                    style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      req['details'] ?? '',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Affairs Notes
                  Text(
                    isAr ? "ملاحظات الشؤون:" : "Affairs Notes:",
                    style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (req['affairs_notes'] == null || req['affairs_notes'].toString().isEmpty) 
                          ? (isAr ? 'لا يوجد ملاحظات من الشؤون' : 'No notes from affairs') 
                          : req['affairs_notes'],
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // HOD Notes Input
                  if (isPending) ...[
                    Text(
                      isAr ? "ملاحظتك (رئيس القسم):" : "Your Notes (HOD):",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isAr ? 'أضف ملاحظتك هنا...' : 'Add your notes here...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: textColor.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _respond(req['id'], 'rejected', 'الرفض', notesController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100, 
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(isAr ? 'رفض' : 'Reject', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _respond(req['id'], 'approved', 'القبول', notesController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade100, 
                              foregroundColor: Colors.green,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(isAr ? 'قبول' : 'Approve', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Already responded
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: req['hod_decision'] == 'approved' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? "القرار المتخذ:" : "Decision taken:",
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            req['hod_decision'] == 'approved' ? (isAr ? 'تم القبول' : 'Approved') : (isAr ? 'تم الرفض' : 'Rejected'),
                            style: TextStyle(
                              color: req['hod_decision'] == 'approved' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (req['hod_notes'] != null && req['hod_notes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(isAr ? "ملاحظتك:" : "Your Note:", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            Text(req['hod_notes'], style: TextStyle(color: textColor)),
                          ]
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14))),
      ],
    );
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
                child: DefaultTabController(
                  length: 2,
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
                        icon: Icon(Icons.arrow_back, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      bottom: TabBar(
                        labelColor: AppColors.accent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.accent,
                        tabs: [
                          Tab(text: isAr ? 'طلبات معلقة' : 'Pending'),
                          Tab(text: isAr ? 'طلبات منتهية' : 'Completed'),
                        ],
                      ),
                    ),
                    body: _isLoading
                        ? Center(child: CircularProgressIndicator(color: AppColors.accent))
                        : TabBarView(
                            children: [
                              _buildRequestsList(
                                _requests.where((r) => r['hod_decision'] == 'pending' || r['hod_decision'] == null).toList(),
                                isAr, cardColor, textColor,
                              ),
                              _buildRequestsList(
                                _requests.where((r) => r['hod_decision'] != 'pending' && r['hod_decision'] != null).toList(),
                                isAr, cardColor, textColor,
                              ),
                            ],
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

  Widget _buildRequestsList(List<dynamic> list, bool isAr, Color cardColor, Color textColor) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              isAr ? "لا توجد طلبات هنا حالياً" : "No requests found here",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          return _buildRequestCard(req, cardColor, textColor, isAr);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic req, Color cardColor, Color textColor, bool isAr) {
    bool isPending = req['hod_decision'] == 'pending' || req['hod_decision'] == null;
    bool isApproved = req['hod_decision'] == 'approved';
    
    Color statusColor = isPending ? Colors.orange : (isApproved ? Colors.green : Colors.red);
    String statusText = isPending 
        ? (isAr ? 'قيد الانتظار' : 'Pending') 
        : (isApproved ? (isAr ? 'مقبول' : 'Approved') : (isAr ? 'مرفوض' : 'Rejected'));

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRequestDetailsDialog(req, cardColor, textColor, isAr),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req['student_name'] ?? 'طالب غير معروف',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (isAr ? 'التاريخ: ' : 'Date: ') + (req['date'] ?? ''),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  Row(
                    children: [
                      Text(
                        isAr ? 'عرض التفاصيل' : 'View Details',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.visibility_rounded, color: AppColors.accent, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
