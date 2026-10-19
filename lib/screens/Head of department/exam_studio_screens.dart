import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/Head of department/schedule_settings_screen.dart';
import 'package:edu_pridge_flutter/screens/student/study_screens.dart' show StudyScaffold;
import 'package:edu_pridge_flutter/services/exam_studio_services.dart';
import 'package:edu_pridge_flutter/services/study_services.dart' show StudyResult;
import 'package:flutter/material.dart';

const _statusLabels = {'draft': 'مسودة', 'approved': 'معتمد', 'discarded': 'مُهمَل'};
const _kindColor = {'midterm': Color(0xFF1565C0), 'final': Color(0xFF6A1B9A)};
const _levelColor = {'ok': Color(0xFF2E7D32), 'info': Color(0xFF1565C0), 'warn': Color(0xFFE65100), 'error': Color(0xFFC62828)};
const _levelIcon = {'ok': '✓', 'info': 'ℹ', 'warn': '⚠', 'error': '✖'};

Color _statusColor(String s) => s == 'approved' ? const Color(0xFF2E7D32) : (s == 'draft' ? const Color(0xFFE65100) : const Color(0xFF78909C));

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _hm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

Widget _note(String msg, Color color) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(msg, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5)),
    );

Widget _chip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );

/// مدخل مولّد الامتحانات: الفصل، زر بناء واضح، جاهزية البيانات، وقائمة الجداول الامتحانية.
class ExamStudioScreen extends StatefulWidget {
  const ExamStudioScreen({super.key});

  @override
  State<ExamStudioScreen> createState() => _ExamStudioScreenState();
}

class _ExamStudioScreenState extends State<ExamStudioScreen> {
  final _service = ExamStudioService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  int? _semesterId;

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
        _semesterId ??= (_data['selected_semester_id'] as num?)?.toInt();
      }
    });
  }

  Future<void> _openBuild() async {
    final id = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => ExamBuildScreen(semesterId: _semesterId, defaults: Map<String, dynamic>.from((_data['defaults'] as Map?) ?? {}), maxSlots: (_data['max_slots_per_day'] as num?)?.toInt() ?? 6, saveForNext: _isNext)));
    if (id != null && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDraftScreen(id: id)));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'مولّد الامتحانات',
      actions: [
        IconButton(
          tooltip: 'القاعات',
          icon: const Icon(Icons.meeting_room_rounded),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen()));
            _load();
          },
        ),
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
                    items: [for (final s in semesters) DropdownMenuItem(value: (s['id'] as num).toInt(), child: Text('${s['name']}${s['current'] == true ? ' (الحالي)' : ''}'))],
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
            if (_isNext) _note('هذا الفصل ليس الفعّال حالياً: الجدول الذي تولّده يُحفظ للفصل القادم، ولا يُعتمد ولا يظهر للطلاب إلا عندما يصبح فعّالاً.', const Color(0xFF1565C0)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.85), AppColors.primary])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('📝 ابنِ لي جدول المذاكرات والامتحانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 6),
                const Text('تدخل تواريخ كل فترة وفتراتها اليومية ومدة كل نوع. تقييم واحد فقط لكل شعبة في اليوم، ويُوزَّع الطلاب على عدة قاعات عند الحاجة، ثم تختار مراقب كل قاعة.',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.6)),
                const SizedBox(height: 12),
                Row(children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                    onPressed: (_semesterId == null || errors > 0) ? null : _openBuild,
                    child: const Text('ابدأ البناء', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  if (readiness != null)
                    Flexible(child: Text(errors > 0 ? '⚠ $errors يمنع البناء' : (warnings > 0 ? '$warnings تنبيه' : '✓ البيانات جاهزة'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
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
                            ]),
                          ),
                        ]),
                      );
                    }),
                  ]),
                ),
              ),
            const SizedBox(height: 14),
            Text('الجداول الامتحانية', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            if (drafts.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('لا جداول بعد. اضغط «ابدأ البناء».', style: TextStyle(color: sub)))),
            ...drafts.map((d) {
              final st = '${d['status']}';
              final next = d['saved_for_next'] == true;
              return Card(
                color: card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text('${d['name']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${d['semester_name'] ?? ''} · ${d['placed']} / ${d['required']} تقييم · ${d['unscheduled']} ناقص', style: TextStyle(color: sub, fontSize: 12)),
                  trailing: Text(next ? 'محفوظ للفصل القادم' : (_statusLabels[st] ?? st), style: TextStyle(color: next ? const Color(0xFF1565C0) : _statusColor(st), fontWeight: FontWeight.bold, fontSize: 12)),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDraftScreen(id: (d['id'] as num).toInt())));
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
}

class _SlotInput {
  TimeOfDay? start;
  TimeOfDay? end;
  _SlotInput(this.start, this.end);
}

class _KindForm {
  bool enabled = true;
  DateTime? from;
  DateTime? to;
  final TextEditingController duration;
  final List<_SlotInput> slots;
  final List<DateTime> excluded = [];
  _KindForm(int minutes, this.slots) : duration = TextEditingController(text: '$minutes');
}

/// نموذج بناء الجدول الامتحاني: فترة وفترات يومية ومدة لكل نوع (مذاكرات / امتحانات). يعيد رقم المسودة عند النجاح.
class ExamBuildScreen extends StatefulWidget {
  final int? semesterId;
  final Map<String, dynamic> defaults;
  final int maxSlots;
  final bool saveForNext;
  const ExamBuildScreen({super.key, required this.semesterId, required this.defaults, required this.maxSlots, required this.saveForNext});

  @override
  State<ExamBuildScreen> createState() => _ExamBuildScreenState();
}

class _ExamBuildScreenState extends State<ExamBuildScreen> {
  final _service = ExamStudioService();
  bool _busy = false;
  late final Map<String, _KindForm> _forms;

  static const _titles = {'midterm': 'المذاكرات', 'final': 'الامتحانات النهائية'};
  static const _hints = {'midterm': 'امتحان نصفي مصغّر، بفترة مستقلة عن الامتحانات النهائية', 'final': 'تبدأ بعد انتهاء فترة المذاكرات'};

  @override
  void initState() {
    super.initState();
    _forms = {
      'midterm': _KindForm((widget.defaults['midterm'] as num?)?.toInt() ?? 60, [_SlotInput(const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 10, minute: 30)), _SlotInput(const TimeOfDay(hour: 12, minute: 0), const TimeOfDay(hour: 13, minute: 30))]),
      'final': _KindForm((widget.defaults['final'] as num?)?.toInt() ?? 120, [_SlotInput(const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 11, minute: 30)), _SlotInput(const TimeOfDay(hour: 12, minute: 0), const TimeOfDay(hour: 14, minute: 30))]),
    };
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));

  Map<String, dynamic>? _payload() {
    final out = <String, dynamic>{};
    for (final e in _forms.entries) {
      final f = e.value;
      if (!f.enabled) continue;
      if (f.from == null || f.to == null) {
        _toast('حدّد تاريخ البداية والنهاية لفترة ${_titles[e.key]}');
        return null;
      }
      final slots = <Map<String, String>>[];
      for (final s in f.slots) {
        if (s.start == null || s.end == null) {
          _toast('أكمل الفترات اليومية في ${_titles[e.key]} أو احذف الفارغة');
          return null;
        }
        slots.add({'start': _hm(s.start!), 'end': _hm(s.end!)});
      }
      out[e.key] = {
        'from': _ymd(f.from!), 'to': _ymd(f.to!), 'duration': int.tryParse(f.duration.text.trim()) ?? 0,
        'excluded': f.excluded.map(_ymd).toList(), 'slots': slots,
      };
    }
    if (out.isEmpty) {
      _toast('فعّل المذاكرات أو الامتحانات (أو كليهما)');
      return null;
    }
    return out;
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    final kinds = _payload();
    if (kinds == null) return;
    setState(() => _busy = true);
    final r = await _service.generate(kinds, semesterId: widget.semesterId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      _toast(r.error!);
      return;
    }
    Navigator.pop(context, (r.data!['id'] as num).toInt());
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'بناء جدول امتحاني',
      body: (card, text, sub) => ListView(padding: const EdgeInsets.all(16), children: [
        if (widget.saveForNext) _note('سيُحفظ الجدول للفصل القادم ولن يُعتمد الآن.', const Color(0xFF1565C0)),
        for (final kind in ['midterm', 'final']) _kindCard(kind, card, text, sub),
        const SizedBox(height: 6),
        Text('الأيام المتاحة هي أيام الدوام الأسبوعية فقط. اليوم الذي تُحجز فيه مذاكرة أو امتحان لشعبة لا يُحجز فيه شيء آخر لها. لن يظهر شيء لأحد قبل اعتمادك.', style: TextStyle(color: sub, fontSize: 12, height: 1.6)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _busy ? null : _submit,
            icon: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: const Text('ابنِ الجدول'),
          ),
        ),
      ]),
    );
  }

  Widget _kindCard(String kind, Color card, Color text, Color sub) {
    final f = _forms[kind]!;
    final color = _kindColor[kind]!;
    return Card(
      color: card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.4))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: f.enabled,
            activeThumbColor: color,
            onChanged: (v) => setState(() => f.enabled = v),
            title: Text(_titles[kind]!, style: TextStyle(color: text, fontWeight: FontWeight.w800)),
            subtitle: Text(_hints[kind]!, style: TextStyle(color: sub, fontSize: 11.5)),
          ),
          if (f.enabled) ...[
            Row(children: [
              Expanded(child: _dateBtn('من تاريخ', f.from, () async {
                final d = await _pickDate(f.from);
                if (d != null) setState(() => f.from = d);
              })),
              const SizedBox(width: 10),
              Expanded(child: _dateBtn('إلى تاريخ', f.to, () async {
                final d = await _pickDate(f.to ?? f.from);
                if (d != null) setState(() => f.to = d);
              })),
            ]),
            const SizedBox(height: 10),
            TextField(controller: f.duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدة التقييم (دقيقة)')),
            const SizedBox(height: 12),
            Text('الفترات اليومية', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13)),
            for (var i = 0; i < f.slots.length; i++)
              Row(children: [
                Expanded(child: _timeBtn('من', f.slots[i].start, () async {
                  final t = await showTimePicker(context: context, initialTime: f.slots[i].start ?? const TimeOfDay(hour: 9, minute: 0));
                  if (t != null) setState(() => f.slots[i].start = t);
                })),
                const SizedBox(width: 8),
                Expanded(child: _timeBtn('إلى', f.slots[i].end, () async {
                  final t = await showTimePicker(context: context, initialTime: f.slots[i].end ?? const TimeOfDay(hour: 11, minute: 0));
                  if (t != null) setState(() => f.slots[i].end = t);
                })),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => f.slots.removeAt(i))),
              ]),
            if (f.slots.length < widget.maxSlots)
              TextButton.icon(onPressed: () => setState(() => f.slots.add(_SlotInput(null, null))), icon: const Icon(Icons.add), label: const Text('فترة')),
            const SizedBox(height: 6),
            Text('أيام مستثناة (عطل)', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 13)),
            Wrap(spacing: 6, children: [
              for (final d in f.excluded) Chip(label: Text(_ymd(d), style: const TextStyle(fontSize: 12)), onDeleted: () => setState(() => f.excluded.remove(d))),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('يوم'),
                onPressed: () async {
                  final d = await _pickDate(f.from);
                  if (d != null && !f.excluded.any((x) => _ymd(x) == _ymd(d))) setState(() => f.excluded.add(d));
                },
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _dateBtn(String label, DateTime? v, VoidCallback onTap) => OutlinedButton(onPressed: onTap, child: Text(v == null ? label : _ymd(v)));
  Widget _timeBtn(String label, TimeOfDay? v, VoidCallback onTap) => OutlinedButton(onPressed: onTap, child: Text(v == null ? label : _hm(v)));
}

/// مراجعة الجدول الامتحاني: تقييمات مرتبة بالأيام، تعديل بالنقر (نقل/تثبيت/مراقب كل قاعة/نقل طالب)، ثم اعتماد.
class ExamDraftScreen extends StatefulWidget {
  final int id;
  const ExamDraftScreen({super.key, required this.id});

  @override
  State<ExamDraftScreen> createState() => _ExamDraftScreenState();
}

class _ExamDraftScreenState extends State<ExamDraftScreen> {
  final _service = ExamStudioService();
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _d = {};

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

  Future<bool> _run(Future<StudyResult<Map<String, dynamic>>> Function() call, {String? ok}) async {
    setState(() => _busy = true);
    final r = await call();
    if (!mounted) return false;
    setState(() {
      _busy = false;
      if (r.ok) _apply(r);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.ok ? (ok ?? 'تم') : r.error!)));
    return r.ok;
  }

  Map? _entry(int id) {
    for (final e in (_d['entries'] as List? ?? [])) {
      if ((e['id'] as num).toInt() == id) return e as Map;
    }
    return null;
  }

  Future<void> _approve() async {
    final needAck = ((_d['unscheduled_items'] as List?) ?? []).isNotEmpty || ((_d['rooms_without_proctor'] as num?)?.toInt() ?? 0) > 0;
    final impact = _d['impact'] as Map?;
    var ack = false;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('اعتماد الجدول الامتحاني'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('سيظهر للطلاب والمعلمين والمراقبين ويُشعَرون به.'),
            if (impact != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('يُحدَّث ${impact['updated']} تقييماً قائماً ويُضاف ${impact['created']}، ويصل إلى ${impact['students']} طالباً و${impact['teachers']} معلماً. العلامات المرصودة لا تُمسّ.', style: const TextStyle(fontSize: 12.5))),
            if (needAck)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: ack,
                onChanged: (v) => set(() => ack = v ?? false),
                title: const Text('أقرّ بوجود تقييمات لم تُجدول أو قاعات بلا مراقب وأريد الاعتماد كما هو', style: TextStyle(fontSize: 13)),
              ),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('اعتماد'))],
        ),
      ),
    );
    if (yes == true) _run(() => _service.approve(widget.id, acknowledge: ack), ok: 'اعتُمد الجدول الامتحاني وأُشعر الجميع');
  }

  Future<void> _confirm(String title, String body, Future<void> Function() onYes) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(title: Text(title), content: Text(body), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('نعم'))]),
    );
    if (yes == true) await onYes();
  }

  void _entrySheet(int entryId, Color card, Color text, Color sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      builder: (c) => _EntrySheet(
        service: _service, draftId: widget.id, entryId: entryId, editable: _editable,
        read: () => _entry(entryId), teachers: ((_d['teachers'] as List?) ?? []).cast<Map>(),
        dates: Map<String, dynamic>.from((_d['dates'] as Map?) ?? {}), slots: Map<String, dynamic>.from((_d['slots'] as Map?) ?? {}),
        onChanged: (data) => setState(() => _d = data), text: text, sub: sub,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'مراجعة الجدول الامتحاني',
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));

        final entries = ((_d['entries'] as List?) ?? []).cast<Map>();
        final byDate = <String, List<Map>>{};
        for (final e in entries) {
          byDate.putIfAbsent('${e['date']}', () => []).add(e);
        }
        final dates = byDate.keys.toList()..sort();
        final violations = ((_d['violation_messages'] as List?) ?? []).cast<String>();
        final unscheduled = ((_d['unscheduled_items'] as List?) ?? []).cast<Map>();
        final noProctor = (_d['rooms_without_proctor'] as num?)?.toInt() ?? 0;
        final st = '${_d['status']}';

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            Wrap(spacing: 8, runSpacing: 6, children: [
              _chip(_statusLabels[st] ?? st, _statusColor(st)),
              if (_d['reverted'] == true) _chip('تُرُوجع عنه', const Color(0xFF78909C)),
              _chip('${_d['semester_name'] ?? ''}', AppColors.primary),
            ]),
            if (_d['saved_for_next'] == true) _note('محفوظ للفصل القادم: لا يُعتمد ولا يظهر لأحد إلا عندما يصبح فصله فعّالاً.', const Color(0xFF1565C0)),
            const SizedBox(height: 10),
            Row(children: [
              _stat('${_d['placed']} / ${_d['required']}', 'موضوعة', const Color(0xFF2E7D32), card, text, sub),
              _stat('${unscheduled.length}', 'لم تُجدول', unscheduled.isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFE65100), card, text, sub),
              _stat('${violations.length}', 'تعارضات', violations.isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFC62828), card, text, sub),
              _stat('$noProctor', 'بلا مراقب', noProctor == 0 ? const Color(0xFF2E7D32) : const Color(0xFFE65100), card, text, sub),
            ]),
            for (final v in violations) _note('⛔ $v', const Color(0xFFC62828)),
            for (final u in unscheduled) _note('${u['group']} — ${u['title']} (${u['kind']}): ${u['message']}', const Color(0xFFE65100)),
            const SizedBox(height: 10),
            for (final date in dates) ...[
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: Text('${byDate[date]!.first['day']} — $date', style: TextStyle(color: text, fontWeight: FontWeight.w800))),
              for (final e in byDate[date]!) _entryCard(e, card, text, sub),
            ],
            const SizedBox(height: 18),
            if (_editable) ...[
              _btn('إعادة توزيع غير المثبّت', () => _run(() => _service.regenerate(widget.id), ok: 'أُعيد التوزيع')),
              _btn('اعتماد الجدول', _approve, filled: true, disabled: violations.isNotEmpty || _d['saved_for_next'] == true),
              if (violations.isNotEmpty) _note('لا يمكن الاعتماد قبل حل التعارضات.', const Color(0xFFC62828)),
              _btn('إهمال المسودة', () => _confirm('إهمال المسودة', 'إهمال هذه المسودة؟', () async {
                    final nav = Navigator.of(context);
                    final ok = await _run(() => _service.discard(widget.id), ok: 'أُهملت المسودة');
                    if (ok) nav.pop();
                  }), danger: true),
            ],
            if (st == 'approved' && _d['reverted'] != true)
              _btn('تراجع عن الاعتماد', () => _confirm('التراجع', 'سيعود الجدول كما كان قبل هذا الاعتماد. متابعة؟', () async {
                    await _run(() => _service.revert(widget.id), ok: 'تم التراجع');
                  }), danger: true),
          ]),
        );
      },
    );
  }

  Widget _stat(String v, String l, Color c, Color card, Color text, Color sub) => Expanded(
        child: Card(
          color: card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 17)), Text(l, style: TextStyle(color: sub, fontSize: 10.5))]),
          ),
        ),
      );

  Widget _entryCard(Map e, Color card, Color text, Color sub) {
    final color = _kindColor['${e['kind']}'] ?? Colors.grey;
    final rooms = ((e['rooms'] as List?) ?? []).cast<Map>();
    return Card(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: e['locked'] == true ? const Color(0xFFE65100) : color.withValues(alpha: 0.35))),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _entrySheet((e['id'] as num).toInt(), card, text, sub),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _chip('${e['kind_label']}', color),
              const SizedBox(width: 8),
              Expanded(child: Text('${e['title']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14))),
              if (e['locked'] == true) const Icon(Icons.lock, size: 16, color: Color(0xFFE65100)),
            ]),
            const SizedBox(height: 4),
            Text('${e['group_label']} · ${e['start']}–${e['end']} (${e['duration']} د)', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 6),
            for (final r in rooms)
              Text('• ${r['name']} (${r['count']}/${r['capacity']}) — ${r['proctor'] ?? 'بلا مراقب'}', style: TextStyle(color: r['proctor'] == null ? const Color(0xFFE65100) : text, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

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

/// ورقة تقييم واحد: النقل، التثبيت، مراقب كل قاعة، وطلاب كل قاعة مع نقلهم بين قاعات التقييم.
class _EntrySheet extends StatefulWidget {
  final ExamStudioService service;
  final int draftId;
  final int entryId;
  final bool editable;
  final Map? Function() read;
  final List<Map> teachers;
  final Map<String, dynamic> dates;
  final Map<String, dynamic> slots;
  final void Function(Map<String, dynamic>) onChanged;
  final Color text;
  final Color sub;
  const _EntrySheet({required this.service, required this.draftId, required this.entryId, required this.editable, required this.read, required this.teachers, required this.dates, required this.slots, required this.onChanged, required this.text, required this.sub});

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  bool _busy = false;
  String? _date;
  int? _slot;

  Future<void> _do(Future<StudyResult<Map<String, dynamic>>> Function() call) async {
    setState(() => _busy = true);
    final r = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      widget.onChanged(r.data!);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.read();
    if (e == null) return const SizedBox.shrink();
    final kind = '${e['kind']}';
    final dates = ((widget.dates[kind] as List?) ?? []).cast<String>();
    final slots = ((widget.slots[kind] as List?) ?? []).cast<Map>();
    _date ??= '${e['date']}';
    _slot ??= slots.indexWhere((s) => s['start'] == e['start']).clamp(0, 99);
    final rooms = ((e['rooms'] as List?) ?? []).cast<Map>();
    final id = (e['id'] as num).toInt();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (c, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
          Text('${e['kind_label']}: ${e['title']}', style: TextStyle(color: widget.text, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${e['group_label']} · ${e['day']} ${e['date']} · ${e['start']}–${e['end']}', style: TextStyle(color: widget.sub, fontSize: 12)),
          if (widget.editable) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: dates.contains(_date) ? _date : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'اليوم'),
                  items: dates.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _date = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _slot,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الفترة'),
                  items: [for (var i = 0; i < slots.length; i++) DropdownMenuItem(value: i, child: Text('${slots[i]['start']}–${slots[i]['end']}'))],
                  onChanged: (v) => setState(() => _slot = v),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _busy ? null : () => _do(() => widget.service.move(widget.draftId, id, _date!, _slot!)), child: const Text('نقل'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _do(() => widget.service.lock(widget.draftId, id, e['locked'] != true)), child: Text(e['locked'] == true ? 'إلغاء التثبيت' : 'تثبيت'))),
            ]),
          ],
          const Divider(height: 28),
          for (final r in rooms) ...[
            Text('${r['name']} — ${r['count']} / ${r['capacity']} طالباً', style: TextStyle(color: widget.text, fontWeight: FontWeight.w800)),
            if (widget.editable)
              DropdownButtonFormField<int?>(
                initialValue: widget.teachers.any((t) => (t['id'] as num).toInt() == (r['proctor_id'] as num?)?.toInt()) ? (r['proctor_id'] as num).toInt() : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'المراقب'),
                items: [const DropdownMenuItem<int?>(value: null, child: Text('— بلا مراقب —')), for (final t in widget.teachers) DropdownMenuItem<int?>(value: (t['id'] as num).toInt(), child: Text('${t['name']}'))],
                onChanged: _busy ? null : (v) => _do(() => widget.service.setProctor(widget.draftId, id, '${r['name']}', v)),
              )
            else
              Text('المراقب: ${r['proctor'] ?? 'غير محدد'}', style: TextStyle(color: widget.sub, fontSize: 12)),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('الطلاب (${r['count']})', style: TextStyle(color: widget.sub, fontSize: 13)),
              children: [
                for (final s in ((r['students'] as List?) ?? []).cast<Map>())
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${s['name']}', style: TextStyle(color: widget.text, fontSize: 13)),
                    trailing: (widget.editable && rooms.length > 1)
                        ? PopupMenuButton<String>(
                            tooltip: 'نقل إلى قاعة',
                            icon: const Icon(Icons.swap_horiz),
                            onSelected: (room) => _do(() => widget.service.moveStudent(widget.draftId, id, (s['id'] as num).toInt(), room)),
                            itemBuilder: (_) => [for (final o in rooms) if (o['name'] != r['name']) PopupMenuItem(value: '${o['name']}', child: Text('${o['name']}'))],
                          )
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ]),
      ),
    );
  }
}
