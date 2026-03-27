import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';
// 🌟 استدعاء واجهة الإعدادات 🌟
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  int _selectedFilter = 0; // 0=الكل, 1=المكتملة, 2=فائتة

  // دالة لجلب الكروت المفلترة
  List<Widget> _getFilteredAssignments() {
    final pendingCard = const _AssignmentCard(
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
      imageBgColor: Color(0xFF263238), // Colors.blueGrey.shade900
      initiallyExpanded: true,
      showSubmitForm: true, // ✅ مفعلة
      detailText:
          'يجب إعداد تقرير شامل عن تجربة الانكسار الضوئي، متضمناً الرسوم البيانية للنتائج وجداول البيانات الخام. يرجى التأكد من اتباع معايير التنسيق الموضحة في المحاضرة.',
    );

    final newCard = const _AssignmentCard(
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
      imageBgColor: Color(0xFFA1887F), // Colors.brown.shade300
      showSubmitForm: true, // ✅ مفعلة لتفتح مثل الأولى
      detailText:
          'يرجى كتابة بحث لا يقل عن 5 صفحات يتحدث عن تطور العمارة في العصر الحديث مع إرفاق صور للمباني التاريخية المهمة.',
    );

    final completedCard = const _AssignmentCard(
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
      imageBgColor: Color(0xFFBDBDBD), // Colors.grey.shade400
      showSubmitForm: true, // ✅ مفعلة
      detailText:
          'لقد قمت بتسليم هذا الواجب وحصلت على تقييم 95/100. يمكنك مراجعة ملاحظات المدرس في الملف المرفق.',
    );

    final missedCard = const _AssignmentCard(
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
      imageBgColor: Color(0xFF37474F), // Colors.blueGrey.shade800
      showSubmitForm: true, // ✅ مفعلة
      detailText:
          'لقد انتهى الوقت المخصص لتسليم هذا الواجب. يرجى التواصل مع مدرس المادة لمعرفة إمكانية التسليم المتأخر.',
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
          // ✅ تم تصحيح اتجاه السهم
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الواجبات والمشاريع',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            // ✅ تم ربط الإعدادات
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
                      _buildFilterChip(
                        'المكتملة',
                        1,
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        'فائتة',
                        2,
                        Icons.access_time_filled,
                        Colors.red,
                      ),
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
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 120,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: filteredAssignments,
                  ),
                ),
              ],
            ),

            // 🌟 استدعاء الشريط الموحد هنا (-1 لأنها واجهة فرعية) 🌟
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

  // تصميم الفلاتر العلوية
  Widget _buildFilterChip(
    String label,
    int index,
    IconData? icon,
    Color? iconColor,
  ) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFF00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEFFF00).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// كلاس خاص لكرت الواجب
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
  final String detailText; // 🌟 إضافة متغير لتفاصيل الواجب

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
    this.detailText =
        'يرجى قراءة التعليمات المرفقة وتجهيز الحل بشكل منظم، ثم رفعه هنا قبل انتهاء الموعد المحدد.',
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

  // 🌟 دالة لعرض النافذة المنبثقة (Pop-up) للنجاح 🌟
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 20),
              const Text(
                'تم ارسال ردك بنجاح\nسيتم تصحيحه في اقرب وقت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "حسناً",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🌟 دالة لفتح خيارات إرفاق الملف 🌟
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إرفاق ملف الحل',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(Icons.image, 'صورة', Colors.blue),
                  _buildAttachmentOption(Icons.videocam, 'فيديو', Colors.pink),
                  _buildAttachmentOption(
                    Icons.insert_drive_file,
                    'مستند',
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // إغلاق القائمة السفلية
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرفاق $title بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الهيدر
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.imageBgColor,
                  borderRadius: BorderRadius.circular(15),
                ),
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
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildTag(
                          widget.tagText,
                          widget.tagColor,
                          widget.tagIcon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(widget.fileTypeIcon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.fileType,
                          style: TextStyle(
                            color: widget.fileTypeColor ?? Colors.grey,
                            fontSize: 11,
                            fontWeight: widget.fileTypeColor != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 10),
                        Text(
                          widget.status,
                          style: TextStyle(
                            color: widget.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
              Text(
                widget.dueDate,
                style: TextStyle(
                  color: widget.dueDateColor ?? Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: Colors.transparent, // مساحة شفافة لتسهيل النقر
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                  ),
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
            const Text(
              'تفاصيل الواجب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              widget.detailText, // ✅ استخدام المتغير الديناميكي للتفاصيل
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15),

            // ✅ مربع رفع الملف صار تفاعلي ويفتح الـ Bottom Sheet
            InkWell(
              onTap: _showAttachmentOptions,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اضغط لرفع ملف الحل',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'PDF, JPG, Video, ZIP (Max 50MB)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            const Text(
              'ملاحظات إضافية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'أضف أي ملاحظات للمدرس هنا...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                contentPadding: const EdgeInsets.all(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // ✅ زر الإرسال مع الـ Pop-up
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFFF00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  _showSuccessDialog(); // عرض رسالة النجاح
                  setState(
                    () => isExpanded = false,
                  ); // اختياري: إغلاق الكرت بعد الإرسال
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'إرسال الحل',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
