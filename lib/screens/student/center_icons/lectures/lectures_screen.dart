import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/student_speed_dial.dart';

// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

// 🌟 استدعاء ملف الخدمات
import 'package:edu_pridge_flutter/services/student_services.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _allSubjects = [];

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  // ============================================================================
  // 🌟 دالة جلب المحاضرات (مع الذكاء بقراءة نوع الملف من الرابط)
  // ============================================================================
  Future<void> _fetchLectures() async {
    setState(() => _isLoading = true);

    try {
      final data = await StudentServices().getLectures();

      if (data != null) {
        setState(() {
          _allSubjects = data.map<Map<String, dynamic>>((course) {
            return {
              'title': course['course_name'],
              'subtitle':
                  '${course['teacher_name']} • ${course['total_files']} ملفات',
              'icon': Icons.menu_book_outlined,
              'iconColor': const Color(0xFF1976D2),
              'iconBgColor': const Color(0xFFBBDEFB),
              'initiallyExpanded': false,
              'files': (course['lessons'] as List).map<Map<String, dynamic>>((
                lesson,
              ) {
                // 🌟 السحر هون: نقرأ الرابط الصحيح من الداتا بيز
                String fileUrl = lesson['content_url'] ?? lesson['url'] ?? '';

                // القيم الافتراضية (PDF)
                String type = 'pdf';
                IconData icon = Icons.picture_as_pdf;
                IconData actionIcon = Icons.download_outlined;
                Color color = Colors.red;
                Color bgColor = const Color(0xFFFFEBEE);

                // 🌟 تحديد النوع ذكياً بناءً على الرابط
                if (fileUrl.endsWith('.mp4')) {
                  type = 'video';
                  icon = Icons.play_arrow_rounded;
                  actionIcon = Icons.play_arrow_rounded;
                  color = const Color(0xFFFBC02D);
                  bgColor = const Color(0xFFFFF9C4);
                } else if (fileUrl.startsWith('http') &&
                    !fileUrl.endsWith('.pdf')) {
                  type = 'link';
                  icon = Icons.link_rounded;
                  actionIcon = Icons.open_in_new_rounded;
                  color = const Color(0xFF4CAF50);
                  bgColor = const Color(0xFFE8F5E9);
                }

                // تجهيز النص الفرعي (التاريخ والحجم والمدة)
                String subtitleStr = lesson['date'] ?? '';
                if (lesson['file_size'] != null) {
                  subtitleStr += ' • ${lesson['file_size']}';
                }
                if (lesson['duration'] != null) {
                  subtitleStr += ' • ${lesson['duration']}';
                }

                return {
                  'title': lesson['title'],
                  'subtitle': subtitleStr,
                  'type': type,
                  'url': fileUrl.isNotEmpty
                      ? fileUrl
                      : null, // 🌟 نمرر الرابط هنا
                  'icon': icon,
                  'actionIcon': actionIcon,
                  'color': color,
                  'bgColor': bgColor,
                };
              }).toList(),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error Fetching Lectures: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF9F9F9);
    final textColor = isDark ? Colors.white : Colors.black;

    List<Map<String, dynamic>> filteredSubjects = _allSubjects.where((subject) {
      return subject['title'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
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
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
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
                          child: CircularProgressIndicator(color: Colors.amber),
                        )
                      : filteredSubjects.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد مواد مطابقة لبحثك',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
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
                              initiallyExpanded: subject['initiallyExpanded'],
                              files: subject['files'],
                            );
                          },
                        ),
                ),
              ],
            ),
            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
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

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    List<Map<String, dynamic>> filteredFiles = widget.files.where((file) {
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
                          color: isDark ? Colors.grey.shade400 : Colors.grey,
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
                  int index = entry.key;
                  var file = entry.value;
                  return Column(
                    children: [
                      _buildFileItem(
                        title: file['title'],
                        subtitle: file['subtitle'],
                        iconBgColor: isDark
                            ? file['bgColor'].withAlpha(20)
                            : file['bgColor'],
                        iconColor: file['color'],
                        icon: file['icon'],
                        actionIcon: file['actionIcon'],
                        isDark: isDark,
                        onActionTap: () {
                          if (file['url'] != null) {
                            _launchURL(file['url']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('عذراً، لا يوجد رابط لهذا الملف'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
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

  Widget _buildFilterChip(
    String label,
    int index,
    IconData? icon,
    bool isDark,
  ) {
    bool isSelected = selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFFF00)
              : (isDark
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.grey.shade200,
                ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.black87
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem({
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required IconData actionIcon,
    required VoidCallback onActionTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              actionIcon,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
              size: 22,
            ),
            onPressed: onActionTap,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}
