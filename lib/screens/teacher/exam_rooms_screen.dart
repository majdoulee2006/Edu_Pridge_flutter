import 'package:edu_pridge_flutter/screens/student/study_screens.dart' show StudyScaffold;
import 'package:edu_pridge_flutter/services/teacher_exam_service.dart';
import 'package:flutter/material.dart';

const _kindColor = {'midterm': Color(0xFF1565C0), 'final': Color(0xFF6A1B9A)};

/// جدول المعلم الامتحاني المعتمد: قاعات مراقبته (مع قوائم طلابها)، وقاعات تقييمات مقرراته.
class TeacherExamRoomsScreen extends StatefulWidget {
  const TeacherExamRoomsScreen({super.key});

  @override
  State<TeacherExamRoomsScreen> createState() => _TeacherExamRoomsScreenState();
}

class _TeacherExamRoomsScreenState extends State<TeacherExamRoomsScreen> {
  final _service = TeacherExamService();
  bool _loading = true;
  bool _failed = false;
  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await _service.invigilations();
    final b = await _service.courseExamRooms();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = a == null && b == null;
      _mine = a ?? [];
      _courses = b ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: StudyScaffold(
        title: 'الامتحانات والمراقبة',
        body: (card, text, sub) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          if (_failed) return Center(child: Text('تعذّر تحميل البيانات', style: TextStyle(color: text)));
          return Column(children: [
            TabBar(labelColor: text, unselectedLabelColor: sub, tabs: const [Tab(text: 'مراقباتي'), Tab(text: 'تقييمات مقرراتي')]),
            Expanded(
              child: TabBarView(children: [
                _list(_mine, card, text, sub, 'لم تُسنَد إليك مراقبة بعد'),
                _list(_courses, card, text, sub, 'لا تقييمات معتمدة لمقرراتك بعد'),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> items, Color card, Color text, Color sub, String empty) {
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(children: [Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(empty, style: TextStyle(color: sub))))])
          : ListView(padding: const EdgeInsets.all(16), children: [for (final e in items) _card(e, card, text, sub)]),
    );
  }

  Widget _card(Map<String, dynamic> e, Color card, Color text, Color sub) {
    final color = _kindColor['${e['kind']}'] ?? Colors.grey;
    final rooms = ((e['rooms'] as List?) ?? []).cast<Map>();
    return Card(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: color.withValues(alpha: 0.4))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${e['type_label']}: ${e['course']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('${e['class_group'] ?? ''} · ${e['date']} · ${e['start']}–${e['end']}', style: TextStyle(color: sub, fontSize: 12)),
          for (final r in rooms)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('${r['name']} — ${r['count']} طالباً', style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w700)),
              subtitle: Text('المراقب: ${r['proctor'] ?? 'غير محدد'}', style: TextStyle(color: sub, fontSize: 11.5)),
              children: [
                for (final s in ((r['students'] as List?) ?? []).cast<Map>())
                  ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('${s['name']}', style: TextStyle(color: text, fontSize: 13)), trailing: Text('مقعد ${s['seat']}', style: TextStyle(color: sub, fontSize: 11.5))),
              ],
            ),
        ]),
      ),
    );
  }
}
