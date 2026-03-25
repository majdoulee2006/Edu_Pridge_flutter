import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/parents_center_icon.dart';
import '../../../teacher/messages_screen.dart';
import '../../../teacher/notifications_screen.dart';
import '../../../teacher/profile_screen.dart';
import '../../../teacher/teacher_home.dart';
import '../../nav_bar/parents_messages_screen.dart';
import '../../nav_bar/parents_notifications_screen.dart';
import '../../nav_bar/parents_profile_screen.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool _showSubjectDetails = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Directionality(
        textDirection: TextDirection.rtl, // تفعيل الاتجاه العربي للواجهة بالكامل
        child: Scaffold(
          backgroundColor: const Color(0xFFFDFDFD),
          appBar: _showSubjectDetails ? _buildDetailsAppBar() : _buildMainAppBar(),
          body: _showSubjectDetails
              ? _buildSubjectDetailsView()
              : TabBarView(
            children: [
              _buildResultsTab(),
              _buildGradesTab(),
              _buildAttendanceTab(),
            ],
          ),
          floatingActionButton: const Parents_Center_Icon(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  // --- AppBar الرئيسي ---
  PreferredSizeWidget _buildMainAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildCircleBtn(Icons.settings_outlined),
      title: const Text("أداء سارة محمد", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      actions: [_buildCircleBtn(Icons.arrow_forward), const SizedBox(width: 10)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(35)),
          child: TabBar(
            indicator: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(30)),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [Tab(text: "النتائج"), Tab(text: "العلامات"), Tab(text: "الحضور")],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDetailsAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildCircleBtn(Icons.settings_outlined),
      title: const Text("علامات برمجة متقدمة 2", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () => setState(() => _showSubjectDetails = false),
          child: _buildCircleBtn(Icons.arrow_forward),
        ),
        const SizedBox(width: 10)
      ],
    );
  }

  // ================= 1. واجهة النتائج (RTL) =================
  Widget _buildResultsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGpaCard(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard("الترتيب على الدفعة", "الـ 5", Icons.bar_chart, Colors.blue)),
            const SizedBox(width: 15),
            Expanded(child: _buildSmallStatCard("الساعات المنجزة", "84 / 132", Icons.school_outlined, Colors.purple)),
          ],
        ),
        const SizedBox(height: 30),
        const Align(alignment: Alignment.centerRight, child: Text("أبرز المواد هذا الفصل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 15),
        _buildSubjectResultCard("برمجة متقدمة 2", "د. سمير خليل", "95", "ممتاز", Colors.blue, Icons.code),
        _buildSubjectResultCard("قواعد بيانات", "د. نورة العلي", "88", "جيد جداً", Colors.orange, Icons.storage),
        _buildAdvisorNote(),
        const SizedBox(height: 100),
      ],
    );
  }

  // ================= 2. واجهة العلامات (RTL) =================
  Widget _buildGradesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSubjectDetails = true),
          child: _buildGradeDetailCard("برمجة متقدمة 2", "د. سمير خليل", "88%", Icons.code, const Color(0xFF5D78FF)),
        ),
        _buildGradeDetailCard("قواعد بيانات", "د. نورة العلي", "85%", Icons.storage, const Color(0xFFFF9E43)),
        _buildGradeDetailCard("جبر خطي", "أ. مازن سعيد", "79%", Icons.functions, const Color(0xFFFF69B4)),
        _buildGradeDetailCard("تطوير ويب", "د. عمر فاروق", "92%", Icons.language, const Color(0xFF00C48C)),
        const SizedBox(height: 100),
      ],
    );
  }

  // ================= 3. واجهة الحضور (RTL) =================
  Widget _buildAttendanceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildAttendanceCircleCard("92%", "نسبة الحضور", Colors.green, Icons.check_circle_outline)),
            const SizedBox(width: 15),
            Expanded(child: _buildAttendanceCircleCard("8%", "نسبة الغياب", Colors.red, Icons.cancel_outlined)),
          ],
        ),
        const SizedBox(height: 25),
        _buildDistributionSection(),
        const SizedBox(height: 25),
        const Align(alignment: Alignment.centerRight, child: Text("سجل المحاضرات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 15),
        _buildLectureRow("15", "OCT", "برمجة متقدمة 2", "08:30 ص", "حاضر", Colors.green),
        _buildLectureRow("12", "OCT", "جبر خطي", "09:30 ص", "غائب", Colors.red),
        const SizedBox(height: 100),
      ],
    );
  }

  // ================= 4. واجهة تفاصيل المادة (RTL) =================
  Widget _buildSubjectDetailsView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader("المذاكرات", Icons.assignment_outlined, Colors.blue),
        _buildDetailsGroupCard([
          _buildDetailRow("مذاكرة منتصف الفصل", "20 نوفمبر 2023", "28/30", "نظري", Colors.blue, Icons.edit_note),
          _buildDetailRow("مشروع الفصل العملي", "15 ديسمبر 2023", "29/30", "عملي", Colors.blue, Icons.laptop_mac),
        ]),
        const SizedBox(height: 20),
        _buildSectionHeader("الامتحانات", Icons.fact_check_outlined, Colors.green),
        _buildDetailsGroupCard([
          _buildDetailRow("الامتحان النظري النهائي", "15 يناير 2024", "48/50", "96%", Colors.blue, Icons.description_outlined),
          _buildDetailRow("الامتحان العملي النهائي", "10 يناير 2024", "47/50", "94%", Colors.blue, Icons.terminal_outlined),
        ]),
        const SizedBox(height: 20),
        _buildSectionHeader("الكويزات", Icons.quiz_outlined, Colors.purple),
        _buildDetailsGroupCard([
          _buildDetailRow("كويز 3 - البرمجة كائنية التوجه", "10 ديسمبر 2023", "10/10", "ممتاز", Colors.purple, Icons.code),
          _buildDetailRow("كويز 2 - المؤشرات (Pointers)", "25 نوفمبر 2023", "7/10", "جيد", Colors.purple, Icons.memory),
        ]),
        const SizedBox(height: 100),
      ],
    );
  }

  // --- Widgets المساعدة مع تعديل الترتيب ليناسب RTL ---

  Widget _buildSectionHeader(String title, IconData icon, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // الأيقونة ثم النص من اليمين
        children: [
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: col, size: 20)),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String date, String score, String sub, Color col, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.5))),
      child: Row(children: [
        Container(width: 45, height: 45, decoration: BoxDecoration(color: col.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, color: col, size: 22)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11))],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(score, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
      ]),
    );
  }

  Widget _buildLectureRow(String day, String month, String subject, String time, String status, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black12)),
      child: Row(children: [
        Column(children: [Text(month, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)), Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12))),
      ]),
    );
  }

  Widget _buildGradeDetailCard(String t, String te, String p, IconData i, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(children: [
        CircleAvatar(radius: 25, backgroundColor: c.withOpacity(0.08), child: Icon(i, color: c)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [Text("المعدل: ", style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(p, style: TextStyle(color: c, fontWeight: FontWeight.bold)), Text(" . $te", style: const TextStyle(color: Colors.grey, fontSize: 12))]),
          ]),
        ),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26), // سهم لليسار في RTL
      ]),
    );
  }

  Widget _buildSubjectResultCard(String title, String teacher, String grade, String status, Color col, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black12)),
      child: Row(children: [
        CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(icon, color: col, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(teacher, style: const TextStyle(color: Colors.grey, fontSize: 11))])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(grade, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 20)), Text(status, style: const TextStyle(color: Colors.green, fontSize: 10))]),
      ]),
    );
  }

  // الواجهات الثابتة الأخرى تبقى كما هي مع التأكد من محاذاة نصوصها داخلياً
  Widget _buildGpaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("(GPA) المعدل الفصلي", style: TextStyle(color: Colors.grey)),
            const Text("3.85", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(15)), child: const Text("+ 0.2 عن الفصل الماضي", style: TextStyle(color: Colors.green, fontSize: 10))),
          ]),
          const Stack(alignment: Alignment.center, children: [
            SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: 0.85, strokeWidth: 8, color: Color(0xFFEFFF00), backgroundColor: Color(0xFFF5F5F5))),
            Column(children: [Text("A", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text("ممتاز", style: TextStyle(fontSize: 10, color: Colors.grey))]),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailsGroupCard(List<Widget> children) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black.withOpacity(0.05))), child: Column(children: children));
  Widget _buildAttendanceCircleCard(String val, String label, Color col, IconData icon) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.black12)), child: Column(children: [Icon(icon, color: col, size: 30), const SizedBox(height: 10), Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]));
  Widget _buildSmallStatCard(String t, String v, IconData i, Color c) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Align(alignment: Alignment.topRight, child: CircleAvatar(radius: 18, backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c, size: 18))), const SizedBox(height: 10), Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]));
  Widget _buildDistributionSection() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.black12)), child: Column(children: [const Row(children: [Icon(Icons.pie_chart_outline, size: 20), SizedBox(width: 10), Text("توزيع الغياب", style: TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 20), _buildProgressRow("غياب مبرر", "3 محاضرات", 0.7, Colors.blue), const SizedBox(height: 15), _buildProgressRow("غياب غير مبرر", "1 محاضرة", 0.2, Colors.red)]));
  Widget _buildProgressRow(String label, String count, double val, Color col) => Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(10)), child: Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Row(children: [Text(label, style: const TextStyle(fontSize: 12)), const SizedBox(width: 8), Icon(Icons.circle, color: col, size: 10)])]), const SizedBox(height: 8), LinearProgressIndicator(value: val, backgroundColor: Colors.grey[100], color: col, minHeight: 8)]);
  Widget _buildAdvisorNote() => Container(margin: const EdgeInsets.only(top: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFEEF5FF), borderRadius: BorderRadius.circular(35)), child: const Row(children: [Icon(Icons.chat_bubble_outline, color: Colors.blue), SizedBox(width: 15), Expanded(child: Text("أداء سارة متميز هذا الفصل، خاصة في المواد العملية.", style: TextStyle(color: Colors.blue, fontSize: 12)))]));
  Widget _buildCircleBtn(IconData icon) => Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12)), child: Icon(icon, color: Colors.black, size: 20));


  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home_outlined, "الرئيسية", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ParentsHomeScreen()
            ))
            ),
            _navItem(context, Icons.person_outline, "الملف", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen()))),
            const SizedBox(width: 40),
            _navItem(context, Icons.notifications_none, "الإشعارات", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen()))),
            _navItem(context, Icons.chat_bubble_outline, "الرسائل", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEFFF00) : Colors.grey),
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey)),
        ],
      ),
    );
  }





}