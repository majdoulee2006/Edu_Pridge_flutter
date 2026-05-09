import 'package:flutter/material.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';
// 🌟 استدعاء واجهة الإعدادات 🌟
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

// 🌟 استدعاء ملف الخدمات 🌟
import 'package:edu_pridge_flutter/services/student_services.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  int _selectedFilter = 0; // 0=الكل, 1=المكتملة, 2=فائتة

  // 🌟 متغيرات السيرفر 🌟
  bool _isLoading = true;
  List<dynamic> _assignmentsList = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  // 🌟 دالة جلب الواجبات من الباك إند
  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentServices().getAssignments();
      if (data != null) {
        setState(() {
          _assignmentsList = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching assignments: $e");
    }
  }

  // 🌟 دالة ذكية لتحويل بيانات السيرفر إلى كروت وتطبيق الفلاتر 🌟
  List<Widget> _getFilteredAssignments() {
    // تصفية المصفوفة الأساسية بناءً على التاب المحدد
    List<dynamic> filteredData = _assignmentsList.where((assignment) {
      String status =
          assignment['status'] ?? 'pending'; // pending, completed, missed
      if (_selectedFilter == 1) return status == 'completed';
      if (_selectedFilter == 2) return status == 'missed';
      return true; // 0 = الكل
    }).toList();

    // قائمة الألوان والأيقونات العشوائية/المرتبة لإعطاء جمالية للتصميم (نفس ألوانك)
    List<Color> bgColors = [
      const Color(0xFF263238), // أزرق رمادي غامق
      const Color(0xFFA1887F), // بني
      const Color(0xFFBDBDBD), // رمادي
      const Color(0xFF37474F), // كحلي غامق
    ];
    List<IconData> icons = [
      Icons.science,
      Icons.menu_book,
      Icons.calculate,
      Icons.computer,
    ];

    return filteredData.asMap().entries.map((entry) {
      int index = entry.key;
      var assignment = entry.value;

      String status = assignment['status'] ?? 'pending';

      // متغيرات الكرت الافتراضية
      Color statusColor = Colors.blue;
      String statusText = 'قيد الانتظار';
      String tagText = 'جديد';
      Color tagColor = Colors.blue;
      IconData tagIcon = Icons.access_time;
      bool showSubmitForm = true;
      String fileTypeStr = assignment['type'] == 'project'
          ? 'مشروع'
          : 'ملف PDF';
      IconData fileTypeIcon = assignment['type'] == 'project'
          ? Icons.folder
          : Icons.description_outlined;
      Color? fileTypeColor;

      // تخصيص الكرت بناءً على الحالة
      if (status == 'completed') {
        statusText = 'تم التسليم';
        statusColor = Colors.grey;
        tagText = 'مكتمل';
        tagColor = Colors.green;
        tagIcon = Icons.check_circle;
        showSubmitForm = false; // لا حاجة لنموذج التسليم إذا كان مكتملاً
        if (assignment['mark'] != null) {
          fileTypeStr = '${assignment['mark']} / 100';
          fileTypeColor = Colors.green;
          fileTypeIcon = Icons.grade;
        }
      } else if (status == 'missed') {
        statusText = 'انتهى الوقت';
        statusColor = Colors.red;
        tagText = 'فائتة';
        tagColor = Colors.red;
        tagIcon = Icons.error;
        showSubmitForm = false;
      } else {
        // Pending
        statusText = 'متبقي وقت';
        statusColor = Colors.orange;
        tagText = 'مطلوب';
        tagColor = Colors.orange;
        tagIcon = Icons.access_time;
        showSubmitForm = true;
      }

      return _AssignmentCard(
        title: assignment['title'] ?? 'بدون عنوان',
        subtitle:
            '${assignment['course_name']} • ${assignment['teacher_name']}',
        dueDate: 'آخر موعد: ${assignment['due_date']}',
        dueDateColor: status == 'missed' ? Colors.red : null,
        status: statusText,
        statusColor: statusColor,
        tagText: tagText,
        tagColor: tagColor,
        tagIcon: tagIcon,
        fileType: fileTypeStr,
        fileTypeIcon: fileTypeIcon,
        fileTypeColor: fileTypeColor,
        iconData: icons[index % icons.length],
        imageBgColor: bgColors[index % bgColors.length],
        initiallyExpanded:
            index == 0 && status == 'pending', // نفتح أول واجب مطلوب تلقائياً
        showSubmitForm: showSubmitForm,
        detailText:
            assignment['description'] ??
            'يرجى قراءة التعليمات المرفقة وتجهيز الحل بشكل منظم، ثم رفعه هنا قبل انتهاء الموعد المحدد.',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF9F9F9);
    final textColor = isDark ? Colors.white : Colors.black;

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
            'الواجبات والمشاريع',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // 1. الفلاتر العلوية
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 0, null, null, isDark),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        'المكتملة',
                        1,
                        Icons.check_circle,
                        Colors.green,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        'فائتة',
                        2,
                        Icons.access_time_filled,
                        Colors.red,
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 🌟 عرض دائرة التحميل أو البيانات 🌟
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEFFF00),
                      ),
                    ),
                  )
                else ...[
                  // 2. عدد الواجبات المحدث تلقائياً
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'لديك ${_getFilteredAssignments().length} واجبات في القائمة.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // 3. قائمة الواجبات المفلترة
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchAssignments,
                      color: const Color(0xFFEFFF00),
                      child: _getFilteredAssignments().isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                Center(
                                  child: Text(
                                    'لا يوجد واجبات حالياً',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 120,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              children: _getFilteredAssignments(),
                            ),
                    ),
                  ),
                ],
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

  // تصميم الفلاتر العلوية
  Widget _buildFilterChip(
    String label,
    int index,
    IconData? icon,
    Color? iconColor,
    bool isDark,
  ) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFFF00)
              : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.grey.shade200,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEFFF00).withAlpha(76),
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
  final String detailText;

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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
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
              Text(
                'تم ارسال ردك بنجاح\nسيتم تصحيحه في اقرب وقت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إرفاق ملف الحل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.image,
                      'صورة',
                      Colors.blue,
                      isDark,
                    ),
                    _buildAttachmentOption(
                      Icons.videocam,
                      'فيديو',
                      Colors.pink,
                      isDark,
                    ),
                    _buildAttachmentOption(
                      Icons.insert_drive_file,
                      'مستند',
                      Colors.orange,
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String title,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
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
              color: color.withAlpha(isDark ? 50 : 25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? color.withAlpha(200) : color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark
                      ? widget.imageBgColor.withAlpha(150)
                      : widget.imageBgColor,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildTag(
                          widget.tagText,
                          widget.tagColor,
                          widget.tagIcon,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          widget.fileTypeIcon,
                          size: 14,
                          color: isDark ? Colors.grey.shade500 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.fileType,
                          style: TextStyle(
                            color:
                                widget.fileTypeColor ??
                                (isDark ? Colors.grey.shade400 : Colors.grey),
                            fontSize: 11,
                            fontWeight: widget.fileTypeColor != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade600 : Colors.grey,
                          ),
                        ),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.dueDate,
                style: TextStyle(
                  color:
                      widget.dueDateColor ??
                      (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
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
                  color: Colors.transparent,
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),

          if (isExpanded && widget.showSubmitForm) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                thickness: 1,
              ),
            ),
            Text(
              'تفاصيل الواجب',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.detailText,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15),

            InkWell(
              onTap: _showAttachmentOptions,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(10)
                      : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(30)
                        : Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blueGrey.shade800
                            : Colors.blueGrey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload,
                        color: isDark
                            ? Colors.blueGrey.shade300
                            : Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'اضغط لرفع ملف الحل',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'PDF, JPG, Video, ZIP (Max 50MB)',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            Text(
              'ملاحظات إضافية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'أضف أي ملاحظات للمدرس هنا...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.all(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha(30)
                        : Colors.grey.shade200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha(30)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

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
                  _showSuccessDialog();
                  setState(() => isExpanded = false);
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

  Widget _buildTag(String text, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 50 : 25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDark ? color.withAlpha(200) : color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isDark ? color.withAlpha(200) : color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
