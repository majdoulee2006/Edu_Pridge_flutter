import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';

const _yellow = Color(0xFFFFCC00);

class ReportRequestScreen extends StatefulWidget {
  const ReportRequestScreen({super.key});
  @override
  State<ReportRequestScreen> createState() => _ReportRequestScreenState();
}

class _ReportRequestScreenState extends State<ReportRequestScreen> {
  List<Map<String, dynamic>> _myRequests      = [];
  List<Map<String, dynamic>> _gradeRequests   = [];
  bool _isLoadingRequests = true;

  List<Map<String, dynamic>> _teachers  = [];
  List<Map<String, dynamic>> _students  = [];
  List<Map<String, dynamic>> _courses   = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _loadDropdowns();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoadingRequests = true);
    try {
      final token = await _token();
      final base = ApiService().baseUrl;
      final headers = {"Authorization": "Bearer $token"};

      final results = await Future.wait([
        Dio().get("$base/department-head/report-requests?type=my",     options: Options(headers: headers)),
        Dio().get("$base/department-head/grade-report-requests",       options: Options(headers: headers)),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].statusCode == 200 && results[0].data['success'] == true)
            _myRequests = List<Map<String, dynamic>>.from(results[0].data['data'] ?? []);
          if (results[1].statusCode == 200 && results[1].data['success'] == true)
            _gradeRequests = List<Map<String, dynamic>>.from(results[1].data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('⛔ fetchAll: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadDropdowns() async {
    try {
      final token = await _token();
      final base  = ApiService().baseUrl;
      final h     = {"Authorization": "Bearer $token"};

      final res = await Future.wait([
        Dio().get("$base/department-head/users/trainers",  options: Options(headers: h)),
        Dio().get("$base/department-head/users/students",  options: Options(headers: h)),
        Dio().get("$base/department-head/courses",         options: Options(headers: h)),
      ]);

      if (mounted) {
        setState(() {
          if (res[0].statusCode == 200) _teachers = List<Map<String, dynamic>>.from(res[0].data['data'] ?? []);
          if (res[1].statusCode == 200) _students = List<Map<String, dynamic>>.from(res[1].data['data'] ?? []);
          if (res[2].statusCode == 200) _courses  = List<Map<String, dynamic>>.from(res[2].data['data'] ?? res[2].data['courses'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('⛔ loadDropdowns: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // زر الإضافة — 3 خيارات
  // ═══════════════════════════════════════════════

  void _showNewReportPicker() {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Text('نوع التقرير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
              const SizedBox(height: 20),
              _pickerOption(
                icon: Icons.person_pin_circle_outlined,
                color: Colors.purple,
                title: 'تقرير سلوكي',
                subtitle: 'يرسله المسؤول ليكتب تقييم الطالب',
                onTap: () { Navigator.pop(context); _showBehavioralForm(); },
              ),
              const SizedBox(height: 12),
              _pickerOption(
                icon: Icons.school_outlined,
                color: Colors.blue,
                title: 'تقرير أكاديمي',
                subtitle: 'النظام يولّده تلقائياً للطالب',
                onTap: () { Navigator.pop(context); _showAcademicForm(); },
              ),
              const SizedBox(height: 12),
              _pickerOption(
                icon: Icons.grade_outlined,
                color: Colors.orange,
                title: 'تقرير علامات',
                subtitle: 'تطلب من المعلم إرسال علامات مادة معينة',
                onTap: () { Navigator.pop(context); _showGradeReportForm(); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // فورم التقرير السلوكي
  // ═══════════════════════════════════════════════

  void _showBehavioralForm() {
    String? selStudent, selStudentName, selTeacher, selTeacherName;
    String notes = '';
    bool submitting = false;
    List<Map<String, dynamic>> filteredTeachers = List.from(_teachers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSB) {
          final textColor = Theme.of(ctx2).textTheme.bodyLarge?.color ?? Colors.black;
          final cardColor = Theme.of(ctx2).cardColor;
          final isDark = Theme.of(ctx2).brightness == Brightness.dark;
          final fieldColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F7F9);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.person_pin_circle_outlined, color: Colors.purple, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text('تقرير سلوكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // اختيار الطالب
                    Text('الطالب المعني', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _dropdownTile(
                      label: selStudentName ?? 'اختر الطالب...',
                      selected: selStudent != null,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      onTap: () => _showSearchDialog(
                        items: _students,
                        searchHint: 'ابحث باسم الطالب...',
                        onSelected: (s) {
                          if (s == null) return;
                          setSB(() {
                            selStudent     = s['id']?.toString();
                            selStudentName = '${s['full_name']} - ${s['student_code'] ?? ''}';
                          });
                          // جلب معلمي هذا الطالب
                          _loadTeachersForStudent(s['id'].toString()).then((teachers) {
                            setSB(() => filteredTeachers = teachers);
                          });
                        },
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // اختيار المدرب
                    Text('المدرب المسؤول', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _dropdownTile(
                      label: selTeacherName ?? 'اختر المدرب...',
                      selected: selTeacher != null,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      onTap: () => _showSearchDialog(
                        items: filteredTeachers,
                        searchHint: 'ابحث باسم المدرب...',
                        onSelected: (t) {
                          if (t == null) return;
                          setSB(() {
                            selTeacher     = t['id']?.toString();
                            selTeacherName = t['full_name'] as String?;
                          });
                        },
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ملاحظات
                    Text('ملاحظات (اختياري)', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => notes = v,
                      maxLines: 3,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'أي نقاط تريد التركيز عليها...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selStudent != null && selTeacher != null ? _yellow : Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: (selStudent == null || selTeacher == null || submitting) ? null : () async {
                          setSB(() => submitting = true);
                          await _submitReport(selStudent!, selTeacher!, false, notes);
                          if (mounted) Navigator.pop(ctx2);
                        },
                        child: submitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('إرسال طلب التقييم السلوكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  // ═══════════════════════════════════════════════
  // فورم التقرير الأكاديمي
  // ═══════════════════════════════════════════════

  void _showAcademicForm() {
    String? selStudent, selStudentName;
    String notes = '';
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSB) {
          final textColor = Theme.of(ctx2).textTheme.bodyLarge?.color ?? Colors.black;
          final isDark = Theme.of(ctx2).brightness == Brightness.dark;
          final fieldColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F7F9);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.school_outlined, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text('تقرير أكاديمي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('النظام سيحسب المعدل ونسبة الحضور تلقائياً', style: TextStyle(color: Colors.blue, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('الطالب المعني', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _dropdownTile(
                      label: selStudentName ?? 'اختر الطالب...',
                      selected: selStudent != null,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      onTap: () => _showSearchDialog(
                        items: _students,
                        searchHint: 'ابحث باسم الطالب...',
                        onSelected: (s) {
                          if (s == null) return;
                          setSB(() {
                            selStudent     = s['id']?.toString();
                            selStudentName = '${s['full_name']} - ${s['student_code'] ?? ''}';
                          });
                        },
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('ملاحظات (اختياري)', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => notes = v,
                      maxLines: 3,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'أي نقاط تريد التركيز عليها...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selStudent != null ? _yellow : Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: (selStudent == null || submitting) ? null : () async {
                          setSB(() => submitting = true);
                          await _submitReport(selStudent!, null, true, notes);
                          if (mounted) Navigator.pop(ctx2);
                        },
                        child: submitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('توليد التقرير الأكاديمي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  // ═══════════════════════════════════════════════
  // فورم تقرير العلامات
  // ═══════════════════════════════════════════════

  void _showGradeReportForm() {
    String? selCourse, selCourseTitle, selTeacher, selTeacherName;
    List<Map<String, dynamic>> courseTeachers = [];
    bool loadingTeachers = false;
    bool submitting = false;
    String notes = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSB) {
          final textColor = Theme.of(ctx2).textTheme.bodyLarge?.color ?? Colors.black;
          final isDark = Theme.of(ctx2).brightness == Brightness.dark;
          final fieldColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F7F9);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.grade_outlined, color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text('تقرير علامات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'إذا كانت العلامات موجودة يصلك التقرير فوراً، وإلا يُرسل إشعار للمعلم',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // اختيار المادة
                    Text('المادة / الدورة', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _dropdownTile(
                      label: selCourseTitle ?? 'اختر المادة...',
                      selected: selCourse != null,
                      fieldColor: fieldColor,
                      textColor: textColor,
                      onTap: () => _showSearchDialog(
                        items: _courses.map((c) => {
                          'id': c['course_id'] ?? c['id'],
                          'full_name': c['title'] ?? c['name'] ?? '',
                        }).toList(),
                        searchHint: 'ابحث باسم المادة...',
                        onSelected: (c) async {
                          if (c == null) return;
                          setSB(() {
                            selCourse      = c['id']?.toString();
                            selCourseTitle = c['full_name'] as String?;
                            selTeacher     = null;
                            selTeacherName = null;
                            courseTeachers = [];
                            loadingTeachers = true;
                          });
                          // جلب معلمي هذه المادة
                          try {
                            final token = await _token();
                            final res = await Dio().get(
                              "${ApiService().baseUrl}/department-head/courses/${c['id']}/teachers",
                              options: Options(headers: {"Authorization": "Bearer $token"}),
                            );
                            setSB(() {
                              courseTeachers  = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
                              loadingTeachers = false;
                            });
                          } catch (_) {
                            setSB(() => loadingTeachers = false);
                          }
                        },
                        textColor: textColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // اختيار المعلم
                    Text('المعلم المسؤول عن المادة', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (loadingTeachers)
                      const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: _yellow, strokeWidth: 2)))
                    else
                      _dropdownTile(
                        label: selTeacherName ?? (selCourse == null ? 'اختر المادة أولاً...' : 'اختر المعلم...'),
                        selected: selTeacher != null,
                        fieldColor: fieldColor,
                        textColor: textColor,
                        onTap: selCourse == null ? null : () => _showSearchDialog(
                          items: courseTeachers.map((t) => {
                            'id': (t['user_id'] ?? t['id'])?.toString(),
                            'full_name': t['full_name'] ?? t['name'] ?? '',
                          }).toList(),
                          searchHint: 'ابحث باسم المعلم...',
                          onSelected: (t) {
                            if (t == null) return;
                            setSB(() {
                              selTeacher     = t['id']?.toString();
                              selTeacherName = t['full_name'] as String?;
                            });
                          },
                          textColor: textColor,
                          isDark: isDark,
                        ),
                      ),
                    const SizedBox(height: 14),

                    // ملاحظات
                    Text('ملاحظات (اختياري)', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (v) => notes = v,
                      maxLines: 2,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ملاحظة للمعلم...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (selCourse != null && selTeacher != null) ? _yellow : Colors.grey.shade300,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: (selCourse == null || selTeacher == null || submitting) ? null : () async {
                          setSB(() => submitting = true);
                          await _submitGradeReport(selCourse!, selTeacher!, notes, ctx2);
                          if (mounted) Navigator.pop(ctx2);
                        },
                        child: submitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('إرسال طلب تقرير العلامات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  // ═══════════════════════════════════════════════
  // API calls
  // ═══════════════════════════════════════════════

  Future<void> _submitReport(String studentId, String? teacherId, bool isAcademic, String notes) async {
    try {
      final token = await _token();
      final res = await Dio().post(
        "${ApiService().baseUrl}/department-head/report-requests",
        data: {
          'student_id': studentId,
          'teacher_id': teacherId,
          'report_type': isAcademic ? 'academic' : 'behavioral',
          'notes': notes,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final msg = res.data['message'] as String? ?? 'تم إرسال الطلب';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
        _fetchAll();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red));
    }
  }

  Future<void> _submitGradeReport(String courseId, String teacherUserId, String notes, BuildContext sheetCtx) async {
    try {
      final token = await _token();
      final res = await Dio().post(
        "${ApiService().baseUrl}/department-head/grade-report-requests",
        data: {
          'course_id':      courseId,
          'teacher_user_id': teacherUserId,
          'notes':          notes,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final alreadyAvailable = res.data['already_available'] == true;
        final msg = res.data['message'] as String? ?? 'تم الإرسال';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alreadyAvailable ? '✅ البيانات موجودة — يمكنك مراجعة التقرير' : msg),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        _fetchAll();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red));
    }
  }

  Future<List<Map<String, dynamic>>> _loadTeachersForStudent(String studentId) async {
    try {
      final token = await _token();
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/users/trainers?student_id=$studentId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    } catch (_) {
      return _teachers;
    }
  }

  // ═══════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleBtn(Icons.settings_outlined, cardColor, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(userName: "رئيس القسم", userRole: "إدارة")));
                        }),
                        Column(
                          children: [
                            Text('التقارير', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('إدارة تقارير القسم', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                        _circleBtn(Icons.arrow_back, cardColor, () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  // قائمة التقارير
                  Expanded(
                    child: _isLoadingRequests
                        ? const Center(child: CircularProgressIndicator(color: _yellow))
                        : RefreshIndicator(
                            onRefresh: _fetchAll,
                            color: _yellow,
                            child: _allReports().isEmpty
                                ? ListView(
                                    children: [
                                      const SizedBox(height: 120),
                                      Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.assignment_outlined, size: 70, color: Colors.grey.shade300),
                                            const SizedBox(height: 16),
                                            Text('لا توجد تقارير بعد', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                                            const SizedBox(height: 8),
                                            Text('اضغط + لإنشاء تقرير جديد', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                                    itemCount: _allReports().length,
                                    itemBuilder: (_, i) {
                                      final r = _allReports()[i];
                                      return r['_type'] == 'grade'
                                          ? _buildGradeCard(r, cardColor, textColor, isDark)
                                          : _buildReportCard(r, cardColor, textColor, isDark);
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
              // FAB
              Positioned(
                left: 20,
                bottom: 100,
                child: FloatingActionButton(
                  backgroundColor: _yellow,
                  foregroundColor: Colors.black,
                  onPressed: _showNewReportPicker,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
              CustomBottomNav(
                currentIndex: 0,
                centerButton: const Boss_Center_Icon(),
                onHomeTap:          () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
                onProfileTap:       () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
                onMessagesTap:      () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _allReports() {
    final List<Map<String, dynamic>> all = [];
    for (final r in _gradeRequests) all.add({...r, '_type': 'grade'});
    for (final r in _myRequests)    all.add({...r, '_type': 'report'});
    all.sort((a, b) {
      final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });
    return all;
  }

  // ─── كرت تقرير عادي ───────────────────────────

  Widget _buildReportCard(Map<String, dynamic> r, Color cardColor, Color textColor, bool isDark) {
    final status      = r['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';
    final isAcademic  = r['report_type'] == 'academic';
    final typeLabel   = isAcademic ? 'أكاديمي' : 'سلوكي';
    final typeColor   = isAcademic ? Colors.blue : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isAcademic ? Icons.school_outlined : Icons.person_pin_circle_outlined, color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['student_name'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                const SizedBox(height: 3),
                if ((r['teacher_name'] as String?) != null)
                  Text('المدرب: ${r['teacher_name']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _badge(typeLabel, typeColor.withValues(alpha: 0.1), typeColor),
                    _badge(isCompleted ? 'مكتمل' : 'قيد الانتظار',
                        (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                        isCompleted ? Colors.green : Colors.orange),
                  ],
                ),
                if (isCompleted) ...[
                  const Divider(height: 20, thickness: 0.5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (r['sent_to_parent'] != true && r['sent_to_parent'] != 1)
                        _actionBtn(Icons.send_rounded, 'إرسال للأهل', Colors.blue, () => _sendToParents(r['id'])),
                      _actionBtn(Icons.visibility_outlined, 'قراءة', Colors.teal, () => _viewReportDetails(r)),
                      _actionBtn(Icons.download_outlined, 'تنزيل', Colors.indigo, () => _downloadReport(r)),
                      _actionBtn(Icons.delete_outline, 'حذف', Colors.red, () => _deleteReport(r['id'])),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── كرت تقرير علامات ────────────────────────

  Widget _buildGradeCard(Map<String, dynamic> r, Color cardColor, Color textColor, bool isDark) {
    final status      = r['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isCompleted ? Border.all(color: Colors.green.withValues(alpha: 0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.grade_outlined, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['course_title'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                const SizedBox(height: 3),
                Text('المعلم: ${r['teacher_name'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _badge('علامات', Colors.orange.withValues(alpha: 0.1), Colors.orange),
                    _badge(
                      isCompleted ? 'جاهز للمراجعة' : 'في انتظار المعلم',
                      (isCompleted ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                      isCompleted ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
                if (isCompleted) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 10),
                  _actionBtn(Icons.bar_chart_rounded, 'عرض العلامات', Colors.green, () {
                    final courseId    = r['course_id']?.toString() ?? '';
                    final courseTitle = r['course_title'] as String? ?? '';
                    _showGradeEntriesDialog(courseId, courseTitle);
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildExcel(List<dynamic> entries, String courseTitle) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['علامات'];
    excel.setDefaultSheet('علامات');

    void cell(int r, int c, dynamic v, {bool bold = false, String? color}) {
      final s = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      s.value = ex.TextCellValue(v?.toString() ?? '—');
      s.cellStyle = ex.CellStyle(bold: bold, backgroundColorHex: color != null ? ex.ExcelColor.fromHexString(color) : ex.ExcelColor.none);
    }

    cell(0, 0, '#',           bold: true, color: 'FFFFCC00');
    cell(0, 1, 'الاسم',       bold: true, color: 'FFFFCC00');
    cell(0, 2, 'الرقم',       bold: true, color: 'FFFFCC00');
    cell(0, 3, 'مذاكرة',      bold: true, color: 'FFFFCC00');
    cell(0, 4, 'امتحان',      bold: true, color: 'FFFFCC00');
    cell(0, 5, 'شفهي',        bold: true, color: 'FFFFCC00');
    cell(0, 6, 'المجموع',     bold: true, color: 'FFFFCC00');
    cell(0, 7, 'المعدل%',     bold: true, color: 'FFFFCC00');
    cell(0, 8, 'الحالة',      bold: true, color: 'FFFFCC00');

    for (int i = 0; i < entries.length; i++) {
      final e    = entries[i];
      final pass = e['pass'] == true;
      final bg   = pass ? 'FFE8F5E9' : 'FFFFEBEE';
      cell(i + 1, 0, '${i + 1}',                                    color: bg);
      cell(i + 1, 1, e['student_name'] ?? '',                        color: bg);
      cell(i + 1, 2, e['university_id'] ?? '',                       color: bg);
      cell(i + 1, 3, e['quiz']  != null ? '${e['quiz']}/${e['quiz_max']}' : '—', color: bg);
      cell(i + 1, 4, e['exam']  != null ? '${e['exam']}/${e['exam_max']}' : '—', color: bg);
      cell(i + 1, 5, e['oral']  != null ? '${e['oral']}/${e['oral_max']}' : '—', color: bg);
      cell(i + 1, 6, e['total_score'] != null ? '${e['total_score']}/${e['total_max']}' : '—', color: bg);
      cell(i + 1, 7, e['average'] != null ? '${e['average']}%' : '—', color: bg);
      cell(i + 1, 8, e['average'] != null ? (pass ? 'ناجح' : 'راسب') : '—', bold: true, color: bg);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  Future<Uint8List> _buildPdf(List<dynamic> entries, String courseTitle) async {
    final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldData    = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final arabicFont  = pw.Font.ttf(regularData);
    final arabicBold  = pw.Font.ttf(boldData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
    );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      textDirection: pw.TextDirection.rtl,
      build: (ctx) => [
        pw.Text(courseTitle, style: pw.TextStyle(font: arabicBold, fontSize: 18)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['#', 'الاسم', 'الرقم', 'مذاكرة', 'امتحان', 'شفهي', 'المجموع', 'المعدل%', 'الحالة'],
          data: List.generate(entries.length, (i) {
            final e    = entries[i];
            final pass = e['pass'] == true;
            return [
              '${i + 1}',
              e['student_name'] ?? '',
              e['university_id'] ?? '',
              e['quiz']  != null ? '${e['quiz']}/${e['quiz_max']}' : '-',
              e['exam']  != null ? '${e['exam']}/${e['exam_max']}' : '-',
              e['oral']  != null ? '${e['oral']}/${e['oral_max']}' : '-',
              e['total_score'] != null ? '${e['total_score']}/${e['total_max']}' : '-',
              e['average'] != null ? '${e['average']}%' : '-',
              e['average'] != null ? (pass ? 'ناجح' : 'راسب') : '-',
            ];
          }),
          headerStyle: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.amber800),
          cellStyle: pw.TextStyle(font: arabicFont, fontSize: 8),
          cellAlignments: {for (var i = 0; i < 9; i++) i: pw.Alignment.center},
          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
      ],
    ));

    return doc.save();
  }

  Future<void> _exportFile(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
    } else {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: fileName);
    }
  }

  Future<void> _showGradeEntriesDialog(String courseId, String courseTitle) async {
    final token = await _token();
    final base  = ApiService().baseUrl;
    List<dynamic> entries = [];
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSB) {
            if (loading) {
              Dio().get(
                "$base/department-head/grade-report-requests/$courseId/entries",
                options: Options(headers: {"Authorization": "Bearer $token"}),
              ).then((res) {
                if (res.statusCode == 200 && res.data['success'] == true) {
                  setSB(() { entries = res.data['data'] ?? []; loading = false; });
                } else { setSB(() => loading = false); }
              }).catchError((e) { setSB(() => loading = false); return null; });
            }

            final isDark    = Theme.of(ctx2).brightness == Brightness.dark;
            final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.97,
              minChildSize: 0.4,
              builder: (_, ctrl) => Container(
                decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text('علامات: $courseTitle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))),
                          if (!loading) ...[
                            if (entries.isEmpty)
                              _iconExportBtn(Icons.notifications_active, Colors.orange, 'إشعار المعلم', () async {
                                try {
                                  await Dio().post(
                                    "$base/department-head/grade-report-requests/$courseId/remind-teacher",
                                    options: Options(headers: {"Authorization": "Bearer $token"}),
                                  );
                                  if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(content: Text('تم إرسال التذكير للمعلم ✅'), backgroundColor: Colors.green));
                                } catch (_) {}
                              })
                            else ...[
                              _iconExportBtn(Icons.picture_as_pdf, Colors.red, 'PDF', () async {
                                try {
                                  final bytes = await _buildPdf(entries, courseTitle);
                                  await _exportFile(bytes, 'علامات_$courseTitle.pdf');
                                } catch (e) {
                                  if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(
                                    SnackBar(content: Text('خطأ PDF: $e'), backgroundColor: Colors.red));
                                }
                              }),
                              const SizedBox(width: 8),
                              _iconExportBtn(Icons.table_chart, Colors.green, 'Excel', () async {
                                try {
                                  final bytes = await _buildExcel(entries, courseTitle);
                                  await _exportFile(bytes, 'علامات_$courseTitle.xlsx');
                                } catch (e) {
                                  if (ctx2.mounted) ScaffoldMessenger.of(ctx2).showSnackBar(
                                    SnackBar(content: Text('خطأ Excel: $e'), backgroundColor: Colors.red));
                                }
                              }),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 20),
                    if (!loading && entries.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _colHeader('الاسم', flex: 3, color: textColor),
                            _colHeader('مذاكرة', color: Colors.blue),
                            _colHeader('امتحان', color: Colors.red),
                            _colHeader('شفهي', color: Colors.purple),
                            _colHeader('معدل', color: const Color(0xFFAA8800)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator(color: _yellow))
                          : entries.isEmpty
                              ? Center(child: Text('لا توجد علامات مسجلة', style: TextStyle(color: Colors.grey.shade500)))
                              : ListView.builder(
                                  controller: ctrl,
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 30),
                                  itemCount: entries.length,
                                  itemBuilder: (_, i) {
                                    final e    = entries[i];
                                    final pass = e['pass'] == true;
                                    final avg  = e['average'];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
                                        borderRadius: BorderRadius.circular(14),
                                        border: avg != null
                                            ? Border.all(color: pass ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80))
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Text('${i + 1}. ', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                            Expanded(child: Text(e['student_name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13))),
                                            if (avg != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: pass ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                                                child: Text(pass ? 'ناجح' : 'راسب', style: TextStyle(color: pass ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                          ]),
                                          Text(e['university_id'] ?? '', style: TextStyle(color: subColor, fontSize: 11)),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            _scoreChip('مذاكرة', e['quiz'], e['quiz_max'], Colors.blue, isDark),
                                            const SizedBox(width: 6),
                                            _scoreChip('امتحان', e['exam'], e['exam_max'], Colors.red, isDark),
                                            const SizedBox(width: 6),
                                            _scoreChip('شفهي', e['oral'], e['oral_max'], Colors.purple, isDark),
                                            const Spacer(),
                                            if (avg != null)
                                              Text('$avg%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: pass ? Colors.green : Colors.red)),
                                          ]),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _colHeader(String t, {int flex = 1, Color? color}) => Expanded(
    flex: flex,
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? Colors.grey), textAlign: TextAlign.center),
  );

  Widget _scoreChip(String label, dynamic score, dynamic max, Color color, bool isDark) {
    final hasScore = score != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(isDark ? 40 : 20), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, color: color)),
        Text(hasScore ? '$score/$max' : '—', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasScore ? color : Colors.grey)),
      ]),
    );
  }

  Widget _iconExportBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ─── helpers ─────────────────────────────────

  Widget _dropdownTile({
    required String label,
    required bool selected,
    required Color fieldColor,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: fieldColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _yellow : Colors.grey.withValues(alpha: 0.15), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: selected ? textColor : Colors.grey.shade500, fontSize: 13)),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold)),
      );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      );

  Widget _circleBtn(IconData icon, Color cardColor, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
          child: Icon(icon, size: 22),
        ),
      );

  void _showSearchDialog({
    required List<Map<String, dynamic>> items,
    required String searchHint,
    required ValueChanged<Map<String, dynamic>?> onSelected,
    required Color textColor,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSD) {
            final filtered = items.where((item) {
              final name = (item['full_name'] ?? item['name'] ?? item['title'] ?? '').toString().toLowerCase();
              final code = (item['student_code'] ?? '').toString().toLowerCase();
              return name.contains(query.toLowerCase()) || code.contains(query.toLowerCase());
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: TextField(
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setSD(() => query = v),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: filtered.isEmpty
                      ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) {
                            final item = filtered[idx];
                            final name = item['full_name'] ?? item['name'] ?? item['title'] ?? '';
                            final code = item['student_code'] != null ? ' (${item['student_code']})' : '';
                            return ListTile(
                              title: Text('$name$code', style: TextStyle(color: textColor, fontSize: 13)),
                              onTap: () { onSelected(item); Navigator.pop(ctx); },
                            );
                          },
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendToParents(dynamic id) async {
    try {
      final token = await _token();
      final res = await Dio().post(
        "${ApiService().baseUrl}/department-head/report-requests/$id/send-to-parent",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.data['message'] ?? 'تم الإرسال'),
          backgroundColor: res.data['success'] == true ? Colors.green : Colors.red,
        ));
        _fetchAll();
      }
    } catch (_) {}
  }

  Future<void> _deleteReport(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل تريد حذف هذا التقرير نهائياً؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final token = await _token();
      await Dio().delete(
        "${ApiService().baseUrl}/department-head/report-requests/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: Colors.green));
        _fetchAll();
      }
    } catch (_) {}
  }

  void _viewReportDetails(Map<String, dynamic> r) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(r['report_type'] == 'academic' ? 'التقرير الأكاديمي' : 'التقرير السلوكي',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الطالب: ${r['student_name'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                if ((r['teacher_name'] as String?) != null)
                  Text('المدرب: ${r['teacher_name']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 20),
                Text(r['notes'] ?? 'لا يوجد محتوى.', style: TextStyle(fontSize: 13, height: 1.5, color: textColor)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: _yellow, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport(Map<String, dynamic> r) async {
    try {
      final studentName = r['student_name'] ?? 'student';
      final fileName    = "${studentName}_report_${r['id']}.txt";
      final dir         = await getTemporaryDirectory();
      final file        = File("${dir.path}/$fileName");

      final sb = StringBuffer()
        ..writeln('== تقرير أداء الطالب: $studentName ==')
        ..writeln('النوع: ${r['report_type'] == 'academic' ? 'أكاديمي' : 'سلوكي'}')
        ..writeln('المدرب: ${r['teacher_name'] ?? ''}')
        ..writeln('التاريخ: ${(r['created_at'] ?? '').toString().split('T')[0]}')
        ..writeln('------')
        ..writeln(r['notes'] ?? 'لا يوجد تفاصيل.');

      await file.writeAsString(sb.toString());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التنزيل')));
    }
  }
}
