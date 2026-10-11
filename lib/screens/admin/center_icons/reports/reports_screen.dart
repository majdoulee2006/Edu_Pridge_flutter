import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
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
  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  List<dynamic> _reportsLog = [];
  bool isLoading = true;

  // متغيرات نموذج إنشاء التقرير
  String selectedReportType = "نسب الحضور";
  String selectedDept = "جميع الأقسام";
  String selectedYear = "العام الدراسي 2024-2025";
  String selectedSemester = "الفصل الدراسي الأول";
  DateTime? fromDate;
  DateTime? toDate;

  final List<String> departments = ["جميع الأقسام", "نظم معلومات", "تجاري", "طبي", "هندسي"];
  final List<String> years = ["العام الدراسي 2024-2025", "العام الدراسي 2025-2026"];
  final List<String> semesters = ["الفصل الدراسي الأول", "الفصل الدراسي الثاني", "العام كامل"];

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadReports();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  String _getDeptLabel(String dept) {
    if (!isAr) {
      switch (dept) {
        case "جميع الأقسام": return "All Departments";
        case "نظم معلومات": return "Information Systems";
        case "تجاري": return "Commercial";
        case "طبي": return "Medical";
        case "هندسي": return "Engineering";
      }
    }
    return dept;
  }

  String _getYearLabel(String year) {
    if (!isAr) {
      switch (year) {
        case "العام الدراسي 2024-2025": return "Academic Year 2024-2025";
        case "العام الدراسي 2025-2026": return "Academic Year 2025-2026";
      }
    }
    return year;
  }

  String _getSemesterLabel(String sem) {
    if (!isAr) {
      switch (sem) {
        case "الفصل الدراسي الأول": return "First Semester";
        case "الفصل الدراسي الثاني": return "Second Semester";
        case "العام كامل": return "Full Year";
      }
    }
    return sem;
  }

  Future<void> _loadReports() async {
    setState(() => isLoading = true);
    final data = await AdminServices().getReportsLog();
    if (data != null) {
      setState(() {
        _reportsLog = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

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

  Future<void> _download(int reportId, String format, String title) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAr ? "جاري تحميل $title بصيغة ${format.toUpperCase()}..." : "Downloading $title as ${format.toUpperCase()}..."),
      ),
    );
    final filename = "${title.replaceAll(' ', '_')}.$format";
    final path = await AdminServices().downloadReport(reportId, format, filename);
    if (path != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "تم تحميل التقرير بنجاح على جهازك ✓" : "Report downloaded successfully to your device ✓")),
        );
      }
      OpenFilex.open(path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? "حدث خطأ أثناء تحميل التقرير" : "Error occurred while downloading report")),
        );
      }
    }
  }

  void _showGeneratedReportOptions(int reportId, String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 15),
                Text(
                  isAr ? "تم توليد التقرير بنجاح 🎉" : "Report Generated Successfully 🎉",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? "اختر طريقة التنزيل لنقل التقرير وتخزينه على جهازك المحمول:"
                      : "Select download format to save report to your device:",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _download(reportId, 'pdf', title);
                        },
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: Text(isAr ? "تنزيل PDF" : "Download PDF", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _download(reportId, 'excel', title);
                        },
                        icon: const Icon(Icons.table_chart, color: Colors.white),
                        label: Text(isAr ? "تنزيل Excel" : "Download Excel", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateReportModal(BuildContext context, bool isDark, Color primaryYellow) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Directionality(
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.post_add_rounded, color: primaryYellow, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              isAr ? "إنشاء وتوليد تقرير جديد" : "Generate New Report",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAr ? "نوع التقرير" : "Report Type", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTypeCard(
                                    isAr ? "أداء الطلاب" : "Student Performance",
                                    Icons.bar_chart_rounded,
                                    selectedReportType == "أداء الطلاب",
                                    primaryYellow,
                                    isDark,
                                    () => setModalState(() => selectedReportType = "أداء الطلاب"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTypeCard(
                                    isAr ? "نسب الحضور" : "Attendance Rates",
                                    Icons.person_search_outlined,
                                    selectedReportType == "نسب الحضور",
                                    primaryYellow,
                                    isDark,
                                    () => setModalState(() => selectedReportType = "نسب الحضور"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Text(isAr ? "معايير التصفية والتاريخ" : "Filter Criteria & Date", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildFilterDropdown(
                                    isAr ? "القسم / المرحلة" : "Department / Stage",
                                    departments,
                                    selectedDept,
                                    (v) => setModalState(() => selectedDept = v!),
                                    isDark,
                                    labelMapper: _getDeptLabel,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFilterDropdown(
                                    isAr ? "الدورة / العام الدراسي" : "Program / Academic Year",
                                    years,
                                    selectedYear,
                                    (v) => setModalState(() => selectedYear = v!),
                                    isDark,
                                    labelMapper: _getYearLabel,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFilterDropdown(
                                    isAr ? "الفصل الدراسي" : "Semester",
                                    semesters,
                                    selectedSemester,
                                    (v) => setModalState(() => selectedSemester = v!),
                                    isDark,
                                    labelMapper: _getSemesterLabel,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDatePicker(
                                          isAr ? "من تاريخ" : "From Date",
                                          fromDate,
                                          (date) => setModalState(() => fromDate = date),
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildDatePicker(
                                          isAr ? "إلى تاريخ" : "To Date",
                                          toDate,
                                          (date) => setModalState(() => toDate = date),
                                          isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        final newId = DateTime.now().millisecondsSinceEpoch;
                        final typeLabel = selectedReportType == "نسب الحضور"
                            ? (isAr ? "نسب الحضور" : "Attendance")
                            : (isAr ? "أداء الطلاب" : "Performance");
                        final deptLabel = _getDeptLabel(selectedDept);
                        final newTitle = isAr ? "تقرير $typeLabel - $deptLabel" : "$typeLabel Report - $deptLabel";
                        setState(() {
                          _reportsLog.insert(0, {
                            "id": newId,
                            "title": newTitle,
                            "report_type": selectedReportType == "نسب الحضور" ? "attendance" : "performance",
                            "created_at": "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
                            "status": isAr ? "مكتمل" : "Completed",
                          });
                        });
                        Navigator.pop(context);
                        _showGeneratedReportOptions(newId, newTitle);
                      },
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                      label: Text(
                        isAr ? "توليد التقرير وتنزيله" : "Generate & Download Report",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? "سجل التقارير والإحصائيات" : "Reports & Statistics Log"),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              icon: Icon(Icons.settings_outlined, color: primaryYellow, size: 28),
              tooltip: isAr ? "الإعدادات" : "Settings",
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reportsLog.isEmpty
                      ? Center(child: Text(isAr ? "لا يوجد تقارير محفوظة" : "No saved reports"))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 140),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? "التقارير المحفوظة (${_reportsLog.length})" : "Saved Reports (${_reportsLog.length})",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _reportsLog.length,
                                itemBuilder: (context, index) {
                                  final item = _reportsLog[index];
                                  final typeStr = item['report_type'] == 'attendance'
                                      ? (isAr ? 'نسب الحضور' : 'Attendance')
                                      : (isAr ? 'أداء الطلاب' : 'Performance');
                                  final dateStr = item['created_at'].toString().split(' ')[0];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: primaryYellow.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                typeStr,
                                                style: TextStyle(
                                                  color: isDark ? primaryYellow : Colors.black87,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isAr ? "جاهز للتنزيل" : "Ready to download",
                                                style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item['title'] ?? (isAr ? 'بدون عنوان' : 'Untitled'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                            const Spacer(),
                                            ElevatedButton.icon(
                                              onPressed: () => _download(item['id'], 'pdf', item['title'] ?? ''),
                                              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                                              label: const Text("PDF", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () => _download(item['id'], 'excel', item['title'] ?? ''),
                                              icon: const Icon(Icons.table_chart, size: 16, color: Colors.white),
                                              label: const Text("Excel", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blueAccent,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
            ),

            // 🌟 زر الزائد (+) العائم في أسفل الشاشة 🌟
            Positioned(
              bottom: 100,
              left: isAr ? 20 : null,
              right: isAr ? null : 20,
              child: GestureDetector(
                onTap: () => _showCreateReportModal(context, isDark, primaryYellow),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 30),
                ),
              ),
            ),

            // الشريط السفلي الأصلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => _navigateToNavScreen(0),
              onMessagesTap: () => _navigateToNavScreen(1),
              onNotificationsTap: () => _navigateToNavScreen(2),
              onProfileTap: () => _navigateToNavScreen(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String label, IconData icon, bool isSelected, Color yellow, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? yellow : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: isSelected ? yellow.withValues(alpha: 0.2) : Colors.grey.shade100,
                  child: Icon(icon, color: isSelected ? Colors.black : Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: isAr ? 8 : null,
              left: isAr ? null : 8,
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

  Widget _buildFilterDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
    bool isDark, {
    String Function(String)? labelMapper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 5, left: 5, bottom: 4),
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(labelMapper != null ? labelMapper(e) : e, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onPicked, bool isDark) {
    final formattedDate = date == null
        ? (isAr ? "اختر التاريخ" : "Select Date")
        : "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: date != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey),
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