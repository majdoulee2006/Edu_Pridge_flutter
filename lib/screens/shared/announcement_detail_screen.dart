import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/widgets/facebook_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final String? screenTitle;
  const AnnouncementDetailScreen({super.key, required this.announcement, this.screenTitle});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      final relatedIdStr = widget.announcement['announcement_id']?.toString() 
                        ?? widget.announcement['id']?.toString();
      final relatedId = int.tryParse(relatedIdStr ?? '');

      // Assuming most announcements here fall under 'announcement' or 'administrative'
      final type = widget.announcement['type']?.toString() ?? 'announcement';

      await Dio().put(
        '${ApiService().baseUrl}/notifications/read-by-type',
        data: {
          'type': type,
          if (relatedId != null) 'related_id': relatedId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('⛔ Mark announcement read error: $e');
    }
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
    final rawAuthor   = widget.announcement['author_name'] as String?
                     ?? widget.announcement['publisher_name'] as String?
                     ?? widget.announcement['publisher']   as String?
                     ?? widget.announcement['created_by']   as String? ?? 'الإدارة';
    final author      = rawAuthor.startsWith('نشر') ? rawAuthor : 'نشر بواسطة: $rawAuthor';
    final timeAgo     = widget.announcement['time_ago']    as String?
                     ?? widget.announcement['created_at']  as String? ?? '';
    final linkUrl     = widget.announcement['link_url']    as String? ?? '';
    final targetLabel = _targetLabel(widget.announcement);

    List<String> imageUrls = [];
    if (widget.announcement['image_urls'] != null && widget.announcement['image_urls'] is List) {
      imageUrls = (widget.announcement['image_urls'] as List)
          .map((url) => ApiService.fixMediaUrl(url.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (imageUrls.isEmpty && widget.announcement['image_url'] != null) {
      final single = ApiService.fixMediaUrl(widget.announcement['image_url'].toString());
      if (single != null && single.isNotEmpty) {
        imageUrls.add(single);
      }
    }

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
            icon: Icon(Icons.arrow_back,
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

              // الصور (شبكة متعددة الصور)
              if (imageUrls.isNotEmpty) ...[
                FacebookImageGrid(imageUrls: imageUrls, maxHeight: 350),
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

  String _targetLabel(Map<String, dynamic> data) {
    final String target = data['target_audience']?.toString() ?? 'all';
    final String? dept = data['department_name']?.toString() ?? data['department']?.toString();
    final String? course = data['course_name']?.toString() ?? data['course']?.toString();

    String label = switch (target) {
      'students' => 'الطلاب',
      'teachers' => 'المعلمون',
      'heads'    => 'رؤساء الأقسام',
      _          => 'الجميع',
    };

    List<String> details = [];
    if (dept != null && dept.isNotEmpty) details.add('قسم: $dept');
    if (course != null && course.isNotEmpty) details.add('دورة: $course');

    if (details.isNotEmpty) {
      label += ' (${details.join(" | ")})';
    }
    return label;
  }
}

