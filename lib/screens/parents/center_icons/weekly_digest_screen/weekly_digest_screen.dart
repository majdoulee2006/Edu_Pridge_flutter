import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/parent_services.dart';

/// الملخص الأسبوعي لولي الأمر: قائمة بملخصات الأسابيع السابقة لكل ابن،
/// مع إمكانية إيقاف الملخص من الأعلى. النص نفسه يُبنى في السيرفر من حقائق محسوبة.
class WeeklyDigestScreen extends StatefulWidget {
  /// عند فتح الشاشة من إشعار: يُفتح هذا الملخص مباشرة بعد التحميل
  final int? openDigestId;

  const WeeklyDigestScreen({super.key, this.openDigestId});

  @override
  State<WeeklyDigestScreen> createState() => _WeeklyDigestScreenState();
}

class _WeeklyDigestScreenState extends State<WeeklyDigestScreen> {
  final ParentService _service = ParentService();

  bool _loading = true;
  bool _failed = false;
  bool? _enabled;
  int _unread = 0;
  bool _deepLinkHandled = false;
  List<Map<String, dynamic>> _digests = [];

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

    final results = await Future.wait([
      _service.getDigests(),
      _service.getDigestEnabled(),
    ]);
    final res = results[0] as Map<String, dynamic>?;

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _failed = true;
        return;
      }
      _unread = (res['unread_count'] as num?)?.toInt() ?? 0;
      _digests = ((res['data'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _enabled = results[1] as bool?;
    });

    final target = widget.openDigestId;
    if (target != null && !_deepLinkHandled) {
      _deepLinkHandled = true;
      final match = _digests.where((d) => (d['id'] as num).toInt() == target);
      if (match.isNotEmpty && mounted) {
        final isDark = AppSettings.isDarkMode.value;
        _open(match.first, isDark);
      }
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> digest) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('جارٍ تجهيز ملف PDF...')));

    final id = (digest['id'] as num).toInt();
    final path = await _service.downloadDigestPdf(
      id,
      fileName: 'weekly_digest_${digest['week_start']}_$id.pdf',
    );

    messenger.hideCurrentSnackBar();
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذّر تنزيل الملف، حاول مرة أخرى')),
      );
      return;
    }
    await OpenFilex.open(path);
  }

  Future<void> _toggle(bool value) async {
    final previous = _enabled;
    setState(() => _enabled = value);
    final ok = await _service.setDigestEnabled(value);
    if (!mounted) return;
    if (!ok) {
      setState(() => _enabled = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحديث الإعداد، حاول مرة أخرى')),
      );
    }
  }

  Future<void> _open(Map<String, dynamic> digest, bool isDark) async {
    final wasUnread = digest['is_read'] != true;
    if (wasUnread) {
      setState(() {
        digest['is_read'] = true;
        if (_unread > 0) _unread--;
      });
      _service.markDigestRead((digest['id'] as num).toInt());
    }

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DigestSheet(
        digest: digest,
        isDark: isDark,
        onDownload: () => _downloadPdf(digest),
      ),
    );
  }

  Color _toneColor(String? tone) {
    switch (tone) {
      case 'concern':
        return AppColors.error;
      case 'attention':
        return const Color(0xFFF9A825);
      default:
        return AppColors.primary;
    }
  }

  IconData _toneIcon(String? tone) {
    switch (tone) {
      case 'concern':
        return Icons.priority_high_rounded;
      case 'attention':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _weekLabel(Map<String, dynamic> d) =>
      '${d['week_start']}  ←  ${d['week_end']}';

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
              title: Text(
                'الملخص الأسبوعي',
                style: TextStyle(
                    color: text, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: text),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(card, text, sub, isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(Color card, Color text, Color sub, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failed) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off_rounded, size: 56, color: sub),
          const SizedBox(height: 12),
          Center(
            child: Text('تعذّر تحميل الملخصات',
                style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
                onPressed: _load, child: const Text('إعادة المحاولة')),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: Text('استلام الملخص كل أسبوع',
                style: TextStyle(color: text, fontWeight: FontWeight.w600)),
            subtitle: Text(
              'يصلك مساء الخميس عن حضور أبنائك وواجباتهم وعلاماتهم',
              style: TextStyle(color: sub, fontSize: 12),
            ),
            value: _enabled ?? true,
            onChanged: _enabled == null ? null : _toggle,
          ),
        ),
        const SizedBox(height: 16),
        if (_digests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: [
                Icon(Icons.insights_rounded, size: 56, color: sub),
                const SizedBox(height: 12),
                Text('لا توجد ملخصات بعد',
                    style:
                        TextStyle(color: text, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('سيظهر أول ملخص بنهاية أسبوع دراسي فيه نشاط',
                    style: TextStyle(color: sub, fontSize: 12)),
              ],
            ),
          )
        else ...[
          if (_unread > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 4),
              child: Text('$_unread غير مقروء',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          ..._digests.map((d) => _digestCard(d, card, text, sub, isDark)),
        ],
      ],
    );
  }

  Widget _digestCard(
      Map<String, dynamic> d, Color card, Color text, Color sub, bool isDark) {
    final color = _toneColor(d['tone'] as String?);
    final unread = d['is_read'] != true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(d, isDark),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: unread ? color.withValues(alpha: 0.6) : Colors.transparent,
                width: 1.4),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(_toneIcon(d['tone'] as String?), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['title']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_weekLabel(d),
                        style: TextStyle(color: sub, fontSize: 12)),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              IconButton(
                tooltip: 'تنزيل PDF',
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent),
                onPressed: () => _downloadPdf(d),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DigestSheet extends StatelessWidget {
  final Map<String, dynamic> digest;
  final bool isDark;
  final VoidCallback onDownload;

  const _DigestSheet({
    required this.digest,
    required this.isDark,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : AppColors.textDark;
    final sub = isDark ? Colors.grey.shade400 : AppColors.textGrey;
    final isAi = digest['source'] == 'ai';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sub.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                digest['title']?.toString() ?? '',
                style: TextStyle(
                    color: text, fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 14),
              SelectableText(
                digest['body']?.toString() ?? '',
                style: TextStyle(color: text, height: 1.8, fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('تنزيل الملخص PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (isAi) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: sub),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'صيغ النص بمساعدة الذكاء الاصطناعي من أرقام حقيقية محسوبة في النظام',
                        style: TextStyle(color: sub, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
