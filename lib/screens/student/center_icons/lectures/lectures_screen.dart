import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // مكتبة فتح الروابط
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar (تأكدي منها حسب مشروعك)
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
  // متغير لحفظ نص البحث
  String _searchQuery = '';

  // بيانات تجريبية للمواد مع ملفاتها
  final List<Map<String, dynamic>> _allSubjects = [
    {
      'title': 'الرياضيات المتقدمة',
      'subtitle': 'د. أحمد علي • 3 ملفات',
      'icon': Icons.calculate_outlined,
      'iconColor': const Color(0xFFFBC02D),
      'iconBgColor': const Color(0xFFFFF9C4),
      'initiallyExpanded': true,
      'files': [
        {
          'title': 'المحاضرة 4: التكامل',
          'subtitle': '12 أكتوبر • 2.5 MB',
          'type': 'pdf',
          'icon': Icons.picture_as_pdf,
          'actionIcon': Icons.download_outlined,
          'color': Colors.red,
          'bgColor': const Color(0xFFFFEBEE),
        },
        {
          'title': 'شرح الدوال المثلثية',
          'subtitle': '10 أكتوبر • 45 دقيقة',
          'type': 'video',
          'icon': Icons.play_arrow_rounded,
          'actionIcon': Icons.play_arrow_rounded,
          'color': const Color(0xFFFBC02D),
          'bgColor': const Color(0xFFFFF9C4),
        },
        // 🌟 ملف الرابط الخارجي 🌟
        {
          'title': 'مصادر خارجية للمراجعة',
          'subtitle': 'رابط ويب',
          'type': 'link',
          'url': 'https://www.google.com',
          'icon': Icons.link_rounded,
          'actionIcon': Icons.open_in_new_rounded,
          'color': const Color(0xFF4CAF50),
          'bgColor': const Color(0xFFE8F5E9),
        },
      ],
    },
    {
      'title': 'الفيزياء العامة',
      'subtitle': 'أ. سارة محمد • 2 ملفات',
      'icon': Icons.science_outlined,
      'iconColor': const Color(0xFFF57C00),
      'iconBgColor': const Color(0xFFFFE0B2),
      'initiallyExpanded': false,
      'files': [
        {
          'title': 'قوانين نيوتن للحركة',
          'subtitle': '15 أكتوبر • 3.1 MB',
          'type': 'pdf',
          'icon': Icons.picture_as_pdf,
          'actionIcon': Icons.download_outlined,
          'color': Colors.red,
          'bgColor': const Color(0xFFFFEBEE),
        },
        {
          'title': 'تجربة السقوط الحر',
          'subtitle': '14 أكتوبر • 20 دقيقة',
          'type': 'video',
          'icon': Icons.play_arrow_rounded,
          'actionIcon': Icons.play_arrow_rounded,
          'color': const Color(0xFFFBC02D),
          'bgColor': const Color(0xFFFFF9C4),
        },
      ],
    },
    {
      'title': 'علوم الحاسوب',
      'subtitle': 'م. خالد يوسف • 2 ملفات',
      'icon': Icons.computer_outlined,
      'iconColor': const Color(0xFF1976D2),
      'iconBgColor': const Color(0xFFBBDEFB),
      'initiallyExpanded': false,
      'files': [
        {
          'title': 'مقدمة في الخوارزميات',
          'subtitle': '18 أكتوبر • 1.5 MB',
          'type': 'pdf',
          'icon': Icons.picture_as_pdf,
          'actionIcon': Icons.download_outlined,
          'color': Colors.red,
          'bgColor': const Color(0xFFFFEBEE),
        },
        {
          'title': 'شرح لغة Dart',
          'subtitle': '17 أكتوبر • 55 دقيقة',
          'type': 'video',
          'icon': Icons.play_arrow_rounded,
          'actionIcon': Icons.play_arrow_rounded,
          'color': const Color(0xFFFBC02D),
          'bgColor': const Color(0xFFFFF9C4),
        },
      ],
    },
    {
      'title': 'اللغة الإنجليزية',
      'subtitle': 'د. ليلى حسن • 2 ملفات',
      'icon': Icons.language_outlined,
      'iconColor': const Color(0xFFE53935),
      'iconBgColor': const Color(0xFFFFCDD2),
      'initiallyExpanded': false,
      'files': [
        {
          'title': 'Grammar Rules: Tenses',
          'subtitle': '20 أكتوبر • 2 MB',
          'type': 'pdf',
          'icon': Icons.picture_as_pdf,
          'actionIcon': Icons.download_outlined,
          'color': Colors.red,
          'bgColor': const Color(0xFFFFEBEE),
        },
        {
          'title': 'Conversation Practice',
          'subtitle': '19 أكتوبر • 30 دقيقة',
          'type': 'video',
          'icon': Icons.play_arrow_rounded,
          'actionIcon': Icons.play_arrow_rounded,
          'color': const Color(0xFFFBC02D),
          'bgColor': const Color(0xFFFFF9C4),
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // منطق البحث
    List<Map<String, dynamic>> filteredSubjects = _allSubjects.where((subject) {
      return subject['title'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'المحاضرات',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
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
                  child: filteredSubjects.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد مواد مطابقة لبحثك',
                            style: TextStyle(color: Colors.grey),
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

            Align(
              alignment: Alignment.bottomCenter,
              child: _buildFloatingBottomNavBar(context),
            ),
            const Positioned.fill(child: StudentSpeedDial()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن مادة...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            'الرئيسية',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ),
            ),
          ),
          _buildNavItem(
            Icons.person_outline,
            'حسابي',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
          const SizedBox(width: 70),
          _buildNavItem(
            Icons.notifications_none,
            'إشعارات',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          _buildNavItem(
            Icons.mail_outline,
            'مراسلات',
            false,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ],
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

  // 🌟 دالة لفتح الروابط الخارجية (جوجل وغيرها) 🌟
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
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
                    color: widget.iconBgColor,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
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
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                _buildFilterChip('الكل', 0, null),
                const SizedBox(width: 8),
                _buildFilterChip('محاضرات', 1, Icons.picture_as_pdf),
                const SizedBox(width: 8),
                _buildFilterChip('فيديو', 2, Icons.play_circle_fill),
              ],
            ),
            const SizedBox(height: 15),

            if (filteredFiles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'لا توجد ملفات من هذا النوع',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
                        iconBgColor: file['bgColor'],
                        iconColor: file['color'],
                        icon: file['icon'],
                        actionIcon: file['actionIcon'],
                        // 🌟 تفعيل الضغط على الأيقونة اللي ع اليسار 🌟
                        onActionTap: () {
                          if (file['type'] == 'link') {
                            _launchURL(file['url']); // فتح الرابط في متصفح جوجل
                          } else {
                            // رسالة وهمية للملفات الأخرى (تحميل أو تشغيل)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('جاري فتح ${file['title']}...'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        },
                      ),
                      if (index < filteredFiles.length - 1)
                        Divider(color: Colors.grey.shade100, height: 1),
                    ],
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, IconData? icon) {
    bool isSelected = selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFF00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ تم تحديث الدالة لتدعم خاصية الضغط على أيقونة الإجراء (actionIcon)
  Widget _buildFileItem({
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required IconData actionIcon,
    required VoidCallback onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 5,
      ), // تقليل البادينغ شوي ليتناسب مع الزر
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          // 🌟 زر الإجراء (التحميل، التشغيل، أو فتح الرابط) 🌟
          IconButton(
            icon: Icon(actionIcon, color: Colors.grey, size: 22),
            onPressed: onActionTap, // استدعاء الدالة عند الضغط
            splashRadius: 24, // تأثير الموجة عند الضغط
          ),
        ],
      ),
    );
  }
}
