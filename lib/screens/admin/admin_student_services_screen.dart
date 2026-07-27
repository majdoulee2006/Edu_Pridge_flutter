import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';

class AdminStudentServicesScreen extends StatefulWidget {
  final String serviceType; // 'mercy', 'document', 'makeup'
  final String titleAr;
  final String titleEn;

  const AdminStudentServicesScreen({
    super.key,
    required this.serviceType,
    required this.titleAr,
    required this.titleEn,
  });

  @override
  State<AdminStudentServicesScreen> createState() => _AdminStudentServicesScreenState();
}

class _AdminStudentServicesScreenState extends State<AdminStudentServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminServices _adminServices = AdminServices();

  List<dynamic> _pendingRequests = [];
  List<dynamic> _completedRequests = [];
  bool _isLoadingPending = true;
  bool _isLoadingCompleted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    _fetchPending();
    _fetchCompleted();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoadingPending = true);
    final res = await _adminServices.getStudentServicesRequests(
      type: widget.serviceType,
      status: 'pending',
    );
    if (mounted) {
      setState(() {
        _pendingRequests = res ?? [];
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _fetchCompleted() async {
    setState(() => _isLoadingCompleted = true);
    final res = await _adminServices.getStudentServicesRequests(
      type: widget.serviceType,
      status: 'completed',
    );
    if (mounted) {
      setState(() {
        _completedRequests = res ?? [];
        _isLoadingCompleted = false;
      });
    }
  }

  void _showProcessDialog(Map<String, dynamic> req, bool canRespond) {
    final TextEditingController notesController = TextEditingController(
      text: req['admin_notes'] ?? '',
    );
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : AppColors.textDark;

            final String studentName = req['student_name'] ?? 'طالب';
            final String studentCode = req['student_code'] ?? 'N/A';
            final String academicYear = req['academic_year'] ?? 'N/A';
            final String deptName = req['department_name'] ?? 'غير محدد';
            final String progName = req['program_name'] ?? 'غير محدد';
            final String details = req['details'] ?? 'لا توجد تفاصيل';
            final String affairsNotes = req['affairs_notes'] ?? 'لا توجد ملاحظات';
            final String hodNotes = req['hod_notes'] ?? 'لا توجد ملاحظات';
            final String adminNotes = req['admin_notes'] ?? '';
            final String adminDecision = req['admin_decision'] ?? '';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "تفاصيل الطلب (${widget.titleAr})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCC00).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow("اسم الطالب:", studentName, textColor),
                            const SizedBox(height: 6),
                            _buildInfoRow("الرقم الجامعي:", studentCode, textColor),
                            const SizedBox(height: 6),
                            _buildInfoRow("القسم / الفرع:", "$deptName - $progName", textColor),
                            const SizedBox(height: 6),
                            _buildInfoRow("العام الدراسي:", academicYear, textColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details
                      Text(
                        "تفاصيل الطلب:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          details,
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Affairs Opinion (Read-only)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.assignment_ind, color: Colors.amber, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "رأي وملاحظات الشؤون:",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              affairsNotes,
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // HOD Opinion (Read-only)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.indigo.shade700, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "رأي وملاحظات رئيس القسم:",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade900, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hodNotes,
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Admin Decision Field or Result
                      if (canRespond) ...[
                        Text(
                          "قرار وملاحظات الإدارة النهائية (مطلوب إجبارياً):",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "اكتب قرار الإدارة النهائي وأسباب قبول أو رفض الطلب...",
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: isSubmitting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: const Text("اعتماد نهائي (موافقة)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (notesController.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("❌ يرجى كتابة ملاحظات القرار النهائي أولاً")),
                                          );
                                          return;
                                        }
                                        setModalState(() => isSubmitting = true);
                                        final success = await _adminServices.processStudentServiceRequest(
                                          id: req['id'],
                                          decision: 'approved',
                                          notes: notesController.text.trim(),
                                        );
                                        setModalState(() => isSubmitting = false);
                                        if (success && mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            const SnackBar(content: Text("✅ تم اعتماد الطلب بالموافقة بنجاح وإشعار الطالب")),
                                          );
                                          _loadRequests();
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: isSubmitting
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.cancel_outlined, color: Colors.white),
                                label: const Text("رفض الطلب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (notesController.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("❌ يرجى كتابة ملاحظات القرار النهائي أولاً")),
                                          );
                                          return;
                                        }
                                        setModalState(() => isSubmitting = true);
                                        final success = await _adminServices.processStudentServiceRequest(
                                          id: req['id'],
                                          decision: 'rejected',
                                          notes: notesController.text.trim(),
                                        );
                                        setModalState(() => isSubmitting = false);
                                        if (success && mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            const SnackBar(content: Text("✅ تم رفض الطلب بنجاح وإغلاقه")),
                                          );
                                          _loadRequests();
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: adminDecision == 'approved' ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: adminDecision == 'approved' ? Colors.green.shade300 : Colors.red.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    adminDecision == 'approved' ? Icons.check_circle : Icons.cancel,
                                    color: adminDecision == 'approved' ? Colors.green.shade800 : Colors.red.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "القرار النهائي للإدارة: ${adminDecision == 'approved' ? 'مقبول' : 'مرفوض'}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: adminDecision == 'approved' ? Colors.green.shade900 : Colors.red.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (adminNotes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "ملاحظات الإدارة: $adminNotes",
                                  style: TextStyle(
                                    color: adminDecision == 'approved' ? Colors.green.shade900 : Colors.red.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
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
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFFCC00),
                  labelColor: const Color(0xFFFFCC00),
                  unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(isAr ? "طلبات معلقة" : "Pending"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(isAr ? "طلبات منتهية" : "Completed"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Pending
                  _buildRequestListView(
                    requests: _pendingRequests,
                    isLoading: _isLoadingPending,
                    canRespond: true,
                    onRefresh: _fetchPending,
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),

                  // Tab 2: Completed
                  _buildRequestListView(
                    requests: _completedRequests,
                    isLoading: _isLoadingCompleted,
                    canRespond: false,
                    onRefresh: _fetchCompleted,
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestListView({
    required List<dynamic> requests,
    required bool isLoading,
    required bool canRespond,
    required Future<void> Function() onRefresh,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    if (requests.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFFFCC00),
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "لا توجد طلبات في هذا التبويب",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFFCC00),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = Map<String, dynamic>.from(requests[index]);
          final String studentName = req['student_name'] ?? 'غير معروف';
          final String studentCode = req['student_code'] ?? 'N/A';
          final String details = req['details'] ?? '';
          final String createdAt = req['created_at'] ?? '';
          final String adminDecision = req['admin_decision'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFFCC00),
                        radius: 20,
                        child: Text(
                          studentName.isNotEmpty ? studentName.substring(0, 1) : 'ط',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "الرقم الجامعي: $studentCode | $createdAt",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      if (canRespond)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "بانتظار قرارك",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: adminDecision == 'approved' ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adminDecision == 'approved' ? "مقبول" : "مرفوض",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: adminDecision == 'approved' ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Action
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRespond ? const Color(0xFFFFCC00) : Colors.blueGrey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        canRespond ? Icons.edit_note_rounded : Icons.visibility_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      label: Text(
                        canRespond ? "معاينة واتخاذ القرار" : "معاينة التفاصيل",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showProcessDialog(req, canRespond),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
