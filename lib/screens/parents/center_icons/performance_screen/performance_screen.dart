import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  String studentName = "";
  Map<String, dynamic>? data;
  bool isLoading = true;
  int? studentId;

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _fetchPerformanceData();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  Future<void> _fetchPerformanceData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      int? sId = prefs.getInt('selected_student_id');
      studentId = sId;
      String? token = prefs.getString('token');
      studentName = prefs.getString('selected_student_name') ?? "";

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

  void _showJustifyAbsenceDialog(String date, String subjectName) {
    final bool isAr = AppSettings.language.value == 'ar';
    TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(isAr ? 'تبرير غياب' : 'Justify Absence', style: const TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isAr
                          ? 'الرجاء إدخال سبب الغياب لمادة $subjectName بتاريخ $date:'
                          : 'Please enter reason for absence in $subjectName on $date:'),
                      const SizedBox(height: 15),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: isAr ? 'مثال: عذر طبي...' : 'e.g., Medical excuse...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          );
                          if (result != null) {
                            setStateDialog(() {
                              selectedFile = File(result.files.single.path!);
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(selectedFile != null
                            ? (isAr ? 'تم إرفاق ملف' : 'File attached')
                            : (isAr ? 'إرفاق تقرير طبي أو صورة' : 'Attach medical report or image')),
                      ),
                      if (selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(selectedFile!.path.split('/').last.split('\\').last, style: const TextStyle(fontSize: 12, color: Colors.green)),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(context),
                    child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (reasonController.text.trim().isEmpty) return;
                            setStateDialog(() => isSubmitting = true);
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              String? token = prefs.getString('token');

                              FormData formData = FormData.fromMap({
                                "student_id": studentId,
                                "type": "justification",
                                "date": date,
                                "subject_name": subjectName,
                                "reason": reasonController.text.trim(),
                              });

                              if (selectedFile != null) {
                                formData.files.add(MapEntry(
                                  "attachment",
                                  await MultipartFile.fromFile(selectedFile!.path, filename: selectedFile!.path.split('/').last.split('\\').last),
                                ));
                              }

                              var res = await Dio().post(
                                "${ApiService().baseUrl}/parent/leave-requests/submit",
                                data: formData,
                                options: Options(headers: {
                                  "Accept": "application/json",
                                  "Authorization": "Bearer $token"
                                }),
                              );
                              if (res.statusCode == 200 || res.statusCode == 201) {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تم إرسال تبرير الغياب بنجاح!' : 'Absence justification sent successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setStateDialog(() => isSubmitting = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? 'حدث خطأ أثناء الإرسال' : 'Error occurred while sending'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text(isAr ? 'إرسال' : 'Submit', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGradeDialog(Map<String, dynamic> item, Color col) {
    final bool isAr = AppSettings.language.value == 'ar';
    final exams = (item['exams'] as List?) ?? [];
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              CircleAvatar(backgroundColor: col.withValues(alpha: 0.1), child: Icon(Icons.book, color: col, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16))),
            ],
          ),
          content: exams.isEmpty
              ? Text(isAr ? "لا توجد تفاصيل للاختبارات" : "No exam details available", style: TextStyle(color: textColor.withValues(alpha: 0.5)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: exams.map<Widget>((e) {
                    final examName = e['exam_name'] ?? (isAr ? 'اختبار' : 'Exam');
                    final score = (e['score'] as num?)?.toDouble() ?? 0.0;
                    final max = (e['max_score'] as num?)?.toInt() ?? 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(examName, style: TextStyle(color: textColor, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text("$score/$max", style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? "إغلاق" : "Close", style: TextStyle(color: col, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final bool isAr = AppSettings.language.value == 'ar';

    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: _buildMainAppBar(context, textColor, cardColor, isAr),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
              : Stack(
                  children: [
                    Positioned.fill(
                      child: TabBarView(
                        children: [
                          _buildResultsTab(textColor, cardColor, isAr),
                          _buildGradesTab(textColor, cardColor, isAr),
                          _buildAttendanceTab(textColor, cardColor, isAr),
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
      ),
    );
  }

  PreferredSizeWidget _buildMainAppBar(BuildContext context, Color textColor, Color cardColor, bool isAr) {
    final String displayName = studentName.isNotEmpty ? studentName : (isAr ? "الطالب" : "Student");
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text("${isAr ? 'أداء' : 'Performance of'} $displayName", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: textColor), onPressed: () => Navigator.pop(context)),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(35)),
          child: TabBar(
            indicator: BoxDecoration(color: const Color(0xFFFFCC00), borderRadius: BorderRadius.circular(30)),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: isAr ? "النتائج" : "Results"),
              Tab(text: isAr ? "العلامات" : "Grades"),
              Tab(text: isAr ? "الحضور" : "Attendance"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTab(Color textColor, Color cardColor, bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildGpaCard(data?['gpa']?.toString() ?? "0.0", textColor, cardColor, isAr),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard(isAr ? "الحضور" : "Attendance", "${data?['attendance_rate'] ?? 0}%", Icons.check_circle, Colors.green, textColor, cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildSmallStatCard(isAr ? "الغياب" : "Absence", "${data?['absent_count'] ?? 0} ${isAr ? 'يوم' : 'days'}", Icons.cancel, Colors.red, textColor, cardColor)),
          ],
        ),
        const SizedBox(height: 30),
        if (data?['grades'] != null)
          ...(data!['grades'] as List).take(2).map((item) {
            return _buildSubjectResultCard(item['name'] ?? "", "${item['score'] ?? 0}", Colors.blue, cardColor, textColor);
          }),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildGradesTab(Color textColor, Color cardColor, bool isAr) {
    List grades = data?['grades'] ?? [];
    if (grades.isEmpty) return Center(child: Text(isAr ? "لا توجد علامات حالياً" : "No grades available currently"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final item = grades[index] as Map<String, dynamic>;
        final col = index % 2 == 0 ? Colors.blue : Colors.orange;
        return _buildGradeDetailCard(item, "${item['score'] ?? 0}%", col, textColor, cardColor, isAr);
      },
    );
  }

  Widget _buildAttendanceTab(Color textColor, Color cardColor, bool isAr) {
    List logs = data?['attendance_logs'] ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildAttendanceCircleCard("${data?['attendance_rate'] ?? 0}%", isAr ? "حضور" : "Attendance", Colors.green, textColor, cardColor)),
            const SizedBox(width: 15),
            Expanded(child: _buildAttendanceCircleCard("${(100 - (data?['attendance_rate'] ?? 0))}%", isAr ? "غياب" : "Absence", Colors.red, textColor, cardColor)),
          ],
        ),
        const SizedBox(height: 25),
        if (logs.isEmpty) Center(child: Text(isAr ? "لا توجد سجلات حضور" : "No attendance records")),
        ...logs.map((log) {
          final status = log['status']?.toString().toLowerCase() ?? '';
          String statusText = isAr ? 'غائب' : 'Absent';
          Color statusColor = Colors.red;
          if (status == 'present' || status == 'حاضر') {
            statusText = isAr ? 'حاضر' : 'Present';
            statusColor = Colors.green;
          } else if (status == 'late' || status == 'متأخر') {
            statusText = isAr ? 'متأخر' : 'Late';
            statusColor = Colors.amber;
          } else if (status == 'pending' || status == 'قيد الانتظار') {
            statusText = isAr ? 'قيد الانتظار' : 'Pending';
            statusColor = Colors.orange;
          }
          final bool isAbsent = status == 'absent' || status == 'غائب' || statusText == (isAr ? 'غائب' : 'Absent');

          return _buildLectureRow(
            log['attendance_date']?.toString().split('-').last ?? "00",
            isAr ? "الشهر" : "Month",
            log['name'] ?? "",
            statusText,
            statusColor,
            textColor,
            cardColor,
            onTap: isAbsent ? () => _showJustifyAbsenceDialog(log['attendance_date'].toString().split(' ')[0], log['name'] ?? "") : null,
          );
        }),
        const SizedBox(height: 150),
      ],
    );
  }

  Widget _buildGpaCard(String gpaValue, Color textColor, Color cardColor, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(35)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isAr ? "المعدل التراكمي" : "Cumulative GPA", style: TextStyle(color: textColor.withValues(alpha: 0.5))),
              Text(gpaValue, style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          CircularProgressIndicator(
            value: (double.tryParse(gpaValue) ?? 0) / 4,
            strokeWidth: 8,
            color: const Color(0xFFFFCC00),
            backgroundColor: textColor.withValues(alpha: 0.1),
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
          Text(t, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
          Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildGradeDetailCard(Map<String, dynamic> item, String percent, Color col, Color textColor, Color cardColor, bool isAr) {
    return GestureDetector(
      onTap: () => _showGradeDialog(item, col),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: col.withValues(alpha: 0.1), child: Icon(Icons.book, color: col, size: 18)),
            const SizedBox(width: 15),
            Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            Text(percent, style: TextStyle(color: col, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(isAr ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios, size: 12, color: textColor.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureRow(String day, String month, String subject, String status, Color col, Color textColor, Color cardColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            Column(children: [
              Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
              Text(month, style: const TextStyle(fontSize: 10, color: Colors.blue)),
            ]),
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
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }
}
