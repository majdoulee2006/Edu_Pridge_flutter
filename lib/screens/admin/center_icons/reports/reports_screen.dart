import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';

// استيراد شاشات الشريط السفلي
import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/messages_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // متغيرات التحديد
  String selectedReportType = "نسب الحضور";
  String selectedDept = "جميع الأقسام";
  String selectedYear = "العام الدراسي 2023-2024";
  String selectedSemester = "الفصل الدراسي الأول";

  DateTime? fromDate;
  DateTime? toDate;

  final List<String> departments = ["جميع الأقسام", "قسم الكومبيوتر", "قسم الهندسي", "قسم الطبي"];
  final List<String> years = ["العام الدراسي 2023-2024", "العام الدراسي 2024-2025"];
  final List<String> semesters = ["الفصل الدراسي الأول", "الفصل الدراسي الثاني", "العام كامل"];

  // دالة التنقل في الشريط السفلي
  void _navigateToNavScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const AdminHomeScreen();
        break;
      case 1:
        screen = const AdminMessagesScreen();
        break;
      case 2:
        screen = const AdminNotificationsScreen();
        break;
      case 3:
        screen = const AdminProfileScreen();
        break;
      default:
        screen = const AdminHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("توليد التقارير"),
          centerTitle: true,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))
          ],
        ),

        body: Stack(
          children: [
            // المحتوى الرئيسي
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("نوع التقرير",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // بطاقات نوع التقرير
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeCard(
                            "أداء الطلاب",
                            Icons.bar_chart_rounded,
                            selectedReportType == "أداء الطلاب",
                            primaryYellow,
                            isDark),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTypeCard(
                            "نسب الحضور",
                            Icons.person_search_outlined,
                            selectedReportType == "نسب الحضور",
                            primaryYellow,
                            isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text("معايير التصفية",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // حاوية المعايير
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildFilterDropdown("القسم / المرحلة", departments, selectedDept,
                                (v) => setState(() => selectedDept = v!), isDark),
                        const SizedBox(height: 15),
                        _buildFilterDropdown("الدورة", years, selectedYear,
                                (v) => setState(() => selectedYear = v!), isDark),
                        const SizedBox(height: 15),
                        _buildFilterDropdown("الفصل", semesters, selectedSemester,
                                (v) => setState(() => selectedSemester = v!), isDark),
                        const SizedBox(height: 20),

                        // اختيار التاريخ
                        Row(
                          children: [
                            Expanded(
                                child: _buildDatePicker("من تاريخ", fromDate,
                                        (date) => setState(() => fromDate = date), isDark)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _buildDatePicker("إلى تاريخ", toDate,
                                        (date) => setState(() => toDate = date), isDark)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // زر توليد التقرير
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.description_outlined, color: Colors.black),
                    label: const Text("توليد التقرير",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),

                  const SizedBox(height: 160), // مسافة إضافية لتجنب التداخل
                ],
              ),
            ),

            // الشريط السفلي
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNav(
                currentIndex: 0,
                centerButton: const AdminSpeedDial(),
                onHomeTap: () => _navigateToNavScreen(0),
                onMessagesTap: () => _navigateToNavScreen(1),
                onNotificationsTap: () => _navigateToNavScreen(2),
                onProfileTap: () => _navigateToNavScreen(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== الدوال المساعدة ======================

  Widget _buildTypeCard(String label, IconData icon, bool isSelected, Color yellow, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => selectedReportType = label),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isSelected ? yellow : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: isSelected ? yellow.withOpacity(0.2) : Colors.grey.shade100,
                  child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: yellow,
                child: const Icon(Icons.check, size: 12, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String value,
      ValueChanged<String?> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, bottom: 5),
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(
                  value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onPicked, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null ? "mm/dd/yyyy" : "${date.toLocal()}".split(' ')[0],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}