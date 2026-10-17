import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class TeacherParentSummonScreen extends StatefulWidget {
  const TeacherParentSummonScreen({super.key});

  @override
  State<TeacherParentSummonScreen> createState() => _TeacherParentSummonScreenState();
}

class _TeacherParentSummonScreenState extends State<TeacherParentSummonScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoadingStudents = true;
  bool _isLoadingHistory = true;
  bool _isSubmitting = false;

  List<dynamic> _students = [];
  dynamic _selectedStudent;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  late TabController _tabController;
  List<dynamic> _summonsHistory = [];
  String _currentFilter = 'all'; // all, pending, completed

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) _currentFilter = 'all';
        if (_tabController.index == 1) _currentFilter = 'pending';
        if (_tabController.index == 2) _currentFilter = 'completed';
        _fetchHistory();
      }
    });

    _fetchStudents();
    _fetchHistory();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _reasonController.dispose();
    _detailsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    final data = await _apiService.getEducatorStudents();
    if (mounted) {
      setState(() {
        _students = data ?? [];
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    final data = await _apiService.getTeacherSummonsHistory(status: _currentFilter);
    if (mounted) {
      setState(() {
        _summonsHistory = data ?? [];
        _isLoadingHistory = false;
      });
    }
  }

  void _showNewSummonModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isAr = AppSettings.language.value == 'ar';
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textClr = isDark ? Colors.white : AppColors.textDark;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        isAr ? "استدعاء ولي أمر طالب" : "Summon Student's Parent",
                        style: TextStyle(color: textClr, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _isLoadingStudents
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<dynamic>(
                              initialValue: _selectedStudent,
                              decoration: InputDecoration(
                                labelText: isAr
                                    ? "اختر الطالب (من دوراتي/مجموعاتي)"
                                    : "Select Student (From my courses/groups)",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _students.map((st) {
                                return DropdownMenuItem<dynamic>(
                                  value: st,
                                  child: Text("${st['student_name']} (${st['department_name'] ?? ''})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() => _selectedStudent = val);
                                setState(() => _selectedStudent = val);
                              },
                            ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: isAr ? "سبب الاستدعاء (العنوان)" : "Summon Reason (Title)",
                          hintText: isAr
                              ? "مثال: مراجعة بخصوص تحصيل الطالب الأكاديمي"
                              : "e.g. Review regarding academic progress",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _detailsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? "التفاصيل والملاحظات لمربي الدورة / رئيس القسم"
                              : "Details & notes for course advisor / dept head",
                          hintText: isAr ? "اكتب التفاصيل الكاملة هنا..." : "Write full details here...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  if (_selectedStudent == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr ? "يرجى اختيار طالب أولاً" : "Please select a student first",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (_reasonController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr ? "يرجى كتابة سبب الاستدعاء" : "Please enter summon reason",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => _isSubmitting = true);
                                  final ok = await _apiService.requestTeacherParentSummon(
                                    _selectedStudent['student_id'],
                                    _reasonController.text.trim(),
                                    _detailsController.text.trim(),
                                  );
                                  setModalState(() => _isSubmitting = false);

                                  if (ok && mounted && context.mounted) {
                                    Navigator.pop(context);
                                    _reasonController.clear();
                                    _detailsController.clear();
                                    _selectedStudent = null;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAr
                                              ? "تم إرسال الطلب إلى رئيس القسم بنجاح"
                                              : "Summon request sent to Department Head successfully",
                                        ),
                                      ),
                                    );
                                    _fetchHistory();
                                  }
                                },
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Icon(Icons.send, color: Colors.black),
                          label: Text(
                            _isSubmitting
                                ? (isAr ? "جاري الإرسال..." : "Sending...")
                                : (isAr ? "إرسال لرئيس القسم" : "Send to Dept Head"),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status, bool isAr) {
    if (status == 'sent' || status == 'approved' || status == 'completed') {
      return {
        'color': Colors.green,
        'icon': Icons.check_circle,
        'text': isAr ? 'تم الإرسال للأهل' : 'Sent to Parents',
      };
    } else if (status == 'pending_affairs') {
      return {
        'color': Colors.blue,
        'icon': Icons.sync,
        'text': isAr ? 'محوّل للشؤون' : 'Referred to Affairs',
      };
    } else if (status == 'rejected' || status == 'cancelled') {
      return {
        'color': Colors.red,
        'icon': Icons.cancel,
        'text': isAr ? 'ملغى' : 'Cancelled',
      };
    } else {
      return {
        'color': Colors.orange,
        'icon': Icons.hourglass_empty,
        'text': isAr ? 'بانتظار موافقة رئيس القسم' : 'Awaiting Dept Head Approval',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            isAr ? "استدعاء أولياء الأمور (مربي الدورة)" : "Parent Summon (Course Advisor)",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_back : Icons.arrow_back_ios_new,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFFCC00),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFFCC00),
            tabs: [
              Tab(text: isAr ? "الكل" : "All"),
              Tab(text: isAr ? "المعلقة" : "Pending"),
              Tab(text: isAr ? "المنتهية" : "Completed"),
            ],
          ),
        ),
        body: Stack(
          children: [
            _isLoadingHistory
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : _summonsHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_ind_outlined, size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              isAr ? "لا توجد استدعاءات في هذا الفلتر" : "No summon requests found in this filter",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        color: const Color(0xFFFFCC00),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _summonsHistory.length,
                          itemBuilder: (context, index) {
                            final item = _summonsHistory[index];
                            final st = _getStatusConfig(item['status'] ?? '', isAr);

                            return Card(
                              color: cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "${isAr ? "الطالب: " : "Student: "}${item['student_name'] ?? (isAr ? 'غير محدد' : 'Unspecified')}",
                                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: st['color'].withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(st['icon'], color: st['color'], size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                st['text'],
                                                style: TextStyle(color: st['color'], fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${isAr ? "السبب: " : "Reason: "}${item['reason_title'] ?? ''}",
                                      style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    if (item['details'] != null && item['details'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item['details'],
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      "${isAr ? "تاريخ الطلب: " : "Request Date: "}${item['created_at'] ?? ''}",
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 75.0),
          child: FloatingActionButton(
            heroTag: 'add_parent_summon_fab',
            backgroundColor: const Color(0xFFFFCC00),
            foregroundColor: Colors.black,
            elevation: 4,
            onPressed: _showNewSummonModal,
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
        floatingActionButtonLocation: isAr ? FloatingActionButtonLocation.startFloat : FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
