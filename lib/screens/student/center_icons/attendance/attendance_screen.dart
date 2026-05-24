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

  Future<void> _submitLeaveRequest() async {
    final reason = _leaveReasonController.text.trim();
    final date = _dateController.text.trim();
    if (date.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
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
            icon: Icon(Icons.arrow_back, color: textColor),
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

          if (status == 'absent') {
            return _buildRecordCard(
              date: date,
              subject: subject,
              statusText: 'غائب',
              statusColor: isDark ? Colors.red.shade300 : Colors.red,
              bgColor: isDark ? Colors.red.withAlpha(30) : const Color(0xFFFFEBEE),
              icon: Icons.close,
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
                    const SizedBox(height: 5),
                    Text(
                      subject,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
        // ── تاريخ الطلبات ──
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

        // ── نموذج طلب جديد ──
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نوع الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(15)
                      : const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn('إجازة يوم كامل', 0),
                    _buildToggleBtn('إجازة ساعية', 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _leaveType == 0 ? 'التاريخ' : 'الوقت',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),

              if (_leaveType == 0)
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'اختر التاريخ...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(15)
                        : const Color(0xFFF5F6F8),
                    suffixIcon: Icon(
                      Icons.calendar_today_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              else
                TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'اختر الوقت...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(15)
                        : const Color(0xFFF5F6F8),
                    suffixIcon: Icon(
                      Icons.access_time_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                'سبب الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _leaveReasonController,
                maxLines: 4,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'اذكر سبب طلب الإجازة...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade600 : Colors.grey,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withAlpha(15)
                      : const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmittingLeave ? null : _submitLeaveRequest,
                  child: _isSubmittingLeave
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.black, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'إرسال الطلب',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
    );
  }

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