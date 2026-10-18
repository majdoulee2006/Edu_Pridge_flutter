import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/at_risk_student_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/risk_services.dart';

/// ألوان وتسميات مستويات الخطر، مشتركة بين شاشتي القائمة والتفاصيل.
Color riskColor(String? level) {
  switch (level) {
    case 'high':
      return const Color(0xFFC62828);
    case 'medium':
      return const Color(0xFFE65100);
    case 'low':
      return const Color(0xFF2E7D32);
    default:
      return const Color(0xFF78909C);
  }
}

/// الطلاب المعرَّضون للتعثر: للمرشد (basePath = teacher) ولرئيس القسم (basePath = department-head).
/// درجة الخطر أداة لترتيب أولويات المتابعة وليست حكمًا على الطالب.
class AtRiskStudentsScreen extends StatefulWidget {
  final String basePath;

  /// فتح القائمة مفلترة مباشرة (من مربعات لوحة المتابعة): مستوى، أو المتابعات المتأخرة، أو ترتيب.
  final String? initialLevel;
  final String? initialFollowUp;
  final String? initialSort;

  const AtRiskStudentsScreen({super.key, required this.basePath, this.initialLevel, this.initialFollowUp, this.initialSort});

  @override
  State<AtRiskStudentsScreen> createState() => _AtRiskStudentsScreenState();
}

class _AtRiskStudentsScreenState extends State<AtRiskStudentsScreen> {
  final RiskService _service = RiskService();
  final TextEditingController _search = TextEditingController();

  static const _tabs = {
    '': 'الكل',
    'at_risk': 'معرَّض',
    'high': 'عالٍ',
    'medium': 'متوسط',
    'low': 'منخفض',
    'unknown': 'غير كافية',
    'overdue': 'متابعة متأخرة',
  };

  late String _level = widget.initialLevel ?? 'at_risk';
  late String _followUp = widget.initialFollowUp ?? '';
  late final String _sort = widget.initialSort ?? 'score';
  bool _loading = true;
  bool _failed = false;
  String? _forbidden;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _rows = [];

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
    final res = await _service.list(widget.basePath, level: _level, search: _search.text, sort: _sort, followUp: _followUp);
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
      _summary = Map<String, dynamic>.from(res['summary'] ?? {});
      _rows = ((res['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
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
              title: Text('المعرَّضون للتعثر', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18)),
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

    if (_forbidden != null) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        const SizedBox(height: 120),
        Icon(Icons.lock_outline_rounded, size: 56, color: sub),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(_forbidden!, textAlign: TextAlign.center, style: TextStyle(color: text, fontWeight: FontWeight.bold, height: 1.6)),
        ),
      ]);
    }

    if (_failed) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off_rounded, size: 56, color: sub),
        const SizedBox(height: 12),
        Center(child: Text('تعذّر تحميل القائمة', style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        Center(child: TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
      ]);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text('درجة خطر لكل طالب من الحضور والواجبات والعلامات والنشاط، مع أسبابها. أداة لترتيب أولوياتك وليست حكمًا على الطالب.',
            style: TextStyle(color: sub, fontSize: 12, height: 1.6)),
        const SizedBox(height: 12),
        if (_search.text.trim().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE65100).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.filter_alt_rounded, size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('عرض مفلتر، الأرقام لجزء من طلابك • بحث: «${_search.text.trim()}»',
                    style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w700, fontSize: 12, height: 1.4)),
              ),
              TextButton(
                onPressed: () {
                  _search.clear();
                  _load();
                },
                child: const Text('إزالة ✕', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        // كل مربع يفلتر القائمة تحته (نفس سلوك الويب)
        Row(children: [
          _stat('${_summary['high'] ?? 0}', 'عالٍ', riskColor('high'), sub, card, active: _isActive('high'), onTap: () => _pick('high')),
          _stat('${_summary['medium'] ?? 0}', 'متوسط', riskColor('medium'), sub, card, active: _isActive('medium'), onTap: () => _pick('medium')),
          _stat('${_summary['low'] ?? 0}', 'منخفض', riskColor('low'), sub, card, active: _isActive('low'), onTap: () => _pick('low')),
          _stat('${_summary['unknown'] ?? 0}', 'غير كافية', riskColor('unknown'), sub, card, active: _isActive('unknown'), onTap: () => _pick('unknown')),
          _stat('${_summary['overdue'] ?? 0}', 'متابعة متأخرة', const Color(0xFFE65100), sub, card, active: _isActive('overdue'), onTap: () => _pick('overdue')),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          style: TextStyle(color: text),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            hintText: 'بحث بالاسم أو الرقم',
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
            children: _tabs.entries
                .map((e) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _isActive(e.key),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _isActive(e.key) ? Colors.white : text),
                        onSelected: (_) => _pick(e.key),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(children: [
              Icon(Icons.verified_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text('لا طلاب في هذه القائمة', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('تُحسب الدرجات ليلًا', style: TextStyle(color: sub, fontSize: 12)),
            ]),
          )
        else
          ..._rows.map((r) => _card(r, card, text, sub)),
      ],
    );
  }

  /// هل هذا المربع/الشريحة هو الفلتر الحالي؟ ('overdue' فلتر مستقل عن المستوى)
  bool _isActive(String key) => key == 'overdue' ? _followUp == 'overdue' : (_followUp.isEmpty && _level == key);

  void _pick(String key) {
    if (_isActive(key)) return;
    setState(() {
      _followUp = key == 'overdue' ? 'overdue' : '';
      _level = key == 'overdue' ? '' : key;
    });
    _load();
  }

  Widget _stat(String value, String label, Color color, Color sub, Color card, {required VoidCallback onTap, bool active = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? color : Colors.transparent, width: 1.6),
          ),
          child: Column(children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 10, height: 1.2)),
          ]),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> r, Color card, Color text, Color sub) {
    final level = r['level']?.toString() ?? 'unknown';
    final color = riskColor(level);
    final score = (r['score'] as num?)?.toDouble();
    final change = (r['change'] as num?)?.toDouble();
    final reasons = ((r['reasons'] as List?) ?? []).map((e) => e.toString()).toList();
    final student = Map<String, dynamic>.from(r['student'] as Map);
    final last = r['last_intervention'] as Map?;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AtRiskStudentDetailScreen(basePath: widget.basePath, studentId: (student['id'] as num).toInt())),
        );
        if (mounted) _load(); // قد تتغير المتابعة داخل التفاصيل
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border(right: BorderSide(color: color, width: 5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${student['program'] ?? ''} • ${student['year'] ?? ''}', style: TextStyle(color: sub, fontSize: 11.5)),
                ]),
              ),
              if (score != null && level != 'unknown')
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(_fmt(score), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(r['level_label']?.toString() ?? '', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
            if (score != null && level != 'unknown') ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...reasons.map((x) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('• ', style: TextStyle(color: sub)),
                      Expanded(child: Text(x, style: TextStyle(color: text, fontSize: 12.5, height: 1.5))),
                    ]),
                  )),
            ],
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              if (change != null && change.abs() >= 1)
                Text('${change > 0 ? '▲' : '▼'} ${_fmt(change.abs())} عن آخر حساب',
                    style: TextStyle(color: change > 0 ? riskColor('high') : riskColor('low'), fontSize: 11, fontWeight: FontWeight.bold)),
              if (last != null)
                Text('آخر إجراء: ${last['type_label']}', style: TextStyle(color: sub, fontSize: 11))
              else if (level == 'high' || level == 'medium')
                Text('لم تُسجَّل متابعة بعد', style: TextStyle(color: sub, fontSize: 11)),
              if (r['follow_up_due'] == true)
                Text('موعد المتابعة حلّ', style: TextStyle(color: riskColor('medium'), fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  String _fmt(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
}
