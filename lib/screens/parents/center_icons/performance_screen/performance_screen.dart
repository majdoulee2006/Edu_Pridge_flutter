import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../../widgets/parents_center_icon.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool _showSubjectDetails = false;
  String studentName = "جارِ التحميل...";

  // متغيرات الربط
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    setState(() => isLoading = true); 
    try {
      final prefs = await SharedPreferences.getInstance();
      int? sId = prefs.getInt('selected_student_id');
      String? token = prefs.getString('token');
      studentName = prefs.getString('selected_student_name') ?? "الطالب";

      debugPrint("جلب بيانات الطالب رقم: $sId");

      if (sId != null && token != null) {
        var response = await Dio().get(
          "${ApiService().baseUrl}/parent/performance/$sId",
          options: Options(headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token"
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            data = response.data;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("خطأ في الاتصال: $e");
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: _showSubjectDetails
              ? _buildDetailsAppBar(context, textColor)
              : _buildMainAppBar(context, textColor, cardColor),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEFFF00)))
              : Stack(
            children: [
              _showSubjectDetails
                  ? _buildSubjectDetailsView(textColor, cardColor)
                  : TabBarView(
                children: [
                  _buildResultsTab(textColor, cardColor),
                  _buildGradesTab(textColor, cardColor),
                  _buildAttendanceTab(textColor, cardColor),
                ],
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
      ),
    );
  }

  PreferredSizeWidget _buildMainAppBar(BuildContext context, Color textColor, Color cardColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("أداء $studentName", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withOpacity(0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(icon: Icon(Icons.arrow_forward, color: textColor), onPressed: () => Navigator.pop(context)),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(35)),
          child: TabBar(
            indicator: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(30)),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: "النتائج"), Tab(text: "العلامات"), Tab(text: "الحضور")],
          ),
        ),
      ),
    );
  }

  // --- Widgets Tabs (مربوطة بالبيانات) ---

  Widget _buildResultsTab(Color textColor, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGpaCard(data?['gpa']?.toString() ?? "0.0", textColor, cardColor),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard("الحضور", "${data?['attendance_rate'] ?? 0}%", Icons.check_circle, Colors.green, textColor, cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildSmallStatCard("الغياب", "${data?['absent_count'] ?? 0} يوم", Icons.cancel, Colors.red, textColor, cardColor)),
          ],
        ),
        const SizedBox(height: 30),
        // عرض قائمة مختصرة لأول مادتين في تبويب النتائج
        if (data?['grades'] != null)
          ... (data!['grades'] as List).take(2).map((item) {
            return _buildSubjectResultCard(item['name'] ?? "", "${item['score'] ?? 0}", Colors.blue, cardColor, textColor);
          }),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildGradesTab(Color textColor, Color cardColor) {
    List grades = data?['grades'] ?? [];
    if (grades.isEmpty) return const Center(child: Text("لا توجد علامات حالياً"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        var item = grades[index];
        return _buildGradeDetailCard(
            item['name'] ?? "غير معروف",
            "${item['score'] ?? 0}%",
            index % 2 == 0 ? Colors.blue : Colors.orange,
            textColor,
            cardColor,
            index == 0 // نجعل أول عنصر فقط يفتح التفاصيل كما في تصميمك
        );
      },
    );
  }

  Widget _buildAttendanceTab(Color textColor, Color cardColor) {
    List logs = data?['attendance_logs'] ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildAttendanceCircleCard("${data?['attendance_rate'] ?? 0}%", "حضور", Colors.green, textColor, cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildAttendanceCircleCard("${(100 - (data?['attendance_rate'] ?? 0))}%", "غياب", Colors.red, textColor, cardColor)),
          ],
        ),
        const SizedBox(height: 25),
        if (logs.isEmpty) const Center(child: Text("لا توجد سجلات حضور")),
        ...logs.map((log) {
          bool isPresent = log['status'] == 'present';
          return _buildLectureRow(
              log['attendance_date']?.toString().split('-').last ?? "00",
              "الشهر", // يمكنك تعديلها لجلب الشهر من التاريخ
              log['name'] ?? "",
              isPresent ? "حاضر" : "غائب",
              isPresent ? Colors.green : Colors.red,
              textColor,
              cardColor
          );
        }),
        const SizedBox(height: 150),
      ],
    );
  }

  // --- Helper Widgets (التصميم كما هو تماماً) ---

  Widget _buildGpaCard(String gpaValue, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(35)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("المعدل التراكمي", style: TextStyle(color: textColor.withOpacity(0.5))),
              Text(gpaValue, style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          CircularProgressIndicator(
              value: (double.tryParse(gpaValue) ?? 0) / 4, // افترضنا المعدل من 4
              strokeWidth: 8,
              color: const Color(0xFFEFFF00),
              backgroundColor: textColor.withOpacity(0.1)
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String t, String v, IconData i, Color c, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, color: c, size: 20),
          const SizedBox(height: 10),
          Text(t, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
          Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildGradeDetailCard(String title, String percent, Color col, Color textColor, Color cardColor, bool isFirst) {
    return GestureDetector(
      onTap: isFirst ? () => setState(() => _showSubjectDetails = true) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(Icons.book, color: col, size: 18)),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            Text(percent, style: TextStyle(color: col, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(Icons.arrow_back_ios_new, size: 12, color: textColor.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureRow(String day, String month, String subject, String status, Color col, Color textColor, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Column(children: [Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)), Text(month, style: const TextStyle(fontSize: 10, color: Colors.blue))]),
          const SizedBox(width: 15),
          Text(subject, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Text(status, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectResultCard(String title, String grade, Color col, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          const Spacer(),
          Text(grade, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCircleCard(String val, String label, Color col, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: col)),
          Text(label, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDetailsAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("تفاصيل المادة", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        IconButton(icon: Icon(Icons.arrow_forward, color: textColor), onPressed: () => setState(() => _showSubjectDetails = false)),
      ],
    );
  }

  Widget _buildSubjectDetailsView(Color textColor, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("المذاكرات", Icons.assignment, Colors.blue, textColor),
        _buildDetailsGroupCard(cardColor, [
          _buildDetailRow("مذاكرة منتصف الفصل", "28/30", Colors.blue, textColor),
          _buildDetailRow("مشروع الفصل", "29/30", Colors.blue, textColor),
        ]),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color col, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildDetailsGroupCard(Color cardColor, List<Widget> children) => Container(
    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
    child: Column(children: children),
  );

  Widget _buildDetailRow(String title, String score, Color col, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          Text(score, style: TextStyle(color: col, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}