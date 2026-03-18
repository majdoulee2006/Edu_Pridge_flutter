import 'package:flutter/material.dart';

import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  int _selectedFilter = 0; // 0=الكل, 1=المكتملة, 2=فائتة

  // دالة لجلب الكروت المفلترة
  List<Widget> _getFilteredAssignments() {
    final pendingCard = _AssignmentCard(
      title: 'تقرير مختبر الفيزياء',
      subtitle: 'فيزياء 101 • أ. أحمد علي',
      dueDate: 'آخر موعد: 10 أكتوبر، 11:59 م',
      status: 'قيد الانتظار',
      statusColor: Colors.red,
      tagText: 'غداً',
      tagColor: Colors.orange,
      tagIcon: Icons.access_time,
      fileType: 'ملف PDF',
      iconData: Icons.science,
      imageBgColor: Colors.blueGrey.shade900,
      initiallyExpanded: true,
      showSubmitForm: true,
    );

    final newCard = _AssignmentCard(
      title: 'بحث التاريخ المعاصر',
      subtitle: 'تاريخ العمارة • د. سارة حسن',
      dueDate: 'آخر موعد: 24 أكتوبر',
      status: 'متبقي أسبوعين',
      statusColor: Colors.blue,
      tagText: 'جديد',
      tagColor: Colors.blue,
      tagIcon: Icons.verified,
      fileType: 'مشروع',
      fileTypeIcon: Icons.folder,
      iconData: Icons.menu_book,
      imageBgColor: Colors.brown.shade300,
    );

    final completedCard = _AssignmentCard(
      title: 'مسائل الرياضيات - ف4',
      subtitle: 'رياضيات متقدمة • أ. يوسف',
      dueDate: 'تم التسليم',
      status: 'تم التسليم',
      statusColor: Colors.grey,
      tagText: 'مكتمل',
      tagColor: Colors.green,
      tagIcon: Icons.check_circle,
      fileType: '95 / 100',
      fileTypeColor: Colors.green,
      iconData: Icons.calculate,
      imageBgColor: Colors.grey.shade400,
    );

    final missedCard = _AssignmentCard(
      title: 'واجب خوارزميات الترتيب',
      subtitle: 'علوم حاسوب • د. منى',
      dueDate: 'انتهى الموعد: الأحد الماضي',
      dueDateColor: Colors.red,
      status: 'انتهى الوقت',
      statusColor: Colors.red,
      tagText: 'فائتة',
      tagColor: Colors.red,
      tagIcon: Icons.error,
      fileType: 'كود',
      fileTypeIcon: Icons.code,
      iconData: Icons.computer,
      imageBgColor: Colors.blueGrey.shade800,
    );

    // فلترة بناءً على التاب المحدد
    if (_selectedFilter == 1) return [completedCard];
    if (_selectedFilter == 2) return [missedCard];
    return [pendingCard, newCard, completedCard, missedCard]; // 0 = الكل
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> filteredAssignments = _getFilteredAssignments();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('الواجبات والمشاريع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // 1. الفلاتر العلوية
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 0, null, null),
                      const SizedBox(width: 10),
                      _buildFilterChip('المكتملة', 1, Icons.check_circle, Colors.green),
                      const SizedBox(width: 10),
                      _buildFilterChip('فائتة', 2, Icons.access_time_filled, Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // 2. عدد الواجبات المحدث تلقائياً
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'لديك ${filteredAssignments.length} واجبات في القائمة.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 15),
                // 3. قائمة الواجبات المفلترة
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                    physics: const BouncingScrollPhysics(),
                    children: filteredAssignments,
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

  // تصميم الفلاتر العلوية
  Widget _buildFilterChip(String label, int index, IconData? icon, Color? iconColor) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFF00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFEFFF00).withOpacity(0.3), blurRadius: 8)] : [],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 5),
            ],
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // الشريط السفلي (موحد)
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
          const SizedBox(width: 70),
          _buildNavItem(Icons.notifications_none, 'إشعارات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()))),
          _buildNavItem(Icons.chat_bubble_outline, 'مراسلات', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
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
// كلاس خاص لكرت الواجب (تم تعديل السهم وآلية الفتح)
// ============================================================================
class _AssignmentCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String dueDate;
  final Color? dueDateColor;
  final String status;
  final Color statusColor;
  final String tagText;
  final Color tagColor;
  final IconData tagIcon;
  final String fileType;
  final IconData? fileTypeIcon;
  final Color? fileTypeColor;
  final IconData iconData;
  final Color imageBgColor;
  final bool initiallyExpanded;
  final bool showSubmitForm;

  const _AssignmentCard({
    required this.title,
    required this.subtitle,
    required this.dueDate,
    this.dueDateColor,
    required this.status,
    required this.statusColor,
    required this.tagText,
    required this.tagColor,
    required this.tagIcon,
    required this.fileType,
    this.fileTypeIcon = Icons.description_outlined,
    this.fileTypeColor,
    required this.iconData,
    required this.imageBgColor,
    this.initiallyExpanded = false,
    this.showSubmitForm = false,
  });

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  late bool isExpanded;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الهيدر (بدون GestureDetector عشان ما يفتح لما نكبس هون)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: widget.imageBgColor, borderRadius: BorderRadius.circular(15)),
                child: Icon(widget.iconData, color: Colors.white54, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        _buildTag(widget.tagText, widget.tagColor, widget.tagIcon),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(widget.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(widget.fileTypeIcon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(widget.fileType, style: TextStyle(color: widget.fileTypeColor ?? Colors.grey, fontSize: 11, fontWeight: widget.fileTypeColor != null ? FontWeight.bold : FontWeight.normal)),
                        const SizedBox(width: 10),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 10),
                        Text(widget.status, style: TextStyle(color: widget.statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // التاريخ ع اليمين والسهم ع اليسار (والسهم فقط هو القابل للضغط)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.dueDate, style: TextStyle(color: widget.dueDateColor ?? Colors.grey.shade500, fontSize: 11)),
              GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.transparent, // مساحة شفافة لتسهيل النقر
                  child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),

          // المحتوى الموسع (فورم التسليم)
          if (isExpanded && widget.showSubmitForm) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: Colors.grey.shade100, thickness: 1),
            ),
            const Text('تفاصيل الواجب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Text(
              'يجب إعداد تقرير شامل عن تجربة الانكسار الضوئي، متضمناً الرسوم البيانية للنتائج وجداول البيانات الخام. يرجى التأكد من اتباع معايير التنسيق الموضحة في المحاضرة.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 15),
            
            // مربع رفع الملف
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blueGrey.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.cloud_upload, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),
                  const Text('اضغط لرفع ملف الحل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text('PDF, JPG, PNG, ZIP (Max 20MB)', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 15),

            const Text('ملاحظات إضافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'أضف أي ملاحظات للمدرس هنا...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                contentPadding: const EdgeInsets.all(15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 15),

            // زر الإرسال
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFFF00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text('إرسال الحل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}