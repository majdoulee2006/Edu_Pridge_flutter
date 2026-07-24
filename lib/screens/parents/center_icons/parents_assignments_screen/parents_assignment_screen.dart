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
  @override
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
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                      : assignments.isEmpty
                          ? const Center(child: Text("لا توجد واجبات لعرضها"))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              itemCount: assignments.length,
                              itemBuilder: (context, index) {
                                var item = assignments[index];
                                // فلترة الواجبات
                                if (selectedFilter == "المكتملة" && item['status'] != "مكتملة" && item['status'] != "مصحح") return const SizedBox.shrink();
                                if (selectedFilter == "فائتة" && item['status'] != "فائتة") return const SizedBox.shrink();

                                // تحويل نسبة العلامة (مؤقتاً)
                                double progress = (item['status'] == "مكتملة" || item['status'] == "مصحح") ? 1.0 : (item['status'] == "فائتة" ? 0.0 : 0.5);

                                return _taskCard(
                                   context: context,
                                   title: item['title'] ?? "واجب",
                                   subtitle: item['course_name'] ?? "مادة",
                                   status: item['status'] ?? "جاري",
                                   progress: progress,
                                   date: item['due_date']?.toString().substring(0, 10) ?? "غير محدد",
                                   icon: Icons.assignment_outlined,
                                   iconColor: (item['status'] == "مكتملة" || item['status'] == "مصحح") ? Colors.green : (item['status'] == "فائتة" ? Colors.red : Colors.blue),
                                   cardColor: cardColor,
                                   textColor: textColor,
                                   grade: item['grade'] != null ? "${item['grade']}/${item['max_points']}" : null,
                                   isOverdue: item['status'] == "فائتة",
                                   onTap: () => _showAssignmentDetailsBottomSheet(context, item),
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
          icon: Icon(Icons.arrow_back, color: textColor),
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  color: isOverdue ? Colors.red : ((status == "مكتملة" || status == "مصحح") ? Colors.green : Colors.grey),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (status == "مصحح" ? const Color(0xFFFFCC00) : textColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: status == "مصحح" ? Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.4), width: 1) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == "مصحح" ? Icons.star_rounded : Icons.info_outline,
                      color: status == "مصحح" ? const Color(0xFFCCAA00) : textColor.withValues(alpha: 0.6),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status == "مصحح" ? "عرض الدرجة" : "تفاصيل الواجب",
                      style: TextStyle(
                        color: status == "مصحح" ? const Color(0xFFCCAA00) : textColor.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _statusBadge(String label) {
    Color bg = Colors.yellow.withValues(alpha: 0.1);
    Color txtColor = Colors.orange;
    if (label == "مكتملة" || label == "مصحح") {
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
        color: isSel ? const Color(0xFFFFCC00) : Colors.transparent,
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

  void _showAssignmentDetailsBottomSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final txtColor = isDark ? Colors.white : Colors.black;
        
        final grade = item['grade'];
        final maxPoints = item['max_points'] ?? 100;
        final status = item['status'] ?? "جاري";
        final title = item['title'] ?? "واجب";
        final courseName = item['course_name'] ?? "مادة";
        final dueDate = item['due_date']?.toString().substring(0, 10) ?? "غير محدد";
        final feedback = item['feedback'];
        final submittedAt = item['submitted_at']?.toString().substring(0, 10);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_outlined, color: Color(0xFFFFCC00), size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: txtColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          courseName,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildDetailRow(context, Icons.info_outline, "الحالة", status, isStatus: true),
              const SizedBox(height: 15),
              _buildDetailRow(context, Icons.calendar_today_outlined, "تاريخ التسليم الأقصى", dueDate),
              if (submittedAt != null) ...[
                const SizedBox(height: 15),
                _buildDetailRow(context, Icons.check_circle_outline, "تاريخ تقديم الواجب", submittedAt),
              ],
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 15),
              Text(
                "علامة الواجب",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: txtColor,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 12),
              if (grade != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFCC00), size: 36),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$grade / $maxPoints",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFFDD44) : const Color(0xFFCCAA00),
                            ),
                          ),
                          const Text(
                            "درجة الطالبة",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (feedback != null && feedback.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Text(
                    "ملاحظات المعلم",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: txtColor,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      feedback.toString(),
                      style: TextStyle(color: txtColor.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: Colors.grey, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        "لم يتم رصد العلامة بعد",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "إغلاق",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isStatus = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        isStatus
            ? _statusBadge(value)
            : Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
      ],
    );
  }
}