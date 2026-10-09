import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/at_risk_students_screen.dart' show riskColor;
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/risk_services.dart';

/// تفاصيل طالب معرَّض للتعثر: الدرجة وأسبابها، تفصيل العوامل، اتجاه 12 أسبوعًا، وسجل المتابعة مع إضافة إجراء.
class AtRiskStudentDetailScreen extends StatefulWidget {
  final String basePath;
  final int studentId;

  const AtRiskStudentDetailScreen({super.key, required this.basePath, required this.studentId});

  @override
  State<AtRiskStudentDetailScreen> createState() => _AtRiskStudentDetailScreenState();
}

class _AtRiskStudentDetailScreenState extends State<AtRiskStudentDetailScreen> {
  final RiskService _service = RiskService();

  bool _loading = true;
  bool _failed = false;
  Map<String, dynamic> _d = {};

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
    final res = await _service.detail(widget.basePath, widget.studentId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _failed = true;
      } else {
        _d = res;
      }
    });
  }

  String _fmt(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);

  Future<void> _addIntervention(bool isDark) async {
    final types = Map<String, dynamic>.from(_d['intervention_types'] ?? {});
    String type = types.keys.isNotEmpty ? types.keys.first : 'note';
    final noteCtrl = TextEditingController();
    DateTime? followUp;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final text = isDark ? Colors.white : AppColors.textDark;
        final sub = isDark ? Colors.grey.shade400 : AppColors.textGrey;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تسجيل إجراء متابعة', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: bg,
                  decoration: InputDecoration(labelText: 'نوع الإجراء', labelStyle: TextStyle(color: sub), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toString(), style: TextStyle(color: text)))).toList(),
                  onChanged: (v) => setSheet(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  maxLength: 1000,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(hintText: 'ماذا حدث؟ وما الاتفاق؟', hintStyle: TextStyle(color: sub), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                Row(children: [
                  Expanded(
                    child: Text(followUp == null ? 'موعد المتابعة التالية (اختياري)' : 'المتابعة في ${followUp!.toIso8601String().substring(0, 10)}',
                        style: TextStyle(color: sub, fontSize: 12.5)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setSheet(() => followUp = picked);
                    },
                    child: const Text('اختيار'),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('حفظ'),
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );

    if (ok != true) return;
    final err = await _service.addIntervention(
      widget.basePath,
      widget.studentId,
      type: type,
      note: noteCtrl.text,
      followUpOn: followUp?.toIso8601String().substring(0, 10),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم تسجيل الإجراء')));
    if (err == null) _load();
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
        final name = (_d['student'] as Map?)?['name']?.toString() ?? 'تفاصيل الطالب';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: card,
              elevation: 0,
              centerTitle: true,
              title: Text(name, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 17)),
              leading: IconButton(icon: Icon(Icons.arrow_back, color: text), onPressed: () => Navigator.pop(context)),
            ),
            floatingActionButton: _loading || _failed
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _addIntervention(isDark),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('تسجيل إجراء'),
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
        Center(child: Text('تعذّر تحميل التفاصيل', style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        Center(child: TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
      ]);
    }

    final student = Map<String, dynamic>.from(_d['student'] as Map);
    final risk = _d['risk'] == null ? null : Map<String, dynamic>.from(_d['risk'] as Map);
    final history = ((_d['history'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final interventions = ((_d['interventions'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final since = _d['since_last_intervention'] as Map?;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('${student['program'] ?? ''} • ${student['year'] ?? ''} • ${student['code'] ?? ''}', style: TextStyle(color: sub, fontSize: 12)),
        const SizedBox(height: 12),
        _hero(risk, card, text, sub),
        if (risk != null) ...[
          _section('كيف حُسبت الدرجة', Icons.balance_rounded, _factors(risk, text, sub), card, text),
          _section('الاتجاه (آخر 12 أسبوعًا)', Icons.show_chart_rounded, _trend(history, risk, sub), card, text),
        ],
        _section('سجل المتابعة', Icons.fact_check_rounded, _interventions(interventions, since, text, sub), card, text),
      ],
    );
  }

  Widget _hero(Map<String, dynamic>? risk, Color card, Color text, Color sub) {
    if (risk == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
        child: Text('لم تُحسب درجة لهذا الطالب بعد (تُحسب ليلًا).', style: TextStyle(color: sub)),
      );
    }

    final level = risk['level']?.toString() ?? 'unknown';
    final color = riskColor(level);
    final score = (risk['score'] as num).toDouble();
    final prev = (risk['previous_score'] as num?)?.toDouble();
    final delta = prev == null ? null : double.parse((score - prev).toStringAsFixed(1));
    final reasons = ((risk['reasons'] as List?) ?? []).map((e) => e.toString()).toList();
    final conf = ((risk['confidence'] as num?) ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (level != 'unknown')
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 9,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(_fmt(score), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
              ]),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(risk['level_label']?.toString() ?? '', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
              if (delta != null && delta.abs() >= 1) ...[
                const SizedBox(height: 6),
                Text('${delta > 0 ? '▲' : '▼'} ${_fmt(delta.abs())} عن الحساب السابق',
                    style: TextStyle(color: delta > 0 ? riskColor('high') : riskColor('low'), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 6),
              Text('آخر حساب: ${risk['computed_on']} • اكتمال البيانات ${(conf * 100).round()}%', style: TextStyle(color: sub, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (reasons.isNotEmpty)
          ...reasons.map((x) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('• ', style: TextStyle(color: sub)),
                  Expanded(child: Text(x, style: TextStyle(color: text, height: 1.6))),
                ]),
              ))
        else
          Text(level == 'unknown' ? 'لا تتوفر بيانات كافية لتقدير الخطر بعد. هذا لا يعني أن الطالب بخير.' : 'لا مؤشرات مقلقة حاليًا.',
              style: TextStyle(color: sub, fontSize: 12.5, height: 1.6)),
        if (conf < 0.7 && level != 'unknown') ...[
          const SizedBox(height: 8),
          Text('⚠️ بيانات جزئية: بعض العوامل غير متوفرة، فالدرجة تقدير أولي.', style: TextStyle(color: sub, fontSize: 11.5)),
        ],
      ]),
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

  Widget _factors(Map<String, dynamic> risk, Color text, Color sub) {
    final factors = ((risk['factors'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...factors.map((f) {
        final available = f['available'] == true;
        final score = (f['score'] as num?)?.toDouble() ?? 0;
        final color = score >= 60 ? riskColor('high') : (score >= 35 ? riskColor('medium') : riskColor('low'));
        return Opacity(
          opacity: available ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('${f['label']}  (وزنه ${_fmt(f['weight'] as num)})', style: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                if (f['critical'] == true)
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: riskColor('high').withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text('حرجة', style: TextStyle(color: riskColor('high'), fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(available ? '${_fmt(score)} / 100' : '—', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ]),
              if (available) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${f['reason']}${available ? ' — مساهمته ${_fmt(f['contribution'] as num)}' : ''}',
                style: TextStyle(color: sub, fontSize: 11.5, height: 1.5),
              ),
            ]),
          ),
        );
      }),
      const SizedBox(height: 6),
      Text(
        'الدرجة = مجموع (نقاط كل عامل × وزنه) مقسومًا على أوزان العوامل المتوفرة فقط، فلا يُعاقَب الطالب على بيانات غير موجودة. '
        'وإذا انهار عامل رئيسي كليًا تُرفع الدرجة إلى 60 على الأقل.',
        style: TextStyle(color: sub, fontSize: 11, height: 1.6),
      ),
    ]);
  }

  Widget _trend(List<Map<String, dynamic>> history, Map<String, dynamic> risk, Color sub) {
    if (history.length < 2) {
      return Text('لا يوجد تاريخ كافٍ بعد (يُبنى مع كل حساب ليلي).', style: TextStyle(color: sub, fontSize: 12));
    }
    final color = riskColor(risk['level']?.toString());
    final scores = history.map((h) => (h['score'] as num).toDouble()).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 100, width: double.infinity, child: CustomPaint(painter: _TrendPainter(scores, color))),
      const SizedBox(height: 6),
      Text('الخط الأحمر المنقط: حدّ الخطر العالي (60)، والبرتقالي: المتوسط (35). من ${history.first['date']} إلى ${history.last['date']}.',
          style: TextStyle(color: sub, fontSize: 11, height: 1.5)),
    ]);
  }

  Widget _interventions(List<Map<String, dynamic>> items, Map? since, Color text, Color sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (since != null) ...[
        Text(
          'منذ آخر إجراء (${since['date']}): من ${_fmt(since['from'] as num)} إلى ${_fmt(since['to'] as num)} '
          '(${(since['delta'] as num) > 0 ? '▲' : '▼'} ${_fmt((since['delta'] as num).abs())})',
          style: TextStyle(color: sub, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 10),
      ],
      if (items.isEmpty)
        Text('لم تُسجَّل أي متابعة لهذا الطالب بعد.', style: TextStyle(color: sub, fontSize: 12.5))
      else
        ...items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i['type_label']} • ${i['created_at'].toString().substring(0, 10)}', style: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 13)),
                if ((i['note'] ?? '').toString().isNotEmpty) Text(i['note'].toString(), style: TextStyle(color: text, fontSize: 12.5, height: 1.5)),
                Text(
                  '${i['author']}${i['score_at_time'] != null ? ' • الدرجة وقتها ${_fmt(i['score_at_time'] as num)}' : ''}'
                  '${i['follow_up_on'] != null ? ' • المتابعة في ${i['follow_up_on']}' : ''}',
                  style: TextStyle(color: sub, fontSize: 11),
                ),
              ]),
            )),
    ]);
  }
}

/// رسم بياني بسيط لاتجاه الدرجة مع خطي حدّ المتوسط والعالي.
class _TrendPainter extends CustomPainter {
  final List<double> scores;
  final Color color;

  _TrendPainter(this.scores, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double y(double v) => size.height - 6 - (v.clamp(0, 100) / 100) * (size.height - 12);

    void dashed(double v, Color c) {
      final p = Paint()..color = c.withValues(alpha: 0.55)..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y(v)), Offset(x + 4, y(v)), p);
      }
    }

    dashed(60, riskColor('high'));
    dashed(35, riskColor('medium'));

    final line = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < scores.length; i++) {
      final x = 6 + i / (scores.length - 1) * (size.width - 12);
      i == 0 ? path.moveTo(x, y(scores[i])) : path.lineTo(x, y(scores[i]));
    }
    canvas.drawPath(path, line);
    final last = Offset(size.width - 6, y(scores.last));
    canvas.drawCircle(last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.scores != scores || old.color != color;
}
