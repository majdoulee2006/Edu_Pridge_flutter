import 'dart:async';

import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/student/study_screens.dart';
import 'package:edu_pridge_flutter/services/study_services.dart';
import 'package:flutter/material.dart';

const _statusLabels = {
  'pending': 'قيد التوليد…',
  'draft': 'مسودة بانتظار مراجعتك',
  'approved': 'منشورة للطلاب',
  'failed': 'فشل التوليد',
};

Color _statusColor(String? s) {
  switch (s) {
    case 'approved':
      return const Color(0xFF2E7D32);
    case 'draft':
      return const Color(0xFFE65100);
    case 'failed':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFF1565C0);
  }
}

/// محاضرات المعلم مع زر توليد مسودة لكل منها. الذكاء الاصطناعي يكتب مسودة فقط، والمعلم يعتمد.
class TeacherStudyListScreen extends StatefulWidget {
  const TeacherStudyListScreen({super.key});

  @override
  State<TeacherStudyListScreen> createState() => _TeacherStudyListScreenState();
}

class _TeacherStudyListScreenState extends State<TeacherStudyListScreen> {
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
    final r = await _service.teacherList();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      _rows = r.ok ? _service.asList(r.data) : [];
    });
  }

  Future<void> _generate(Map<String, dynamic> row) async {
    final r = await _service.generate(row['lesson_id'] as int);
    if (!mounted) return;
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
      return;
    }
    final id = (r.data as Map)['material_id'] as int;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherStudyReviewScreen(id: id)));
    _load();
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
                Text('حوّل محاضرتك إلى ملخص وبطاقات وأسئلة. يكتب الذكاء الاصطناعي مسودة فقط، ولا يراها الطلاب إلا بعد اعتمادك.',
                    style: TextStyle(color: sub, fontSize: 12, height: 1.6)),
                const SizedBox(height: 12),
                if (_error != null)
                  Center(child: Text(_error!, style: TextStyle(color: text)))
                else if (_rows.isEmpty)
                  Center(child: Padding(padding: const EdgeInsets.only(top: 60), child: Text('لا محاضرات في مقرراتك بعد', style: TextStyle(color: text, fontWeight: FontWeight.bold))))
                else
                  ..._rows.map((r) => _tile(r, card, text, sub)),
              ]),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> r, Color card, Color text, Color sub) {
    final status = r['status'] as String?;
    final canGenerate = r['can_generate'] == true && status != 'approved' && status != 'pending';
    return Card(
      color: card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r['title']}', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          Text('${r['course'] ?? ''}', style: TextStyle(color: sub, fontSize: 12)),
          if (r['can_generate'] != true) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${r['why_not']}', style: TextStyle(color: sub, fontSize: 11))),
          if (status == 'failed') Padding(padding: const EdgeInsets.only(top: 6), child: Text('${r['failure_reason'] ?? ''}', style: const TextStyle(color: Color(0xFFC62828), fontSize: 12))),
          const SizedBox(height: 8),
          Row(children: [
            if (status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabels[status] ?? status, style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            const Spacer(),
            if (r['material_id'] != null)
              TextButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherStudyReviewScreen(id: r['material_id'] as int)));
                  _load();
                },
                child: const Text('فتح'),
              ),
            if (canGenerate)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () => _generate(r),
                child: Text(status == null ? 'توليد مسودة' : 'إعادة التوليد'),
              ),
          ]),
        ]),
      ),
    );
  }
}

/// مراجعة المسودة: تعديل الملخص وحذف بطاقات/أسئلة غير مناسبة ثم الاعتماد. (إعادة كتابة الخيارات بالتفصيل من الويب.)
class TeacherStudyReviewScreen extends StatefulWidget {
  final int id;
  const TeacherStudyReviewScreen({super.key, required this.id});

  @override
  State<TeacherStudyReviewScreen> createState() => _TeacherStudyReviewScreenState();
}

class _TeacherStudyReviewScreenState extends State<TeacherStudyReviewScreen> {
  final _service = StudyService();
  final _summary = TextEditingController();
  Timer? _poll;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _m = {};
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _questions = [];

  String get _status => '${_m['status'] ?? ''}';
  bool get _editable => _status == 'draft' || _status == 'failed';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _service.teacherShow(widget.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      if (r.ok) {
        _m = Map<String, dynamic>.from(r.data as Map);
        _summary.text = '${_m['summary'] ?? ''}';
        _cards = _service.asList(_m['flashcards']);
        _questions = _service.asList(_m['questions']);
      }
    });
    _poll?.cancel();
    if (_status == 'pending') _poll = Timer(const Duration(seconds: 5), _load);   // يتابع التوليد في الخلفية
  }

  Future<bool> _save() async {
    final r = await _service.save(widget.id, {
      'summary': _summary.text,
      'flashcards': _cards.map((c) => {'front': c['front'], 'back': c['back']}).toList(),
      'questions': _questions,
    });
    if (!r.ok && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
    return r.ok;
  }

  Future<void> _act(Future<StudyResult<dynamic>> Function() call, {bool saveFirst = false, String? ok}) async {
    setState(() => _busy = true);
    if (saveFirst && !await _save()) {
      setState(() => _busy = false);
      return;
    }
    final r = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.ok ? (ok ?? 'تم') : r.error!)));
    if (r.ok) _load();
  }

  Future<void> _confirmApprove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('اعتماد ونشر'),
        content: const Text('سيراها كل طلاب المقرر ويصلهم إشعار. تأكد أنك راجعت الملخص والأسئلة.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('اعتماد'))],
      ),
    );
    if (yes == true) _act(() => _service.approve(widget.id), saveFirst: true, ok: 'اعتُمدت المادة وصارت ظاهرة للطلاب');
  }

  @override
  Widget build(BuildContext context) {
    return StudyScaffold(
      title: '${_m['lesson'] ?? 'مراجعة المسودة'}',
      body: (card, text, sub) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: text)));
        if (_status == 'pending') {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('يجري التوليد…', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            Text('تتحدّث الشاشة تلقائيًا', style: TextStyle(color: sub, fontSize: 12)),
          ]));
        }
        if (_status == 'failed' && (_m['summary'] ?? '').toString().isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${_m['failure_reason'] ?? 'فشل التوليد'}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC62828), height: 1.6))));
        }

        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            const AiBadge(label: 'مسودة مُولَّدة بالذكاء الاصطناعي'),
            const SizedBox(width: 8),
            Text(_statusLabels[_status] ?? _status, style: TextStyle(color: _statusColor(_status), fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text('الملخص', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _summary,
            enabled: _editable,
            maxLines: 8,
            style: TextStyle(color: text, height: 1.6),
            decoration: InputDecoration(filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          Text('بطاقات المراجعة (${_cards.length})', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          ..._cards.asMap().entries.map((e) => Card(
                color: card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text('${e.value['front']}', style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('${e.value['back']}', style: TextStyle(color: sub, fontSize: 12)),
                  trailing: _editable ? IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)), onPressed: () => setState(() => _cards.removeAt(e.key))) : null,
                ),
              )),
          const SizedBox(height: 16),
          Text('أسئلة التدريب (${_questions.length})', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          ..._questions.asMap().entries.map((e) => _questionCard(e.key, e.value, card, text, sub)),
          const SizedBox(height: 20),
          if (_editable) ...[
            _btn('حفظ التعديلات', onTap: () => _act(() => _save().then((ok) => ok ? const StudyResult.ok(null) : const StudyResult.fail('تعذّر الحفظ')), ok: 'حُفظت التعديلات')),
            _btn('اعتماد ونشر للطلاب', filled: true, onTap: _confirmApprove),
          ],
          if (_status == 'approved') _btn('إلغاء النشر', danger: true, onTap: () => _act(() => _service.unpublish(widget.id), ok: 'أُلغي النشر')),
          if (_questions.isNotEmpty) _btn('تصدير الأسئلة إلى كويز رسمي (مسودة)', onTap: () => _act(() => _service.exportQuiz(widget.id), ok: 'صُدّرت إلى كويز غير منشور. اضبط مواعيده ثم انشره')),
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('لتعديل نص الأسئلة والخيارات بالتفصيل استعمل لوحة الويب.', style: TextStyle(color: sub, fontSize: 11))),
        ]);
      },
    );
  }

  Widget _questionCard(int i, Map<String, dynamic> q, Color card, Color text, Color sub) {
    final options = (q['options'] as List).cast<String>();
    return Card(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${i + 1}. ${q['question']}', style: TextStyle(color: text, fontWeight: FontWeight.bold, height: 1.5))),
            if (_editable) IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)), onPressed: () => setState(() => _questions.removeAt(i))),
          ]),
          for (var o = 0; o < options.length; o++)
            Row(children: [
              Icon(o == q['correct_index'] ? Icons.check_circle : Icons.circle_outlined, size: 16, color: o == q['correct_index'] ? const Color(0xFF2E7D32) : sub),
              const SizedBox(width: 6),
              Expanded(child: Text(options[o], style: TextStyle(color: text, fontSize: 13))),
            ]),
        ]),
      ),
    );
  }

  Widget _btn(String label, {required VoidCallback onTap, bool filled = false, bool danger = false}) => Padding(
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
            onPressed: _busy ? null : onTap,
            child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
          ),
        ),
      );
}
