import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar (تأكدي منها حسب مشروعك)
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9), // لون الخلفية الفاتح
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('المحاضرات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // الكرت الأول (مفتوح افتراضياً)
                      _SubjectCard(
                        title: 'الرياضيات المتقدمة',
                        subtitle: 'د. أحمد علي • 12 ملف',
                        icon: Icons.calculate_outlined,
                        iconColor: const Color(0xFFFBC02D),
                        iconBgColor: const Color(0xFFFFF9C4),
                        initiallyExpanded: true,
                      ),
                      // الكروت المغلقة
                      const _SubjectCard(
                        title: 'الفيزياء العامة',
                        subtitle: 'أ. سارة محمد • 8 ملفات',
                        icon: Icons.science_outlined,
                        iconColor: Color(0xFFF57C00),
                        iconBgColor: Color(0xFFFFE0B2),
                      ),
                      const _SubjectCard(
                        title: 'علوم الحاسوب',
                        subtitle: 'م. خالد يوسف • 15 ملف',
                        icon: Icons.computer_outlined,
                        iconColor: Color(0xFF1976D2),
                        iconBgColor: Color(0xFFBBDEFB),
                      ),
                      const _SubjectCard(
                        title: 'اللغة الإنجليزية',
                        subtitle: 'د. ليلى حسن • 5 ملفات',
                        icon: Icons.language_outlined,
                        iconColor: Color(0xFFE53935),
                        iconBgColor: Color(0xFFFFCDD2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // الشريط السفلي والزر الأصفر المنبثق
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildFloatingBottomNavBar(context),
            ),
            const Positioned.fill(
              child: StudentSpeedDial(),
            ),
          ],
        ),
      ),
    );
  }

  // 1. شريط البحث
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث عن مادة أو ملف...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // 2. الشريط السفلي الموحد
  Widget _buildFloatingBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'الرئيسية', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()))),
          _buildNavItem(Icons.person_outline, 'حسابي', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          const SizedBox(width: 70), // مساحة للزر المنبثق
          _buildNavItem(Icons.notifications_none, 'إشعارات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
          _buildNavItem(Icons.mail_outline, 'مراسلات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.black : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey)),
        ],
      ),
    );
  }
}

// ============================================================================
// كلاس خاص لكرت المادة (Stateful عشان يتحكم بالفتح والإغلاق والفلاتر)
// ============================================================================
class _SubjectCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool initiallyExpanded;

  const _SubjectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.initiallyExpanded = false,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  late bool isExpanded;
  int selectedFilter = 0; // 0=الكل, 1=محاضرات, 2=فيديو

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // الهيدر (عند الضغط عليه بيفتح ويسكر)
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Row(
              children: [
                // أيقونة المادة المربعة
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: widget.iconBgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.icon, color: widget.iconColor, size: 24),
                ),
                const SizedBox(width: 15),
                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                // سهم الفتح والإغلاق
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
          
          // المحتوى الداخلي (بيظهر بس إذا الكرت مفتوح)
          if (isExpanded) ...[
            const SizedBox(height: 15),
            // الفلاتر
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
            
            // قائمة الملفات للمادة
            _buildFileItem(
              title: 'المحاضرة 4: التكامل',
              subtitle: '12 أكتوبر • 2.5 MB',
              iconBgColor: const Color(0xFFFFEBEE),
              iconColor: Colors.red,
              icon: Icons.picture_as_pdf,
              actionIcon: Icons.download_outlined,
            ),
            Divider(color: Colors.grey.shade100, height: 1),
            _buildFileItem(
              title: 'شرح الدوال المثلثية',
              subtitle: '10 أكتوبر • 45 دقيقة',
              iconBgColor: const Color(0xFFFFF9C4),
              iconColor: const Color(0xFFFBC02D),
              icon: Icons.play_arrow_rounded,
              actionIcon: Icons.play_arrow_rounded,
            ),
            Divider(color: Colors.grey.shade100, height: 1),
            _buildFileItem(
              title: 'مصادر خارجية للمراجعة',
              subtitle: 'رابط ويب',
              iconBgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
              icon: Icons.link_rounded,
              actionIcon: Icons.open_in_new_rounded,
            ),
          ],
        ],
      ),
    );
  }

  // تصميم حبة الفلتر (Chip)
  Widget _buildFilterChip(String label, int index, IconData? icon) {
    bool isSelected = selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = index),
      child: Container(
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
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // تصميم عنصر الملف الواحد
  Widget _buildFileItem({required String title, required String subtitle, required Color iconBgColor, required Color iconColor, required IconData icon, required IconData actionIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Icon(actionIcon, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}