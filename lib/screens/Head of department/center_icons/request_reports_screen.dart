import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

class ReportRequestScreen extends StatefulWidget {
  const ReportRequestScreen({super.key});

  @override
  State<ReportRequestScreen> createState() => _ReportRequestScreenState();
}

class _ReportRequestScreenState extends State<ReportRequestScreen> {
  // Lists of reports
  List<Map<String, dynamic>> _myRequests = [];
  List<Map<String, dynamic>> _advisorRequests = [];
  bool _isLoadingRequests = true;
  String _activeSubTab = 'my'; // 'my' or 'advisor'

  // Form selections
  String? _selectedTeacher;
  String? _selectedTeacherName;
  String? _selectedStudent;
  String? _selectedStudentName;
  bool _isAcademic = true;
  String _notes = '';

  // Loading states
  // ignore: unused_field
  bool _isLoadingTeachers = true;
  // ignore: unused_field
  bool _isLoadingStudents = true;
  bool _isSubmitting = false;

  // Data lists
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchReportRequests();
    _loadAllStudents();
    _loadAllTeachers();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchReportRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingRequests = true);
    try {
      final token = await _token();
      final resMy = await Dio().get(
        "${ApiService().baseUrl}/department-head/report-requests?type=my",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      final resAdvisor = await Dio().get(
        "${ApiService().baseUrl}/department-head/report-requests?type=advisor",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        setState(() {
          if (resMy.statusCode == 200 && resMy.data['success'] == true) {
            _myRequests = List<Map<String, dynamic>>.from(resMy.data['data'] ?? []);
          }
          if (resAdvisor.statusCode == 200 && resAdvisor.data['success'] == true) {
            _advisorRequests = List<Map<String, dynamic>>.from(resAdvisor.data['data'] ?? []);
          }
        });
      }
    } catch (e) {
      debugPrint('⛔ Fetch Report Requests Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadAllTeachers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeachers = true;
      _teachers = [];
      _selectedTeacher = null;
      _selectedTeacherName = null;
    });
    try {
      final token = await _token();
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/users/trainers",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() => _teachers = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
      }
    } catch (e) {
      debugPrint('⛔ Load Teachers Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _loadAllStudents() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _selectedStudent = null;
      _selectedStudentName = null;
    });
    try {
      final token = await _token();
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/users/students",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() => _students = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
      }
    } catch (e) {
      debugPrint('⛔ Load Students Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  bool get _canSubmit => _selectedStudent != null;

  Future<void> _loadTeachersForStudent(String studentId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeachers = true;
      _teachers = [];
      _selectedTeacher = null;
      _selectedTeacherName = null;
    });
    try {
      final token = await _token();
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/users/trainers?student_id=$studentId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() => _teachers = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
      }
    } catch (e) {
      debugPrint('⛔ Load Teachers for Student Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الطالب أولاً', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    if (!_isAcademic && _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المدرب المسؤول لإرسال التقييم السلوكي', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final token = await _token();
      final res = await Dio().post(
        "${ApiService().baseUrl}/department-head/report-requests",
        data: {
          'student_id': _selectedStudent,
          'teacher_id': _selectedTeacher,
          'report_type': _isAcademic ? 'academic' : 'behavioral',
          'notes': _notes,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final msg = res.data['message'] as String? ?? '✅ تم إرسال الطلب بنجاح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green),
        );
        _fetchReportRequests();
        setState(() {
          _selectedTeacher = null;
          _selectedTeacherName = null;
          _selectedStudent = null;
          _selectedStudentName = null;
          _notes = '';
        });
      }
    } catch (e) {
      debugPrint('⛔ Submit Report Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<Map<String, dynamic>> _getCurrentRequests() {
    return _activeSubTab == 'my' ? _myRequests : _advisorRequests;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final fieldColor = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF5F7F9);
    const primaryYellow = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: DefaultTabController(
            length: 2,
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildAppBar(context, textColor, cardColor),
                    TabBar(
                      tabs: const [
                        Tab(child: Text('طلب تقرير جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                        Tab(child: Text('سجل التقارير', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
                      ],
                      labelColor: primaryYellow,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryYellow,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildRequestFormTab(cardColor, textColor, fieldColor),
                          _buildReportRecordsTab(cardColor, textColor, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                CustomBottomNav(
                  currentIndex: 0,
                  centerButton: const Boss_Center_Icon(),
                  onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
                  onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossProfileScreen())),
                  onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
                  onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossMessageScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestFormTab(Color cardColor, Color textColor, Color fieldColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 130),
      child: Column(
        children: [
          // ─── القسم 1: الطالب المعني ───
          _buildFormSection(
            step: 1,
            title: 'الطالب المعني',
            icon: Icons.school_outlined,
            iconColor: primaryYellow,
            cardColor: cardColor,
            textColor: textColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مربع البحث
                GestureDetector(
                  onTap: () {
                    _showSearchDialog(
                      items: _students,
                      searchHint: 'ابحث باسم الطالب المكتوب أدناه...',
                      onSelected: (s) {
                        if (s != null) {
                          setState(() {
                            _selectedStudent = s['id']?.toString();
                            _selectedStudentName = '${s['full_name']} - ${s['student_code'] ?? ''}';
                          });
                          _loadTeachersForStudent(s['id'].toString());
                        }
                      },
                      textColor: textColor,
                      isDark: isDark,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'ابحث باسم الطالب المكتوب أدناه...',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // مربع الاختيار
                GestureDetector(
                  onTap: () {
                    _showSearchDialog(
                      items: _students,
                      searchHint: 'ابحث باسم الطالب المكتوب أدناه...',
                      onSelected: (s) {
                        if (s != null) {
                          setState(() {
                            _selectedStudent = s['id']?.toString();
                            _selectedStudentName = '${s['full_name']} - ${s['student_code'] ?? ''}';
                          });
                          _loadTeachersForStudent(s['id'].toString());
                        }
                      },
                      textColor: textColor,
                      isDark: isDark,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedStudent != null ? primaryYellow : Colors.grey.withValues(alpha: 0.15),
                        width: _selectedStudent != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedStudentName ?? 'اختر الطالب من القائمة...',
                          style: TextStyle(
                            color: _selectedStudentName == null ? Colors.grey.shade500 : textColor,
                            fontSize: 13,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                // مقترحات سريعة
                if (_students.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'مقترحات سريعة (انقر للاختيار الفوري)',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _students.take(5).map((s) {
                        final isSel = _selectedStudent == s['id']?.toString();
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStudent = s['id']?.toString();
                              _selectedStudentName = '${s['full_name']} - ${s['student_code'] ?? ''}';
                            });
                            _loadTeachersForStudent(s['id'].toString());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? primaryYellow.withValues(alpha: 0.15) : fieldColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? primaryYellow : Colors.grey.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.primaries[s['id'] % Colors.primaries.length],
                                  child: Text(
                                    (s['full_name'] as String).isNotEmpty ? (s['full_name'] as String)[0] : '',
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s['full_name'] ?? '',
                                  style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: textColor, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── القسم 2: المدرب المسؤول ───
          _buildFormSection(
            step: 2,
            title: 'المدرب المسؤول',
            icon: Icons.person_outlined,
            iconColor: Colors.blueAccent,
            cardColor: cardColor,
            textColor: textColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مربع البحث
                GestureDetector(
                  onTap: () {
                    _showSearchDialog(
                      items: _teachers,
                      searchHint: 'ابحث باسم المدرب المسؤول...',
                      onSelected: (t) {
                        if (t != null) {
                          setState(() {
                            _selectedTeacher = t['id']?.toString();
                            _selectedTeacherName = t['full_name'] as String?;
                          });
                        }
                      },
                      textColor: textColor,
                      isDark: isDark,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'ابحث باسم المدرب المسؤول...',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // مربع الاختيار
                GestureDetector(
                  onTap: () {
                    _showSearchDialog(
                      items: _teachers,
                      searchHint: 'ابحث باسم المدرب المسؤول...',
                      onSelected: (t) {
                        if (t != null) {
                          setState(() {
                            _selectedTeacher = t['id']?.toString();
                            _selectedTeacherName = t['full_name'] as String?;
                          });
                        }
                      },
                      textColor: textColor,
                      isDark: isDark,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedTeacher != null ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.15),
                        width: _selectedTeacher != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTeacherName ?? 'اختر المدرب من القائمة...',
                          style: TextStyle(
                            color: _selectedTeacherName == null ? Colors.grey.shade500 : textColor,
                            fontSize: 13,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── القسم 3: تفاصيل التقرير ───
          _buildFormSection(
            step: 3,
            title: 'تفاصيل التقرير',
            icon: Icons.assignment_outlined,
            iconColor: Colors.purpleAccent,
            cardColor: cardColor,
            textColor: textColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _typeCard('أداء أكاديمي', Icons.school_outlined, _isAcademic, cardColor, textColor, () => setState(() => _isAcademic = true)),
                    const SizedBox(width: 12),
                    _typeCard('سلوك وحضور', Icons.person_pin_circle_outlined, !_isAcademic, cardColor, textColor, () => setState(() => _isAcademic = false)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isAcademic ? Colors.blue : Colors.purple).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAcademic ? Icons.info_outline : Icons.edit_note_outlined,
                        size: 16,
                        color: _isAcademic ? Colors.blue : Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isAcademic ? 'النظام سيقوم بحساب المعدل ونسبة الحضور تلقائياً' : 'يُرسل للمدرب المسؤول ليكتب التقييم السلوكي والحضور',
                          style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: _isAcademic ? Colors.blue : Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('ملاحظات إضافية (اختياري)', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: TextField(
                    onChanged: (val) => _notes = val,
                    maxLines: 3,
                    style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'Cairo'),
                    decoration: InputDecoration(
                      hintText: 'اكتب أي نقاط محددة ترغب في التركيز عليها...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── زر التوليد ───
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: _canSubmit ? primaryYellow : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _canSubmit
                    ? [
                        BoxShadow(
                          color: primaryYellow.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text(
                        _isAcademic ? 'توليد التقرير الأكاديمي' : 'إرسال طلب التقييم السلوكي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _canSubmit ? Colors.black : Colors.grey, fontFamily: 'Cairo'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRecordsTab(Color cardColor, Color textColor, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _filterButton(
                title: "ردود طلباتي",
                isActive: _activeSubTab == 'my',
                onTap: () => setState(() => _activeSubTab = 'my'),
              ),
              const SizedBox(width: 10),
              _filterButton(
                title: "طلبات المربين",
                isActive: _activeSubTab == 'advisor',
                onTap: () => setState(() => _activeSubTab = 'advisor'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _isLoadingRequests
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
              : RefreshIndicator(
                  onRefresh: _fetchReportRequests,
                  color: const Color(0xFFFFCC00),
                  child: _getCurrentRequests().isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    _activeSubTab == 'my' ? 'لا توجد ردود لطلباتك بعد' : 'لا توجد طلبات من المربين بعد',
                                    style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                          itemCount: _getCurrentRequests().length,
                          itemBuilder: (context, index) {
                            final r = _getCurrentRequests()[index];
                            return _buildReportCard(r, cardColor, textColor, isDark);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildFormSection({
    required int step,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo', color: textColor)),
              const Spacer(),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Center(child: Text('$step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _filterButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFCC00) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r, Color cardColor, Color textColor, bool isDark) {
    final status = r['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';
    final reportType = r['report_type'] == 'academic' ? 'أداء أكاديمي' : 'سلوك وحضور';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_outline : Icons.pending_outlined,
              color: isCompleted ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['student_name'] as String? ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 3),
                Text(
                  'المدرب: ${r['teacher_name'] ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                ),
                if ((r['course_name'] as String?) != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'الدورة: ${r['course_name']}  |  السنة: ${r['year'] ?? '—'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge(reportType, const Color(0xFFFFCC00).withValues(alpha: 0.15), const Color(0xFFAA8800)),
                    const SizedBox(width: 8),
                    _badge(
                      isCompleted ? 'مكتمل' : 'قيد الانتظار',
                      (isCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                      isCompleted ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                if (isCompleted && (r['notes'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'التقييم: ${r['notes']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isCompleted && _activeSubTab == 'my') ...[
                  const Divider(height: 20, thickness: 0.5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.start,
                    children: [
                      _actionButton(
                        icon: Icons.send_rounded,
                        label: (r['sent_to_parent'] == true || r['sent_to_parent'] == 1) ? "تم الإرسال" : "إرسال للأهل",
                        color: (r['sent_to_parent'] == true || r['sent_to_parent'] == 1) ? Colors.grey : Colors.blue,
                        onTap: (r['sent_to_parent'] == true || r['sent_to_parent'] == 1) ? null : () => _sendToParents(r['id']),
                      ),
                      _actionButton(
                        icon: Icons.visibility_outlined,
                        label: "قراءة",
                        color: Colors.teal,
                        onTap: () => _viewReportDetails(r),
                      ),
                      _actionButton(
                        icon: Icons.download_outlined,
                        label: "تنزيل",
                        color: Colors.indigo,
                        onTap: () => _downloadReport(r),
                      ),
                      _actionButton(
                        icon: Icons.delete_outline,
                        label: "حذف",
                        color: Colors.red,
                        onTap: () => _deleteReport(r['id']),
                      ),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToParents(dynamic requestId) async {
    try {
      final token = await _token();
      final res = await Dio().post(
        "${ApiService().baseUrl}/department-head/report-requests/$requestId/send-to-parent",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final success = res.data['success'] as bool? ?? false;
        final msg = res.data['message'] as String? ?? 'تم إرسال التقرير للأهل';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _fetchReportRequests();
        }
      }
    } catch (e) {
      debugPrint('⛔ Send Report to Parent Error: $e');
    }
  }

  Future<void> _deleteReport(dynamic requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد من رغبتك في حذف هذا التقرير نهائياً؟', style: TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _token();
      final res = await Dio().delete(
        "${ApiService().baseUrl}/department-head/report-requests/$requestId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        final success = res.data['success'] as bool? ?? false;
        final msg = res.data['message'] as String? ?? 'تم الحذف بنجاح';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _fetchReportRequests();
        }
      }
    } catch (e) {
      debugPrint('⛔ Delete Report Error: $e');
    }
  }

  void _viewReportDetails(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.assignment_outlined, color: Color(0xFFFFCC00)),
                const SizedBox(width: 8),
                Text(
                  r['report_type'] == 'academic' ? 'التقرير الأكاديمي' : 'التقرير السلوكي',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الطالب: ${r['student_name'] ?? ""}',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المدرب: ${r['teacher_name'] ?? ""}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                  ),
                  if (r['course_name'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'المادة: ${r['course_name']} | السنة: ${r['year'] ?? "—"}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const Divider(height: 20),
                  Text(
                    r['notes'] ?? 'لا يوجد محتوى للتقرير.',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.5, color: textColor),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFFFFCC00), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadReport(Map<String, dynamic> r) async {
    try {
      final studentName = r['student_name'] ?? 'student';
      final reportType = r['report_type'] == 'academic' ? 'academic_report' : 'behavioral_report';
      final fileName = "${studentName}_${reportType}_${r['id']}.txt";

      final tempDir = await getTemporaryDirectory();
      final file = File("${tempDir.path}/$fileName");

      final content = StringBuffer();
      content.writeln("==============================");
      content.writeln("تقرير أداء الطالب: $studentName");
      content.writeln("==============================");
      content.writeln("نوع التقرير: ${r['report_type'] == 'academic' ? 'أكاديمي' : 'سلوكي'}");
      content.writeln("المدرب: ${r['teacher_name'] ?? ''}");
      if (r['course_name'] != null) {
        content.writeln("المادة/الدورة: ${r['course_name']}");
        content.writeln("السنة: ${r['year'] ?? ''}");
      }
      content.writeln("تاريخ الإنشاء: ${r['created_at'] != null ? r['created_at'].toString().split('T')[0] : ''}");
      content.writeln("------------------------------");
      content.writeln("محتوى التقرير والتقييم:");
      content.writeln(r['notes'] ?? 'لا يوجد تفاصيل.');
      content.writeln("==============================");

      await file.writeAsString(content.toString());

      final result = await OpenFilex.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم تحميل التقرير وفتحه: ${result.message}", style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('⛔ Download Report Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحميل التقرير')),
        );
      }
    }
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontFamily: 'Cairo')),
      );

  Widget _buildAppBar(BuildContext context, Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleBtn(Icons.settings_outlined, cardColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(userName: "رئيس القسم", userRole: "إدارة")));
          }),
          Column(
            children: [
              Text("طلبات التقارير", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              Text("إدارة تقارير القسم الدراسي", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'Cairo')),
            ],
          ),
          _buildCircleBtn(Icons.arrow_forward, cardColor, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
        child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
      ),
    );
  }


  Widget _typeCard(String title, IconData icon, bool selected, Color cardColor, Color textColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? const Color(0xFFFFCC00) : Colors.grey.withValues(alpha: 0.2), width: 2),
            boxShadow: selected ? [BoxShadow(color: const Color(0xFFFFCC00).withValues(alpha: 0.2), blurRadius: 10)] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black) : Colors.grey, size: 26),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 12, color: textColor, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cairo')),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSearchSelectionButton({
    required String hint,
    required List<Map<String, dynamic>> items,
    required String searchHint,
    required ValueChanged<Map<String, dynamic>?> onSelected,
    required Color fieldColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: () {
        _showSearchDialog(
          items: items,
          searchHint: searchHint,
          onSelected: onSelected,
          textColor: textColor,
          isDark: Theme.of(context).brightness == Brightness.dark,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 13,
                  color: hint.contains("اختر") ? Colors.grey : textColor,
                  fontFamily: 'Cairo',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog({
    required List<Map<String, dynamic>> items,
    required String searchHint,
    required ValueChanged<Map<String, dynamic>?> onSelected,
    required Color textColor,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                  style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    setStateDialog(() {
                      query = val;
                    });
                  },
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: filtered.isEmpty
                      ? const Center(child: Text("لا توجد نتائج", style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final name = item['full_name'] ?? item['name'] ?? item['title'] ?? '';
                            final code = item['student_code'] != null ? " (${item['student_code']})" : "";
                            return ListTile(
                              title: Text("$name$code", style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 13)),
                              onTap: () {
                                onSelected(item);
                                Navigator.pop(context);
                              },
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
}
