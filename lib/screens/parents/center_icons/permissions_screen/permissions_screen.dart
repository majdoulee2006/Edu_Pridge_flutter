import 'package:flutter/material.dart';
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

class PermissionsScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;
  const PermissionsScreen({super.key, this.studentId, this.studentName});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<dynamic> permissions = [];
  List<dynamic> children = [];
  bool isLoading = true;

  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _fetchPermissions();
    _fetchChildren();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchPermissions() async {
    try {
      final token = await _getToken();
      if (token.isEmpty) { setState(() => isLoading = false); return; }

      final url = widget.studentId != null
          ? "${ApiService().baseUrl}/parent/leave-requests?student_id=${widget.studentId}"
          : "${ApiService().baseUrl}/parent/leave-requests";

      var response = await Dio().get(
        url,
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          permissions = response.data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("خطأ في جلب الأذونات: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchChildren() async {
    try {
      final token = await _getToken();
      if (token.isEmpty) return;
      final res = await Dio().get(
        "${ApiService().baseUrl}/parent/children",
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true && mounted) {
        setState(() => children = res.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint("خطأ في جلب الأبناء: $e");
    }
  }

  Future<void> _respondToPermission(int requestId, String status) async {
    try {
      final token = await _getToken();
      var response = await Dio().post(
        "${ApiService().baseUrl}/parent/leave-requests/$requestId/respond",
        data: {"status": status},
        options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && mounted) {
        final approvedText = isAr ? 'تمت الموافقة ✓' : 'Approved ✓';
        final rejectedText = isAr ? 'تم الرفض' : 'Rejected';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? approvedText : rejectedText),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _fetchPermissions();
      }
    } catch (e) {
      debugPrint("Error responding to permission: $e");
    }
  }

  void _showNewLeaveRequestDialog() {
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? "لا يوجد أبناء مرتبطون بحسابك" : "No children linked to your account")),
      );
      return;
    }

    int? selectedStudentId = children.isNotEmpty ? (children[0]['student_id'] as int?) : null;
    String selectedType = 'full_day';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cardColor = Theme.of(context).cardColor;
          final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAr ? "طلب إجازة جديد" : "New Leave Request",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 20),

                    // Child selector
                    Text(
                      isAr ? "الابن" : "Child",
                      style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedStudentId,
                          isExpanded: true,
                          items: children.map<DropdownMenuItem<int>>((c) {
                            return DropdownMenuItem<int>(
                              value: c['student_id'] as int?,
                              child: Text(c['full_name'] ?? (isAr ? 'طالب' : 'Student'), style: TextStyle(color: textColor)),
                            );
                          }).toList(),
                          onChanged: (v) => setModalState(() => selectedStudentId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type selector
                    Text(
                      isAr ? "نوع الإجازة" : "Leave Type",
                      style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'full_day'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedType == 'full_day' ? const Color(0xFFFFCC00) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? "يوم كامل" : "Full Day",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedType == 'full_day' ? Colors.black : textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'hourly'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedType == 'hourly' ? const Color(0xFFFFCC00) : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  isAr ? "ساعية" : "Hourly",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedType == 'hourly' ? Colors.black : textColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date & Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? "التاريخ" : "Date",
                                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (picked != null) setModalState(() => selectedDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 18, color: textColor.withValues(alpha: 0.5)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                                          style: TextStyle(color: textColor, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? "الوقت/الساعة" : "Time/Hour",
                                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final pickedTime = await showTimePicker(
                                    context: ctx,
                                    initialTime: selectedTime,
                                  );
                                  if (pickedTime != null) {
                                    if (pickedTime.hour > 15 || (pickedTime.hour == 15 && pickedTime.minute > 0)) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isAr
                                                  ? 'عذراً، يجب أن يكون وقت الإذن قبل انتهاء الدوام الرسمي (الساعة 3:00 عصراً)'
                                                  : 'Sorry, leave time must be before official school hours end (3:00 PM)',
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      setModalState(() => selectedTime = pickedTime);
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 18, color: textColor.withValues(alpha: 0.5)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                                          style: TextStyle(color: textColor, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Reason
                    Text(
                      isAr ? "السبب" : "Reason",
                      style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        hintText: isAr ? "اكتب سبب الإجازة..." : "Enter leave reason...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          if (selectedStudentId == null) return;
                          if (reasonController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isAr ? "يرجى كتابة سبب الإجازة" : "Please enter the leave reason")),
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final token = await _getToken();
                            final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                            final timeStr = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
                            await Dio().post(
                              "${ApiService().baseUrl}/parent/leave-requests/submit",
                              data: {
                                "student_id": selectedStudentId,
                                "type": selectedType,
                                "date": dateStr,
                                "time": timeStr,
                                "reason": reasonController.text.trim(),
                              },
                              options: Options(headers: {"Accept": "application/json", "Authorization": "Bearer $token"}),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(isAr ? "✅ تم إرسال طلب الإجازة بنجاح" : "✅ Leave request submitted successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchPermissions();
                            }
                          } on DioException catch (e) {
                            setModalState(() => isSubmitting = false);
                            final msg = e.response?.data['message'] ?? (isAr ? "حدث خطأ، حاول مجدداً" : "An error occurred, try again");
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                isAr ? "إرسال الطلب" : "Submit Request",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : permissions.isEmpty
                    ? Center(child: Text(isAr ? "لا توجد أذونات مسجلة" : "No permissions recorded"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: permissions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == permissions.length) {
                            return Column(
                              children: [
                                const SizedBox(height: 20),
                                Center(
                                  child: Text(
                                    isAr ? "نهاية القائمة" : "End of list",
                                    style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 150),
                              ],
                            );
                          }

                          var item = permissions[index];
                          final String itemStatus = item['status'] ?? 'pending';

                          if (itemStatus == 'pending_parent') {
                            return _buildDetailedCard(item, cardColor, textColor);
                          } else if (itemStatus == 'pending_hod' || itemStatus == 'pending_affairs' || itemStatus == 'pending') {
                            String statusText = isAr ? 'قيد المراجعة' : 'Under Review';
                            if (itemStatus == 'pending_hod') {
                              statusText = isAr ? 'بانتظار رئيس القسم' : 'Awaiting HOD';
                            } else if (itemStatus == 'pending_affairs') {
                              statusText = isAr ? 'بانتظار شؤون الطلاب' : 'Awaiting Student Affairs';
                            }
                            return _buildSimpleCard(
                              title: item['student_name'] ?? (isAr ? 'طالب' : 'Student'),
                              date: item['date']?.toString().substring(0, 10) ?? "",
                              icon: Icons.hourglass_empty_rounded,
                              iconCol: Colors.orange,
                              cardColor: cardColor,
                              textColor: textColor,
                              statusText: statusText,
                              statusColor: Colors.orange,
                            );
                          } else {
                            final isApproved = itemStatus == 'approved';
                            return _buildSimpleCard(
                              title: item['student_name'] ?? (isAr ? 'طالب' : 'Student'),
                              date: item['date']?.toString().substring(0, 10) ?? "",
                              icon: isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                              iconCol: isApproved ? Colors.green : Colors.red,
                              cardColor: cardColor,
                              textColor: textColor,
                              statusText: isApproved ? (isAr ? 'موافق عليه' : 'Approved') : (isAr ? 'مرفوض' : 'Rejected'),
                              statusColor: isApproved ? Colors.green : Colors.red,
                            );
                          }
                        },
                      ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
            Positioned(
              bottom: 100,
              left: isAr ? 20 : null,
              right: isAr ? null : 20,
              child: FloatingActionButton(
                heroTag: "add_permission_btn",
                onPressed: _showNewLeaveRequestDialog,
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    final titleText = widget.studentName != null
        ? (isAr ? "أذونات ${widget.studentName}" : "${widget.studentName}'s Permissions")
        : (isAr ? "أذونات الطالب" : "Student Permissions");

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        titleText,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDetailedCard(dynamic item, Color cardColor, Color textColor) {
    final leaveTypeText = item['type'] == 'hourly'
        ? (isAr ? 'إجازة ساعية' : 'Hourly Leave')
        : (isAr ? 'إجازة يوم كامل' : 'Full Day Leave');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFFFCC00), width: 2),
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.event_note_outlined, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['student_name'] ?? (isAr ? 'طالب' : 'Student'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      Text(
                        leaveTypeText,
                        style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
              _statusTag(isAr ? "بانتظار موافقتك" : "Awaiting approval", Colors.orange),
            ],
          ),
          const SizedBox(height: 1),
          Text(item['date']?.toString().substring(0, 10) ?? "", style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(25)),
            child: Text(
              item['reason'] ?? (isAr ? "بدون سبب" : "No reason specified"),
              style: TextStyle(fontSize: 13, height: 1.5, color: textColor.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () => _respondToPermission(item['id'], 'rejected'),
                child: _actionBtn(isAr ? "رفض" : "Reject", Colors.red, isOutlined: true),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => _respondToPermission(item['id'], 'approved'),
                child: _actionBtn(isAr ? "موافقة" : "Approve", Colors.black, btnColor: const Color(0xFFFFCC00)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard({
    required String title, required String date, required IconData icon,
    required Color iconCol, required Color cardColor, required Color textColor,
    required String statusText, required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconCol.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconCol, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(date, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          _statusTag(statusText, statusColor),
        ],
      ),
    );
  }

  Widget _statusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(String label, Color textCol, {Color? btnColor, bool isOutlined = false}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: btnColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: isOutlined ? Border.all(color: textCol.withValues(alpha: 0.3)) : null,
      ),
      child: Center(child: Text(label, style: TextStyle(color: textCol, fontWeight: FontWeight.bold))),
    );
  }
}
