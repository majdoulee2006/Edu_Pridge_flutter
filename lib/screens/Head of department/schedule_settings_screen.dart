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

  String _roomType = 'classroom';
  int? _roomProgram;
  int _roomYear = 1;

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
    await _do(_service.addRoom(_roomName.text.trim(), cap, type: _roomType, programId: _roomProgram, year: _roomProgram == null ? null : _roomYear));
    _roomName.clear();
    _roomCap.clear();
  }

  Future<void> _autoRooms() async {
    final r = await _service.autoRooms();
    if (!mounted) return;
    final created = ((r.data?['created'] as List?) ?? []).length;
    final linked = ((r.data?['linked'] as List?) ?? []).length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.ok ? (created + linked == 0 ? 'لكل شعبة قاعتها الخاصة أصلاً' : 'أُنشئت $created قاعة وربطت $linked بشعبتها. راجع السعات.') : r.error!)));
    _load();
  }

  Future<void> _importRooms() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('استيراد قاعات'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('سطر لكل قاعة: الاسم، السعة، النوع (اختياري)، الدورة (اختياري)، السنة (اختياري)', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextField(controller: ctrl, maxLines: 6, decoration: const InputDecoration(hintText: 'قاعة معلوماتية - سنة أولى، 40، قاعة شعبة، معلوماتية، أولى\nمخبر الحاسوب، 25، مخبر', border: OutlineInputBorder())),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('استيراد'))],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final r = await _service.importRooms(text);
    if (!mounted) return;
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
      return;
    }
    final errors = Map<String, dynamic>.from((r.data?['errors'] as Map?) ?? {});
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('نتيجة الاستيراد'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('جديدة: ${r.data?['created'] ?? 0} · محدّثة: ${r.data?['updated'] ?? 0}'),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('أسطر لم تُستورد:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
              ...errors.entries.map((e) => Text('سطر ${e.key}: ${e.value}', style: const TextStyle(fontSize: 12))),
            ],
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('حسناً'))],
      ),
    );
    _load();
  }

  Future<void> _editRoom(Map room) async {
    final programs = ((_s['programs'] as List?) ?? []).cast<Map>();
    final types = ((_s['room_types'] as List?) ?? []).cast<Map>();
    final name = TextEditingController(text: '${room['name']}');
    final cap = TextEditingController(text: '${room['capacity']}');
    var type = '${room['type'] ?? 'classroom'}';
    int? program = (room['program_id'] as num?)?.toInt();
    var year = (room['year'] as num?)?.toInt() ?? 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('تعديل القاعة'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: cap, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعة')),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: types.map((t) => DropdownMenuItem(value: '${t['key']}', child: Text('${t['label']}'))).toList(),
                onChanged: (v) => set(() => type = v ?? type),
              ),
              DropdownButtonFormField<int?>(
                initialValue: program,
                decoration: const InputDecoration(labelText: 'الدورة (فارغ = مشتركة)'),
                items: [const DropdownMenuItem<int?>(value: null, child: Text('مشتركة')), ...programs.map((p) => DropdownMenuItem<int?>(value: (p['id'] as num).toInt(), child: Text('${p['name']}')))],
                onChanged: (v) => set(() => program = v),
              ),
              if (program != null)
                DropdownButtonFormField<int>(
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'السنة'),
                  items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('سنة $y'))],
                  onChanged: (v) => set(() => year = v ?? year),
                ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حفظ'))],
        ),
      ),
    );
    final capacity = int.tryParse(cap.text.trim());
    if (ok == true && capacity != null && capacity > 0 && name.text.trim().isNotEmpty) {
      await _do(_service.updateRoom((room['id'] as num).toInt(), name.text.trim(), capacity, type: type, programId: program, year: program == null ? null : year));
    }
  }


  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'القاعات وتوفّر المعلمين',
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));

        final rooms = (_s['rooms'] as List).cast<Map>();
        final programs = ((_s['programs'] as List?) ?? []).cast<Map>();
        final roomTypes = ((_s['room_types'] as List?) ?? []).cast<Map>();
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
            Text('لكل دورة وسنة قاعة خاصة بها وتبقى حصصها فيها. القاعة المشتركة (مخبر أو قاعة كبرى) بلا شعبة ويستعملها أي صف.', style: TextStyle(color: sub, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: _autoRooms,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('أنشئ قاعة لكل شعبة'),
              ),
              OutlinedButton.icon(onPressed: _importRooms, icon: const Icon(Icons.upload_file), label: const Text('استيراد قائمة')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 3, child: TextField(controller: _roomName, style: TextStyle(color: text), decoration: deco('اسم القاعة'))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: _roomCap, keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: deco('السعة'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _roomType,
                  decoration: deco('النوع'),
                  items: roomTypes.map((t) => DropdownMenuItem(value: '${t['key']}', child: Text('${t['label']}'))).toList(),
                  onChanged: (v) => setState(() => _roomType = v ?? _roomType),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _roomProgram,
                  isExpanded: true,
                  decoration: deco('الدورة'),
                  items: [const DropdownMenuItem<int?>(value: null, child: Text('مشتركة')), ...programs.map((p) => DropdownMenuItem<int?>(value: (p['id'] as num).toInt(), child: Text('${p['name']}', overflow: TextOverflow.ellipsis)))],
                  onChanged: (v) => setState(() => _roomProgram = v),
                ),
              ),
              if (_roomProgram != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: DropdownButtonFormField<int>(
                    initialValue: _roomYear,
                    decoration: deco('السنة'),
                    items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('$y'))],
                    onChanged: (v) => setState(() => _roomYear = v ?? _roomYear),
                  ),
                ),
              ],
              IconButton(onPressed: _addRoom, icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32)),
            ]),
            ...rooms.map((r) {
              final owner = r['program'] != null ? '${r['program']} - سنة ${r['year']}' : 'مشتركة';
              return ListTile(
                dense: true,
                title: Text('${r['name']}${r['shared'] == true ? ' (بين الأقسام)' : ''}', style: TextStyle(color: text)),
                subtitle: Text('${r['type_label'] ?? ''} · $owner · ${r['capacity']} مقعد', style: TextStyle(color: sub)),
                trailing: r['shared'] == true
                    ? null
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editRoom(r)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)), onPressed: () => _do(_service.deleteRoom((r['id'] as num).toInt()))),
                      ]),
              );
            }),
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
