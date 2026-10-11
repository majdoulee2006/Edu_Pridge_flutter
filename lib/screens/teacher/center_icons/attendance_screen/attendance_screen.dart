import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/totp_qr_service.dart';
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

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _attendanceTabController;
  static const Color _yellow = Color(0xFFFFCC00);

  bool _isLoadingCourses = true;
  bool _isStarting = false;
  bool _isEnding = false;

  // كل المواد من الـ API
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _allPrograms = [];

  // مفتاح مدمج للدورة والسنة: "programId_year"
  String? _selectedProgramYearKey;

  
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
  int? _lastSessionId; // يُحفظ بعد إنهاء الجلسة للتصدير
  String? _sessionUuid;
  String? _sessionSecret;
  String? _qrToken;
  bool _sessionActive = false;
  bool _sessionEnded  = false; // يظهر أزرار التصدير بعد الإنهاء

  // عدادات تجديد QR وانتهاء الجلسة
  Timer? _qrRefreshTimer;
  Timer? _sessionCountdownTimer;
  int _qrCountdown      = 30;
  int _sessionCountdown = 600;

  // قوائم الحضور والغياب
  // ignore: unused_field
  List<Map<String, dynamic>> _absentStudents = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _allStudents = [];
  // ignore: unused_field
  int _presentCount = 0;
  int _totalCount = 0;

  // التقارير المولدة محلياً
  List<File> _generatedReports = [];

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _attendanceTabController = TabController(length: 2, vsync: this);
    _attendanceTabController.addListener(() {
      if (!_attendanceTabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
    _loadGeneratedReports();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _attendanceTabController.dispose();
    _stopTimers();
    super.dispose();
  }

  void _startTimers() {
    _stopTimers();
    _qrCountdown = 30;
    _sessionCountdown = 600;

    // عداد تجديد QR كل ثانية
    _qrRefreshTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _qrCountdown--);
      if (_qrCountdown <= 0) {
        _qrCountdown = 30;
        _refreshQrToken();
      }
    });

    // عداد انتهاء الجلسة كل ثانية
    _sessionCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _sessionCountdown--);
      if (_sessionCountdown <= 0) {
        t.cancel();
        _endSession();
      }
    });
  }

  void _stopTimers() {
    _qrRefreshTimer?.cancel();
    _sessionCountdownTimer?.cancel();
    _qrRefreshTimer = null;
    _sessionCountdownTimer = null;
  }

  Future<void> _refreshQrToken() async {
    // إذا توفر سر ومعرف الجلسة: تجديد الرمز محلياً فوراً بخوارزمية TOTP (المرحلة 2: يعمل حتى بدون إنترنت)
    if (_sessionUuid != null && _sessionSecret != null) {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = TotpQrService.generatePayload(
        secret: _sessionSecret!,
        sessionUuid: _sessionUuid!,
        unixTime: nowUnix,
      );
      if (mounted) setState(() => _qrToken = payload);
      return;
    }

    if (_sessionId == null) return;
    try {
      final token = await _getToken();
      final res = await Dio().post(
        "${ApiService().baseUrl}/teacher/attendance/session/$_sessionId/refresh-qr",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (res.data['session_ended'] == true) {
          _stopTimers();
          if (mounted) setState(() { _sessionActive = false; _qrToken = null; _sessionId = null; });
          final isAr = AppSettings.language.value == 'ar';
          _showSnack(isAr ? 'انتهت مدة الجلسة (10 دقائق) ✅' : 'Session duration ended (10 minutes) ✅');
          return;
        }
        if (mounted) setState(() => _qrToken = res.data['data']['qr_token'] as String?);
      }
    } catch (e) {
      debugPrint('⛔ Refresh QR Error: $e');
    }
  }

  Future<void> _loadGeneratedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.get('user_id')?.toString() ?? 'unknown';
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();
      setState(() {
        _generatedReports = files
            .whereType<File>()
            .where((f) =>
                f.path.contains('attendance_report_u${userId}_') &&
                f.path.endsWith('.pdf'))
            .toList();
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
    final isAr = AppSettings.language.value == 'ar';
    if (_selectedCourseId == null) {
      _showSnack(isAr ? 'اختر المادة والدورة أولاً' : 'Select course and program first');
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
        final sessionUuid = d['session_uuid'] as String?;
        final sessionSecret = d['session_secret'] as String?;
        String? currentToken = d['qr_token'] as String?;

        if (sessionUuid != null && sessionSecret != null) {
          final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          currentToken = TotpQrService.generatePayload(
            secret: sessionSecret,
            sessionUuid: sessionUuid,
            unixTime: nowUnix,
          );
        }

        setState(() {
          _sessionId = d['session_id'] as int?;
          _sessionUuid = sessionUuid;
          _sessionSecret = sessionSecret;
          _qrToken = currentToken;
          _sessionActive = true;
          _sessionEnded  = false;
          _absentStudents = [];
          _allStudents = [];
          _presentCount = 0;
          _totalCount = 0;
        });
        _startTimers();
      } else {
        _showSnack(isAr ? 'فشل بدء الجلسة، حاول مجدداً' : 'Failed to start session, please try again');
      }
    } catch (e) {
      debugPrint('⛔ Start Session Error: $e');
      _showSnack(isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, please try again');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _fetchAbsentList([String initialFilter = 'all']) async {
    if (_sessionId == null) return;
    final isAr = AppSettings.language.value == 'ar';
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
        _showStudentListSheet(initialFilter);
      }
    } catch (e) {
      debugPrint('⛔ Absent List Error: $e');
      _showSnack(isAr ? 'تعذر جلب القائمة' : 'Unable to fetch student list');
    }
  }

  Future<void> _endSession() async {
    if (_sessionId == null) return;
    final isAr = AppSettings.language.value == 'ar';
    setState(() => _isEnding = true);
    try {
      final token = await _getToken();
      await Dio().post(
        "${ApiService().baseUrl}/teacher/attendance/session/$_sessionId/end",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      _stopTimers();
      setState(() {
        _lastSessionId = _sessionId;
        _sessionActive = false;
        _sessionEnded  = true;
        _qrToken = null;
        _sessionId = null;
        _sessionUuid = null;
        _sessionSecret = null;
        _absentStudents = [];
      });
      _showSnack(isAr ? 'تم إنهاء الجلسة وتسجيل الغياب بنجاح ✅' : 'Session ended and absence recorded successfully ✅');
    } catch (e) {
      debugPrint('⛔ End Session Error: $e');
      _showSnack(isAr ? 'حدث خطأ أثناء إنهاء الجلسة' : 'An error occurred while ending the session');
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  // تصدير كشف الحضور كملف Excel ومشاركته
  Future<void> _exportExcel() async {
    final isAr = AppSettings.language.value == 'ar';
    final sid = _sessionId ?? _lastSessionId;
    if (sid == null) {
      _showSnack(isAr ? 'لا توجد جلسة للتصدير' : 'No session available to export');
      return;
    }

    try {
      // جلب البيانات مباشرة من الـ API
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/attendance/session/$sid/list",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200 || res.data['success'] != true) {
        _showSnack(isAr ? 'تعذر جلب بيانات الكشف' : 'Failed to fetch attendance data');
        return;
      }

      final d = res.data['data'] as Map<String, dynamic>;
      final allStudents = (d['students'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

      // بناء ملف Excel
      final excel = xl.Excel.createExcel();
      final sheet = excel[isAr ? 'كشف الحضور' : 'Attendance'];
      excel.delete('Sheet1');

      // رأس الجدول
      final headers = isAr
          ? ['اسم الطالب', 'القسم', 'المادة', 'التاريخ', 'الحالة']
          : ['Student Name', 'Department', 'Course', 'Date', 'Status'];
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
        orElse: () => {'title': isAr ? 'غير محدد' : 'N/A'},
      )['title'] as String? ?? (isAr ? 'غير محدد' : 'N/A');

      for (int i = 0; i < allStudents.length; i++) {
        final student = allStudents[i];
        final isPresent = student['status'] == 'present';
        final rowData = [
          student['name'] ?? '',
          isAr ? 'غير محدد' : 'N/A',
          courseName,
          dateStr,
          isPresent ? (isAr ? 'حاضر' : 'Present') : (isAr ? 'غائب' : 'Absent'),
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
        _showSnack(isAr ? 'فشل إنشاء الملف' : 'Failed to create file');
        return;
      }

      final safeDate = dateStr.replaceAll('/', '-');
      final fileName = 'Attendance_$safeDate.xlsx';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: isAr ? 'حفظ كشف الحضور' : 'Save Attendance Sheet',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      if (savedPath != null) {
        _showSnack(isAr ? '✅ تم الحفظ بنجاح' : '✅ Saved successfully');
      }
    } catch (e) {
      debugPrint('⛔ Excel Export Error: $e');
      _showSnack(isAr ? 'حدث خطأ أثناء التصدير' : 'An error occurred while exporting');
    }
  }

  // تصدير PDF للمادة المحددة طوال الفصل
  Future<void> _exportPdf() async {
    final isAr = AppSettings.language.value == 'ar';
    if (_selectedCourseId == null) {
      _showSnack(isAr ? 'اختر المادة أولاً لتصدير كشف PDF الشامل' : 'Select a course first to export PDF');
      return;
    }
    _showSnack(isAr ? 'جاري تجهيز التقرير، يرجى الانتظار...' : 'Preparing report, please wait...');

    try {
      final token = await _getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = "${ApiService().baseUrl}/teacher/attendance/export-pdf?course_id=$_selectedCourseId&period=semester&_t=$timestamp";
      
      final res = await Dio().get(
        url,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes, // Important for downloading files
        ),
      );

      if (res.statusCode == 200) {
        final safeDate = DateTime.now().toString().split(' ')[0];
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: isAr ? 'حفظ كشف الحضور PDF' : 'Save Attendance PDF Report',
          fileName: 'attendance_report_$safeDate.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: Uint8List.fromList(res.data as List<int>),
        );

        if (savedPath != null) {
          _showSnack(isAr ? '✅ تم الحفظ بنجاح' : '✅ Saved successfully');
        }
      } else {
        _showSnack(isAr ? 'فشل تحميل التقرير' : 'Failed to download report');
      }
    } catch (e) {
      debugPrint('⛔ PDF Export Error: $e');
      _showSnack(isAr ? 'حدث خطأ أثناء تحميل التقرير' : 'An error occurred while downloading report');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // تصدير PDF مفلتر بناءً على تبويب "سجل الحضور"
  Future<void> _exportHistoryPdf() async {
    final isAr = AppSettings.language.value == 'ar';
    _showSnack(isAr ? 'جاري تجهيز التقرير، يرجى الانتظار...' : 'Preparing report, please wait...');
    try {
      final token = await _getToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
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
      url += "&period=$_historyPeriod&_t=$timestamp";
      
      final res = await Dio().get(
        url,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes, // Important for downloading files
        ),
      );

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.get('user_id')?.toString() ?? 'unknown';
        final safeDate = DateTime.now().toString().split(' ')[0];
        final safeTime = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'attendance_report_u${userId}_${safeDate}_$safeTime.pdf';
        final bytes = Uint8List.fromList(res.data as List<int>);

        // حفظ نسخة داخلية للقائمة
        final dir = await getApplicationDocumentsDirectory();
        final internalPath = '${dir.path}/$fileName';
        await File(internalPath).writeAsBytes(bytes);
        await _loadGeneratedReports();

        // حفظ في مكان اختيار المستخدم
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: isAr ? 'حفظ تقرير الحضور' : 'Save Attendance Report',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes,
        );

        if (savedPath != null) {
          _showSnack(isAr ? '✅ تم الحفظ بنجاح' : '✅ Saved successfully');
        } else {
          _showSnack(isAr ? 'تم إنشاء التقرير ✅' : 'Report generated successfully ✅');
        }
      } else {
        _showSnack(isAr ? 'فشل تحميل التقرير' : 'Failed to download report');
      }
    } catch (e) {
      debugPrint('⛔ PDF Export Error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          _showSnack(isAr ? 'لا توجد جلسات حضور في هذه الفترة لتوليد تقرير.' : 'No attendance sessions found in this period to generate a report.');
        } else {
          // محاولة قراءة الخطأ من السيرفر (لو كان JSON بالرغم من أننا طلبنا bytes)
          String errorMsg = isAr ? 'خطأ خادم: ${e.response?.statusCode}' : 'Server error: ${e.response?.statusCode}';
          try {
            if (e.response?.data != null) {
               errorMsg = isAr ? 'خطأ خادم: ${String.fromCharCodes(e.response!.data)}' : 'Server error: ${String.fromCharCodes(e.response!.data)}';
            }
          } catch (_) {}
          _showSnack(errorMsg);
        }
      } else {
        _showSnack(isAr ? 'حدث خطأ أثناء تحميل التقرير: $e' : 'Error downloading report: $e');
      }
    }
  }

  void _showStudentListSheet([String initialFilter = 'all']) {
    final isAr = AppSettings.language.value == 'ar';
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;
    String activeFilter = initialFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final presentStudents = _allStudents.where((s) => s['status'] == 'present').toList();
            final absentStudents = _allStudents.where((s) => s['status'] == 'absent').toList();

            List<Map<String, dynamic>> displayedStudents;
            if (activeFilter == 'present') {
              displayedStudents = presentStudents;
            } else if (activeFilter == 'absent') {
              displayedStudents = absentStudents;
            } else {
              displayedStudents = _allStudents;
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtrl) {
                return Directionality(
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                              isAr ? 'سجل طلاب الجلسة' : 'Session Students Log',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _yellow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAr
                                    ? '$_presentCount / $_totalCount حاضر'
                                    : '$_presentCount / $_totalCount Present',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filter Buttons (الكل / الحاضرون / الغائبون)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              _buildFilterTab(
                                label: isAr
                                    ? 'الكل (${_allStudents.length})'
                                    : 'All (${_allStudents.length})',
                                isSelected: activeFilter == 'all',
                                activeColor: _yellow,
                                textColor: Colors.black,
                                onTap: () => setSheetState(() => activeFilter = 'all'),
                              ),
                              _buildFilterTab(
                                label: isAr
                                    ? 'الحاضرون (${presentStudents.length})'
                                    : 'Present (${presentStudents.length})',
                                isSelected: activeFilter == 'present',
                                activeColor: Colors.green.shade600,
                                textColor: Colors.white,
                                onTap: () => setSheetState(() => activeFilter = 'present'),
                              ),
                              _buildFilterTab(
                                label: isAr
                                    ? 'الغائبون (${absentStudents.length})'
                                    : 'Absent (${absentStudents.length})',
                                isSelected: activeFilter == 'absent',
                                activeColor: Colors.red.shade600,
                                textColor: Colors.white,
                                onTap: () => setSheetState(() => activeFilter = 'absent'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(),

                      Expanded(
                        child: displayedStudents.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      activeFilter == 'present'
                                          ? Icons.person_off_outlined
                                          : activeFilter == 'absent'
                                              ? Icons.check_circle_outline
                                              : Icons.group_off_outlined,
                                      color: activeFilter == 'absent' ? Colors.green : Colors.grey,
                                      size: 50,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      activeFilter == 'present'
                                          ? (isAr ? 'لم يقم أي طالب بمسح الرمز حتى الآن' : 'No student has scanned the code yet')
                                          : activeFilter == 'absent'
                                              ? (isAr ? 'ما في غائبين (الجميع حاضر!)' : 'No absent students (All present!)')
                                              : (isAr ? 'لا يوجد طلاب في هذه الجلسة' : 'No students in this session'),
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollCtrl,
                                itemCount: displayedStudents.length,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (_, i) {
                                  final s = displayedStudents[i];
                                  final isPresent = s['status'] == 'present';
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: isPresent
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : Colors.red.withValues(alpha: 0.12),
                                      child: Icon(
                                        isPresent ? Icons.check : Icons.close,
                                        color: isPresent ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      s['name'] as String? ?? '',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      isPresent
                                          ? (isAr ? 'قام بالمسح وتسجيل الحضور' : 'Scanned & recorded attendance')
                                          : (isAr ? 'لم يقم بالمسح (غائب)' : 'Did not scan (Absent)'),
                                      style: TextStyle(
                                        color: isPresent ? Colors.green.shade700 : Colors.red.shade400,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isPresent
                                            ? (isAr ? 'حاضر' : 'Present')
                                            : (isAr ? 'غائب' : 'Absent'),
                                        style: TextStyle(
                                          color: isPresent ? Colors.green : Colors.red,
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
      },
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? textColor
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppSettings.language.value == 'ar';
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isAr ? Icons.arrow_back : Icons.arrow_back_ios_new,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isAr ? 'تسجيل الحضور' : 'Attendance Recording',
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
            bottom: TabBar(
              controller: _attendanceTabController,
              labelColor: isDark ? _yellow : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _yellow,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: [
                Tab(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  text: isAr ? 'إعداد الجلسة' : 'Session Setup',
                ),
                Tab(
                  icon: const Icon(Icons.history_outlined, size: 18),
                  text: isAr ? 'سجل الحضور' : 'Attendance Log',
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              _buildAttendanceTabView(cardColor, textColor, isDark),
              // زر + لتوليد PDF في تبويب سجل الحضور
              if (_attendanceTabController.index == 1)
                Positioned(
                  bottom: 90,
                  left: isAr ? 16 : null,
                  right: isAr ? null : 16,
                  child: FloatingActionButton(
                    heroTag: 'generatePdf',
                    backgroundColor: _yellow,
                    onPressed: _showGenerateReportSheet,
                    child: const Icon(Icons.add, color: Colors.black, size: 28),
                  ),
                ),
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

  Widget _buildAttendanceTabView(Color cardColor, Color textColor, bool isDark) {
    final isAr = AppSettings.language.value == 'ar';
    return TabBarView(
      controller: _attendanceTabController,
      children: [
        // تبويب إعداد الجلسة
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSessionSettingsCard(cardColor, textColor, isDark),
              const SizedBox(height: 25),
              if (_sessionActive && _qrToken != null) ...[
                _buildDividerWithText(isAr ? 'الرمز النشط' : 'Active QR Code', textColor),
                const SizedBox(height: 15),
                _buildQRCodeCard(cardColor, textColor, isDark),
              ],
              if (_sessionEnded) ...[
                const SizedBox(height: 25),
                _buildDividerWithText(isAr ? 'تصدير الكشف' : 'Export Sheet', textColor),
                const SizedBox(height: 15),
                _buildExportCard(cardColor, textColor),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
        // تبويب سجل الحضور
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportsListOnly(cardColor, textColor, isDark),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  // قائمة التقارير فقط (بدون فورم)
  Widget _buildReportsListOnly(Color cardColor, Color textColor, bool isDark) {
    final isAr = AppSettings.language.value == 'ar';
    if (_generatedReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                isAr
                    ? 'لا توجد تقارير بعد\nاضغط + لتوليد تقرير'
                    : 'No reports yet\nTap + to generate a report',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_special, color: _yellow, size: 20),
            const SizedBox(width: 8),
            Text(
              isAr
                  ? 'التقارير المولدة سابقاً (${_generatedReports.length})'
                  : 'Previously Generated Reports (${_generatedReports.length})',
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _generatedReports.length,
          separatorBuilder: (ctx2, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, idx) {
            final file = _generatedReports[idx];
            final dateModified = file.lastModifiedSync();
            final displayDate =
                "${dateModified.year}-${dateModified.month.toString().padLeft(2, '0')}-${dateModified.day.toString().padLeft(2, '0')} "
                "${dateModified.hour.toString().padLeft(2, '0')}:${dateModified.minute.toString().padLeft(2, '0')}";
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                title: Text(
                  isAr ? 'سجل حضور' : 'Attendance Record',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(displayDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                      onPressed: () => OpenFilex.open(file.path),
                      tooltip: isAr ? 'فتح' : 'Open',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      onPressed: () => Share.shareXFiles([XFile(file.path)], text: isAr ? 'تقرير الحضور' : 'Attendance Report'),
                      tooltip: isAr ? 'مشاركة' : 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(isAr ? 'تأكيد الحذف' : 'Confirm Deletion'),
                          content: Text(isAr ? 'هل أنت متأكد من حذف هذا التقرير؟' : 'Are you sure you want to delete this report?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(isAr ? 'إلغاء' : 'Cancel'),
                            ),
                            TextButton(
                              onPressed: () { Navigator.pop(ctx); _deleteReport(file); },
                              child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                      tooltip: isAr ? 'حذف' : 'Delete',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // bottom sheet الفورم
  void _showGenerateReportSheet() {
    final isAr = AppSettings.language.value == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // حساب الدورات المفلترة داخل الـ modal
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

          final uniqueProgramYears = <String, Map<String, dynamic>>{};
          for (var c in _allCourses) {
            final pid = c['program_id'].toString();
            final year = c['year'];
            final key = '${pid}_$year';
            if (!uniqueProgramYears.containsKey(key)) {
              final pName = _allPrograms.firstWhere(
                (p) => p['id'].toString() == pid,
                orElse: () => {'name': isAr ? 'غير معروف' : 'Unknown'},
              )['name'];
              uniqueProgramYears[key] = {
                'key': key,
                'display': '$pName - ${isAr ? (year == 1 ? "السنة الأولى" : "السنة الثانية") : (year == 1 ? "Year 1" : "Year 2")}',
              };
            }
          }

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              padding: EdgeInsets.only(
                top: 24, left: 20, right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: _yellow, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'توليد تقرير PDF' : 'Generate PDF Report',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // نطاق التقرير
                    _buildFieldLabel(isAr ? 'النطاق' : 'Scope', textColor),
                    _buildDropdown(
                      hint: isAr ? 'اختر النطاق' : 'Select Scope',
                      value: _historyScope,
                      items: [
                        DropdownMenuItem(
                          value: 'my_courses',
                          child: Text(isAr ? 'المواد الموكلة إلي' : 'My Assigned Courses'),
                        ),
                        DropdownMenuItem(
                          value: 'advisor_class',
                          child: Text(isAr ? 'دورتي الإشرافية' : 'My Supervisory Class'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _historyScope = val;
                            _historyProgramYearKey = null;
                            _historyCourseId = null;
                          });
                          setModalState(() {});
                        }
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 15),

                    if (_historyScope == 'my_courses') ...[
                      _buildFieldLabel(isAr ? 'الدورة والسنة' : 'Program & Year', textColor),
                      _buildDropdown(
                        hint: isAr ? 'اختر الدورة والسنة' : 'Select Program & Year',
                        value: _historyProgramYearKey,
                        items: uniqueProgramYears.values.map((p) => DropdownMenuItem<String>(
                          value: p['key'] as String,
                          child: Text(p['display'] as String, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) {
                          setState(() { _historyProgramYearKey = val; _historyCourseId = null; });
                          setModalState(() {});
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 15),
                      _buildFieldLabel(isAr ? 'المادة' : 'Course', textColor),
                      _buildDropdown(
                        hint: isAr ? 'اختر المادة (أو جميع المواد)' : 'Select Course (or All Courses)',
                        value: _historyCourseId,
                        items: [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Text(isAr ? 'جميع المواد' : 'All Courses'),
                          ),
                          ...filteredHistoryCourses.map((c) => DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Text(c['title'] as String, overflow: TextOverflow.ellipsis),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() => _historyCourseId = val);
                          setModalState(() {});
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 15),
                    ],

                    _buildFieldLabel(isAr ? 'الفترة الزمنية' : 'Time Period', textColor),
                    _buildDropdown(
                      hint: isAr ? 'الفترة الزمنية' : 'Time Period',
                      value: _historyPeriod,
                      items: [
                        DropdownMenuItem(value: 'today', child: Text(isAr ? 'اليوم' : 'Today')),
                        DropdownMenuItem(value: 'week', child: Text(isAr ? 'أسبوع' : 'Week')),
                        DropdownMenuItem(value: 'month', child: Text(isAr ? 'شهر' : 'Month')),
                        DropdownMenuItem(value: 'semester', child: Text(isAr ? 'من بداية الفصل' : 'Since Semester Start')),
                      ],
                      onChanged: (val) {
                        setState(() => _historyPeriod = val ?? 'today');
                        setModalState(() {});
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _yellow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_historyScope == 'my_courses') {
                            if (_historyProgramYearKey == null) {
                              _showSnack(isAr ? 'الرجاء اختيار الدورة والسنة' : 'Please select program and year');
                              return;
                            }
                            if (_historyCourseId == null) {
                              _showSnack(isAr ? 'الرجاء اختيار المادة' : 'Please select course');
                              return;
                            }
                          }
                          Navigator.pop(ctx);
                          _exportHistoryPdf();
                        },
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                        label: Text(
                          isAr ? 'توليد الكشف (PDF)' : 'Generate Report (PDF)',
                          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildExportCard(Color cardColor, Color textColor) {
    final isAr = AppSettings.language.value == 'ar';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr
                    ? 'انتهت الجلسة — يمكنك تصدير الكشف'
                    : 'Session ended — You can export the sheet',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.table_chart_outlined, color: Colors.green),
              label: Text(
                isAr ? 'تصدير كشف اليوم (Excel)' : 'Export Today Sheet (Excel)',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _exportExcel,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: Text(
                isAr ? 'تصدير كشف المادة الشامل (PDF)' : 'Export Comprehensive PDF',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _exportPdf,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSettingsCard(
      Color cardColor, Color textColor, bool isDark) {
    final isAr = AppSettings.language.value == 'ar';
    // استخراج الدورات المميزة
    final uniqueProgramYears = <String, Map<String, dynamic>>{};
    for (var c in _allCourses) {
      final pid = c['program_id'].toString();
      final year = c['year'];
      final key = '${pid}_$year';
      if (!uniqueProgramYears.containsKey(key)) {
        final pName = _allPrograms.firstWhere(
          (p) => p['id'].toString() == pid, 
          orElse: () => {'name': isAr ? 'غير معروف' : 'Unknown'}
        )['name'];
        uniqueProgramYears[key] = {
          'key': key,
          'display': '$pName - ${isAr ? (year == 1 ? "السنة الأولى" : "السنة الثانية") : (year == 1 ? "Year 1" : "Year 2")}',
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
              Text(
                isAr ? 'إعدادات الجلسة' : 'Session Settings',
                style: const TextStyle(
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
                    _buildFieldLabel(isAr ? 'الدورة والسنة' : 'Program & Year', textColor, isAr),
                    _buildDropdown(
                      hint: isAr ? 'اختر الدورة والسنة' : 'Select Program & Year',
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
            _buildFieldLabel(isAr ? 'المادة الدراسية' : 'Course', textColor, isAr),
            _filteredCourses.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isAr ? 'لا توجد مواد لهذه الدورة والسنة' : 'No courses found for this program and year',
                        style: const TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  )
                : _buildDropdown(
                    hint: isAr ? 'اختر المادة' : 'Select Course',
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
                _sessionActive
                    ? (isAr ? 'جلسة نشطة' : 'Session Active')
                    : (isAr ? 'بدء الجلسة الآن' : 'Start Session Now'),
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
    final isAr = AppSettings.language.value == 'ar';
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(backgroundColor: Colors.green, radius: 4),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'مباشر' : 'Live',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            isAr ? 'رمز الحضور السريع' : 'Quick Attendance QR',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'اطلب من الطلاب مسح الرمز أدناه لتسجيل الحضور'
                : 'Ask students to scan the QR code below to record attendance',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          // عداد تجديد QR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: _yellow, size: 16),
              const SizedBox(width: 6),
              Text(
                isAr
                    ? 'يتجدد الرمز خلال $_qrCountdown ثانية'
                    : 'Code refreshes in $_qrCountdown s',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.hourglass_empty, color: Colors.orange, size: 14),
              const SizedBox(width: 4),
              Text(
                '${isAr ? "الجلسة: " : "Session: "}${(_sessionCountdown ~/ 60).toString().padLeft(2, '0')}:${(_sessionCountdown % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),

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

          // زر كشف الطلاب الموحد (يحتوي على الفلترة الكاملة)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.groups_outlined, color: Colors.black, size: 20),
              label: Text(
                isAr ? 'عرض كشف الطلاب (حضور / غياب)' : 'View Students Sheet (Present / Absent)',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () => _fetchAbsentList('all'),
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
                  : Text(
                      isAr ? 'إنهاء الجلسة وإغلاق السجل' : 'End Session & Close Sheet',
                      style: const TextStyle(
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

  Widget _buildFieldLabel(String label, Color textColor, [bool isAr = true]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, right: isAr ? 4 : 0, left: isAr ? 0 : 4),
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
