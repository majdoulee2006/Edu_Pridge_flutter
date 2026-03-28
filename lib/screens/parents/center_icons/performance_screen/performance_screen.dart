import 'package:flutter/material.dart';
// استيراد القطع الموحدة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف الألوان المتجاوبة
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: _showSubjectDetails
              ? _buildDetailsAppBar(context, textColor)
              : _buildMainAppBar(context, textColor, cardColor),
          body: Stack(
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

              // 2. الشريط السفلي الموحد
              CustomBottomNav(
                currentIndex: 0, // تتبع للرئيسية
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

  // --- AppBars المحسنة ---
  PreferredSizeWidget _buildMainAppBar(BuildContext context, Color textColor, Color cardColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("أداء الطالبة", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
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

  PreferredSizeWidget _buildDetailsAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("تفاصيل المادة", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () {},
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => setState(() => _showSubjectDetails = false),
        ),
      ],
    );
  }

  // --- تبويب النتائج ---
  Widget _buildResultsTab(Color textColor, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGpaCard(textColor, cardColor),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard("الترتيب", "الـ 5", Icons.bar_chart, Colors.blue, textColor, cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildSmallStatCard("الساعات", "84 / 132", Icons.school, Colors.purple, textColor, cardColor)),
          ],
        ),
        const SizedBox(height: 30),
        _buildSubjectResultCard("برمجة متقدمة", "95", Colors.blue, cardColor, textColor),
        _buildSubjectResultCard("قواعد بيانات", "88", Colors.orange, cardColor, textColor),
        const SizedBox(height: 150),
      ],
    );
  }

  // --- تبويب العلامات ---
  Widget _buildGradesTab(Color textColor, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGradeDetailCard("برمجة متقدمة", "88%", Colors.blue, textColor, cardColor, true),
        _buildGradeDetailCard("قواعد بيانات", "85%", Colors.orange, textColor, cardColor, false),
        _buildGradeDetailCard("تطوير ويب", "92%", Colors.green, textColor, cardColor, false),
        const SizedBox(height: 150),
      ],
    );
  }

  // --- تبويب الحضور ---
  Widget _buildAttendanceTab(Color textColor, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildAttendanceCircleCard("92%", "حضور", Colors.green, textColor, cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildAttendanceCircleCard("8%", "غياب", Colors.red, textColor, cardColor)),
          ],
        ),
        const SizedBox(height: 25),
        _buildLectureRow("15", "أكتوبر", "برمجة متقدمة", "حاضر", Colors.green, textColor, cardColor),
        _buildLectureRow("12", "أكتوبر", "جبر خطي", "غائب", Colors.red, textColor, cardColor),
        const SizedBox(height: 150),
      ],
    );
  }

  // --- واجهة تفاصيل المادة ---
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

  // --- الويجت المساعدة (Helper Widgets) ---

  Widget _buildGpaCard(Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(35)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("المعدل الفصلي", style: TextStyle(color: textColor.withValues(alpha: 0.5))),
              Text("3.85", style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          CircularProgressIndicator(value: 0.85, strokeWidth: 8, color: const Color(0xFFEFFF00), backgroundColor: textColor.withValues(alpha: 0.05)),
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
          Text(t, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
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
            CircleAvatar(backgroundColor: col.withValues(alpha: 0.1), child: Icon(Icons.book, color: col, size: 18)),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            Text(percent, style: TextStyle(color: col, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(Icons.arrow_back_ios_new, size: 12, color: textColor.withValues(alpha: 0.3)),
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
            decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Text(status, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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

  Widget _buildAttendanceCircleCard(String val, String label, Color col, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: col)),
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
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
}