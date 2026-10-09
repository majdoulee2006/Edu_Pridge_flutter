import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/student/study_screens.dart' show StudyScaffold;
import 'package:edu_pridge_flutter/services/schedule_studio_services.dart';
import 'package:edu_pridge_flutter/services/study_services.dart' show StudyResult;
import 'package:flutter/material.dart';

/// قاعات القسم وتوفّر المعلمين: يغذّيان قيود المولّد (سعة القاعة، وقت غير متاح، وقت يُفضَّل تجنّبه).
class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  final _service = ScheduleStudioService();
  final _roomName = TextEditingController();
  final _roomCap = TextEditingController();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _s = {};

  int? _teacher;
  String _day = 'Sunday';
  int _period = 1;
  String _kind = 'unavailable';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _roomName.dispose();
    _roomCap.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _service.settings();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      if (r.ok) {
        _s = r.data!;
        final teachers = (_s['teachers'] as List).cast<Map>();
        if (_teacher == null && teachers.isNotEmpty) _teacher = (teachers.first['user_id'] as num).toInt();
      }
    });
  }

  Future<void> _do(Future<StudyResult<Map<String, dynamic>>> call) async {
    final r = await call;
    if (!mounted) return;
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
      return;
    }
    _load();
  }

  Future<void> _addRoom() async {
    final cap = int.tryParse(_roomCap.text.trim());
    if (_roomName.text.trim().isEmpty || cap == null || cap < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم القاعة وسعتها')));
      return;
    }
    await _do(_service.addRoom(_roomName.text.trim(), cap));
    _roomName.clear();
    _roomCap.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'القاعات وتوفّر المعلمين',
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));

        final rooms = (_s['rooms'] as List).cast<Map>();
        final teachers = (_s['teachers'] as List).cast<Map>();
        final avail = (_s['availability'] as List).cast<Map>();
        final days = (_s['days'] as List).cast<String>();
        final labels = Map<String, dynamic>.from(_s['day_labels'] as Map);
        final periods = _s['periods'] as Map;
        final maxP = (_s['max_periods'] as num).toInt();
        final names = {for (final t in teachers) (t['user_id'] as num).toInt(): '${t['name']}'};

        InputDecoration deco(String label) => InputDecoration(labelText: label, filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
            Text('القاعات', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('بدون قاعات مسجّلة لا يفحص النظام سعة القاعة ولا تعارض حجزها.', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(flex: 3, child: TextField(controller: _roomName, style: TextStyle(color: text), decoration: deco('اسم القاعة'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: _roomCap, keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: deco('السعة'))),
              IconButton(onPressed: _addRoom, icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32)),
            ]),
            ...rooms.map((r) => ListTile(
                  dense: true,
                  title: Text('${r['name']}${r['shared'] == true ? ' (مشتركة)' : ''}', style: TextStyle(color: text)),
                  subtitle: Text('${r['capacity']} مقعد', style: TextStyle(color: sub)),
                  trailing: r['shared'] == true ? null : IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)), onPressed: () => _do(_service.deleteRoom((r['id'] as num).toInt()))),
                )),
            const Divider(height: 32),
            Text('توفّر المعلمين', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('«غير متاح» قيد صلب لا توضع فيه حصة. «يفضّل تجنّبه» قيد ناعم يتجنبه النظام إن أمكن.', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 8),
            if (teachers.isEmpty)
              Text('لا معلمين مرتبطين بمقررات قسمك', style: TextStyle(color: sub))
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _teacher,
                isExpanded: true,
                decoration: deco('المعلم'),
                items: teachers.map((t) => DropdownMenuItem(value: (t['user_id'] as num).toInt(), child: Text('${t['name']}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _teacher = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _day,
                    decoration: deco('اليوم'),
                    items: days.map((d) => DropdownMenuItem(value: d, child: Text('${labels[d] ?? d}'))).toList(),
                    onChanged: (v) => setState(() => _day = v ?? _day),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _period,
                    decoration: deco('الفترة'),
                    items: [for (var p = 1; p <= maxP; p++) DropdownMenuItem(value: p, child: Text('$p (${(periods['$p'] as List).first})'))],
                    onChanged: (v) => setState(() => _period = v ?? _period),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [ButtonSegment(value: 'unavailable', label: Text('غير متاح')), ButtonSegment(value: 'avoid', label: Text('يفضّل تجنّبه'))],
                    selected: {_kind},
                    onSelectionChanged: (v) => setState(() => _kind = v.first),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: _teacher == null ? null : () => _do(_service.addAvailability(_teacher!, _day, _period, _kind)),
                  child: const Text('حفظ'),
                ),
              ]),
            ],
            const SizedBox(height: 8),
            ...avail.map((a) => ListTile(
                  dense: true,
                  title: Text(names[(a['teacher_user_id'] as num).toInt()] ?? '—', style: TextStyle(color: text)),
                  subtitle: Text('${labels[a['day']] ?? a['day']} · الفترة ${a['period']} · ${a['kind'] == 'unavailable' ? 'غير متاح' : 'يفضّل تجنّبه'}', style: TextStyle(color: sub)),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)), onPressed: () => _do(_service.deleteAvailability((a['id'] as num).toInt()))),
                )),
          ]),
        );
      },
    );
  }
}
