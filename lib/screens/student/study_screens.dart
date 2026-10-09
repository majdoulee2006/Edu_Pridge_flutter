import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/study_services.dart';
import 'package:flutter/material.dart';

/// غلاف مشترك: ألوان الوضع الداكن/الفاتح واتجاه RTL.
class StudyScaffold extends StatelessWidget {
  final String title;
  final Widget Function(Color card, Color text, Color sub) body;
  final List<Widget>? actions;

  const StudyScaffold({super.key, required this.title, required this.body, this.actions});

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
              title: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18)),
              leading: IconButton(icon: Icon(Icons.arrow_back, color: text), onPressed: () => Navigator.pop(context)),
              actions: actions,
            ),
            body: body(card, text, sub),
          ),
        );
      },
    );
  }
}

/// وسم يوضّح أن المحتوى مولَّد بالذكاء الاصطناعي.
class AiBadge extends StatelessWidget {
  final String label;
  const AiBadge({super.key, this.label = 'مُولَّد بالذكاء الاصطناعي وراجعه المعلم'});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF1565C0)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      );
}

/// قائمة مواد المذاكرة المعتمدة للطالب.
class StudyListScreen extends StatefulWidget {
  const StudyListScreen({super.key});

  @override
  State<StudyListScreen> createState() => _StudyListScreenState();
}

class _StudyListScreenState extends State<StudyListScreen> {
  final _service = StudyService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _service.studentList();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      _rows = r.ok ? _service.asList(r.data) : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: 'رفيق المذاكرة',
      body: (card, text, sub) => RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
                Text('ملخصات وبطاقات وأسئلة تدريب أعدّها معلموك. التدريب لا يُحتسب بالعلامات.', style: TextStyle(color: sub, fontSize: 12, height: 1.6)),
                const SizedBox(height: 12),
                if (_error != null)
                  Center(child: Padding(padding: const EdgeInsets.only(top: 60), child: Text(_error!, style: TextStyle(color: text))))
                else if (_rows.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.only(top: 60), child: Text('لم ينشر معلموك مواد مذاكرة بعد', style: TextStyle(color: text, fontWeight: FontWeight.bold))))
                else
                  ..._rows.map((m) => Card(
                        color: card,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text('${m['title'] ?? ''}', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
                          subtitle: Text('${m['flashcards']} بطاقة · ${m['questions']} سؤال تدريب', style: TextStyle(color: sub, fontSize: 12)),
                          trailing: Icon(Icons.chevron_left_rounded, color: sub),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudyMaterialScreen(id: m['id'] as int))),
                        ),
                      )),
              ]),
      ),
    );
  }
}

/// مادة مذاكرة: ملخص، مصطلحات، بطاقات قلب، وتدريب يُصحَّح في الخادم.
class StudyMaterialScreen extends StatefulWidget {
  final int id;
  const StudyMaterialScreen({super.key, required this.id});

  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  final _service = StudyService();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic> _m = {};
  final Set<int> _flipped = {};
  final Map<int, int> _answers = {};
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _service.studentShow(widget.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      if (r.ok) _m = Map<String, dynamic>.from(r.data as Map);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final r = await _service.attempt(widget.id, _answers);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (r.ok) {
        _result = Map<String, dynamic>.from(r.data as Map);
      }
    });
    if (!r.ok) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error ?? 'تعذّر التصحيح')));
  }

  void _retry() => setState(() {
        _result = null;
        _answers.clear();
      });

  Map<String, dynamic>? _review(int qid) {
    final list = (_result?['review'] as List?) ?? [];
    for (final e in list) {
      if ((e as Map)['question_id'] == qid) return Map<String, dynamic>.from(e);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: '${_m['title'] ?? 'مذاكرة'}',
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));

        final cards = ((_m['flashcards'] as List?) ?? []).cast<Map>();
        final terms = ((_m['key_terms'] as List?) ?? []).cast<Map>();
        final qs = ((_m['questions'] as List?) ?? []).cast<Map>();

        return ListView(padding: const EdgeInsets.all(16), children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: AiBadge()),
          const SizedBox(height: 12),
          _section('الملخص', card, text, [Text('${_m['summary'] ?? ''}', style: TextStyle(color: text, height: 1.9))]),
          if (terms.isNotEmpty)
            _section('مصطلحات رئيسية', card, text, terms.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${t['term']}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${t['definition']}'),
                  ]), style: TextStyle(color: text, height: 1.6)),
                )).toList()),
          if (cards.isNotEmpty)
            _section('بطاقات المراجعة (اضغط لتظهر الإجابة)', card, text, [
              for (var i = 0; i < cards.length; i++)
                InkWell(
                  onTap: () => setState(() => _flipped.contains(i) ? _flipped.remove(i) : _flipped.add(i)),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: sub.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${cards[i]['front']}', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
                      if (_flipped.contains(i)) ...[
                        const Divider(),
                        Text('${cards[i]['back']}', style: TextStyle(color: sub, height: 1.6)),
                      ],
                    ]),
                  ),
                ),
            ]),
          if (qs.isNotEmpty) _practice(qs, card, text, sub),
        ]);
      },
    );
  }

  Widget _section(String title, Color card, Color text, List<Widget> children) => Card(
        color: card,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );

  Widget _practice(List<Map> qs, Color card, Color text, Color sub) {
    final done = _result != null;
    return _section('تدرّب (لا يُحتسب بعلاماتك)', card, text, [
      if (done)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('نتيجتك: ${_result!['score']} من ${_result!['total']}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      for (var i = 0; i < qs.length; i++) _question(i, qs[i], text, sub, done),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: _submitting ? null : (done ? _retry : _submit),
          child: _submitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(done ? 'حاول من جديد' : 'تصحيح'),
        ),
      ),
    ]);
  }

  Widget _question(int i, Map q, Color text, Color sub, bool done) {
    final qid = q['id'] as int;
    final rv = done ? _review(qid) : null;
    final options = (q['options'] as List).cast<String>();
    final border = rv == null ? sub.withValues(alpha: 0.4) : (rv['is_correct'] == true ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${i + 1}. ${q['question']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, height: 1.5)),
        for (var o = 0; o < options.length; o++)
          InkWell(
            onTap: done ? null : () => setState(() => _answers[qid] = o),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Icon(
                  _answers[qid] == o ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 20,
                  color: _answers[qid] == o ? AppColors.primary : sub,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(options[o], style: TextStyle(color: text))),
                if (rv != null && rv['correct_index'] == o) const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
              ]),
            ),
          ),
        if (rv != null && (rv['explanation'] ?? '').toString().isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text('${rv['explanation']}', style: TextStyle(color: sub, fontSize: 12, height: 1.5))),
      ]),
    );
  }
}
