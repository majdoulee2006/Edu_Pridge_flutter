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
  // إضافة باراميترات اختيارية لاستقبال البيانات مباشرة من صفحة الهوم
  final String? studentName;
  final int? studentId;

  const ReportsScreen({super.key, this.studentName, this.studentId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedReport = "أكاديمي";
  String? studentName;
  int? studentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. التحقق أولاً إذا تم تمرير الاسم عند الانتقال للصفحة
    if (widget.studentName != null) {
      setState(() {
        studentName = widget.studentName;
        studentId = widget.studentId;
      });
    } else {
      // 2. إذا لم يتم التمرير، نحاول جلب الاسم من الذاكرة (SharedPreferences)
      _loadSelectedStudent();
    }
  }

  // دالة جلب بيانات الطالب المخزنة
  Future<void> _loadSelectedStudent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // ✅ تأكدي أن هذه المفاتيح مطابقة لما يتم تخزينه في صفحة الهوم
      studentName = prefs.getString('selected_student_name');
      studentId = prefs.getInt('selected_student_id');

      // قيمة افتراضية في حال عدم وجود بيانات
      if (studentName == null) {
        studentName = "لم يتم اختيار طالب";
      }
    });
  }

  // إرسال طلب التقرير
  Future<void> _sendReportRequest() async {
    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى اختيار طالب من القائمة الرئيسية أولاً"))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      var response = await Dio().post(
        "${ApiService().baseUrl}/parent/request-report",
        data: {
          "student_id": studentId,
          "report_type": selectedReport == "أكاديمي" ? "academic" : "behavioral",
        },
        options: Options(
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200) {
        _showSuccessMessage();
      }
    } on DioException catch (e) {
      String msg = e.response?.data['message'] ?? "حدث خطأ أثناء طلب التقرير";
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ تم إرسال طلب التقرير للابن: $studentName بنجاح"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(textColor, cardColor),
                  const SizedBox(height: 35),
                  Text("نوع التقرير", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 15),
                  _buildReportCard(
                    title: "تقرير أكاديمي",
                    subtitle: "يشمل الدرجات، الحضور، والملاحظات الأكاديمية",
                    icon: Icons.school_rounded,
                    color: Colors.blueAccent,
                    isSelected: selectedReport == "أكاديمي",
                    onTap: () => setState(() => selectedReport = "أكاديمي"),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  _buildReportCard(
                    title: "تقرير سلوك",
                    subtitle: "يشمل الالتزام، المشاركة، والتقييم السلوكي",
                    icon: Icons.psychology_outlined,
                    color: Colors.purpleAccent,
                    isSelected: selectedReport == "سلوك",
                    onTap: () => setState(() => selectedReport = "سلوك"),
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 25),
                  _buildPolicyBox(textColor),
                  const SizedBox(height: 40),
                  _buildRequestButton(textColor),
                  const SizedBox(height: 150),
                ],
              ),
            ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
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
        border: Border.all(color: const Color(0xFFEFFF00).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEFFF00),
            child: Icon(Icons.person, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("أنت تطلب تقريراً للابن:", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
                // ✅ عرض الاسم بشكل ديناميكي
                Text(studentName ?? "جاري تحميل الاسم...",
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
        icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildReportCard({
    required String title, required String subtitle, required IconData icon,
    required Color color, required bool isSelected, required VoidCallback onTap,
    required Color cardColor, required Color textColor
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: isSelected ? const Color(0xFFEFFF00) : textColor.withOpacity(0.05), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5))),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFEFFF00), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyBox(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEE7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.yellow.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "يمكنك طلب تقرير جديد لكل طالب مرة واحدة كل 15 يومًا لضمان دقة البيانات.",
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(Color textColor) {
    return InkWell(
      onTap: _isLoading ? null : _sendReportRequest,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFF00),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: const Color(0xFFEFFF00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
              height: 25,
              width: 25,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : Column(
            children: [
              const Text("طلب التقرير الآن", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              Text("سيصلك إشعار عند جاهزية الملف", style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6))),
            ],
          ),
        ),
      ),
    );
  }
}