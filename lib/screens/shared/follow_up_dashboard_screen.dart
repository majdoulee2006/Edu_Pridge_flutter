import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/at_risk_student_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/at_risk_students_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/followup_services.dart';

/// ألوان وتسميات حالة الدورة/البرنامج (نفس ألوان صفحة الويب).
Color statusColor(String? s) {
  switch (s) {
    case 'attention':
      return const Color(0xFFC62828);
    case 'watch':
      return const Color(0xFFE65100);
    case 'ok':
      return const Color(0xFF2E7D32);
    default:
      return const Color(0xFF78909C);
  }
}

const _statusLabels = {
  'attention': 'تحتاج اهتمامًا',
  'watch': 'راقبها',
  'ok': 'وضعها جيد',
  'nodata': 'بيانات غير كافية',
};

/// لوحة المتابعة: ما الذي يحتاج انتباهي اليوم؟ ثم البرامج (الدورات) ومقرراتها مرتبة بالأحوج للاهتمام.
/// الدرجة أداة لترتيب أولوياتك وليست حكمًا على الدورة أو معلمها.
class FollowUpDashboardScreen extends StatefulWidget {
  final String basePath;

  const FollowUpDashboardScreen({super.key, required this.basePath});

  @override
  State<FollowUpDashboardScreen> createState() => _FollowUpDashboardScreenState();
}

class _FollowUpDashboardScreenState extends State<FollowUpDashboardScreen> {
  final FollowUpService _service = FollowUpService();
  final TextEditingController _search = TextEditingController();

  static const _sorts = {
    'attention': 'الأحوج للاهتمام',
    'attendance': 'الحضور الأقل',
    'risk': 'الأكثر معرَّضين',
    'name': 'الاسم',
  };

  String _status = '';
  String _sort = 'attention';
  int? _programId;
  bool _loading = true;
  bool _failed = false;
  String? _forbidden;
  Map<String, dynamic> _d = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final res = await _service.load(widget.basePath, status: _status, sort: _sort, search: _search.text, programId: _programId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _failed = true;
        return;
      }
      if (res['forbidden'] == true) {
        _forbidden = res['message']?.toString() ?? 'هذه الخدمة للمرشدين ورؤساء الأقسام فقط';
        return;
      }
      _d = res;
    });
  }

  Map<String, dynamic> get _kpis => Map<String, dynamic>.from(_d['kpis'] ?? {});
  Map<String, dynamic> get _today => Map<String, dynamic>.from(_d['today'] ?? {});
  List<Map<String, dynamic>> _list(dynamic v) => ((v as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) {
        final bg = isDark ? const Color(0xFF121212) : AppColors.background;
        final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final text = isDark ? Colors.white : AppColors.textDark;
        final sub = isDark ? Colors.grey.shade400 : AppColors.textGrey;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: card,
              elevation: 0,
              centerTitle: true,
              title: Text('لوحة المتابعة', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18)),
              leading: IconButton(icon: Icon(Icons.arrow_back, color: text), onPressed: () => Navigator.pop(context)),
            ),
            body: RefreshIndicator(onRefresh: _load, child: _body(card, text, sub)),
          ),
        );
      },
    );
  }

  Widget _message(IconData icon, String msg, Color text, Color sub, {bool retry = false}) {
    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      const SizedBox(height: 120),
      Icon(icon, size: 56, color: sub),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: text, fontWeight: FontWeight.bold, height: 1.6)),
      ),
      if (retry) Center(child: TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
    ]);
  }

  Widget _body(Color card, Color text, Color sub) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_forbidden != null) return _message(Icons.lock_outline_rounded, _forbidden!, text, sub);
    if (_failed) return _message(Icons.cloud_off_rounded, 'تعذّر تحميل اللوحة', text, sub, retry: true);

    final programs = _list(_d['programs']);
    final advisors = _list(_d['advisors']);
    final programOptions = _list((_d['filters'] as Map?)?['programs']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _kpiGrid(card, sub),
        const SizedBox(height: 14),
        _filters(card, text, sub, programOptions),
        const SizedBox(height: 14),
        _sectionTitle('عليك اليوم', text),
        _todayBox('الأعلى خطرًا', _list(_today['top_risk']), card, text, sub, (r) => _topRiskRow(r, text, sub)),
        _todayBox('متابعات فات موعدها', _list(_today['overdue']), card, text, sub, (r) => _overdueRow(r, text, sub)),
        _todayBox('تلاعب بساعة الهاتف دون رد', _list(_today['clock_alerts']), card, text, sub, (r) => _clockRow(r, text, sub)),
        const SizedBox(height: 6),
        _sectionTitle('البرامج ومقرراتها (${programs.length})', text),
        if (programs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(child: Text('لا توجد دورات مطابقة. جرّب تغيير الفلاتر.', style: TextStyle(color: sub))),
          )
        else
          ...programs.map((p) => _programTile(p, card, text, sub)),
        if (advisors.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionTitle('المرشدون ومتابعتهم لطلابهم', text),
          ...advisors.map((a) => _advisorCard(a, card, text, sub)),
        ],
        const SizedBox(height: 16),
        Text(
          'درجات الخطر تُحسب ليلًا${_d['computed_on'] != null ? ' (آخر تحديث: ${_d['computed_on']})' : ''}. '
          'نسبة حضور الدورة = (حاضر + متأخر) ÷ كل السجلات خلال آخر ${_d['period_days'] ?? 30} يومًا، بدون الغياب المعذور، ولطلابك فقط.',
          style: TextStyle(color: sub, fontSize: 11, height: 1.6),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ───────────────────────────── المؤشرات ─────────────────────────────

  Widget _kpiGrid(Color card, Color sub) {
    final k = _kpis;
    int n(String key) => (k[key] as num?)?.toInt() ?? 0;
    Widget item(String value, String label, Color color, {VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 10.5, height: 1.3)),
            ]),
          ),
        );
    void risk() => Navigator.push(context, MaterialPageRoute(builder: (_) => AtRiskStudentsScreen(basePath: widget.basePath)));

    return Wrap(spacing: 8, runSpacing: 8, children: [
      item('${n('high')}', 'خطر عالٍ', riskColor('high'), onTap: risk),
      item('${n('medium')}', 'خطر متوسط', riskColor('medium'), onTap: risk),
      item('${n('rising_week')}', 'ارتفع خطرهم هذا الأسبوع', const Color(0xFFC62828), onTap: risk),
      item('${n('overdue_followups')}', 'متابعات فات موعدها', n('overdue_followups') > 0 ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
      item('${n('clock_alerts_escalated')}', 'تلاعب بساعة الهاتف بلا رد', n('clock_alerts_escalated') > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32)),
      item('${n('pending_sessions')}', 'جلسات بانتظار الإغلاق (12 ليلاً)', n('pending_sessions') > 0 ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
    ]);
  }

  // ───────────────────────────── الفلاتر ─────────────────────────────

  Widget _filters(Color card, Color text, Color sub, List<Map<String, dynamic>> programOptions) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _search,
        style: TextStyle(color: text),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _load(),
        decoration: InputDecoration(
          hintText: 'بحث باسم المقرر أو رمزه',
          hintStyle: TextStyle(color: sub),
          prefixIcon: Icon(Icons.search_rounded, color: sub),
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: {'': 'الكل', ..._statusLabels}
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _status == e.key,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _status == e.key ? Colors.white : text),
                      onSelected: (_) {
                        if (_status == e.key) return;
                        setState(() => _status = e.key);
                        _load();
                      },
                    ),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: _dropdown<String>(
            card, text, 'الترتيب', _sort,
            _sorts.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            (v) {
              setState(() => _sort = v ?? 'attention');
              _load();
            },
          ),
        ),
        if (programOptions.length > 1) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _dropdown<int?>(
              card, text, 'البرنامج', _programId,
              [
                const DropdownMenuItem<int?>(value: null, child: Text('كل البرامج')),
                ...programOptions.map((p) => DropdownMenuItem<int?>(value: (p['id'] as num).toInt(), child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis))),
              ],
              (v) {
                setState(() => _programId = v);
                _load();
              },
            ),
          ),
        ],
      ]),
    ]);
  }

  Widget _dropdown<T>(Color card, Color text, String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: card,
          style: TextStyle(color: text, fontSize: 13),
          hint: Text(label),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ───────────────────────────── عليك اليوم ─────────────────────────────

  Widget _sectionTitle(String t, Color text) =>
      Padding(padding: const EdgeInsets.only(bottom: 8, top: 4), child: Text(t, style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 15)));

  Widget _todayBox(String title, List<Map<String, dynamic>> rows, Color card, Color text, Color sub, Widget Function(Map<String, dynamic>) row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(height: 6),
        if (rows.isEmpty) Text('لا يوجد.', style: TextStyle(color: sub, fontSize: 12)) else ...rows.map(row),
      ]),
    );
  }

  void _openStudent(Map<String, dynamic> r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AtRiskStudentDetailScreen(basePath: widget.basePath, studentId: (r['student_id'] as num).toInt())),
    ).then((_) {
      if (mounted) _load();
    });
  }

  Widget _topRiskRow(Map<String, dynamic> r, Color text, Color sub) {
    final reasons = ((r['reasons'] as List?) ?? []);
    final change = (r['change'] as num?)?.toDouble();
    final score = (r['score'] as num?)?.toDouble() ?? 0;
    return InkWell(
      onTap: () => _openStudent(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.w600)),
              Text(reasons.isNotEmpty ? reasons.first.toString() : (r['program']?.toString() ?? ''), style: TextStyle(color: sub, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Text(score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1), style: TextStyle(color: riskColor(r['level']?.toString()), fontWeight: FontWeight.w800, fontSize: 18)),
          if (change != null && change != 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6),
              child: Text('${change > 0 ? '▲' : '▼'} ${change.abs().toStringAsFixed(0)}', style: TextStyle(color: sub, fontSize: 11)),
            ),
        ]),
      ),
    );
  }

  Widget _overdueRow(Map<String, dynamic> r, Color text, Color sub) {
    return InkWell(
      onTap: () => _openStudent(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.w600)),
              Text('آخر إجراء: ${r['last_action'] ?? ''}', style: TextStyle(color: sub, fontSize: 11)),
            ]),
          ),
          Text('${r['days_late'] ?? 0} يوم', style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _clockRow(Map<String, dynamic> r, Color text, Color sub) {
    return InkWell(
      onTap: () => _openStudent(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(r['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.w600))),
          Text('${r['count'] ?? 0} تنبيهات', style: TextStyle(color: sub, fontSize: 11.5)),
        ]),
      ),
    );
  }

  // ───────────────────────────── البرامج والمقررات ─────────────────────────────

  Widget _chip(String t, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  String _pct(num v) => '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}%';

  Widget _programTile(Map<String, dynamic> p, Color card, Color text, Color sub) {
    final color = statusColor(p['status']?.toString());
    final courses = _list(p['courses']);
    final rate = (p['attendance_rate'] as num?);
    final high = (p['high'] as num?)?.toInt() ?? 0;
    final med = (p['medium'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border(right: BorderSide(color: color, width: 6))),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('prog_${p['program_id']}_${p['name']}'),
          initiallyExpanded: p['status'] != 'ok' || _list(_d['programs']).length == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          iconColor: sub,
          collapsedIconColor: sub,
          title: Text(p['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${p['department'] != null ? '${p['department']} • ' : ''}${p['students']} طالب • ${courses.length} مقرر${rate != null ? ' • الحضور ${_pct(rate)}' : ''}',
              style: TextStyle(color: sub, fontSize: 11.5),
            ),
          ),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            _chip(_statusLabels[p['status']] ?? '', color),
            if (high + med > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${high > 0 ? '$high عالٍ' : ''}${high > 0 && med > 0 ? ' • ' : ''}${med > 0 ? '$med متوسط' : ''}', style: TextStyle(color: sub, fontSize: 10.5)),
              ),
          ]),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          children: courses.isEmpty
              ? [Padding(padding: const EdgeInsets.all(12), child: Text('لا مقررات لطلاب هذا البرنامج.', style: TextStyle(color: sub, fontSize: 12)))]
              : courses.map((c) => _courseCard(c, text, sub)).toList(),
        ),
      ),
    );
  }

  Widget _courseCard(Map<String, dynamic> c, Color text, Color sub) {
    final color = statusColor(c['status']?.toString());
    final rate = (c['attendance_rate'] as num?)?.toDouble();
    final barColor = rate == null ? const Color(0xFF78909C) : (rate >= 90 ? const Color(0xFF2E7D32) : (rate >= 70 ? const Color(0xFFE65100) : const Color(0xFFC62828)));
    final reasons = ((c['reasons'] as List?) ?? []).map((e) => e.toString()).toList();
    final teachers = ((c['teachers'] as List?) ?? []).map((e) => e.toString()).take(2).join('، ');
    final high = (c['high'] as num?)?.toInt() ?? 0;
    final med = (c['medium'] as num?)?.toInt() ?? 0;
    final pending = (c['pending_sessions'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(color: color, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c['title'] ?? ''}${c['code'] != null ? ' (${c['code']})' : ''}', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
              Text('${c['year'] != null ? 'السنة ${c['year']}' : ''}${teachers.isNotEmpty ? ' • د. $teachers' : ''}', style: TextStyle(color: sub, fontSize: 11)),
            ]),
          ),
          _chip(_statusLabels[c['status']] ?? '', color),
        ]),
        const SizedBox(height: 10),
        if (rate != null)
          Row(children: [
            Text('الحضور', style: TextStyle(color: sub, fontSize: 11.5)),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: (rate / 100).clamp(0.0, 1.0), minHeight: 8, color: barColor, backgroundColor: Colors.grey.withValues(alpha: 0.25)),
              ),
            ),
            const SizedBox(width: 8),
            Text(_pct(rate), style: TextStyle(color: barColor, fontWeight: FontWeight.w800)),
          ])
        else
          Text('الحضور: بيانات غير كافية', style: TextStyle(color: sub, fontSize: 11.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip('${c['enrolled']} طالب', sub),
          if (high > 0) _chip('$high خطر عالٍ', riskColor('high')),
          if (med > 0) _chip('$med متوسط', riskColor('medium')),
          if (pending > 0) _chip('⏳ $pending جلسة بانتظار الإغلاق', const Color(0xFFE65100)),
        ]),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...reasons.map((r) => Padding(padding: const EdgeInsets.only(top: 2), child: Text('• $r', style: TextStyle(color: text, fontSize: 11.5)))),
        ],
      ]),
    );
  }

  // ───────────────────────────── المرشدون ─────────────────────────────

  Widget _advisorCard(Map<String, dynamic> a, Color card, Color text, Color sub) {
    final nudge = a['needs_nudge'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: nudge ? Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.5)) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.bold))),
          if (nudge) _chip('لم يتابع المعرَّضين', const Color(0xFFC62828)),
        ]),
        Text('${a['branch'] ?? ''} • ${a['year'] ?? ''}', style: TextStyle(color: sub, fontSize: 11.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip('${a['students']} طالب', sub),
          if ((a['high'] as num? ?? 0) > 0) _chip('${a['high']} عالٍ', riskColor('high')),
          if ((a['medium'] as num? ?? 0) > 0) _chip('${a['medium']} متوسط', riskColor('medium')),
          if ((a['overdue_followups'] as num? ?? 0) > 0) _chip('${a['overdue_followups']} متابعة متأخرة', const Color(0xFFE65100)),
          _chip('${a['actions_recent']} إجراء آخر ${a['idle_days']} يومًا', sub),
        ]),
      ]),
    );
  }
}
