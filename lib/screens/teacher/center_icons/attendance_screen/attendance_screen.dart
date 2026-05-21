import 'dart:io';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:shared_preferences/shared_preferences.dart';
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

  // الـ dropdown الأول: أسماء المواد (بدون تكرار)
  List<String> _uniqueTitles = [];
  String? _selectedTitle;

  // دورات المعلم حسب اختصاصه (القسم)
  List<Map<String, dynamic>> _allPrograms = [];
  List<Map<String, dynamic>> _filteredPrograms = [];
  String? _selectedProgramId;

  // course_id المحدد تلقائياً من (المادة + الدورة)
  String? _selectedCourseId;

  // السنة الدراسية
  String? _selectedYear;
  final List<String> _years = ['السنة الأولى', 'السنة الثانية'];

  // بيانات الجلسة الحالية
  int? _sessionId;
  String? _qrToken;
  bool _sessionActive = false;

  // قوائم الحضور والغياب
  List<Map<String, dynamic>> _absentStudents = [];
  List<Map<String, dynamic>> _allStudents = [];
  int _presentCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchPrograms();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchCourses() async {
    try {
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/courses",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as List<dynamic>? ?? [];

        final courses = data.map<Map<String, dynamic>>((c) => {
          'id': c['id'].toString(),
          'title': c['title'].toString(),
          'level': c['level']?.toString() ?? '',
          'program_id': c['program_id']?.toString() ?? '',
          'program_name': c['program_name']?.toString() ?? '',
        }).toList();

        final seen = <String>{};
        final titles = courses
            .map((c) => c['title'] as String)
            .where(seen.add)
            .toList();

        setState(() {
          _allCourses = courses;
          _uniqueTitles = titles;
        });
      }
    } catch (e) {
      debugPrint('⛔ Courses Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _fetchPrograms() async {
    try {
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/programs",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _allPrograms = data
              .map<Map<String, dynamic>>((p) => {
                    'id': p['id'].toString(),
                    'name': p['name'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Programs Error: $e');
    }
  }

  void _onTitleSelected(String? title) {
    if (title == null) return;
    // عرض كل برامج قسم المعلم بدون فلترة — المعلم يختار الدورة بحرية
    final coursesForTitle = _allCourses.where((c) => c['title'] == title).toList();
    final autoId = coursesForTitle.length == 1 ? coursesForTitle[0]['id'] as String : null;

    setState(() {
      _selectedTitle     = title;
      _filteredPrograms  = List.from(_allPrograms);
      _selectedProgramId = null;
      _selectedCourseId  = _allPrograms.isEmpty ? autoId : null;
    });
  }

  void _onProgramSelected(String? programId) {
    if (programId == null) return;
    // أولاً: كورس يطابق المادة + الدورة بالضبط
    var match = _allCourses.firstWhere(
      (c) => c['title'] == _selectedTitle && c['program_id'] == programId,
      orElse: () => {},
    );
    // إذا ما في → اختار أول كورس بهذا العنوان
    if (match.isEmpty) {
      match = _allCourses.firstWhere(
        (c) => c['title'] == _selectedTitle,
        orElse: () => {},
      );
    }
    setState(() {
      _selectedProgramId = programId;
      _selectedCourseId  = match.isNotEmpty ? match['id'] as String : null;
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
      final courseName = _selectedTitle ?? 'غير محدد';

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

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/كشف_الحضور_$dateStr.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // مشاركة الملف
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تسجيل الحضور والغياب',
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
            SingleChildScrollView(
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

  Widget _buildSessionSettingsCard(
      Color cardColor, Color textColor, bool isDark) {
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

          // Dropdown 1 — المادة الدراسية
          _buildFieldLabel('المادة الدراسية', textColor),
          _isLoadingCourses
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: _yellow, strokeWidth: 2),
                  ),
                )
              : _buildDropdown(
                  hint: 'اختر المادة',
                  value: _selectedTitle,
                  items: _uniqueTitles
                      .map((t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: _sessionActive ? null : _onTitleSelected,
                  isDark: isDark,
                ),

          const SizedBox(height: 16),

          // Dropdown 2 — الدورة (يظهر إذا في برامج لقسم المعلم)
          if (_selectedTitle != null && _allPrograms.isNotEmpty) ...[
            _buildFieldLabel('الدورة', textColor),
            _buildDropdown(
              hint: 'اختر الدورة',
              value: _selectedProgramId,
              items: _filteredPrograms
                  .map((p) => DropdownMenuItem<String>(
                        value: p['id'] as String,
                        child: Text(p['name'] as String),
                      ))
                  .toList(),
              onChanged: _sessionActive ? null : _onProgramSelected,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],

          // Dropdown 3 — السنة الدراسية (يظهر دائماً بعد اختيار المادة)
          if (_selectedTitle != null) ...[
            // Dropdown 3 — السنة الدراسية
            _buildFieldLabel('السنة الدراسية', textColor),
            _buildDropdown(
              hint: 'اختر السنة',
              value: _selectedYear,
              items: _years
                  .map((y) => DropdownMenuItem<String>(value: y, child: Text(y)))
                  .toList(),
              onChanged: _sessionActive
                  ? null
                  : (val) => setState(() => _selectedYear = val),
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
                'تصدير كشف Excel',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
