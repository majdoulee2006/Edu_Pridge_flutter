import 'dart:io';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color _yellow = Color(0xFFFFCC00);

  bool _isLoadingCourses = true;
  bool _isStarting = false;
  bool _isEnding = false;

  // كل المواد من الـ API
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _allPrograms = [];

  // مفتاح مدمج للدورة والسنة: "programId_year"
  String? _selectedProgramYearKey;

  // حالة التبويبات الداخلية في صفحة "تسجيل الحضور"
  String _attendanceTabFilter = "إعداد الجلسة";
  
  // فلترة سجل الحضور
  String _historyScope = 'my_courses'; // my_courses, advisor_class
  String? _historyProgramYearKey;
  String? _historyCourseId;
  String _historyPeriod = "today"; // today, week, month, semester

  // المواد المفلترة بعد اختيار الدورة والسنة
  List<Map<String, dynamic>> _filteredCourses = [];
  String? _selectedCourseId;

  // بيانات الجلسة الحالية
  int? _sessionId;
  String? _qrToken;
  bool _sessionActive = false;

  // قوائم الحضور والغياب
  List<Map<String, dynamic>> _absentStudents = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _allStudents = [];
  // ignore: unused_field
  int _presentCount = 0;
  int _totalCount = 0;

  // التقارير المولدة محلياً
  List<File> _generatedReports = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadGeneratedReports();
  }

  Future<void> _loadGeneratedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id')?.toString() ?? 'unknown';

    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();
      debugPrint('Found \${files.length} items in \${dir.path}');
      setState(() {
        _generatedReports = files
            .whereType<File>()
            .where((f) => f.path.contains('attendance_report_') && f.path.endsWith('.pdf'))
            .toList();
        // ترتيب من الأحدث للأقدم
        _generatedReports.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      });
    } catch (e) {
      debugPrint('Error listing files: $e');
    }
  }

  Future<void> _deleteReport(File file) async {
    if (await file.exists()) {
      await file.delete();
      await _loadGeneratedReports();
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _loadData() async {
    try {
      final token = await _getToken();
      final headers = {"Authorization": "Bearer $token"};
      final results = await Future.wait([
        Dio().get("${ApiService().baseUrl}/teacher/courses",  options: Options(headers: headers)),
        Dio().get("${ApiService().baseUrl}/teacher/programs", options: Options(headers: headers)),
      ]);

      if (results[0].statusCode == 200 && results[0].data['success'] == true) {
        _allCourses = (results[0].data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((c) => {
                  'id':         c['id'].toString(),
                  'title':      c['title'].toString(),
                  'program_id': c['program_id']?.toString() ?? '',
                  'year':       (c['year'] as num?)?.toInt() ?? 1,
                })
            .toList();
      }

      if (results[1].statusCode == 200 && results[1].data['success'] == true) {
        _allPrograms = (results[1].data['data'] as List? ?? [])
            .map<Map<String, dynamic>>((p) => {
                  'id':   p['id'].toString(),
                  'name': p['name'].toString(),
                })
            .toList();
      }
    } catch (e) {
      debugPrint('⛔ Load Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  void _applyFilter() {
    if (_selectedProgramYearKey == null) {
      setState(() { _filteredCourses = []; _selectedCourseId = null; });
      return;
    }
    final parts = _selectedProgramYearKey!.split('_');
    final pid = parts[0];
    final yr = int.tryParse(parts[1]) ?? 1;

    setState(() {
      _filteredCourses = _allCourses.where((c) {
        return c['program_id'].toString() == pid && c['year'] == yr;
      }).toList();
      _selectedCourseId = null;
    });
  }

  Future<void> _startSession() async {
    if (_selectedCourseId == null) {
      _showSnack('اختر المادة والدورة أولاً');
      return;
    }
    setState(() => _isStarting = true);
    try {
      final token = await _getToken();
      final res = await Dio().post(
        "${ApiService().baseUrl}/teacher/attendance/generate-qr",
        data: {"course_id": _selectedCourseId},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _sessionId = d['session_id'] as int?;
          _qrToken = d['qr_token'] as String?;
          _sessionActive = true;
          _absentStudents = [];
          _allStudents = [];
          _presentCount = 0;
          _totalCount = 0;
        });
      } else {
        _showSnack('فشل بدء الجلسة، حاول مجدداً');
      }
    } catch (e) {
      debugPrint('⛔ Start Session Error: $e');
      _showSnack('حدث خطأ، حاول مجدداً');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _fetchAbsentList() async {
    if (_sessionId == null) return;
    try {
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/attendance/session/$_sessionId/list",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final d = res.data['data'] as Map<String, dynamic>;
        final allStudents = (d['students'] as List? ?? [])
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();

        setState(() {
          _presentCount = (d['present_count'] as int?) ?? 0;
          _totalCount = (d['total_count'] as int?) ?? 0;
          _allStudents = allStudents;
          _absentStudents = allStudents
              .where((s) => s['status'] == 'absent')
              .toList();
        });
        _showAbsentSheet();
      }
    } catch (e) {
      debugPrint('⛔ Absent List Error: $e');
      _showSnack('تعذر جلب القائمة');
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;
    setState(() => _isEnding = true);
    try {
      final token = await _getToken();
      await Dio().post(
        "${ApiService().baseUrl}/teacher/attendance/session/$_sessionId/end",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      setState(() {
        _sessionActive = false;
        _qrToken = null;
        _sessionId = null;
        _absentStudents = [];
      });
      _showSnack('تم إنهاء الجلسة وتسجيل الغياب بنجاح ✅');
    } catch (e) {
      debugPrint('⛔ End Session Error: $e');
      _showSnack('حدث خطأ أثناء إنهاء الجلسة');
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  // تصدير كشف الحضور كملف Excel ومشاركته
  Future<void> _exportExcel() async {
    if (_sessionId == null) {
      _showSnack('ابدأ جلسة أولاً لتصدير الكشف');
      return;
    }

    try {
      // جلب البيانات مباشرة من الـ API
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/attendance/session/$_sessionId/list",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200 || res.data['success'] != true) {
        _showSnack('تعذر جلب بيانات الكشف');
        return;
      }

      final d = res.data['data'] as Map<String, dynamic>;
      final allStudents = (d['students'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

      // بناء ملف Excel
      final excel = xl.Excel.createExcel();
      final sheet = excel['كشف الحضور'];
      excel.delete('Sheet1');

      // رأس الجدول
      final headers = ['اسم الطالب', 'القسم', 'المادة', 'التاريخ', 'الحالة'];
      final headerStyle = xl.CellStyle(
        bold: true,
        horizontalAlign: xl.HorizontalAlign.Center,
        backgroundColorHex: xl.ExcelColor.fromHexString('#FFCC00'),
      );

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = xl.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // بيانات الطلاب
      final today = DateTime.now();
      final dateStr = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
      final courseName = _filteredCourses.firstWhere(
        (c) => c['id'] == _selectedCourseId,
        orElse: () => {'title': 'غير محدد'},
      )['title'] as String? ?? 'غير محدد';

      for (int i = 0; i < allStudents.length; i++) {
        final student = allStudents[i];
        final isPresent = student['status'] == 'present';
        final rowData = [
          student['name'] ?? '',
          'غير محدد',
          courseName,
          dateStr,
          isPresent ? 'حاضر' : 'غائب',
        ];

        for (int j = 0; j < rowData.length; j++) {
          final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = xl.TextCellValue(rowData[j]);
          if (!isPresent) {
            cell.cellStyle = xl.CellStyle(fontColorHex: xl.ExcelColor.fromHexString('#CC0000'));
          }
        }
      }

      // حفظ الملف
      final bytes = excel.save();
      if (bytes == null) {
        _showSnack('فشل إنشاء الملف');
        return;
      }

      // اسم ملف بأحرف ASCII فقط لتجنب مشاكل التوافق
      final safeDate = dateStr.replaceAll('/', '-');
      final fileName = 'Attendance_$safeDate.xlsx';

      // حاول حفظ في مجلد التنزيلات أولاً، وإلا استخدم المستندات
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();

      final filePath = '${dir.path}/$fileName';
      await File(filePath).writeAsBytes(bytes);

      // مشاركة / فتح الملف
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'كشف الحضور',
        text: 'كشف الحضور - $courseName - $dateStr',
      );
    } catch (e) {
      debugPrint('⛔ Excel Export Error: $e');
      _showSnack('حدث خطأ أثناء التصدير');
    }
  }

  // تصدير PDF للمادة المحددة طوال الفصل
  Future<void> _exportPdf() async {
    if (_selectedCourseId == null) {
      _showSnack('اختر المادة أولاً لتصدير كشف PDF الشامل');
      return;
    }
    _showSnack('جاري تجهيز التقرير، يرجى الانتظار...');

    try {
      final token = await _getToken();
      final url = "${ApiService().baseUrl}/teacher/attendance/export-pdf?course_id=$_selectedCourseId&period=semester";
      
      final res = await Dio().get(
        url,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes, // Important for downloading files
        ),
      );

      if (res.statusCode == 200) {
        Directory? dir;
        try {
          dir = await getDownloadsDirectory();
        } catch (_) {}
        dir ??= await getApplicationDocumentsDirectory();

        final safeDate = DateTime.now().toString().split(' ')[0];
        final filePath = '${dir.path}/attendance_report_$safeDate.pdf';
        
        final file = File(filePath);
        await file.writeAsBytes(res.data);

        _showSnack('تم التحميل! جاري الفتح...');
        await OpenFilex.open(filePath);
      } else {
        _showSnack('فشل تحميل التقرير');
      }
    } catch (e) {
      debugPrint('⛔ PDF Export Error: $e');
      _showSnack('حدث خطأ أثناء تحميل التقرير');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // تصدير PDF مفلتر بناءً على تبويب "سجل الحضور"
  Future<void> _exportHistoryPdf() async {
    _showSnack('جاري تجهيز التقرير، يرجى الانتظار...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.get('user_id')?.toString() ?? 'unknown';
      final token = await _getToken();
      String url = "${ApiService().baseUrl}/teacher/attendance/export-pdf?";
      
      url += "scope=$_historyScope";

      if (_historyScope == 'my_courses') {
        if (_historyCourseId != null && _historyCourseId != 'all') {
          url += "&course_id=$_historyCourseId";
        } else if (_historyProgramYearKey != null) {
          final parts = _historyProgramYearKey!.split('_');
          url += "&program_id=${parts[0]}&year=${parts[1]}";
        }
      }
      url += "&period=$_historyPeriod";
      
      final res = await Dio().get(
        url,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes, // Important for downloading files
        ),
      );

      if (res.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();

        final safeDate = DateTime.now().toString().split(' ')[0];
        final safeTime = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${dir.path}/attendance_report_${safeDate}_$safeTime.pdf';
        
        final file = File(filePath);
        await file.writeAsBytes(res.data);
        await _loadGeneratedReports();

        _showSnack('تم التحميل! جاري الفتح...');
        await OpenFilex.open(filePath);
      } else {
        _showSnack('فشل تحميل التقرير');
      }
    } catch (e) {
      debugPrint('⛔ PDF Export Error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          _showSnack('لا توجد جلسات حضور في هذه الفترة لتوليد تقرير.');
        } else {
          // محاولة قراءة الخطأ من السيرفر (لو كان JSON بالرغم من أننا طلبنا bytes)
          String errorMsg = 'خطأ خادم: ${e.response?.statusCode}';
          try {
            if (e.response?.data != null) {
               errorMsg = 'خطأ خادم: ${String.fromCharCodes(e.response!.data)}';
            }
          } catch (_) {}
          _showSnack(errorMsg);
        }
      } else {
        _showSnack('حدث خطأ أثناء تحميل التقرير: $e');
      }
    }
  }

  void _showAbsentSheet() {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الغائبون',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_absentStudents.length} غائب من $_totalCount',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: _absentStudents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.green, size: 50),
                                SizedBox(height: 10),
                                Text(
                                  'ما في غائبين حتى الآن!',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: _absentStudents.length,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (_, i) {
                              final s = _absentStudents[i];
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.red.withValues(alpha: 0.12),
                                  child: const Icon(Icons.close,
                                      color: Colors.red, size: 20),
                                ),
                                title: Text(
                                  s['name'] as String? ?? '',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'غائب',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'تسجيل الحضور',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: textColor),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],

          ),
          body: Stack(
            children: [
              const SizedBox.expand(),
              _buildAttendanceTab(cardColor, textColor, isDark),
              CustomBottomNav(
                currentIndex: -1,
                centerButton: const CustomSpeedDialEduBridge(),
                onHomeTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const TeacherHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const MessagesScreen())),
            ),
            ],
          ),
        ),
    );
  }

  Widget _buildAttendanceTab(Color cardColor, Color textColor, bool isDark) {
    return Column(
      children: [
        // أزرار التبديل العلوية (Filter Tabs)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Row(
            children: [
              _buildAttendanceFilterBtn("إعداد الجلسة", isDark),
              const SizedBox(width: 12),
              _buildAttendanceFilterBtn("سجل الحضور", isDark),
            ],
          ),
        ),

        // المحتوى المتغير
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: _attendanceTabFilter == "إعداد الجلسة"
                ? SingleChildScrollView(
                    key: const ValueKey("SessionSettings"),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSessionSettingsCard(cardColor, textColor, isDark),
                        const SizedBox(height: 25),
                        if (_sessionActive && _qrToken != null) ...[
                          _buildDividerWithText('الرمز النشط', textColor),
                          const SizedBox(height: 15),
                          _buildQRCodeCard(cardColor, textColor, isDark),
                        ],
                        const SizedBox(height: 120),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    key: const ValueKey("AttendanceHistory"),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildAttendanceHistoryForm(cardColor, textColor, isDark),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceFilterBtn(String text, bool isDark) {
    bool isActive = _attendanceTabFilter == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _attendanceTabFilter = text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFCC00)
                : (isDark ? Colors.white10 : const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceHistoryForm(Color cardColor, Color textColor, bool isDark) {
    String? historyPid;
    int? historyYr;
    if (_historyProgramYearKey != null) {
      final parts = _historyProgramYearKey!.split('_');
      historyPid = parts[0];
      historyYr = int.tryParse(parts[1]) ?? 1;
    }

    final filteredHistoryCourses = _allCourses.where((c) =>
      c['program_id'].toString() == historyPid &&
      c['year'] == historyYr,
    ).toList();

    // استخراج الدورات المميزة (دورة + سنة)
    final uniqueProgramYears = <String, Map<String, dynamic>>{};
    for (var c in _allCourses) {
      final pid = c['program_id'].toString();
      final year = c['year'];
      final key = '${pid}_$year';
      if (!uniqueProgramYears.containsKey(key)) {
        final pName = _allPrograms.firstWhere(
          (p) => p['id'].toString() == pid, 
          orElse: () => {'name': 'غير معروف'}
        )['name'];
        uniqueProgramYears[key] = {
          'key': key,
          'display': '$pName - السنة ${year == 1 ? "الأولى" : "الثانية"}',
        };
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: _yellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'توليد سجل الحضور (كشف PDF)',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // نطاق التقرير (Scope)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _historyScope,
                hint: const Text('نطاق التقرير', style: TextStyle(color: Colors.grey, fontSize: 14)),
                dropdownColor: cardColor,
                icon: const Icon(Icons.keyboard_arrow_down, color: _yellow),
                items: const [
                  DropdownMenuItem(value: 'my_courses', child: Text('المواد الموكلة إلي')),
                  DropdownMenuItem(value: 'advisor_class', child: Text('دورتي الإشرافية')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _historyScope = val;
                      _historyProgramYearKey = null;
                      _historyCourseId = null;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_historyScope == 'my_courses') ...[
            // الدورة والسنة
            _buildFieldLabel('الدورة والسنة', textColor),
            _buildDropdown(
              hint: 'اختر الدورة والسنة',
              value: _historyProgramYearKey,
              items: uniqueProgramYears.values.map((p) => DropdownMenuItem<String>(
                value: p['key'] as String,
                child: Text(p['display'] as String, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _historyProgramYearKey = val;
                  _historyCourseId = null; // reset course
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 15),

            // المادة
            _buildFieldLabel('المادة', textColor),
            _buildDropdown(
              hint: 'اختر المادة (أو جميع المواد)',
              value: _historyCourseId,
              items: [
                const DropdownMenuItem<String>(
                  value: 'all',
                  child: Text('جميع المواد'),
                ),
                ...filteredHistoryCourses.map((c) => DropdownMenuItem<String>(
                  value: c['id'] as String,
                  child: Text(c['title'] as String, overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (val) {
                setState(() => _historyCourseId = val);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 15),
          ],

          // المدة (الفلترة)
          _buildFieldLabel('الفترة الزمنية', textColor),
          _buildDropdown(
            hint: 'الفترة الزمنية',
            value: _historyPeriod,
            items: const [
              DropdownMenuItem(value: 'today', child: Text('اليوم')),
              DropdownMenuItem(value: 'week', child: Text('أسبوع')),
              DropdownMenuItem(value: 'month', child: Text('شهر')),
              DropdownMenuItem(value: 'semester', child: Text('من بداية الفصل')),
            ],
            onChanged: (val) {
              setState(() => _historyPeriod = val ?? 'today');
            },
            isDark: isDark,
          ),
          const SizedBox(height: 25),

          // زر التصدير
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_historyScope == 'my_courses') {
                  if (_historyProgramYearKey == null) {
                    _showSnack('الرجاء اختيار الدورة والسنة');
                    return;
                  }
                  if (_historyCourseId == null) {
                    _showSnack('الرجاء اختيار المادة');
                    return;
                  }
                }
                _exportHistoryPdf();
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
              label: const Text(
                'توليد الكشف (PDF)',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // التقارير المولدة سابقا
          if (_generatedReports.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.folder_special, color: _yellow, size: 20),
                const SizedBox(width: 8),
                Text(
                  'التقارير المولدة سابقاً (${_generatedReports.length})',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedReports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final file = _generatedReports[idx];
                final fileName = file.path.split('/').last;
                final dateModified = file.lastModifiedSync();
                // تنسيق مبسط للتاريخ
                final displayDate = "${dateModified.year}-${dateModified.month.toString().padLeft(2,'0')}-${dateModified.day.toString().padLeft(2,'0')} ${dateModified.hour.toString().padLeft(2,'0')}:${dateModified.minute.toString().padLeft(2,'0')}";
                
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                    title: Text('سجل حضور', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(displayDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                          onPressed: () => OpenFilex.open(file.path),
                          tooltip: 'فتح الملف',
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          onPressed: () {
                            Share.shareXFiles([XFile(file.path)], text: 'تقرير الحضور');
                          },
                          tooltip: 'مشاركة/تنزيل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: const Text('هل أنت متأكد من حذف هذا التقرير؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteReport(file);
                                    },
                                    child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          tooltip: 'حذف التقرير',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionSettingsCard(
      Color cardColor, Color textColor, bool isDark) {
    // استخراج الدورات المميزة
    final uniqueProgramYears = <String, Map<String, dynamic>>{};
    for (var c in _allCourses) {
      final pid = c['program_id'].toString();
      final year = c['year'];
      final key = '${pid}_$year';
      if (!uniqueProgramYears.containsKey(key)) {
        final pName = _allPrograms.firstWhere(
          (p) => p['id'].toString() == pid, 
          orElse: () => {'name': 'غير معروف'}
        )['name'];
        uniqueProgramYears[key] = {
          'key': key,
          'display': '$pName - السنة ${year == 1 ? "الأولى" : "الثانية"}',
        };
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: _yellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'إعدادات الجلسة',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الدورة والسنة معاً
          _isLoadingCourses
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: _yellow, strokeWidth: 2),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('الدورة والسنة', textColor),
                    _buildDropdown(
                      hint: 'اختر الدورة والسنة',
                      value: _selectedProgramYearKey,
                      items: uniqueProgramYears.values.map((p) => DropdownMenuItem<String>(
                        value: p['key'] as String,
                        child: Text(p['display'] as String, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: _sessionActive ? null : (val) {
                        setState(() => _selectedProgramYearKey = val);
                        _applyFilter();
                      },
                      isDark: isDark,
                    ),
                  ],
                ),

          const SizedBox(height: 16),

          // المادة الدراسية (تظهر بعد اختيار الدورة والسنة)
          if (_selectedProgramYearKey != null) ...[
            _buildFieldLabel('المادة الدراسية', textColor),
            _filteredCourses.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('لا توجد مواد لهذه الدورة والسنة',
                          style: TextStyle(color: Colors.orange, fontSize: 13)),
                    ),
                  )
                : _buildDropdown(
                    hint: 'اختر المادة',
                    value: _selectedCourseId,
                    items: _filteredCourses.map((c) => DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text(c['title'] as String),
                    )).toList(),
                    onChanged: _sessionActive ? null : (val) => setState(() => _selectedCourseId = val),
                    isDark: isDark,
                  ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: _isStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_fill, color: Colors.black),
              label: Text(
                _sessionActive ? 'جلسة نشطة' : 'بدء الجلسة الآن',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              onPressed:
                  (_isStarting || _sessionActive) ? null : _startSession,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(backgroundColor: Colors.green, radius: 4),
                SizedBox(width: 8),
                Text(
                  'مباشر',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'رمز الحضور السريع',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'اطلب من الطلاب مسح الرمز أدناه لتسجيل الحضور',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _yellow, width: 2),
            ),
            child: QrImageView(
              data: _qrToken!,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // زر عرض الغائبين
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_off_outlined, color: Colors.black),
              label: const Text(
                'عرض الغائبين',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _fetchAbsentList,
            ),
          ),

          const SizedBox(height: 10),

          // زر تصدير Excel
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.table_chart_outlined, color: Colors.green),
              label: const Text(
                'تصدير جلسة اليوم (Excel)',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _exportExcel,
            ),
          ),

          const SizedBox(height: 10),

          // زر تصدير PDF الشامل
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: const Text(
                'تصدير كشف المادة الشامل (PDF)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _exportPdf,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isEnding ? null : _endSession,
              child: _isEnding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.red, strokeWidth: 2),
                    )
                  : const Text(
                      'إنهاء الجلسة وإغلاق السجل',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _buildDividerWithText(String text, Color textColor) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(text,
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
