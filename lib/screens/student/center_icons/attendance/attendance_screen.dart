import 'package:flutter/material.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';

// استدعاء السيرفيس
import 'package:edu_pridge_flutter/services/student_services.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedTab = 0; // 0 = سجل الحضور، 1 = طلب إجازة
  int _leaveType = 0; // 0 = يوم كامل، 1 = ساعية
  
  bool _isLoading = true;
  List<dynamic> _attendanceList = [];
  

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();
  // ignore: unused_field
  bool _isSubmittingLeave = false;
  List<dynamic> _myLeaveRequests = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
    _initDefaultDateTime();
    _fetchMyLeaveRequests();
  }

  Future<void> _fetchMyLeaveRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final data = await StudentServices().getMyLeaveRequests();
      if (mounted) setState(() => _myLeaveRequests = data);
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoadingRequests = false); }
  }

  void _initDefaultDateTime() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    _dateController.text = "${now.year}-$month-$day";
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    _timeController.text = "$hour:$minute";
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _leaveReasonController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Future<void> _submitLeaveRequest() async {
    final reason = _leaveReasonController.text.trim();
    final date = _dateController.text.trim();
    if (date.isEmpty || reason.isEmpty || reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول (السبب 3 أحرف على الأقل)')),
      );
      return;
    }
    setState(() => _isSubmittingLeave = true);
    try {
      final type = _leaveType == 0 ? 'full_day' : 'hourly';
      final ok = await StudentServices().submitLeaveRequest(type, date, reason);
      if (ok && mounted) {
        _showSuccessDialog('تم إرسال طلبكم بنجاح\nالطلب قيد المعالجة حالياً');
        _initDefaultDateTime();
        _leaveReasonController.clear();
        _fetchMyLeaveRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، يرجى المحاولة مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingLeave = false);
    }
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentServices().getAttendance();
      if (data != null) {
        List<dynamic> uniqueData = [];
        Set<String> seen = {}; 
        
        for (var record in data) {
          String key = '${record['date']}_${record['course_name']}';
          if (!seen.contains(key)) {
            seen.add(key);
            uniqueData.add(record); 
          }
        }

        setState(() {
          _attendanceList = uniqueData; 
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching attendance: $e");
    }
  }

  String _translateDate(String dateStr) {
    Map<String, String> translations = {
      'January': 'يناير', 'February': 'فبراير', 'March': 'مارس',
      'April': 'أبريل', 'May': 'مايو', 'June': 'يونيو',
      'July': 'يوليو', 'August': 'أغسطس', 'September': 'سبتمبر',
      'October': 'أكتوبر', 'November': 'نوفمبر', 'December': 'ديسمبر',
      'Saturday': 'السبت', 'Sunday': 'الأحد', 'Monday': 'الاثنين',
      'Tuesday': 'الثلاثاء', 'Wednesday': 'الأربعاء', 'Thursday': 'الخميس',
      'Friday': 'الجمعة',
    };

    String translated = dateStr;
    translations.forEach((english, arabic) {
      translated = translated.replaceAll(english, arabic);
    });
    return translated;
  }

  // ignore: unused_element
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFFFCC00),
                    onPrimary: Colors.black,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFFFFCC00),
                    onPrimary: Colors.black,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dateController.text = "${picked.year}-$month-$day";
      });
    }
  }

  // ignore: unused_element
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFFFCC00),
                    onPrimary: Colors.black,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFFFFCC00),
                    onPrimary: Colors.black,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "حسناً",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveRequestSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int sheetLeaveType = _leaveType;
    final dateCtrl   = TextEditingController(text: _dateController.text);
    final timeCtrl   = TextEditingController(text: _timeController.text);
    final reasonCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  const Text('طلب إجازة جديد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // نوع الإجازة
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: GestureDetector(
                          onTap: () => setSheet(() => sheetLeaveType = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sheetLeaveType == 0 ? const Color(0xFFFFCC00) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text('يوم كامل',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: sheetLeaveType == 0 ? Colors.black : Colors.grey))),
                          ),
                        )),
                        Expanded(child: GestureDetector(
                          onTap: () => setSheet(() => sheetLeaveType = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sheetLeaveType == 1 ? const Color(0xFFFFCC00) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text('ساعية',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: sheetLeaveType == 1 ? Colors.black : Colors.grey))),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // التاريخ / الوقت
                  TextField(
                    controller: sheetLeaveType == 0 ? dateCtrl : timeCtrl,
                    readOnly: true,
                    onTap: () async {
                      if (sheetLeaveType == 0) {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheet(() => dateCtrl.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                        }
                      } else {
                        final now = TimeOfDay.now();
                        final picked = await showTimePicker(
                            context: ctx, initialTime: now);
                        if (picked != null) {
                          final today = DateTime.now();
                          final selectedDate = dateCtrl.text.trim();
                          final isToday = selectedDate ==
                              "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
                          if (isToday &&
                              (picked.hour < now.hour ||
                                  (picked.hour == now.hour && picked.minute <= now.minute))) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('لا يمكن طلب إجازة لوقت مضى — اختر وقتاً لاحقاً')),
                              );
                            }
                          } else {
                            setSheet(() => timeCtrl.text = picked.format(ctx));
                          }
                        }
                      }
                    },
                    decoration: InputDecoration(
                      hintText: sheetLeaveType == 0 ? 'اختر التاريخ...' : 'اختر الوقت...',
                      suffixIcon: Icon(sheetLeaveType == 0
                          ? Icons.calendar_today_outlined
                          : Icons.access_time_outlined, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F6F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // السبب
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'سبب الإجازة...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F6F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: sending ? null : () async {
                        final reason = reasonCtrl.text.trim();
                        final date   = dateCtrl.text.trim();
                        if (date.isEmpty || reason.length < 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى ملء جميع الحقول (السبب 3 أحرف على الأقل)')),
                          );
                          return;
                        }
                        setSheet(() => sending = true);
                        try {
                          final type = sheetLeaveType == 0 ? 'full_day' : 'hourly';
                          final ok = await StudentServices().submitLeaveRequest(type, date, reason);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (ok && mounted) {
                            _showSuccessDialog('تم إرسال طلبكم بنجاح\nالطلب قيد المعالجة حالياً');
                            _fetchMyLeaveRequests();
                          }
                        } catch (_) {
                          setSheet(() => sending = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('حدث خطأ، يرجى المحاولة مرة أخرى')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: sending
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('إرسال الطلب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الحضور والغياب',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildCustomTabBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTab == 0
                        ? _buildAttendanceRecord()
                        : _buildLeaveRequest(),
                  ),
                ),
              ],
            ),
            // زر طلب إجازة سريع - يظهر فقط في تبويب طلب إجازة
            if (_selectedTab == 1) Positioned(
              bottom: 95,
              left: 20,
              child: GestureDetector(
                onTap: _showLeaveRequestSheet,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCAA00),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCCAA00).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 28, color: Colors.black),
                ),
              ),
            ),
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(title: 'سجل الحضور والغياب', index: 0),
          _buildTabItem(title: 'طلب إجازة', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFCC00) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.black
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecord() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    if (_attendanceList.isEmpty) {
      return Center(
        child: Text(
          "لا يوجد سجلات حضور وغياب",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAttendance,
      color: const Color(0xFFFFCC00),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
        itemCount: _attendanceList.length,
        itemBuilder: (context, index) {
          final record = _attendanceList[index];
          String status = record['status'] ?? 'present'; 
          String subject = record['course_name'] ?? '';
          
          String date = _translateDate(record['date'] ?? '');

          final time = record['time']?.toString();

          if (status == 'absent') {
            return _buildRecordCard(
              date: date,
              subject: subject,
              statusText: 'غائب',
              statusColor: isDark ? Colors.red.shade300 : Colors.red,
              bgColor: isDark ? Colors.red.withAlpha(30) : const Color(0xFFFFEBEE),
              icon: Icons.close,
              time: time,
            );
          } else if (status == 'pending') {
            return _buildRecordCard(
              date: date,
              subject: subject,
              statusText: 'قيد الانتظار',
              statusColor: isDark ? Colors.orange.shade300 : Colors.orange,
              bgColor: isDark ? Colors.orange.withAlpha(30) : const Color(0xFFFFF3E0),
              icon: Icons.hourglass_empty_rounded,
              time: time,
            );
          }

          Color statusColor;
          Color bgColor;
          IconData icon;
          String statusText;

          if (status == 'present') {
            statusText = 'حاضر';
            statusColor = isDark ? Colors.green.shade400 : const Color(0xFF4CAF50);
            bgColor = isDark ? Colors.green.withAlpha(30) : const Color(0xFFE8F5E9);
            icon = Icons.check;
          } else if (status == 'late') {
            statusText = 'متأخر';
            statusColor = isDark ? Colors.amber.shade300 : const Color(0xFFFBC02D);
            bgColor = isDark ? Colors.amber.withAlpha(30) : const Color(0xFFFFF9C4);
            icon = Icons.warning_amber_rounded;
          } else {
            statusText = 'غير معروف';
            statusColor = Colors.grey;
            bgColor = Colors.grey.shade200;
            icon = Icons.help_outline;
          }

          return _buildRecordCard(
            date: date,
            subject: subject,
            statusText: statusText,
            statusColor: statusColor,
            bgColor: bgColor,
            icon: icon,
            time: time,
          );
        },
      ),
    );
  }

  Widget _buildRecordCard({
    required String date,
    required String subject,
    required String statusText,
    required Color statusColor,
    required Color bgColor,
    required IconData icon,
    String? time,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(50)
                    : Colors.black.withAlpha(8),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(subject, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (time != null) ...[
                          const Text('  •  ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: statusColor, size: 20),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending_parent': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Widget _buildLeaveRequest() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      children: [
        if (_isLoadingRequests)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00), strokeWidth: 2)),
          )
        else if (_myLeaveRequests.isNotEmpty) ...[
          Text('طلباتي السابقة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 10),
          ..._myLeaveRequests.map((req) {
            final status = req['status'] as String? ?? '';
            final statusText = req['status_text'] as String? ?? status;
            final color = _statusColor(status);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req['type'] ?? '', style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 3),
                        Text(req['date'] ?? '', style: TextStyle(fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(statusText, style: TextStyle(color: color,
                        fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 15),
          Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
          const SizedBox(height: 10),
        ],
        Center(
          child: Text(
            'اضغط زر + لطلب إجازة جديدة',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildToggleBtn(String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isActive = _leaveType == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _leaveType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFCC00) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 5)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: isActive
                    ? Colors.black
                    : (isDark ? Colors.grey.shade400 : Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}