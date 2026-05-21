import 'package:flutter/material.dart';
// استيراد الشاشات والقطع الموحدة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../../widgets/parents_center_icon.dart';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentsAssignmentsScreen extends StatefulWidget {
  const ParentsAssignmentsScreen({super.key});

  @override
  State<ParentsAssignmentsScreen> createState() => _ParentsAssignmentsScreenState();
}

class _ParentsAssignmentsScreenState extends State<ParentsAssignmentsScreen> {
  List<dynamic> assignments = [];
  bool isLoading = true;
  String selectedFilter = "الكل"; // الكل، المكتملة، فائتة

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? sId = prefs.getInt('selected_student_id');
      String? token = prefs.getString('token');

      if (sId != null && token != null) {
        var response = await Dio().get(
          "${ApiService().baseUrl}/parent/student/$sId/assignments",
          options: Options(headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token"
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            assignments = response.data;
            isLoading = false;
          });
        }
      } else {
         setState(() => isLoading = false);
      }
    } catch (e) {
      print("خطأ في جلب الواجبات: $e");
      setState(() => isLoading = false);
    }
  }
  Widget build(BuildContext context) {
    // 🎨 ألوان متجاوبة مع الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            Column(
              children: [
                _buildFilterBar(textColor),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFEFFF00)))
                      : assignments.isEmpty
                          ? const Center(child: Text("لا توجد واجبات لعرضها"))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              itemCount: assignments.length,
                              itemBuilder: (context, index) {
                                var item = assignments[index];
                                // فلترة الواجبات
                                if (selectedFilter == "المكتملة" && item['status'] != "مكتملة") return const SizedBox.shrink();
                                if (selectedFilter == "فائتة" && item['status'] != "فائتة") return const SizedBox.shrink();

                                // تحويل نسبة العلامة (مؤقتاً)
                                double progress = item['status'] == "مكتملة" ? 1.0 : (item['status'] == "فائتة" ? 0.0 : 0.5);

                                return _taskCard(
                                  context: context,
                                  title: item['title'] ?? "واجب",
                                  subtitle: item['course_name'] ?? "مادة",
                                  status: item['status'] ?? "جاري",
                                  progress: progress,
                                  date: item['due_date']?.toString().substring(0, 10) ?? "غير محدد",
                                  icon: Icons.assignment_outlined,
                                  iconColor: item['status'] == "مكتملة" ? Colors.green : (item['status'] == "فائتة" ? Colors.red : Colors.blue),
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  grade: item['grade'] != null ? "${item['grade']}/${item['max_points']}" : null,
                                  isOverdue: item['status'] == "فائتة",
                                );
                              },
                            ),
                ),
              ],
            ),

            // الشريط السفلي الموحد المستخدم في Edu_Bridge
            CustomBottomNav(
              currentIndex: 0, // تتبع للرئيسية أو اتركها بدون تظليل حسب التصميم
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

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "واجبات ومشاريع الطالبة",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(onTap: () => setState(() => selectedFilter = "الكل"), child: _filterChip("الكل", selectedFilter == "الكل", textColor)),
            GestureDetector(onTap: () => setState(() => selectedFilter = "المكتملة"), child: _filterChip("المكتملة", selectedFilter == "المكتملة", textColor)),
            GestureDetector(onTap: () => setState(() => selectedFilter = "فائتة"), child: _filterChip("فائتة", selectedFilter == "فائتة", textColor)),
          ],
        ),
      ),
    );
  }

  Widget _taskCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String status,
    required double progress,
    required String date,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color textColor,
    bool hasAttachment = false,
    String? grade,
    bool isOverdue = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isOverdue ? Colors.red.withValues(alpha: 0.2) : textColor.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 15),
          if (progress > 0 && progress < 1.0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: progress,
                  color: Colors.blue,
                  backgroundColor: textColor.withValues(alpha: 0.05),
                  minHeight: 6
              ),
            ),
            const SizedBox(height: 15),
          ],
          Divider(height: 1, color: textColor.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: isOverdue ? Colors.red : (status == "مكتملة" ? Colors.green : Colors.grey),
                  fontSize: 12,
                ),
              ),
              if (hasAttachment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, size: 14, color: textColor.withValues(alpha: 0.6)),
                      const Text(" 3 مرفقات", style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              if (grade != null)
                Text(grade, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              if (isOverdue)
                const Text("طلب تمديد ←", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label) {
    Color bg = Colors.yellow.withValues(alpha: 0.1);
    Color txtColor = Colors.orange;
    if (label == "مكتملة") {
      bg = Colors.green.withValues(alpha: 0.1);
      txtColor = Colors.green;
    }
    if (label == "فائتة") {
      bg = Colors.red.withValues(alpha: 0.1);
      txtColor = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: txtColor)),
    );
  }

  Widget _filterChip(String label, bool isSel, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: isSel ? const Color(0xFFEFFF00) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isSel ? Colors.transparent : textColor.withValues(alpha: 0.1)),
      ),
      child: Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSel ? Colors.black : textColor.withValues(alpha: 0.6)
          )
      ),
    );
  }
}