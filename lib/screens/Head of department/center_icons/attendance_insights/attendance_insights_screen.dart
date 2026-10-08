import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/attendance_intel_services.dart';

/// تحليل الحضور لقسم رئيس القسم: خريطة حرارية (اليوم × الحصة)، أضعف المقررات والمحاضرات،
/// الاتجاه الأسبوعي، وطلاب تغيّر حضورهم فجأة. قراءة فقط.
class AttendanceInsightsScreen extends StatefulWidget {
  const AttendanceInsightsScreen({super.key});

  @override
  State<AttendanceInsightsScreen> createState() => _AttendanceInsightsScreenState();
}

class _AttendanceInsightsScreenState extends State<AttendanceInsightsScreen> {
  final AttendanceIntelService _service = AttendanceIntelService();

  bool _loading = true;
  bool _failed = false;
  int? _programId;
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final res = await _service.getInsights(programId: _programId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _failed = true;
        return;
      }
      _data = Map<String, dynamic>.from(res['data'] ?? {});
      _programs = ((res['filters']?['programs'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });
  }

  /// 40% وما دون = أحمر، 100% = أخضر (نفس تدرّج صفحة الويب).
  Color _rateColor(num? rate) {
    final t = (((rate ?? 0) - 40) / 60).clamp(0.0, 1.0).toDouble();
    return HSLColor.fromAHSL(1, t * 120, 0.62, 0.38).toColor();
  }

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
              title: Text('تحليل الحضور', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18)),
              leading: IconButton(icon: Icon(Icons.arrow_back, color: text), onPressed: () => Navigator.pop(context)),
            ),
            body: RefreshIndicator(onRefresh: _load, child: _body(card, text, sub)),
          ),
        );
      },
    );
  }

  Widget _body(Color card, Color text, Color sub) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_failed) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off_rounded, size: 56, color: sub),
        const SizedBox(height: 12),
        Center(child: Text('تعذّر تحميل التحليل', style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        Center(child: TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
      ]);
    }

    final overall = Map<String, dynamic>.from(_data['overall'] ?? {});
    final flags = Map<String, dynamic>.from(_data['flags'] ?? {});
    final behavior = (_data['behavior_changes'] as List?) ?? [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _programFilter(card, text, sub),
        const SizedBox(height: 12),
        Row(children: [
          _stat(overall['rate'] != null ? '${overall['rate']}%' : '—', 'معدّل الحضور', text, sub, card),
          _stat('${overall['total'] ?? 0}', 'سجلات', text, sub, card),
          _stat('${flags['open'] ?? 0}', 'اشتباهات', const Color(0xFFE65100), sub, card),
          _stat('${behavior.length}', 'تغيّر مفاجئ', AppColors.error, sub, card),
        ]),
        const SizedBox(height: 14),
        _heatmapCard(card, text, sub),
        _rankCard('أضعف المقررات حضورًا', Icons.arrow_downward_rounded, (_data['courses'] as List?) ?? [],
            (c) => c['title']?.toString() ?? '', (c) => '${c['attended']} من ${c['total']} سجل', card, text, sub),
        _rankCard('أضعف المحاضرات حضورًا', Icons.event_busy_rounded, (_data['lessons'] as List?) ?? [],
            (l) => l['course']?.toString() ?? '', (l) => '${l['date']} — ${l['total']} سجل', card, text, sub),
        _rankCard('مقارنة البرامج', Icons.groups_rounded, (_data['programs'] as List?) ?? [],
            (p) => p['name']?.toString() ?? '', (p) => '${p['total']} سجل', card, text, sub),
        _weeklyCard(card, text, sub),
        _behaviorCard(behavior, card, text, sub),
      ],
    );
  }

  Widget _programFilter(Color card, Color text, Color sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _programId,
          dropdownColor: card,
          hint: Text('كل البرامج', style: TextStyle(color: sub)),
          style: TextStyle(color: text, fontFamily: null),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text('كل البرامج', style: TextStyle(color: text))),
            ..._programs.map((p) => DropdownMenuItem<int?>(
                  value: (p['id'] as num).toInt(),
                  child: Text(p['name']?.toString() ?? '', style: TextStyle(color: text)),
                )),
          ],
          onChanged: (v) {
            setState(() => _programId = v);
            _load();
          },
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color valueColor, Color sub, Color card) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          FittedBox(child: Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w800, fontSize: 18))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: sub, fontSize: 10.5)),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child, Color card, Color text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _heatmapCard(Color card, Color text, Color sub) {
    final hm = Map<String, dynamic>.from(_data['heatmap'] ?? {});
    final days = ((hm['days'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final slots = ((hm['slots'] as List?) ?? []).map((e) => e.toString()).toList();
    final cells = <String, Map<String, dynamic>>{};
    for (final c in (hm['cells'] as List?) ?? []) {
      cells['${c['day']}|${c['slot']}'] = Map<String, dynamic>.from(c as Map);
    }

    if (cells.isEmpty) {
      return _section('خريطة الحضور', Icons.grid_view_rounded,
          Text('لا توجد بيانات حضور في هذه الفترة', style: TextStyle(color: sub)), card, text);
    }

    Widget cell(Map<String, dynamic>? c) {
      if (c == null || c['rate'] == null) {
        return Container(
          height: 54,
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text('—', style: TextStyle(color: sub)),
        );
      }
      return Container(
        height: 54,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(color: _rateColor(c['rate'] as num), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${c['rate']}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          Text('${c['total']} سجل', style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]),
      );
    }

    return _section(
      'خريطة الحضور (اليوم × وقت الحصة)',
      Icons.grid_view_rounded,
      Column(children: [
        Row(children: [
          const SizedBox(width: 44),
          ...days.map((d) => Expanded(
                child: Center(child: Text(d['label']?.toString() ?? '', style: TextStyle(color: sub, fontSize: 10.5, fontWeight: FontWeight.w600))),
              )),
        ]),
        const SizedBox(height: 4),
        ...slots.map((slot) => Row(children: [
              SizedBox(width: 44, child: Text(slot, style: TextStyle(color: sub, fontSize: 11), textAlign: TextAlign.center)),
              ...days.map((d) => Expanded(child: cell(cells['${d['key']}|$slot']))),
            ])),
        const SizedBox(height: 10),
        Row(children: [
          Text('أقل حضورًا', style: TextStyle(color: sub, fontSize: 10)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: [_rateColor(0), _rateColor(50), _rateColor(100)]),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('أعلى حضورًا', style: TextStyle(color: sub, fontSize: 10)),
        ]),
      ]),
      card,
      text,
    );
  }

  Widget _rankCard(String title, IconData icon, List items, String Function(Map) name, String Function(Map) subtitle,
      Color card, Color text, Color sub) {
    final rows = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return _section(
      title,
      icon,
      rows.isEmpty
          ? Text('لا توجد بيانات كافية', style: TextStyle(color: sub, fontSize: 12))
          : Column(
              children: rows
                  .map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name(r), style: TextStyle(color: text, fontSize: 13)),
                              Text(subtitle(r), style: TextStyle(color: sub, fontSize: 11)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _rateColor(r['rate'] as num?), borderRadius: BorderRadius.circular(20)),
                            child: Text('${r['rate']}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ]),
                      ))
                  .toList(),
            ),
      card,
      text,
    );
  }

  Widget _weeklyCard(Color card, Color text, Color sub) {
    final weeks = ((_data['weekly'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return _section(
      'الاتجاه الأسبوعي',
      Icons.bar_chart_rounded,
      weeks.isEmpty
          ? Text('لا توجد بيانات', style: TextStyle(color: sub, fontSize: 12))
          : SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeks.map((w) {
                  final rate = (w['rate'] as num?) ?? 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('${w['rate']}%', style: TextStyle(color: text, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Container(
                          height: (rate / 100 * 78).clamp(4, 78).toDouble(),
                          decoration: BoxDecoration(color: _rateColor(rate), borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                        ),
                        const SizedBox(height: 3),
                        Text(w['week_start'].toString().substring(5), style: TextStyle(color: sub, fontSize: 9)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
      card,
      text,
    );
  }

  Widget _behaviorCard(List behavior, Color card, Color text, Color sub) {
    return _section(
      'طلاب تغيّر حضورهم فجأة',
      Icons.person_search_rounded,
      behavior.isEmpty
          ? Text('لا يوجد طالب انخفض حضوره بشكل مفاجئ', style: TextStyle(color: sub, fontSize: 12))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...behavior.map((b) {
                  final m = Map<String, dynamic>.from(b as Map);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['name']?.toString() ?? '', style: TextStyle(color: text, fontSize: 13)),
                          Text('كان ${m['baseline_rate']}% ثم هبط إلى ${m['recent_rate']}% في آخر أسبوعين',
                              style: TextStyle(color: sub, fontSize: 11)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _rateColor(m['recent_rate'] as num?), borderRadius: BorderRadius.circular(20)),
                        child: Text('${m['recent_rate']}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ]),
                  );
                }),
                const SizedBox(height: 6),
                Text('إشارة مبكرة للمرشد وليست اتهامًا', style: TextStyle(color: sub, fontSize: 10.5)),
              ],
            ),
      card,
      text,
    );
  }
}
