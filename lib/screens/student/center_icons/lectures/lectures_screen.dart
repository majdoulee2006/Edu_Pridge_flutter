import 'dart:io';
import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/student_speed_dial.dart';
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _allSubjects = [];

  static const List<Map<String, dynamic>> _subjectStyles = [
    {'icon': Icons.calculate_outlined,  'iconColor': Color(0xFFFBC02D), 'iconBgColor': Color(0xFFFFF9C4)},
    {'icon': Icons.science_outlined,    'iconColor': Color(0xFFF57C00), 'iconBgColor': Color(0xFFFFE0B2)},
    {'icon': Icons.computer_outlined,   'iconColor': Color(0xFF1976D2), 'iconBgColor': Color(0xFFBBDEFB)},
    {'icon': Icons.language_outlined,   'iconColor': Color(0xFFE53935), 'iconBgColor': Color(0xFFFFCDD2)},
    {'icon': Icons.menu_book_outlined,  'iconColor': Color(0xFF43A047), 'iconBgColor': Color(0xFFE8F5E9)},
    {'icon': Icons.history_edu_outlined,'iconColor': Color(0xFF7B1FA2), 'iconBgColor': Color(0xFFE1BEE7)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  Future<void> _fetchLectures() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await Dio().get(
        "${ApiService().baseUrl}/student/lectures",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _allSubjects = data.asMap().entries.map((entry) {
            final i = entry.key;
            final course = entry.value as Map<String, dynamic>;
            final style = _subjectStyles[i % _subjectStyles.length];
            final lessons = (course['lessons'] as List<dynamic>? ?? [])
                .map((l) => _mapLesson(l as Map<String, dynamic>))
                .toList();
            return {
              'title': course['course_name'] as String? ?? '',
              'subtitle':
                  '${course['teacher_name'] ?? ''} • ${course['total_files'] ?? 0} ملفات',
              'icon': style['icon'],
              'iconColor': style['iconColor'],
              'iconBgColor': style['iconBgColor'],
              'initiallyExpanded': i == 0,
              'files': lessons,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Lectures Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapLesson(Map<String, dynamic> lesson) {
    final type = lesson['type'] as String? ?? 'pdf';
    final title = lesson['title'] as String? ?? '';
    final date = lesson['date'] as String? ?? '';
    final fileSize = lesson['file_size'] as String?;
    final duration = lesson['duration'] as String?;
    String subtitle = date;
    if (fileSize != null && fileSize.isNotEmpty) {
      subtitle += ' • $fileSize';
    } else if (duration != null && duration.isNotEmpty) {
      subtitle += ' • $duration';
    }

    return switch (type) {
      'video' => {
        'title': title,
        'subtitle': subtitle,
        'type': 'video',
        'url': lesson['url'],
        'icon': Icons.play_arrow_rounded,
        'actionIcon': Icons.play_arrow_rounded,
        'color': const Color(0xFFFBC02D),
        'bgColor': const Color(0xFFFFF9C4),
      },
      'link' => {
        'title': title,
        'subtitle': subtitle,
        'type': 'link',
        'url': lesson['url'],
        'icon': Icons.link_rounded,
        'actionIcon': Icons.open_in_new_rounded,
        'color': const Color(0xFF4CAF50),
        'bgColor': const Color(0xFFE8F5E9),
      },
      _ => {
        'title': title,
        'subtitle': subtitle,
        'type': 'pdf',
        'url': lesson['url'],
        'icon': Icons.picture_as_pdf,
        'actionIcon': Icons.download_outlined,
        'color': Colors.red,
        'bgColor': const Color(0xFFFFEBEE),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF9F9F9);
    final textColor = isDark ? Colors.white : Colors.black;

    final filteredSubjects = _allSubjects.where((subject) {
      return (subject['title'] as String)
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'المحاضرات',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFCC00),
                          ),
                        )
                      : filteredSubjects.isEmpty
                          ? Center(
                              child: Text(
                                _allSubjects.isEmpty
                                    ? 'لا توجد محاضرات حالياً'
                                    : 'لا توجد مواد مطابقة لبحثك',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchLectures,
                              color: const Color(0xFFFFCC00),
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 10,
                                  bottom: 120,
                                ),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = filteredSubjects[index];
                                  return _SubjectCard(
                                    title: subject['title'],
                                    subtitle: subject['subtitle'],
                                    icon: subject['icon'],
                                    iconColor: subject['iconColor'],
                                    iconBgColor: subject['iconBgColor'],
                                    initiallyExpanded:
                                        subject['initiallyExpanded'],
                                    files: List<Map<String, dynamic>>.from(
                                        subject['files']),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white.withAlpha(20)) : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(40)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'ابحث عن مادة...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey.shade400 : Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

// ============================================================================
// كلاس خاص لكرت المادة
// ============================================================================
class _SubjectCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool initiallyExpanded;
  final List<Map<String, dynamic>> files;

  const _SubjectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.files,
    this.initiallyExpanded = false,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  late bool isExpanded;
  int selectedFilter = 0;
  final Map<String, bool> _downloading = {};
  final Map<String, bool> _downloaded = {};
  int selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
    _checkDownloadedFiles();
  }

  Widget _buildFilterChip(String label, int filterIndex, IconData? icon, bool isDark) {
    final isSelected = selectedFilter == filterIndex;
    final activeBgColor = isDark ? const Color(0xFFFFCC00).withAlpha(40) : const Color(0xFFFFCC00).withAlpha(30);
    final activeBorderColor = const Color(0xFFFFCC00);
    final inactiveBgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : inactiveBgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? activeBorderColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected 
                    ? const Color(0xFFFFCC00) 
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? (isDark ? Colors.white : const Color(0xFFE5A900)) 
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkDownloadedFiles() async {
    Directory? dir;
    try { dir = await getDownloadsDirectory(); } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    for (final file in widget.files) {
      final url = file['url'] as String? ?? '';
      if (url.isEmpty) continue;
      final fileName = Uri.parse(url).pathSegments.last;
      final exists = File('${dir.path}/$fileName').existsSync();
      if (exists && mounted) setState(() => _downloaded[url] = true);
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، لا يمكن فتح الرابط حالياً')),
        );
      }
    }
  }

  Future<String> _getSavePath(String url) async {
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(url).pathSegments.last;
    return '${dir.path}/$fileName';
  }

  Future<void> _download(String url) async {
    if (_downloading[url] == true) return;
    setState(() => _downloading[url] = true);
    try {
      // Fix URL for Android device (127.0.0.1 → localhost via ADB)
      final fixedUrl = ApiService.fixMediaUrl(url) ?? url;
      final savePath = await _getSavePath(url);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await Dio().download(
        fixedUrl,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() => _downloaded[url] = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التحميل بنجاح ✓ — محفوظ في مجلد التنزيلات'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('⛔ Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('فشل التحميل، تأكد من الاتصال'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading[url] = false);
    }
  }

  Future<void> _openFile(String url) async {
    try {
      final savePath = await _getSavePath(url);
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد تطبيق لفتح هذا النوع من الملفات')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الملف'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final filteredFiles = widget.files.where((file) {
      if (selectedFilter == 0) return true;
      if (selectedFilter == 1) return file['type'] == 'pdf';
      if (selectedFilter == 2) return file['type'] == 'video';
      return true;
    }).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDark
                        ? widget.iconBgColor.withAlpha(20)
                        : widget.iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                _buildFilterChip('الكل', 0, null, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('محاضرات', 1, Icons.picture_as_pdf, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('فيديو', 2, Icons.play_circle_fill, isDark),
              ],
            ),
            const SizedBox(height: 15),

            if (filteredFiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'لا توجد ملفات من هذا النوع',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Column(
                children: filteredFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Column(
                    children: [
                      _buildFileItem(
                        title: file['title'],
                        subtitle: file['subtitle'],
                        iconBgColor: isDark
                            ? (file['bgColor'] as Color).withAlpha(20)
                            : file['bgColor'],
                        iconColor: file['color'],
                        icon: file['icon'],
                        isDark: isDark,
                        url: file['url'] as String? ?? '',
                        type: file['type'] as String? ?? 'pdf',
                        isDownloading: _downloading[file['url'] as String? ?? ''] == true,
                        isDownloaded: _downloaded[file['url'] as String? ?? ''] == true,
                        onDownload: () => _download(file['url'] as String? ?? ''),
                        onOpen: () {
                          final url = file['url'] as String? ?? '';
                          final type = file['type'] as String? ?? 'pdf';
                          if (type == 'link' || type == 'video') {
                            _launchURL(url);
                          } else {
                            _openFile(url);
                          }
                        },
                      ),
                      if (index < filteredFiles.length - 1)
                        Divider(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          height: 1,
                        ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }


  Widget _buildFilterChip(String label, int index, IconData? icon, bool isDark) {
    final isSelected = selectedFilter == index;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.grey), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontSize: 12, fontFamily: 'Cairo')),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() => selectedFilter = index);
      },
      selectedColor: const Color(0xFFFFCC00),
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    );
  }

  Widget _buildFileItem({
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required bool isDark,
    required String url,
    required String type,
    required VoidCallback onDownload,
    required VoidCallback onOpen,
    bool isDownloading = false,
    bool isDownloaded = false,
  }) {
    final isFileType = type != 'link' && type != 'video';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          if (!isFileType)
            // رابط أو فيديو — زر فتح مباشر
            IconButton(
              icon: Icon(Icons.open_in_new_rounded,
                  color: isDark ? Colors.grey.shade400 : Colors.grey, size: 22),
              onPressed: onOpen,
              splashRadius: 24,
            )
          else if (isDownloading)
            const SizedBox(width: 40, height: 40,
                child: Center(child: SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFCC00)))))
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر تحميل
                IconButton(
                  icon: Icon(
                    isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                    color: isDownloaded ? Colors.green : (isDark ? Colors.grey.shade400 : Colors.grey),
                    size: 22,
                  ),
                  onPressed: isDownloaded ? null : onDownload,
                  splashRadius: 22,
                  tooltip: isDownloaded ? 'محمّل' : 'تحميل',
                ),
                // زر فتح (يظهر بعد التحميل)
                if (isDownloaded)
                  IconButton(
                    icon: const Icon(Icons.folder_open_rounded, color: Color(0xFFFFCC00), size: 22),
                    onPressed: onOpen,
                    splashRadius: 22,
                    tooltip: 'فتح',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
