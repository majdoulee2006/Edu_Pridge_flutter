import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class ReportRequestsScreen extends StatefulWidget {
  final String? initialRequestId;

  const ReportRequestsScreen({super.key, this.initialRequestId});

  @override
  State<ReportRequestsScreen> createState() => _ReportRequestsScreenState();
}

class _ReportRequestsScreenState extends State<ReportRequestsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _allRequests = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getTeacherReportRequests();
    if (mounted) {
      setState(() {
        _allRequests = data ?? [];
        _isLoading = false;
      });

      // إذا تم تمرير requestId محدد من إشعار، افتح نافذة كتابة التقرير له فوراً
      if (widget.initialRequestId != null) {
        final target = _allRequests.firstWhere(
          (r) => r['id'].toString() == widget.initialRequestId.toString(),
          orElse: () => null,
        );
        if (target != null && target['status'] == 'pending') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSubmitReportSheet(target);
          });
        }
      }
    }
  }

  List<dynamic> get _pendingRequests =>
      _allRequests.where((r) => r['status'] == 'pending').toList();

  List<dynamic> get _completedRequests =>
      _allRequests.where((r) => r['status'] == 'completed').toList();

  void _showSubmitReportSheet(dynamic req) {
    final TextEditingController notesController = TextEditingController();
    bool isSubmitting = false;
    bool isLoadingStats = false;
    Map<String, dynamic>? studentStats;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textClr = isDark ? Colors.white : AppColors.textDark;
          final cardBg  = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F9FC);
          final studentName = req['student_name']?.toString() ?? 'الطالب';
          final courseName  = req['course_name']?.toString() ?? 'غير محدد';
          final reqId       = req['id'] is int ? req['id'] as int : int.tryParse(req['id'].toString()) ?? 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // المقبض العلوي
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(80),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // العنوان
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(40),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.rate_review_outlined, color: Color(0xFFCC9900), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "تقديم تقرير الطالب",
                                  style: TextStyle(color: textClr, fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  studentName,
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // بطاقة تفاصيل الطلب
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.book_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text("المادة: $courseName", style: TextStyle(color: textClr, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (req['requester_name'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text("الجهة الطالبة: ${req['requester_name']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                            if (req['notes'] != null && req['notes'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.withAlpha(60)),
                                ),
                                child: Text(
                                  "ملاحظات رئيس القسم: ${req['notes']}",
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // زر فحص إحصائيات الطالب الأكاديمية
                      if (studentStats == null && !isLoadingStats)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              setSheetState(() => isLoadingStats = true);
                              final stats = await _apiService.getTeacherStudentAcademicStats(reqId);
                              setSheetState(() {
                                studentStats = stats;
                                isLoadingStats = false;
                              });
                            },
                            icon: const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFFCC9900)),
                            label: const Text("عرض حضور وعلامات الطالب للمساعدة", style: TextStyle(color: Color(0xFFCC9900), fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),

                      if (isLoadingStats)
                        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),

                      if (studentStats != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.withAlpha(50)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text("معدل العلامات", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    studentStats!['avg_grade'] != null ? "${studentStats!['avg_grade']} / 100" : "غير متوفر",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 25, color: Colors.grey.withAlpha(80)),
                              Column(
                                children: [
                                  const Text("نسبة الحضور", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    studentStats!['attendance_rate'] != null ? "${studentStats!['attendance_rate']}%" : "غير متوفر",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // حقل إدخال التقرير
                      Text("تقرير المعلم وملاحظاته:", style: TextStyle(color: textClr, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 5,
                        style: TextStyle(color: textClr, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "اكتب تقييمك السلوكي أو الأكاديمي الشامل للطالب هنا...",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          fillColor: cardBg,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // زر الإرسال
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final text = notesController.text.trim();
                                  final messenger = ScaffoldMessenger.of(context);
                                  if (text.length < 3) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text("يرجى كتابة تقرير مناسب (3 أحرف على الأقل)")),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSubmitting = true);
                                  final ok = await _apiService.submitTeacherReportEvaluation(reqId, text);
                                  setSheetState(() => isSubmitting = false);

                                  if (ok) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("تم إرسال التقرير لرئيس القسم بنجاح"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _fetchRequests();
                                    }
                                  } else {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text("حدث خطأ أثناء إرسال التقرير، يرجى المحاولة ثانية"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text("إرسال التقرير لرئيس القسم", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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

            final pending = _pendingRequests;
            final completed = _completedRequests;

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
                    bottom: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isAr ? "بانتظار الرد" : "Pending", style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (pending.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${pending.length}",
                                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isAr ? "المنجزة" : "Completed", style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (completed.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${completed.length}",
                                    style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  body: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRequestsList(pending, isPending: true, cardColor: cardColor, textColor: textColor, isAr: isAr),
                            _buildRequestsList(completed, isPending: false, cardColor: cardColor, textColor: textColor, isAr: isAr),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<dynamic> items, {required bool isPending, required Color cardColor, required Color textColor, required bool isAr}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline : Icons.history_edu_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              isPending
                  ? (isAr ? "لا توجد طلبات تقارير معلقة حالياً" : "No pending report requests")
                  : (isAr ? "لا توجد تقارير منجزة سابقة" : "No completed reports yet"),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final studentName = item['student_name']?.toString() ?? (isAr ? 'طالب' : 'Student');
          final courseName  = item['course_name']?.toString() ?? (isAr ? 'غير محدد' : 'N/A');
          final reportType  = item['report_type']?.toString() == 'behavioral'
              ? (isAr ? 'تقرير سلوكي' : 'Behavioral Report')
              : (isAr ? 'تقرير أكاديمي' : 'Academic Report');
          final requester   = item['requester_name']?.toString();
          final dateStr     = item['created_at']?.toString() ?? '';
          final dateFormatted = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
          final notes       = item['notes']?.toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الهيدر: الأفاتار، الاسم، الحالة
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isPending ? Colors.amber.withAlpha(40) : Colors.green.withAlpha(40),
                        child: Text(
                          studentName.isNotEmpty ? studentName[0] : 'S',
                          style: TextStyle(
                            color: isPending ? const Color(0xFFCC9900) : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item['report_type'] == 'behavioral' ? Colors.purple : Colors.blue).withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    reportType,
                                    style: TextStyle(
                                      color: item['report_type'] == 'behavioral' ? Colors.purple : Colors.blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.amber.withAlpha(30) : Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPending ? (isAr ? "بانتظار ردك" : "Pending") : (isAr ? "مكتمل" : "Done"),
                          style: TextStyle(
                            color: isPending ? const Color(0xFFB45309) : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // تفاصيل المادة والجهة الطالبة
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("${isAr ? 'المادة' : 'Course'}: $courseName", style: TextStyle(color: textColor, fontSize: 13)),
                    ],
                  ),

                  if (requester != null && requester.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("${isAr ? 'طلب بواسطة' : 'Requested by'}: $requester", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],

                  // إذا كان مكتملاً ويوجد تقرير مكتوب
                  if (!isPending && notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withAlpha(50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(isAr ? "التقرير المرسل:" : "Submitted Report:", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notes,
                            style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // إذا كان معلقاً، زر تقديم التقرير
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showSubmitReportSheet(item),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: Text(
                          isAr ? "كتابة وتقديم التقرير" : "Write & Submit Report",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
