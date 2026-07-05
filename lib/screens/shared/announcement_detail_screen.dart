import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final String? screenTitle;
  const AnnouncementDetailScreen({super.key, required this.announcement, this.screenTitle});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  bool _isSavingImage = false;

  Future<void> _saveImage(String imageUrl) async {
    if (_isSavingImage) return;
    setState(() => _isSavingImage = true);
    try {
      final dir      = await getTemporaryDirectory();
      final fileName = 'announcement_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${dir.path}/$fileName';

      await Dio().download(imageUrl, filePath);

      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();

      await Gal.putImage(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الصورة في المعرض ✓'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Save image error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر حفظ الصورة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  void _openFullScreen(String imageUrl) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FullScreenImageViewer(
        imageUrl: imageUrl,
        onSave: () => _saveImage(imageUrl),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    final title       = widget.announcement['title']       as String? ?? '';
    final content     = widget.announcement['content']     as String?
                     ?? widget.announcement['body']        as String? ?? '';
    final author      = widget.announcement['author_name'] as String?
                     ?? widget.announcement['publisher']   as String? ?? 'الإدارة';
    final timeAgo     = widget.announcement['time_ago']    as String?
                     ?? widget.announcement['created_at']  as String? ?? '';
    final imageUrl    = ApiService.fixMediaUrl(widget.announcement['image_url'] as String?) ?? '';
    final linkUrl     = widget.announcement['link_url']    as String? ?? '';
    final targetLabel = _targetLabel(widget.announcement['target_audience'] as String?);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(widget.screenTitle ?? 'تفاصيل الإعلان',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.4)),
              const SizedBox(height: 12),

              // الناشر
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                          color: Color(0x1ACCAA00), shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline_rounded,
                          color: Color(0xFFCCAA00), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          Text(timeAgo,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (targetLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0xFFCCAA00)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(targetLabel,
                            style: const TextStyle(
                                color: Color(0xFFCCAA00),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // الصورة
              if (imageUrl.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _openFullScreen(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, s) => const SizedBox(),
                          ),
                        ),
                        Positioned(
                          bottom: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // المحتوى
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(content,
                    style: TextStyle(
                        fontSize: 15, height: 1.7, color: textColor)),
              ),
              const SizedBox(height: 12),

              // رابط
              if (linkUrl.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(linkUrl,
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

            ],
          ),
        ),
      ),
    );
  }

  String _targetLabel(String? target) {
    switch (target) {
      case 'students': return 'طلاب فقط';
      case 'teachers': return 'معلمون فقط';
      case 'all':      return 'الجميع';
      default:         return '';
    }
  }
}

// ─── Full Screen Image Viewer ──────────────────────────────────────────────

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onSave;
  const _FullScreenImageViewer({required this.imageUrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'حفظ / مشاركة',
            onPressed: onSave,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, e, s) => const Icon(Icons.broken_image, color: Colors.white54, size: 80),
          ),
        ),
      ),
    );
  }
}
