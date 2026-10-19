import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/Head of department/schedule_settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/study_screens.dart' show StudyScaffold;
import 'package:edu_pridge_flutter/services/schedule_studio_services.dart';
import 'package:edu_pridge_flutter/services/study_services.dart' show StudyResult;
import 'package:flutter/material.dart';

const _statusLabels = {'draft': 'مسودة', 'approved': 'معتمدة', 'discarded': 'مُهمَلة'};

Color _statusColor(String s) => s == 'approved' ? const Color(0xFF2E7D32) : (s == 'draft' ? const Color(0xFFE65100) : const Color(0xFF78909C));

/// مدخل الاستوديو: اختيار الفصل، زر بناء واضح، لوحة جاهزية البيانات، وقائمة المسودات.
class ScheduleStudioScreen extends StatefulWidget {
  const ScheduleStudioScreen({super.key});

  @override
  State<ScheduleStudioScreen> createState() => _ScheduleStudioScreenState();
}

class _ScheduleStudioScreenState extends State<ScheduleStudioScreen> {
  final _service = ScheduleStudioService();
  bool _loading = true;
  bool _generating = false;
  String? _error;
  Map<String, dynamic> _data = {};
  int _periods = 5;
  int? _semesterId;

  static const _levelColor = {'ok': Color(0xFF2E7D32), 'info': Color(0xFF1565C0), 'warn': Color(0xFFE65100), 'error': Color(0xFFC62828)};
  static const _levelIcon = {'ok': '✓', 'info': 'ℹ', 'warn': '⚠', 'error': '✖'};
  static const _actionLabel = {'auto_rooms': 'أنشئ قاعة لكل شعبة', 'open_rooms': 'القاعات', 'open_availability': 'إضافة قيود'};

  bool get _isNext => _semesterId != null && _semesterId != (_data['current_semester_id'] as num?)?.toInt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _service.overview(semesterId: _semesterId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      if (r.ok) {
        _data = r.data!;
        _periods = (_data['default_periods'] as num?)?.toInt() ?? 5;
        _semesterId ??= (_data['selected_semester_id'] as num?)?.toInt();
      }
    });
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final r = await _service.generate(periods: _periods, semesterId: _semesterId);
    if (!mounted) return;
    setState(() => _generating = false);
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleDraftScreen(id: (r.data!['id'] as num).toInt())));
    _load();
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen()));
    _load();
  }

  Future<void> _fix(String action) async {
    if (action == 'auto_rooms') {
      final r = await _service.autoRooms();
      if (!mounted) return;
      final created = ((r.data?['created'] as List?) ?? []).length;
      final linked = ((r.data?['linked'] as List?) ?? []).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.ok ? (created + linked == 0 ? 'لكل شعبة قاعتها الخاصة أصلاً' : 'أُنشئت $created قاعة وربطت $linked بشعبتها') : r.error!)));
      _load();
    } else {
      _openSettings();
    }
  }

  void _buildSheet(Color card, Color text, Color sub) {
    final maxPeriods = (_data['max_periods'] as num?)?.toInt() ?? 7;
    final periods = Map<String, dynamic>.from((_data['periods'] as Map?) ?? {});
    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (c, set) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(c).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('بناء جدول أسبوعي', style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _periods,
                decoration: const InputDecoration(labelText: 'عدد الفترات في اليوم'),
                items: [
                  for (var i = 3; i <= maxPeriods; i++)
                    DropdownMenuItem(value: i, child: Text('$i فترات (${(periods['1'] as List?)?.first ?? ''} إلى ${(periods['$i'] as List?)?.last ?? ''})')),
                ],
                onChanged: (v) => set(() => _periods = v ?? _periods),
              ),
              if (_isNext) _note('ستُحفظ المسودة للفصل القادم ولن تُعتمد الآن.', const Color(0xFF1565C0)),
              const SizedBox(height: 8),
              Text('لن يتغيّر الجدول الحالي. ستراجع المسودة وتعدّلها قبل أي اعتماد.', style: TextStyle(color: sub, fontSize: 12)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    Navigator.pop(c);
                    _generate();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('ابنِ الجدول'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'مولّد الجداول',
      actions: [
        IconButton(tooltip: 'القاعات وتوفّر المعلمين', icon: const Icon(Icons.tune_rounded), onPressed: _openSettings),
      ],
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));

        final drafts = ((_data['drafts'] as List?) ?? []).cast<Map>();
        final semesters = ((_data['semesters'] as List?) ?? []).cast<Map>();
        final readiness = _data['readiness'] as Map?;
        final items = ((readiness?['items'] as List?) ?? []).cast<Map>();
        final errors = (readiness?['errors'] as num?)?.toInt() ?? 0;
        final warnings = (readiness?['warnings'] as num?)?.toInt() ?? 0;

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            // الفصل الدراسي
            Card(
              color: card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: semesters.any((s) => (s['id'] as num).toInt() == _semesterId) ? _semesterId : null,
                    hint: Text('اختر الفصل الدراسي', style: TextStyle(color: sub)),
                    dropdownColor: card,
                    style: TextStyle(color: text, fontWeight: FontWeight.bold),
                    items: [
                      for (final s in semesters)
                        DropdownMenuItem(value: (s['id'] as num).toInt(), child: Text('${s['name']}${s['current'] == true ? ' (الحالي)' : ''}')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _semesterId = v;
                        _loading = true;
                      });
                      _load();
                    },
                  ),
                ),
              ),
            ),
            if (_semesterId == null) _note('لا يوجد فصل دراسي فعّال. اختر فصلاً لعرض مقرراته وتوليد جدوله.', const Color(0xFFE65100)),
            if (_isNext) _note('هذا الفصل ليس الفعّال حالياً: المسودة التي تولّدها تُحفظ للفصل القادم، ولا تُعتمد ولا تظهر للطلاب إلا عندما يصبح فعّالاً.', const Color(0xFF1565C0)),
            const SizedBox(height: 10),

            // الإجراء الرئيسي
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.85), AppColors.primary]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('✨ ابنِ لي الجدول تلقائياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 6),
                const Text('يوزّع النظام حصص كل دورة وسنة دون تعارض معلمين أو قاعات، ويشرح ما تعذّر وضعه. تراجع المسودة وتعدّلها ثم تعتمدها بنفسك.',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.6)),
                const SizedBox(height: 12),
                Row(children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                    onPressed: (_generating || _semesterId == null) ? null : () => _buildSheet(card, text, sub),
                    child: _generating
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ابدأ البناء', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  if (readiness != null)
                    Flexible(
                      child: Text(
                        errors > 0 ? '⚠ $errors يمنع جزءاً من الحصص' : (warnings > 0 ? '$warnings تنبيه' : '✓ البيانات جاهزة'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // جاهزية البيانات
            if (items.isNotEmpty)
              Card(
                color: card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('جاهزية البيانات', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...items.map((it) {
                      final col = _levelColor['${it['level']}'] ?? const Color(0xFF78909C);
                      final action = it['action']?.toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: col.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border(right: BorderSide(color: col, width: 4))),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_levelIcon['${it['level']}'] ?? '', style: TextStyle(color: col, fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${it['title']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13)),
                              if ('${it['detail']}'.isNotEmpty) Text('${it['detail']}', style: TextStyle(color: sub, fontSize: 11.5, height: 1.5)),
                              if (action != null && _actionLabel.containsKey(action))
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: OutlinedButton(onPressed: () => _fix(action), child: Text(_actionLabel[action]!)),
                                ),
                            ]),
                          ),
                        ]),
                      );
                    }),
                  ]),
                ),
              ),
            const SizedBox(height: 14),

            Text('المسودات', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            if (drafts.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('لا مسودات بعد. اضغط «ابدأ البناء».', style: TextStyle(color: sub)))),
            ...drafts.map((d) {
              final st = '${d['status']}';
              final next = d['saved_for_next'] == true;
              return Card(
                color: card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text('${d['name']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${d['semester_name'] ?? ''} · ${d['placed']} / ${d['required']} حصة · ${d['unscheduled']} ناقصة', style: TextStyle(color: sub, fontSize: 12)),
                  trailing: Text(next ? 'محفوظة للفصل القادم' : (_statusLabels[st] ?? st), style: TextStyle(color: next ? const Color(0xFF1565C0) : _statusColor(st), fontWeight: FontWeight.bold, fontSize: 12)),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleDraftScreen(id: (d['id'] as num).toInt())));
                    _load();
                  },
                ),
              );
            }),
          ]),
        );
      },
    );
  }

  Widget _note(String msg, Color color) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Text(msg, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5)),
      );
}

/// مراجعة مسودة: شبكة أسبوعية لكل شعبة، تعديل بالنقر على حصة (نقل/تثبيت)، ثم اعتماد.
class ScheduleDraftScreen extends StatefulWidget {
  final int id;
  const ScheduleDraftScreen({super.key, required this.id});

  @override
  State<ScheduleDraftScreen> createState() => _ScheduleDraftScreenState();
}

class _ScheduleDraftScreenState extends State<ScheduleDraftScreen> {
  final _service = ScheduleStudioService();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _d = {};
  int _group = 0;

  bool get _editable => _d['status'] == 'draft';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(StudyResult<Map<String, dynamic>> r) {
    if (r.ok) {
      _d = r.data!;
      _error = null;
    } else {
      _error = _d.isEmpty ? r.error : null;
    }
  }

  Future<void> _load() async {
    final r = await _service.show(widget.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _apply(r);
    });
  }

  /// ينفّذ إجراءً ويحدّث الحالة؛ الرفض يظهر رسالة ولا يغيّر شيئًا.
  Future<void> _run(Future<StudyResult<Map<String, dynamic>>> Function() call, {String? ok}) async {
    setState(() => _busy = true);
    final r = await call();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) _apply(r);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.ok ? (ok ?? 'تم') : r.error!)));
  }

  Future<void> _approve() async {
    final unscheduled = ((_d['unscheduled_items'] as List?) ?? []).isNotEmpty;
    var ack = false;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('اعتماد الجدول'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('سيستبدل الجدول الحالي لقسمك ويُشعر المعلمين والطلاب. يمكنك التراجع لاحقًا.'),
            if (unscheduled)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: ack,
                onChanged: (v) => set(() => ack = v ?? false),
                title: const Text('أقرّ بأن بعض المواد لم تُجدول بالكامل', style: TextStyle(fontSize: 13)),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('اعتماد')),
          ],
        ),
      ),
    );
    if (yes == true) _run(() => _service.approve(widget.id, acknowledge: ack), ok: 'اعتُمد الجدول وأُشعر المعلمون والطلاب');
  }

  Future<void> _confirm(String title, String body, Future<void> Function() onYes) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('نعم'))],
      ),
    );
    if (yes == true) await onYes();
  }

  void _entrySheet(Map e, Color card, Color text) {
    String day = '${e['day']}';
    int period = (e['period'] as num).toInt();
    final days = ((_d['days'] as List?) ?? []).cast<String>();
    final labels = Map<String, dynamic>.from(_d['day_labels'] as Map);
    final count = (_d['period_count'] as num).toInt();
    final periods = _d['periods'] as Map;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (c, set) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(c).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['course']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${e['teacher']} · ${e['room'] ?? ''}', style: TextStyle(color: text.withValues(alpha: 0.6), fontSize: 12)),
              if (_editable) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: day,
                      decoration: const InputDecoration(labelText: 'اليوم'),
                      items: days.map((x) => DropdownMenuItem(value: x, child: Text('${labels[x] ?? x}'))).toList(),
                      onChanged: (v) => set(() => day = v ?? day),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: period,
                      decoration: const InputDecoration(labelText: 'الفترة'),
                      items: [for (var p = 1; p <= count; p++) DropdownMenuItem(value: p, child: Text('$p (${(periods['$p'] as List).first})'))],
                      onChanged: (v) => set(() => period = v ?? period),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(c);
                        _run(() => _service.move(widget.id, (e['id'] as num).toInt(), day, period), ok: 'تم نقل الحصة');
                      },
                      child: const Text('نقل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(c);
                        _run(() => _service.lock(widget.id, (e['id'] as num).toInt(), e['locked'] != true), ok: e['locked'] == true ? 'أُلغي التثبيت' : 'ثُبّتت الحصة');
                      },
                      child: Text(e['locked'] == true ? 'إلغاء التثبيت' : 'تثبيت'),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: '${_d['name'] ?? 'مسودة الجدول'}',
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));

        final groups = ((_d['groups'] as List?) ?? []).cast<Map>();
        if (_group >= groups.length) _group = 0;
        final violations = ((_d['violation_messages'] as List?) ?? []).cast<String>();
        final unscheduled = ((_d['unscheduled_items'] as List?) ?? []).cast<Map>();
        final st = '${_d['status']}';
        final savedForNext = _d['saved_for_next'] == true;

        return ListView(padding: const EdgeInsets.all(16), children: [
          if (savedForNext)
            _note('محفوظة للفصل القادم: هذه المسودة لفصل «${_d['semester_name'] ?? ''}» وهو ليس الفعّال الآن. يمكنك مراجعتها وتعديلها، لكنها لا تُعتمد ولا تظهر للطلاب والمعلمين إلا عندما يصبح هذا الفصل فعّالاً.', const Color(0xFF1565C0)),
          Row(children: [
            Text(_statusLabels[st] ?? st, style: TextStyle(color: _statusColor(st), fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_d['placed']} / ${_d['required']} حصة', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('${violations.length} تعارض', violations.isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
            _chip('${unscheduled.length} مواد ناقصة', unscheduled.isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
            _chip('${(_d['quality'] as Map)['gaps']} فراغات', const Color(0xFF1565C0)),
          ]),
          ...violations.map((v) => _note(v, const Color(0xFFC62828))),
          if (unscheduled.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('ما لم يُجدول ولماذا', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            ...unscheduled.map((u) => _note('${u['group']} — ${u['title']}: ينقص ${u['missing']} من ${u['of']}. ${u['message']}', const Color(0xFFE65100))),
          ],
          const SizedBox(height: 12),
          if (groups.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < groups.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text('${groups[i]['label']}'),
                      selected: _group == i,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _group == i ? Colors.white : text),
                      onSelected: (_) => setState(() => _group = i),
                    ),
                  ),
              ]),
            ),
          const SizedBox(height: 10),
          if (groups.isNotEmpty) _grid(groups[_group], card, text, sub),
          const SizedBox(height: 16),
          if (_editable) ...[
            _btn('إعادة توزيع غير المثبّت', () => _run(() => _service.regenerate(widget.id), ok: 'أُعيد التوزيع')),
            _btn('اعتماد الجدول', _approve, filled: true, disabled: violations.isNotEmpty || savedForNext),
            _btn('إهمال المسودة', () => _confirm('إهمال المسودة', 'ستُهمل هذه المسودة. متابعة؟', () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _busy = true);
                  final r = await _service.discard(widget.id);
                  if (!mounted) return;
                  if (r.ok) {
                    nav.pop();
                  } else {
                    setState(() => _busy = false);
                    messenger.showSnackBar(SnackBar(content: Text(r.error!)));
                  }
                }), danger: true),
          ],
          if (st == 'approved' && _d['reverted'] != true)
            _btn('تراجع عن الاعتماد', () => _confirm('تراجع', 'سيعود جدول قسمك كما كان قبل هذا الاعتماد. متابعة؟', () => _run(() => _service.revert(widget.id), ok: 'عاد الجدول كما كان')), danger: true),
        ]);
      },
    );
  }

  Widget _grid(Map group, Color card, Color text, Color sub) {
    final days = ((_d['days'] as List?) ?? []).cast<String>();
    final labels = Map<String, dynamic>.from(_d['day_labels'] as Map);
    final count = (_d['period_count'] as num).toInt();
    final periods = _d['periods'] as Map;
    final entries = ((group['entries'] as List?) ?? []).cast<Map>();
    Map? at(String day, int p) {
      for (final e in entries) {
        if (e['day'] == day && (e['period'] as num).toInt() == p) return e;
      }
      return null;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(104),
        border: TableBorder.all(color: sub.withValues(alpha: 0.3)),
        children: [
          TableRow(children: [
            const SizedBox(height: 34),
            ...days.map((d) => Container(height: 34, alignment: Alignment.center, child: Text('${labels[d] ?? d}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12)))),
          ]),
          for (var p = 1; p <= count; p++)
            TableRow(children: [
              Container(height: 62, alignment: Alignment.center, child: Text('${(periods['$p'] as List).first}', style: TextStyle(color: sub, fontSize: 11))),
              ...days.map((d) {
                final e = at(d, p);
                if (e == null) return const SizedBox(height: 62);
                final locked = e['locked'] == true;
                final color = locked ? const Color(0xFFE65100) : (e['manual'] == true ? const Color(0xFF2E7D32) : AppColors.primary);
                return InkWell(
                  onTap: () => _entrySheet(e, card, text),
                  child: Container(
                    height: 62,
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8), border: Border(right: BorderSide(color: color, width: 3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${e['course']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
                      Text('${e['room'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 10)),
                    ]),
                  ),
                );
              }),
            ]),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );

  Widget _note(String msg, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(msg, style: TextStyle(color: color, fontSize: 12, height: 1.5)),
      );

  Widget _btn(String label, VoidCallback onTap, {bool filled = false, bool danger = false, bool disabled = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? const Color(0xFFC62828) : (filled ? AppColors.primary : Colors.transparent),
              foregroundColor: (filled || danger) ? Colors.white : AppColors.primary,
              elevation: 0,
              side: (filled || danger) ? null : const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: (_busy || disabled) ? null : onTap,
            child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
          ),
        ),
      );
}
