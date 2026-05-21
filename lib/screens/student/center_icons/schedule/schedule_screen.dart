import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/student_speed_dial.dart';

// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';

// استدعاء واجهة الإعدادات وتفاصيل الدردشة
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';

// استدعاء ملف الخدمات
import 'package:edu_pridge_flutter/services/student_services.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedTab = 0; // 0 = جدول الحصص، 1 = جدول الامتحانات
  int _selectedDateIndex = 0; // تبدأ من 0 برمجياً
  int _selectedLectureIndex =
      0; // 🌟 متغير جديد: لتحديد الحصة المحددة بالإطار الأصفر

  bool _isLoadingSchedules = true;
  bool _isLoadingExams = true;

  List<dynamic> _schedulesData = [];
  List<dynamic> _examsData = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _fetchExams();
  }

  // ----------------------------------------------------------------
  // دوال الاتصال بالخادم (APIs)
  // ----------------------------------------------------------------

  Future<void> _fetchSchedules() async {
    setState(() => _isLoadingSchedules = true);
    try {
      final data = await StudentServices().getSchedules();
      if (data != null) {
        const Map<String, int> daysOrder = {
          'الأحد': 1, 'Sunday': 1,
          'الاثنين': 2, 'Monday': 2,
          'الثلاثاء': 3, 'Tuesday': 3,
          'الأربعاء': 4, 'Wednesday': 4,
          'الخميس': 5, 'Thursday': 5,
        };
        // استبعاد الجمعة والسبت
        final filtered = data.where((d) {
          final day = d['day'] as String? ?? '';
          return day != 'الجمعة' && day != 'Friday' &&
                 day != 'السبت' && day != 'Saturday';
        }).toList();

        filtered.sort(
          (a, b) =>
              (daysOrder[a['day']] ?? 9).compareTo(daysOrder[b['day']] ?? 9),
        );

        setState(() {
          _schedulesData = filtered;
          _isLoadingSchedules = false;
        });
      } else {
        setState(() => _isLoadingSchedules = false);
      }
    } catch (e) {
      setState(() => _isLoadingSchedules = false);
      debugPrint('Error fetching schedules: $e');
    }
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoadingExams = true);
    try {
      final data = await StudentServices().getExams();
      if (data != null) {
        setState(() {
          _examsData = data;
          _isLoadingExams = false;
        });
      } else {
        setState(() => _isLoadingExams = false);
      }
    } catch (e) {
      setState(() => _isLoadingExams = false);
      debugPrint('Error fetching exams: $e');
    }
  }

  Future<void> _exportFile(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('جاري تجهيز وتنزيل ملف الـ ${type.toUpperCase()}...'),
        backgroundColor: Colors.green,
      ),
    );

    try {
      final url = await StudentServices().getExportUrl(type);
      if (url != null && url.isNotEmpty) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          throw 'لا يمكن فتح الرابط';
        }
      } else {
        throw 'الرابط غير متوفر';
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء التنزيل!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // حساب تاريخ اليوم
  String _getDateForDayName(String dayName) {
    Map<String, int> dayMap = {
      'الاثنين': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'السبت': DateTime.saturday,
      'الأحد': DateTime.sunday,
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };

    DateTime now = DateTime.now();
    int targetWeekday = dayMap[dayName] ?? now.weekday;

    int difference = targetWeekday - now.weekday;
    DateTime targetDate = now.add(Duration(days: difference));

    return targetDate.day.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFFDFDFD);
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الجداول الدراسية',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomTabBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTab == 0
                        ? _buildClassSchedule()
                        : _buildExamSchedule(),
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

  // ----------------------------------------------------------------
  // 1. التاب العلوي
  // ----------------------------------------------------------------
  Widget _buildCustomTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTabItem(title: 'جدول الحصص', index: 0),
          _buildTabItem(title: 'جدول الامتحانات', index: 1),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFCC00) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFCC00).withAlpha(100),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.black87
                    : (isDark ? Colors.grey.shade400 : Colors.black87),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 2. واجهة "جدول الحصص"
  // ----------------------------------------------------------------
  Widget _buildClassSchedule() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingSchedules) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    if (_schedulesData.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد حصص دراسية مسجلة',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_selectedDateIndex >= _schedulesData.length) {
      _selectedDateIndex = 0;
    }

    var selectedDayData = _schedulesData[_selectedDateIndex];
    String selectedDayName = selectedDayData['day'];
    List<dynamic> lectures = selectedDayData['lectures'];

    List<Widget> currentSchedule = lectures.asMap().entries.map((entry) {
      int index = entry.key;
      var lecture = entry.value;
      bool isLast = index == lectures.length - 1;

      // 🌟 التحقق هل هذه المحاضرة هي المحددة حالياً؟
      bool isLectureSelected = index == _selectedLectureIndex;

      List<String> timeParts = lecture['start_time'].toString().split(' ');
      String timeStr = timeParts[0];
      String amPmStr = timeParts.length > 1
          ? (timeParts[1] == 'AM' ? 'ص' : 'م')
          : '';

      // 🌟 تم تغليف الكرت بـ GestureDetector لتغيير اللون عند الضغط
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedLectureIndex = index;
          });
        },
        child: _buildTimelineItem(
          time: timeStr,
          amPm: amPmStr,
          isCurrentTime: isLectureSelected, // تفعيل اللون الأصفر للوقت
          isLast: isLast,
          card: _buildClassCard(
            title: lecture['course_name'],
            instructor: lecture['teacher'],
            instructorId: lecture['teacher_id'] ?? 1,
            location: lecture['room'],
            tagText: lecture['duration'] ?? 'محاضرة',
            icon: Icons.menu_book,
            iconColor: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
            iconBgColor: isDark
                ? Colors.blue.withAlpha(30)
                : Colors.blue.shade50,
            isActive: isLectureSelected, // تفعيل الإطار الأصفر للكرت
          ),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(_schedulesData.length, (index) {
              String dayName = _schedulesData[index]['day'];
              String calculatedDate = _getDateForDayName(dayName);

              return _buildDateCircle(
                day: dayName,
                date: calculatedDate,
                index: index,
              );
            }),
          ),
        ),

        const SizedBox(height: 25),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'برنامج $selectedDayName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(25)
                      : const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${currentSchedule.length} حصص',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            key: ValueKey<int>(_selectedDateIndex),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: currentSchedule,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------
  // 3. واجهة "جدول الامتحانات"
  // ----------------------------------------------------------------
  Widget _buildExamSchedule() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingExams) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    if (_examsData.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد امتحانات مسجلة',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الامتحانات النهائية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _exportFile('pdf'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _exportFile('excel'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Excel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ..._examsData.map((exam) {
          return _buildExamCard(
            time: exam['time'],
            title: exam['subject'],
            duration: exam['duration'] ?? 'غير محدد',
            location: exam['room'] ?? 'القاعة الامتحانية',
            month: exam['month'],
            dayNumber: exam['day_num'].toString(),
            dayName: exam['day_name'],
          );
        }),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.orange.withAlpha(20)
                : const Color(0xFFFFFDF0),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark
                  ? Colors.orange.withAlpha(50)
                  : const Color(0xFFFFF59D),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFF57C00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'يرجى الحضور قبل موعد الامتحان بـ 15 دقيقة على الأقل وإحضار البطاقة الجامعية.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.orange.shade400
                        : Colors.orange.shade800,
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // دوال الرسم والتصميم المساعدة
  // =======================================================================

  Widget _buildDateCircle({
    required String day,
    required String date,
    required int index,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _selectedDateIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDateIndex = index;
        _selectedLectureIndex =
            0; // 🌟 إعادة تصفير الإطار الأصفر عند تغيير اليوم
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 12),
        width: 70,
        height: 95,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFCC00)
              : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.circular(35),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.grey.shade200,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFCC00).withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              date,
              style: TextStyle(
                color: isSelected
                    ? Colors.black
                    : (isDark ? Colors.white : Colors.black),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String amPm,
    required bool isCurrentTime,
    required Widget card,
    bool isBreak = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: isCurrentTime
                    ? BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCurrentTime
                        ? Colors.black
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
              Text(
                amPm,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 5),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: isBreak ? 70 : 130,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: card,
          ),
        ),
      ],
    );
  }

  void _showSubjectDetailsDialog(
    String title,
    String instructor,
    String location,
    String tagText,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark
                ? Theme.of(context).cardColor
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.grey),
                  title: const Text(
                    'أستاذ المادة',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    instructor,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: const Text(
                    'القاعة / الموقع',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    location,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.grey),
                  title: const Text(
                    'مدة المحاضرة',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    tagText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReminderDialog(String title) {
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark
                    ? Theme.of(context).cardColor
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                title: Text(
                  'ضبط تذكير',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المادة: $title',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withAlpha(30)
                              : Colors.grey.shade300,
                        ),
                      ),
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      title: Text(
                        '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate!,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setStateBuilder(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withAlpha(30)
                              : Colors.grey.shade300,
                        ),
                      ),
                      leading: const Icon(
                        Icons.access_time,
                        color: Colors.orange,
                      ),
                      title: Text(
                        selectedTime!.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime!,
                        );
                        if (picked != null) {
                          setStateBuilder(() => selectedTime = picked);
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم ضبط التذكير بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text(
                      'حفظ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAbsenceExcuseDialog(String title) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark
                ? Theme.of(context).cardColor
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Text(
              'تقديم عذر - $title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  maxLines: 3,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'يرجى كتابة سبب الغياب أو التأخير...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: _showAttachmentOptions,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(30)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.blueGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إرفاق مستند أو صورة',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.blueGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال العذر بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'إرسال العذر',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إرفاق ملف',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.camera_alt,
                      'الكاميرا',
                      Colors.blue,
                    ),
                    _buildAttachmentOption(
                      Icons.photo_library,
                      'المعرض',
                      Colors.purple,
                    ),
                    _buildAttachmentOption(
                      Icons.insert_drive_file,
                      'مستند',
                      Colors.orange,
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

  Widget _buildAttachmentOption(IconData icon, String title, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم اختيار $title بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 50 : 25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? color.withAlpha(200) : color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard({
    required String title,
    required String instructor,
    required int instructorId,
    required String location,
    required String tagText,
    Color? tagColor,
    Color? tagBgColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isActive
            ? Border.all(color: const Color(0xFFFFCC00), width: 2)
            : Border.all(
                color: Colors.transparent,
                width: 2,
              ), // لحل مشكلة اهتزاز التصميم
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      tagBgColor ??
                      (isDark
                          ? Colors.white.withAlpha(20)
                          : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tagText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        tagColor ?? (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 5),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                    color: isDark ? Theme.of(context).cardColor : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    onSelected: (value) {
                      if (value == 'تفاصيل المادة') {
                        _showSubjectDetailsDialog(
                          title,
                          instructor,
                          location,
                          tagText,
                          icon,
                          iconColor,
                          iconBgColor,
                        );
                      } else if (value == 'مراسلة المدرس') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              receiverId: instructorId,
                              name: instructor,
                              imageUrl:
                                  'https://i.pravatar.cc/150?u=${instructor.hashCode}',
                              isGroup: false,
                            ),
                          ),
                        );
                      } else if (value == 'ضبط تذكير') {
                        _showReminderDialog(title);
                      } else if (value == 'تقديم عذر غياب') {
                        _showAbsenceExcuseDialog(title);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'تفاصيل المادة',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تفاصيل المادة',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'مراسلة المدرس',
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'مراسلة المدرس',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ضبط تذكير',
                        child: Row(
                          children: [
                            Icon(
                              Icons.alarm_add,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ضبط تذكير',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'تقديم عذر غياب',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_document,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تقديم عذر غياب',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                instructor,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 15),
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                location,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard({
    required String time,
    required String title,
    required String duration,
    required String location,
    required String month,
    required String dayNumber,
    required String dayName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withAlpha(30)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'نهائي',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade300 : Colors.red,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  dayNumber,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayName,
                  style: const TextStyle(color: Colors.grey, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
