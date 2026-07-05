import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/accounts/accounts_management_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/organization/exam_schedule_screen/create_exam_schedule_screen.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/center_icons/organization/study_schedule_screen/table_view.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';

class MainOrganizationInterfaceScreen extends StatefulWidget {
  const MainOrganizationInterfaceScreen({super.key});

  @override
  State<MainOrganizationInterfaceScreen> createState() => _MainOrganizationInterfaceScreenState();
}

class _MainOrganizationInterfaceScreenState extends State<MainOrganizationInterfaceScreen> {
  int _tabIndex = 0; // 0=دراسي 1=امتحاني

  // بيانات البرامج مع جداولها
  bool _isLoadingPrograms = true;
  List<Map<String, dynamic>> _programs = [];

  // بيانات الامتحانات
  bool _isLoadingExams = false;
  bool _examsFetched = false;
  List<Map<String, dynamic>> _exams = [];

  // الاختيارات
  int? _selectedProgramId;
  String? _selectedProgramName;
  int _selectedYear = 1;

  static const _dayOrder = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
  static const _dayNames = {
    'Sunday': 'الأحد', 'Monday': 'الاثنين', 'Tuesday': 'الثلاثاء',
    'Wednesday': 'الأربعاء', 'Thursday': 'الخميس',
  };

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchPrograms() async {
    setState(() => _isLoadingPrograms = true);
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/programs-schedule",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _programs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          if (_programs.isNotEmpty && _selectedProgramId == null) {
            _selectedProgramId   = _programs.first['id'] as int?;
            _selectedProgramName = _programs.first['name'] as String?;
          }
        });
      }
    } catch (e) {
      debugPrint('⛔ Programs: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPrograms = false);
    }
  }

  Future<void> _fetchExams({bool force = false}) async {
    if (_isLoadingExams) return;
    if (_examsFetched && !force) return;
    setState(() => _isLoadingExams = true);
    try {
      final res = await Dio().get(
        "${ApiService().baseUrl}/department-head/all-exams",
        options: Options(headers: {"Authorization": "Bearer ${await _token()}"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _exams = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _examsFetched = true;
        });
      }
    } catch (e) {
      debugPrint('⛔ Exams: $e');
    } finally {
      if (mounted) setState(() => _isLoadingExams = false);
    }
  }

  List<Map<String, dynamic>> get _currentSchedule {
    if (_selectedProgramId == null) return [];
    final prog = _programs.firstWhere(
      (p) => p['id'] == _selectedProgramId,
      orElse: () => {},
    );
    if (prog.isEmpty) return [];
    final schedule = prog['schedule'] as Map<String, dynamic>? ?? {};
    final yearData = schedule['$_selectedYear'] as List<dynamic>? ?? [];
    return yearData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const yellow    = Color(0xFFFFCC00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, textColor, isDark),
                  const SizedBox(height: 6),
                  _buildMainTabs(cardColor, yellow),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _tabIndex == 0
                        ? _buildScheduleTab(cardColor, textColor, isDark, yellow)
                        : _buildExamsTab(cardColor, textColor, isDark),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
              CustomBottomNav(
                currentIndex: 0,
                centerButton: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsManagementScreen())),
                  child: const Boss_Center_Icon(),
                ),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Text('واجهة التنظيم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabs(Color cardColor, Color yellow) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Row(children: [
        _mainTab('الجداول الدراسية', 0, yellow),
        _mainTab('الجداول الامتحانية', 1, yellow),
      ]),
    );
  }

  Widget _mainTab(String title, int index, Color yellow) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          if (index == 1) _fetchExams();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(color: active ? yellow : Colors.transparent, borderRadius: BorderRadius.circular(11)),
          child: Center(child: Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: active ? Colors.black : Colors.grey))),
        ),
      ),
    );
  }

  // ─── تبويب الجداول الدراسية ──────────────────────────────────────
  Widget _buildScheduleTab(Color cardColor, Color textColor, bool isDark, Color yellow) {
    if (_isLoadingPrograms) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)));
    if (_programs.isEmpty) {
      return Center(child: Text('لا توجد برامج مسجّلة', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontFamily: 'Cairo')));
    }

    return Column(
      children: [
        // أزرار البرامج (الدورات)
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _programs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final prog = _programs[i];
              final isActive = _selectedProgramId == prog['id'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedProgramId   = prog['id'] as int?;
                  _selectedProgramName = prog['name'] as String?;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? yellow : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                  ),
                  child: Text(prog['name'] as String? ?? '',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? Colors.black : Colors.grey)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // مفتاح السنة
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _yearToggle(1, yellow, cardColor),
            const SizedBox(width: 10),
            _yearToggle(2, yellow, cardColor),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TableViewScreen()),
                );
                _fetchPrograms(); // تحديث البيانات بعد العودة
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_calendar, color: Colors.black, size: 16),
                    SizedBox(width: 4),
                    Text('إدارة الجدول', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_selectedProgramName != null)
              Text(_selectedProgramName!, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
          ]),
        ),
        const SizedBox(height: 10),

        // الجدول
        Expanded(
          child: _buildWeeklySchedule(cardColor, textColor, isDark),
        ),
      ],
    );
  }

  Widget _yearToggle(int year, Color yellow, Color cardColor) {
    final active = _selectedYear == year;
    return GestureDetector(
      onTap: () => setState(() => _selectedYear = year),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? yellow : cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Text('السنة $year', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13, color: active ? Colors.black : Colors.grey)),
      ),
    );
  }

  Widget _buildWeeklySchedule(Color cardColor, Color textColor, bool isDark) {
    final sessions = _currentSchedule;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('لا يوجد جدول لهذا القسم والسنة', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo')),
          ],
        ),
      );
    }

    // تجميع حسب اليوم
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final s in sessions) {
      final day = s['day'] as String? ?? '';
      byDay.putIfAbsent(day, () => []).add(s);
    }

    final orderedDays = _dayOrder.where((d) => byDay.containsKey(d)).toList();

    return RefreshIndicator(
      onRefresh: _fetchPrograms,
      color: const Color(0xFFFFCC00),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: orderedDays.length,
        itemBuilder: (_, i) {
          final day  = orderedDays[i];
          final list = byDay[day]!;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(
              children: [
                // رأس اليوم
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Text(_dayNames[day] ?? day,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFAA8800))),
                ),
                // الجلسات
                ...list.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s   = entry.value;
                  final start = _trimTime(s['start_time'] as String? ?? '');
                  final end   = _trimTime(s['end_time']   as String? ?? '');
                  return Container(
                    decoration: BoxDecoration(
                      border: idx < list.length - 1
                          ? Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))
                          : null,
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                      ),
                      title: Text(s['course_name'] as String? ?? '—',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                      subtitle: Text('$start - $end', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                      trailing: s['room'] != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(s['room'] as String, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _trimTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  // ─── تبويب الجداول الامتحانية ────────────────────────────────────
  int _examSelectedYear = 1;
  int? _examSelectedProgramId;

  List<Map<String, dynamic>> get _filteredExams {
    final selectedProgName = _examSelectedProgramId == null ? null
        : _programs.firstWhere((p) => p['id'] == _examSelectedProgramId, orElse: () => {})['name'] as String?;
    return _exams.where((e) {
      final prog = e['program_name'] as String? ?? '';
      final year = (e['year'] as num?)?.toInt() ?? 1;
      final programMatch = selectedProgName == null || prog == selectedProgName;
      final yearMatch = year == _examSelectedYear;
      return programMatch && yearMatch;
    }).toList();
  }

  Widget _buildExamsTab(Color cardColor, Color textColor, bool isDark) {
    if (_isLoadingExams) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)));
    }

    const yellow = Color(0xFFFFCC00);

    // تهيئة الاختيار الافتراضي
    if (_examSelectedProgramId == null && _programs.isNotEmpty) {
      _examSelectedProgramId = _programs.first['id'] as int?;
    }

    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final exam in _filteredExams) {
      final date = (exam['exam_date'] as String? ?? '').split('T').first;
      byDate.putIfAbsent(date, () => []).add(exam);
    }
    final sortedDates = byDate.keys.toList()..sort();

    return Column(
      children: [
        // ── تبويبات الدورات (معلوماتية / اتصالات / ...) ──
        if (_programs.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _programs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final prog = _programs[i];
                final active = _examSelectedProgramId == prog['id'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _examSelectedProgramId = prog['id'] as int?;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? yellow : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                    ),
                    child: Text(prog['name'] as String? ?? '',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13,
                            color: active ? Colors.black : Colors.grey)),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),

        // ── تبويب السنة ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _examYearToggle(1, yellow, cardColor),
            const SizedBox(width: 10),
            _examYearToggle(2, yellow, cardColor),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final added = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const CreateExamScheduleScreen()));
                if (added == true && mounted) {
                  setState(() => _examsFetched = false);
                  await _fetchExams(force: true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, color: Colors.black, size: 16),
                  SizedBox(width: 4),
                  Text('إضافة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // ── المحتوى ──
        Expanded(
          child: sortedDates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_outlined, size: 52, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('لا توجد امتحانات لهذا القسم والسنة',
                          style: TextStyle(color: textColor.withValues(alpha: 0.5), fontFamily: 'Cairo')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _examsFetched = false);
                    await _fetchExams(force: true);
                  },
                  color: yellow,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: sortedDates.length,
                    itemBuilder: (_, i) => _buildExamDateCard(
                      sortedDates[i], byDate[sortedDates[i]]!,
                      cardColor, textColor, isDark,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _examYearToggle(int year, Color yellow, Color cardColor) {
    final active = _examSelectedYear == year;
    return GestureDetector(
      onTap: () => setState(() => _examSelectedYear = year),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? yellow : cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Text('السنة $year',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13,
                color: active ? Colors.black : Colors.grey)),
      ),
    );
  }

  Widget _buildExamDateCard(
    String date,
    List<Map<String, dynamic>> exams,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    // تنسيق التاريخ: 2025-01-15 → الثلاثاء 15 يناير 2025
    String formattedDate = date;
    String dayName = '';
    try {
      final dt = DateTime.parse(date);
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      const months = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      dayName = days[dt.weekday % 7];
      formattedDate = '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
          blurRadius: 8, offset: const Offset(0, 3),
        )],
      ),
      child: Column(
        children: [
          // ── رأس التاريخ ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              const Icon(Icons.event_outlined, color: Color(0xFFE65100), size: 18),
              const SizedBox(width: 8),
              Text(dayName,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100))),
              const SizedBox(width: 8),
              Text(formattedDate,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ),

          // ── الامتحانات ───────────────────────────────────
          ...exams.asMap().entries.map((entry) {
            final idx  = entry.key;
            final e    = entry.value;
            final start = _trimTime(e['start_time'] as String? ?? '');
            final end   = _trimTime(e['end_time']   as String? ?? '');
            final hasTime = start.isNotEmpty && end.isNotEmpty;
            final hall    = e['hall'] as String? ?? e['room'] as String?;
            final period  = e['period'] as String?;
            final examType = e['exam_type'] as String? ?? e['exam_name'] as String?;

            return Container(
              decoration: BoxDecoration(
                border: idx < exams.length - 1
                    ? Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))
                    : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('${idx + 1}',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                title: Text(
                  e['course_name'] as String? ?? '—',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (examType != null && examType.isNotEmpty)
                      Text(examType,
                          style: const TextStyle(color: Color(0xFFE65100), fontSize: 11, fontFamily: 'Cairo')),
                    if (period != null && period.isNotEmpty)
                      Text(period,
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontFamily: 'Cairo')),
                    if (hasTime)
                      Text('$start - $end',
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Cairo')),
                  ],
                ),
                trailing: hall != null && hall.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(hall,
                            style: const TextStyle(color: Colors.orange, fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
