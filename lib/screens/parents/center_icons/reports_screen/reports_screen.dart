import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/widgets/parents_center_icon.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../nav_bar/parents_profile_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String? studentName;
  final int? studentId;

  const ReportsScreen({super.key, this.studentName, this.studentId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? studentName;
  int? studentId;
  bool _isLoading = false;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    if (widget.studentName != null) {
      studentName = widget.studentName;
      studentId = widget.studentId;
    } else {
      _loadSelectedStudent();
    }
    _fetchHistory();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _loadSelectedStudent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      studentName = prefs.getString('selected_student_name') ?? "لم يتم اختيار طالب";
      studentId = prefs.getInt('selected_student_id');
    });
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/parent/reports/history",
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true && mounted) {
        final list = res.data['data'] as List? ?? [];
        setState(() {
          _history = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      debugPrint("خطأ في جلب سجل التقارير: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _sendReportRequest(String selectedReport) async {
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار طالب من القائمة الرئيسية أولاً")),
      );
      return;
    }
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _getToken();
      var response = await Dio().post(
        "${ApiService().baseUrl}/parent/request-report",
        data: {
          "student_id": studentId,
          "report_type": selectedReport == "أكاديمي" ? "academic" : "behavioral",
        },
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200) {
        messenger.showSnackBar(SnackBar(
          content: Text("✅ تم إرسال طلب التقرير للابن: $studentName بنجاح"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ));
        _fetchHistory();
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? "حدث خطأ أثناء طلب التقرير";
      messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRequestDialog(BuildContext context) {
    String selectedReport = "أكاديمي";
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(
              top: 20, left: 20, right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text("طلب تقرير جديد", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text("الابن: ${studentName ?? 'غير محدد'}",
                    style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6))),
                const SizedBox(height: 20),
                Text("نوع التقرير", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),
                _buildReportOptionTile(
                  title: "تقرير أكاديمي",
                  subtitle: "يشمل الدرجات، الحضور، والملاحظات الأكاديمية — يُصدر تلقائياً",
                  icon: Icons.school_rounded,
                  color: Colors.blueAccent,
                  isSelected: selectedReport == "أكاديمي",
                  onTap: () => setModalState(() => selectedReport = "أكاديمي"),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                _buildReportOptionTile(
                  title: "تقرير سلوك",
                  subtitle: "يشمل الالتزام، المشاركة، والتقييم السلوكي — يُحوَّل إلى المعلم",
                  icon: Icons.psychology_outlined,
                  color: Colors.purpleAccent,
                  isSelected: selectedReport == "سلوك",
                  onTap: () => setModalState(() => selectedReport = "سلوك"),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "يمكنك طلب تقرير جديد لكل طالب مرة واحدة كل 15 يومًا.",
                          style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.pop(ctx);
                      _sendReportRequest(selectedReport);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("إرسال الطلب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textColor),
        body: SizedBox.expand(
          child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(textColor, cardColor),
                  const SizedBox(height: 25),
                  Text("سجل التقارير", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 12),
                  if (_isLoadingHistory)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                    ))
                  else if (_history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_outlined, size: 40, color: textColor.withValues(alpha: 0.2)),
                          const SizedBox(height: 10),
                          Text("لا توجد تقارير سابقة", style: TextStyle(color: textColor.withValues(alpha: 0.4))),
                          const SizedBox(height: 4),
                          Text("اضغط + لطلب تقرير جديد", style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.3))),
                        ],
                      ),
                    )
                  else
                    ..._history.map((report) => _buildHistoryCard(report, cardColor, textColor)),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00))),
              ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
            Positioned(
              bottom: 100,
              left: 20,
              child: FloatingActionButton(
                heroTag: "add_report_btn",
                onPressed: () => _showRequestDialog(context),
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFFFCC00),
            child: Icon(Icons.person, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تقارير الابن:", style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6))),
                Text(studentName ?? "جاري التحميل...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text("تقارير الأبناء", style: TextStyle(fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> report, Color cardColor, Color textColor) {
    final isAcademic = report['report_type'] == 'academic';
    final color = isAcademic ? Colors.blueAccent : Colors.purpleAccent;
    final date = (report['created_at'] as String?)?.split('T')[0] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isAcademic ? Icons.school_rounded : Icons.psychology_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAcademic ? "تقرير أكاديمي" : "تقرير سلوك",
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(report['student_name'] ?? '', style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.4))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("مكتمل", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptionTile({
    required String title, required String subtitle, required IconData icon,
    required Color color, required bool isSelected, required VoidCallback onTap,
    required Color cardColor, required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFFFCC00) : textColor.withValues(alpha: 0.08), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5))),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFFCC00), size: 22),
          ],
        ),
      ),
    );
  }
}
