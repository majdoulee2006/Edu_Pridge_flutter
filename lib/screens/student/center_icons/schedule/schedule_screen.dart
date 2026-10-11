import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:printing/printing.dart';

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
import 'package:edu_pridge_flutter/services/api_service.dart';

class ScheduleScreen extends StatefulWidget {
  final int initialTab;
  const ScheduleScreen({super.key, this.initialTab = 0});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _selectedTab; // 0 = جدول الحصص، 1 = جدول الامتحانات
  int _selectedDateIndex = 0; // تبدأ من 0 برمجياً
  int _selectedLectureIndex =
      0; // 🌟 متغير جديد: لتحديد الحصة المحددة بالإطار الأصفر

  final GlobalKey _classScheduleBoundaryKey = GlobalKey();
  final GlobalKey _examScheduleBoundaryKey = GlobalKey();

  bool _isLoadingSchedules = true;
  bool _isLoadingExams = true;
  bool _isExporting = false;

  List<dynamic> _schedulesData = [];
  List<dynamic> _examsData = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    AppSettings.language.addListener(_onLangChange);
    _fetchSchedules();
    _fetchExams();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
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

  Future<void> _exportScheduleAsImage() async {
    final isAr = AppSettings.language.value == 'ar';
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(isAr ? 'جاري إنشاء صورة الجدول الرسمي بدقة عالية...' : 'Generating high-resolution official schedule image...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final url = await StudentServices().getScheduleExportUrl();
      if (url == null || url.isEmpty) {
        throw isAr ? 'لم نتمكن من استلام رابط الجدول من السيرفر' : 'Failed to retrieve schedule link from server';
      }

      final fixedUrl = ApiService.fixMediaUrl(url) ?? url;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get<List<int>>(
        fixedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw isAr ? 'الملف المستلم فارغ' : 'Received file is empty';
      }

      final pdfBytes = Uint8List.fromList(response.data!);

      Uint8List? pngBytes;
      if (fixedUrl.toLowerCase().contains('.png')) {
        pngBytes = pdfBytes;
      } else {
        await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
          pngBytes = await page.toPng();
          break;
        }
      }

      if (pngBytes == null) {
        throw isAr ? 'تعذر تحويل الجدول إلى صورة' : 'Could not convert schedule to image';
      }

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/schedule_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pngBytes);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImage(tempFile.path);

      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم حفظ صورة الجدول الرسمي في المعرض بدقة عالية بنجاح ✓' : 'Official schedule image saved to gallery successfully ✓'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Export schedule as image error: $e');
      // محاولة بديلة في حال تعذر تنزيل الـ PDF
      await _exportWidgetAsImage(_classScheduleBoundaryKey, 'weekly_schedule');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExamsAsImage() async {
    final isAr = AppSettings.language.value == 'ar';
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(isAr ? 'جاري إنشاء صورة جدول الامتحانات بدقة عالية...' : 'Generating high-resolution exam schedule image...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final url = await StudentServices().getExportUrl('pdf');
      if (url == null || url.isEmpty) {
        throw isAr ? 'لم نتمكن من استلام رابط جدول الامتحانات من السيرفر' : 'Failed to retrieve exam schedule link from server';
      }

      final fixedUrl = ApiService.fixMediaUrl(url) ?? url;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await Dio().get<List<int>>(
        fixedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw isAr ? 'الملف المستلم فارغ' : 'Received file is empty';
      }

      final pdfBytes = Uint8List.fromList(response.data!);

      Uint8List? pngBytes;
      if (fixedUrl.toLowerCase().contains('.png')) {
        pngBytes = pdfBytes;
      } else {
        await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: 300)) {
          pngBytes = await page.toPng();
          break;
        }
      }

      if (pngBytes == null) {
        throw isAr ? 'تعذر تحويل جدول الامتحانات إلى صورة' : 'Could not convert exam schedule to image';
      }

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/exam_schedule_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pngBytes);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImage(tempFile.path);

      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم حفظ صورة جدول الامتحانات في المعرض بدقة عالية بنجاح ✓' : 'Exam schedule image saved to gallery successfully ✓'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Export exam schedule as image error: $e');
      await _exportWidgetAsImage(_examScheduleBoundaryKey, 'exam_schedule');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportWidgetAsImage(GlobalKey key, String fileName) async {
    final isAr = AppSettings.language.value == 'ar';
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw isAr ? 'لم يتم العثور على محتوى للتصدير' : 'No content found to export';
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw isAr ? 'فشل تحويل الصورة إلى بيانات' : 'Failed to convert image to data';
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pngBytes);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      await Gal.putImage(tempFile.path);

      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم حفظ الصورة في المعرض بنجاح ✓' : 'Image saved to gallery successfully ✓'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ أثناء حفظ الصورة في المعرض: $e' : 'Error saving image to gallery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFFDFDFD);
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
            isAr ? 'الجداول الدراسية' : 'Academic Schedules',
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
    final isAr = AppSettings.language.value == 'ar';
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
          _buildTabItem(title: isAr ? 'جدول الحصص' : 'Class Schedule', index: 0),
          _buildTabItem(title: isAr ? 'جدول الامتحانات' : 'Exam Schedule', index: 1),
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

  static const List<String> _weekDaysAr = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'
  ];
  static const List<String> _weekDaysEn = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'
  ];

  // ----------------------------------------------------------------
  // 2. واجهة "جدول الحصص"
  // ----------------------------------------------------------------
  Widget _buildClassSchedule() {
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weekDays = isAr ? _weekDaysAr : _weekDaysEn;

    if (_isLoadingSchedules) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    if (_selectedDateIndex >= weekDays.length) _selectedDateIndex = 0;

    final selectedDayName = weekDays[_selectedDateIndex];
    final selectedArDay = _weekDaysAr[_selectedDateIndex];
    final selectedEnDay = _weekDaysEn[_selectedDateIndex];

    // find lectures for this day from API data (may be empty)
    final dayData = _schedulesData.firstWhere(
      (d) {
        final dDay = d['day']?.toString().trim().toLowerCase() ?? '';
        return dDay == selectedArDay.toLowerCase() ||
               dDay == selectedEnDay.toLowerCase();
      },
      orElse: () => {'day': selectedDayName, 'lectures': []},
    );
    List<dynamic> lectures = dayData['lectures'] ?? [];
    if (lectures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                isAr ? 'لا توجد محاضرات في هذا اليوم' : 'No lectures on this day',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> currentSchedule = lectures.asMap().entries.map((entry) {
      int index = entry.key;
      var lecture = entry.value;
      bool isLast = index == lectures.length - 1;
      bool isLectureSelected = index == _selectedLectureIndex;

        List<String> timeParts = lecture['start_time'].toString().split(' ');
        String startTimeStr = timeParts[0];
        String startAmPmStr = timeParts.length > 1 ? (timeParts[1] == 'AM' ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM')) : '';
        // Parse end time
        List<String> endParts = lecture['end_time']?.toString().split(' ') ?? [];
        String endTimeStr = endParts.isNotEmpty ? endParts[0] : '';
        String endAmPmStr = endParts.length > 1 ? (endParts[1] == 'AM' ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM')) : '';
        
        return GestureDetector(
          onTap: () => setState(() => _selectedLectureIndex = index),
          child: _buildTimelineItem(
            time: startTimeStr,
            amPm: startAmPmStr,
            endTime: endTimeStr,
            endAmPm: endAmPmStr,
            isCurrentTime: isLectureSelected,
            isLast: isLast,
            card: _buildClassCard(
              title: lecture['course_name'],
              instructor: lecture['teacher'],
              instructorId: lecture['teacher_id'] ?? 1,
              location: lecture['room'],
              tagText: lecture['duration'] ?? (isAr ? 'محاضرة' : 'Lecture'),
              icon: Icons.menu_book,
              iconColor: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              iconBgColor: isDark ? Colors.blue.withAlpha(30) : Colors.blue.shade50,
              isActive: isLectureSelected,
            ),
          ),
        );
    }).toList();

    return RepaintBoundary(
      key: _classScheduleBoundaryKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(weekDays.length, (index) {
                return _buildDayCircle(day: weekDays[index], index: index);
              }),
            ),
          ),

          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      isAr ? 'برنامج $selectedDayName' : '$selectedDayName Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _exportScheduleAsImage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.image,
                              color: Colors.blueAccent,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAr ? 'صورة الجدول (PNG)' : 'Schedule (PNG)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(25) : const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  isAr ? '${lectures.length} حصص' : '${lectures.length} classes',
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
          child: lectures.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لا توجد حصص ليوم $selectedDayName' : 'No classes for $selectedDayName',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  key: ValueKey<int>(_selectedDateIndex),
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                  physics: const BouncingScrollPhysics(),
                  children: currentSchedule,
                ),
        ),
      ],
    ),
  );
}

  // ----------------------------------------------------------------
  // 3. واجهة "جدول الامتحانات"
  // ----------------------------------------------------------------
  Widget _buildExamSchedule() {
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingExams) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
      );
    }

    final List<dynamic> displayExams = _examsData;
    final List<dynamic> finalExams = displayExams.where((e) => e['type_label'] != 'مذاكرة' && e['type_label'] != 'Quiz').toList();
    final List<dynamic> quizzes = displayExams.where((e) => e['type_label'] == 'مذاكرة' || e['type_label'] == 'Quiz').toList();

    return RepaintBoundary(
      key: _examScheduleBoundaryKey,
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 120),
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'الامتحانات والمذاكرات' : 'Exams & Quizzes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _exportExamsAsImage(),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image,
                            color: Colors.blueAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isAr ? 'صورة الجدول (PNG)' : 'Schedule Image (PNG)',
                            style: const TextStyle(
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
        if (displayExams.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded, size: 50, color: Colors.grey.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'لا يوجد برنامج امتحانات متاح حالياً' : 'No exam schedule currently available',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: isAr ? 'Cairo' : 'Inter',
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (finalExams.isNotEmpty) ...[
            _buildExamSectionHeader(isAr ? 'الامتحانات النهائية' : 'Final Exams', Icons.assignment_late_rounded, Colors.red),
            const SizedBox(height: 10),
            ...finalExams.map((exam) {
              return _buildExamCard(
                time: exam['time'],
                title: exam['subject'],
                duration: exam['duration'] ?? (isAr ? 'غير محدد' : 'Not specified'),
                location: exam['room'] ?? (isAr ? 'القاعة الامتحانية' : 'Exam Hall'),
                month: exam['month'],
                dayNumber: exam['day_num'].toString(),
                dayName: exam['day_name'],
                typeLabel: exam['type_label'] ?? (isAr ? 'نهائي' : 'Final'),
                score: exam['score'],
                maxScore: exam['max_score'],
                onTap: exam['event_id'] != null
                    ? () => _showGradeSheet(exam['event_id'] as int, exam['subject'] ?? '')
                    : null,
              );
            }),
          ],
          if (quizzes.isNotEmpty) ...[
            SizedBox(height: finalExams.isNotEmpty ? 24 : 0),
            _buildExamSectionHeader(isAr ? 'المذاكرات' : 'Quizzes', Icons.edit_note_rounded, Colors.blue),
            const SizedBox(height: 10),
            ...quizzes.map((exam) {
              return _buildExamCard(
                time: exam['time'],
                title: exam['subject'],
                duration: exam['duration'] ?? (isAr ? 'غير محدد' : 'Not specified'),
                location: exam['room'] ?? (isAr ? 'القاعة الامتحانية' : 'Exam Hall'),
                month: exam['month'],
                dayNumber: exam['day_num'].toString(),
                dayName: exam['day_name'],
                typeLabel: exam['type_label'] ?? (isAr ? 'مذاكرة' : 'Quiz'),
                score: exam['score'],
                maxScore: exam['max_score'],
                onTap: exam['event_id'] != null
                    ? () => _showGradeSheet(exam['event_id'] as int, exam['subject'] ?? '')
                    : null,
              );
            }),
          ],
        ],
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
                  isAr
                      ? 'يرجى الحضور قبل موعد الامتحان بـ 15 دقيقة على الأقل وإحضار البطاقة الجامعية.'
                      : 'Please arrive at least 15 minutes before the exam and bring your university ID.',
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
      ),
    );
  }

  // =======================================================================
  // دوال الرسم والتصميم المساعدة
  // =======================================================================

  Widget _buildDayCircle({required String day, required int index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _selectedDateIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDateIndex = index;
        _selectedLectureIndex = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(left: 12),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFCC00)
              : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.circular(35),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200,
                ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFFFCC00).withAlpha(100), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black87 : (isDark ? Colors.grey.shade300 : Colors.grey),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String amPm,
    String? endTime,
    String? endAmPm,
    required bool isCurrentTime,
    required Widget card,
    bool isBreak = false,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Combine start and end times for display
    String timeLabel = time;
    String amPmLabel = amPm;
    if (endTime != null && endTime.isNotEmpty) {
      timeLabel = '$time - $endTime';
      amPmLabel = '$amPm - ${endAmPm ?? ''}'.trim();
    }
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
                  timeLabel,
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
                amPmLabel,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 1),
              if (!isLast) ...[
                Container(
                  width: 1.5,
                  height: isBreak ? 50 : 90,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ],
              if (isLast && endTime != null && endTime.isNotEmpty) ...[
                Container(
                  width: 1.5,
                  height: isBreak ? 30 : 60,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
                const SizedBox(height: 1),
                Text(
                  endTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  endAmPm ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 1),
              ],
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
        final isAr = AppSettings.language.value == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                  title: Text(
                    isAr ? 'أستاذ المادة' : 'Course Instructor',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  title: Text(
                    isAr ? 'القاعة / الموقع' : 'Hall / Location',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  title: Text(
                    isAr ? 'مدة المحاضرة' : 'Lecture Duration',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  isAr ? 'إغلاق' : 'Close',
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
        final isAr = AppSettings.language.value == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                backgroundColor: isDark
                    ? Theme.of(context).cardColor
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                title: Text(
                  isAr ? 'ضبط تذكير' : 'Set Reminder',
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
                      '${isAr ? "المادة" : "Course"}: $title',
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
                    child: Text(
                      isAr ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(color: Colors.grey),
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
                        SnackBar(
                          content: Text(isAr ? 'تم ضبط التذكير بنجاح' : 'Reminder set successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(
                      isAr ? 'حفظ' : 'Save',
                      style: const TextStyle(
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
        final isAr = AppSettings.language.value == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: isDark
                ? Theme.of(context).cardColor
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: Text(
              '${isAr ? "تقديم عذر" : "Submit Excuse"} - $title',
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
                    hintText: isAr ? 'يرجى كتابة سبب الغياب أو التأخير...' : 'Please enter reason for absence or tardiness...',
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
                          isAr ? 'إرفاق مستند أو صورة' : 'Attach document or image',
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
                child: Text(
                  isAr ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: Colors.grey),
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
                    SnackBar(
                      content: Text(isAr ? 'تم إرسال العذر بنجاح' : 'Excuse submitted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(
                  isAr ? 'إرسال العذر' : 'Submit Excuse',
                  style: const TextStyle(
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
        final isAr = AppSettings.language.value == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                  isAr ? 'إرفاق ملف' : 'Attach File',
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
                      isAr ? 'الكاميرا' : 'Camera',
                      Colors.blue,
                    ),
                    _buildAttachmentOption(
                      Icons.photo_library,
                      isAr ? 'المعرض' : 'Gallery',
                      Colors.purple,
                    ),
                    _buildAttachmentOption(
                      Icons.insert_drive_file,
                      isAr ? 'مستند' : 'Document',
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
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم اختيار $title بنجاح' : '$title selected successfully'),
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
    final isAr = AppSettings.language.value == 'ar';
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
                      if (value == 'details') {
                        _showSubjectDetailsDialog(
                          title,
                          instructor,
                          location,
                          tagText,
                          icon,
                          iconColor,
                          iconBgColor,
                        );
                      } else if (value == 'message') {
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
                      } else if (value == 'reminder') {
                        _showReminderDialog(title);
                      } else if (value == 'excuse') {
                        _showAbsenceExcuseDialog(title);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'تفاصيل المادة' : 'Course Details',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'message',
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'مراسلة المدرس' : 'Message Instructor',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reminder',
                        child: Row(
                          children: [
                            Icon(
                              Icons.alarm_add,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'ضبط تذكير' : 'Set Reminder',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excuse',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_document,
                              size: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'تقديم عذر غياب' : 'Submit Absence Excuse',
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

  Future<void> _showGradeSheet(int eventId, String subject) async {
    final isAr = AppSettings.language.value == 'ar';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic>? info;
    try {
      final resp = await Dio().get(
        '${ApiService().baseUrl}/student/grade-event/$eventId',
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      );
      if (resp.statusCode == 200) info = resp.data as Map<String, dynamic>;
    } catch (_) {}

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final graded  = info?['graded'] == true;
        final score   = info?['score'];
        final maxSc   = info?['max_score'];
        final notes   = info?['notes'];
        final rawType = info?['type_label'] ?? '';
        final type    = isAr
            ? (rawType == 'Quiz' ? 'مذاكرة' : (rawType == 'Final' ? 'نهائي' : rawType))
            : (rawType == 'مذاكرة' ? 'Quiz' : (rawType == 'نهائي' ? 'Final' : rawType));
        final title   = info?['title'] ?? subject;
        final course  = info?['course'] ?? subject;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(course, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text('$type — $title', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                if (info == null)
                  Center(child: Text(isAr ? 'تعذّر تحميل البيانات' : 'Failed to load data', style: const TextStyle(color: Colors.grey)))
                else if (!graded)
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Text(isAr ? 'لم يتم التصحيح بعد' : 'Not graded yet', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                      ])),
                  ])
                else
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFFFCC00).withAlpha(30), borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Text(isAr ? 'علامتك' : 'Your Grade', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('$score / $maxSc', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFFCC9900))),
                      ])),
                    if (notes != null && notes.toString().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                        child: Text(notes.toString(), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.black87)))),
                    ],
                  ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamSectionHeader(String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 40 : 20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade300,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  String _translateExamDay(String day, bool isAr) {
    if (isAr) {
      switch (day.toLowerCase().trim()) {
        case 'sunday': case 'sun': return 'الأحد';
        case 'monday': case 'mon': return 'الإثنين';
        case 'tuesday': case 'tue': return 'الثلاثاء';
        case 'wednesday': case 'wed': return 'الأربعاء';
        case 'thursday': case 'thu': return 'الخميس';
        case 'friday': case 'fri': return 'الجمعة';
        case 'saturday': case 'sat': return 'السبت';
        default: return day;
      }
    } else {
      switch (day.trim()) {
        case 'الأحد': return 'Sun';
        case 'الإثنين': case 'الاثنين': return 'Mon';
        case 'الثلاثاء': return 'Tue';
        case 'الأربعاء': return 'Wed';
        case 'الخميس': return 'Thu';
        case 'الجمعة': return 'Fri';
        case 'السبت': return 'Sat';
        default: return day;
      }
    }
  }

  String _translateExamMonth(String m, bool isAr) {
    final clean = m.toLowerCase().trim();
    if (isAr) {
      if (clean == 'january' || clean == 'jan' || clean == '1' || clean == '01') return 'يناير';
      if (clean == 'february' || clean == 'feb' || clean == '2' || clean == '02') return 'فبراير';
      if (clean == 'march' || clean == 'mar' || clean == '3' || clean == '03') return 'مارس';
      if (clean == 'april' || clean == 'apr' || clean == '4' || clean == '04') return 'أبريل';
      if (clean == 'may' || clean == '5' || clean == '05') return 'مايو';
      if (clean == 'june' || clean == 'jun' || clean == '6' || clean == '06') return 'يونيو';
      if (clean == 'july' || clean == 'jul' || clean == '7' || clean == '07') return 'يوليو';
      if (clean == 'august' || clean == 'aug' || clean == '8' || clean == '08') return 'أغسطس';
      if (clean == 'september' || clean == 'sep' || clean == '9' || clean == '09') return 'سبتمبر';
      if (clean == 'october' || clean == 'oct' || clean == '10') return 'أكتوبر';
      if (clean == 'november' || clean == 'nov' || clean == '11') return 'نوفمبر';
      if (clean == 'december' || clean == 'dec' || clean == '12') return 'ديسمبر';
      return m;
    } else {
      const enMap = {
        'يناير': 'Jan', 'فبراير': 'Feb', 'مارس': 'Mar', 'أبريل': 'Apr',
        'مايو': 'May', 'يونيو': 'Jun', 'يوليو': 'Jul', 'أغسطس': 'Aug',
        'سبتمبر': 'Sep', 'أكتوبر': 'Oct', 'نوفمبر': 'Nov', 'ديسمبر': 'Dec',
        'كانون الثاني': 'Jan', 'شباط': 'Feb', 'آذار': 'Mar', 'نيسان': 'Apr',
        'أيار': 'May', 'حزيران': 'Jun', 'تموز': 'Jul', 'آب': 'Aug',
        'أيلول': 'Sep', 'تشرين الأول': 'Oct', 'تشرين الثاني': 'Nov', 'كانون الأول': 'Dec',
      };
      return enMap[m.trim()] ?? m;
    }
  }

  Widget _buildExamCard({
    required String time,
    required String title,
    required String duration,
    required String location,
    required String month,
    required String dayNumber,
    required String dayName,
    String typeLabel = 'نهائي',
    dynamic score,
    dynamic maxScore,
    VoidCallback? onTap,
  }) {
    final isAr = AppSettings.language.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isQuiz = typeLabel == 'مذاكرة' || typeLabel == 'Quiz';
    final Color tagClr = isQuiz ? Colors.blue : Colors.red;
    final String displayType = isAr
        ? (typeLabel == 'Quiz' ? 'مذاكرة' : (typeLabel == 'Final' ? 'نهائي' : typeLabel))
        : (typeLabel == 'مذاكرة' ? 'Quiz' : (typeLabel == 'نهائي' ? 'Final' : typeLabel));
    final String displayMonth = _translateExamMonth(month, isAr);
    final String displayDayName = _translateExamDay(dayName, isAr);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: onTap != null
              ? Border.all(color: tagClr.withAlpha(60), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? tagClr.withAlpha(40) : tagClr.withAlpha(20),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(displayType, style: TextStyle(color: tagClr, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    if (score != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFFCC00).withAlpha(40), borderRadius: BorderRadius.circular(5)),
                        child: Text('$score / $maxScore', style: const TextStyle(color: Color(0xFFAA8800), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 1),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(displayMonth, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(dayNumber, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(displayDayName, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
