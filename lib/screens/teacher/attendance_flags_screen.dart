import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/attendance_intel_services.dart';

/// طابور مراجعة اشتباهات الحضور للمعلّم. النظام يقترح والقرار للمعلّم:
/// لا يتغيّر حضور أي طالب إلا إذا اختار "سجّله غائبًا" عند التأكيد.
class AttendanceFlagsScreen extends StatefulWidget {
  const AttendanceFlagsScreen({super.key});

  @override
  State<AttendanceFlagsScreen> createState() => _AttendanceFlagsScreenState();
}

class _AttendanceFlagsScreenState extends State<AttendanceFlagsScreen> {
  final AttendanceIntelService _service = AttendanceIntelService();

  static const _tabs = {'open': 'مفتوحة', 'confirmed': 'مؤكَّدة', 'dismissed': 'مرفوضة', 'all': 'الكل'};

  String _status = 'open';
  bool _loading = true;
  bool _failed = false;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _items = [];

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
    final res = await _service.getFlags(status: _status);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _failed = true;
        return;
      }
      _summary = Map<String, dynamic>.from(res['summary'] ?? {});
      _items = ((res['data'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Color _sevColor(String? s) {
    switch (s) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF607D8B);
    }
  }

  Future<void> _review(Map<String, dynamic> flag, bool isDark) async {
    final noteCtrl = TextEditingController();
    bool markAbsent = false;

    final decision = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${flag['student']?['name'] ?? ''} — ${flag['rule_label']}',
                        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(flag['explanation']?.toString() ?? '', style: TextStyle(color: sub, height: 1.7, fontSize: 13)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      maxLength: 500,
                      style: TextStyle(color: text),
                      decoration: InputDecoration(
                        hintText: 'ملاحظة اختيارية',
                        hintStyle: TextStyle(color: sub),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: markAbsent,
                      onChanged: (v) => setSheet(() => markAbsent = v ?? false),
                      title: Text('عند التأكيد: سجّله غائبًا', style: TextStyle(color: text, fontSize: 13)),
                      subtitle: Text('يصله إشعار غياب ويُحتسب في الإنذارات', style: TextStyle(color: sub, fontSize: 11)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, 'dismissed'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('رفض: سلوك طبيعي'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, 'confirmed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('تأكيد الاشتباه'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (decision == null) return;
    final err = await _service.reviewFlag(
      (flag['id'] as num).toInt(),
      confirmed: decision == 'confirmed',
      note: noteCtrl.text,
      markAbsent: markAbsent,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'تم حفظ قرارك')));
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

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: card,
              elevation: 0,
              centerTitle: true,
              title: Text('اشتباهات الحضور', style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18)),
              leading: IconButton(icon: Icon(Icons.arrow_back, color: text), onPressed: () => Navigator.pop(context)),
            ),
            body: RefreshIndicator(onRefresh: _load, child: _body(card, text, sub, isDark)),
          ),
        );
      },
    );
  }

  Widget _body(Color card, Color text, Color sub, bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_failed) {
      return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off_rounded, size: 56, color: sub),
        const SizedBox(height: 12),
        Center(child: Text('تعذّر تحميل الاشتباهات', style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        Center(child: TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
      ]);
    }

    final bySev = Map<String, dynamic>.from(_summary['by_severity'] ?? {});

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'أنماط رُصدت تلقائيًا بعد إغلاق الجلسات. النظام يقترح فقط والقرار لك.',
          style: TextStyle(color: sub, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _stat('${_summary['open'] ?? 0}', 'مفتوحة', text, sub, card),
          _stat('${bySev['high'] ?? 0}', 'عالية', _sevColor('high'), sub, card),
          _stat('${bySev['medium'] ?? 0}', 'متوسطة', _sevColor('medium'), sub, card),
          _stat('${bySev['low'] ?? 0}', 'منخفضة', _sevColor('low'), sub, card),
        ]),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tabs.entries
                .map((e) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _status == e.key,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _status == e.key ? Colors.white : text),
                        onSelected: (_) {
                          if (_status == e.key) return;
                          setState(() => _status = e.key);
                          _load();
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              Icon(Icons.verified_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text('لا توجد اشتباهات في هذه القائمة', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('تظهر الحالات بعد إغلاق كل جلسة إذا رُصد نمط مشبوه', style: TextStyle(color: sub, fontSize: 12)),
            ]),
          )
        else
          ..._items.map((f) => _flagCard(f, card, text, sub, isDark)),
      ],
    );
  }

  Widget _stat(String value, String label, Color valueColor, Color sub, Color card) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: sub, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _flagCard(Map<String, dynamic> f, Color card, Color text, Color sub, bool isDark) {
    final sev = _sevColor(f['severity']?.toString());
    final isOpen = f['status'] == 'open';
    final review = f['review'] as Map?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: sev, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['student']?['name']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${f['course']?['title'] ?? ''}  •  ${f['attendance']?['date'] ?? ''}',
                    style: TextStyle(color: sub, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sev.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(f['severity_label']?.toString() ?? '', style: TextStyle(color: sev, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(f['rule_label']?.toString() ?? '', style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(f['explanation']?.toString() ?? '', style: TextStyle(color: sub, height: 1.7, fontSize: 12.5)),
          const SizedBox(height: 10),
          if (isOpen)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _review(f, isDark),
                icon: const Icon(Icons.fact_check_rounded, size: 18),
                label: const Text('مراجعة هذا الاشتباه'),
              ),
            )
          else
            Text(
              '${f['status'] == 'confirmed' ? 'تم التأكيد' : 'تم الرفض'}'
              '${review?['marked_absent'] == true ? ' — سُجّل غائبًا' : ''}'
              '${(review?['note'] ?? '').toString().isNotEmpty ? ' — «${review?['note']}»' : ''}',
              style: TextStyle(color: sub, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
