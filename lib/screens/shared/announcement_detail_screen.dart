import 'package:flutter/material.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;
  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
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
    final imageUrl    = widget.announcement['image_url']   as String? ?? '';
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
          title: Text('تفاصيل الإعلان',
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, _) => const SizedBox(),
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
