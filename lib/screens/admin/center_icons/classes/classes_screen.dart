import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';

// استيراد شاشات الشريط السفلي
import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/messages_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String? selectedDept;
  String? selectedCourse;
  String selectedYear = "2023 - 2024";
  int selectedSemesterIndex = 0;

  final Map<String, List<String>> dataMap = {
    "قسم الكومبيوتر ونظم المعلومات": ["المعلوماتية", "الاتصالات", "الالكترون", "الذكاء الصناعي"],
    "قسم الطبي": ["المخبري", "الصيدلة"],
    "إدارة الأعمال": ["المحاسبة", "التسويق"],
  };

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("الفصول الدراسية والمواد", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))],
        ),

        body: Stack(
          children: [
            // المحتوى الرئيسي
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // حاوية الفلاتر
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _buildLabel("القسم", textColor),
                        _buildDropdown(
                          hint: "اختر القسم",
                          value: selectedDept,
                          items: dataMap.keys.toList(),
                          onChanged: (val) => setState(() {
                            selectedDept = val;
                            selectedCourse = null;
                          }),
                          isDark: isDark,
                          cardColor: cardColor,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("السنة", textColor),
                                  _buildDropdown(
                                    hint: "السنة",
                                    value: selectedYear,
                                    items: ["2023 - 2024", "2024 - 2025"],
                                    onChanged: (val) => setState(() => selectedYear = val!),
                                    isDark: isDark,
                                    cardColor: cardColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("الدورة", textColor),
                                  _buildDropdown(
                                    hint: "اختر الدورة",
                                    value: selectedCourse,
                                    items: selectedDept != null ? dataMap[selectedDept]! : [],
                                    onChanged: (val) => setState(() => selectedCourse = val),
                                    isDark: isDark,
                                    cardColor: cardColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // تبديل الفصول
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _buildSemesterTab("فصل أول", 0, primaryYellow),
                        _buildSemesterTab("فصل ثاني", 1, primaryYellow),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("المواد الدراسية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      Text("4 مواد", style: TextStyle(color: Colors.blue.shade300, fontSize: 12)),
                    ],
                  ),

                  const SizedBox(height: 15),

                  _buildSubjectCard("الرياضيات المتقدمة", "د. أحمد المنصور", Icons.calculate_outlined, Colors.blue.shade50, cardColor, textColor),
                  _buildSubjectCard("أساسيات البرمجة", "م. سارة العلي", Icons.code_rounded, Colors.purple.shade50, cardColor, textColor),
                  _buildSubjectCard("قواعد البيانات", "د. خالد يوسف", Icons.storage_rounded, Colors.green.shade50, cardColor, textColor),
                  _buildSubjectCard("اللغة الإنجليزية التقنية", "أ. ليلى الشمري", Icons.language_rounded, Colors.orange.shade50, cardColor, textColor),

                  const SizedBox(height: 160), // مسافة إضافية للشريط السفلي
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

  // ====================== الدوال المُحدثة ======================
  Widget _buildLabel(String text, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 5, right: 5),
    child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey)),
  );

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          isExpanded: true,
          dropdownColor: cardColor,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSemesterTab(String label, int index, Color yellow) {
    bool isSelected = selectedSemesterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSemesterIndex = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String title, String teacher, IconData icon, Color iconBg, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              Row(
                children: [
                  Text(teacher, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 5),
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}