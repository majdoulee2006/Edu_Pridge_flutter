import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final int? highlightId;
  const AssignmentsScreen({super.key, this.highlightId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  int _selectedFilter = 0;
  bool _isLoading = true;
  List<dynamic> _assignmentsList = [];
  int? _highlightedId;

  @override
  void initState() {
    super.initState();
    _highlightedId = widget.highlightId;
    _fetchAssignments();
    // يُزيل الإطار الأصفر بعد 3 ثواني
    if (widget.highlightId != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlightedId = null);
      });
    }
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
      final s = (assignment['status'] ?? '').toString();
      final isCompleted = s == 'مكتملة' || s == 'completed';
      final isMissed    = s == 'فائتة'  || s == 'missed';
      final isPending   = !isCompleted && !isMissed;
      if (_selectedFilter == 1) return isCompleted;
      if (_selectedFilter == 2) return isMissed;
      if (_selectedFilter == 3) return isPending;
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

      final rawStatus = (assignment['status'] ?? '').toString();
      final isCompleted = rawStatus == 'مكتملة' || rawStatus == 'completed';
      final isMissed    = rawStatus == 'فائتة'  || rawStatus == 'missed';

      final submission = assignment['submission'] as Map?;
      final maxPoints = (assignment['max_points'] as num?)?.toInt() ?? 100;
      final notesVal = assignment['notes']?.toString() ?? '';

      Color statusColor;
      String statusText;
      String tagText;
      Color tagColor;
      IconData tagIcon;
      bool showSubmitForm;
      String fileTypeStr = assignment['type'] == 'project' ? 'مشروع' : 'ملف PDF';
      IconData fileTypeIcon = assignment['type'] == 'project' ? Icons.folder : Icons.description_outlined;
      Color? fileTypeColor;

      if (isCompleted) {
        statusText = 'تم الحل';
        statusColor = Colors.green;
        tagText = 'مكتمل';
        tagColor = Colors.green;
        tagIcon = Icons.check_circle;
        showSubmitForm = false;
        final gradeVal = submission?['grade'];
        if (gradeVal != null) {
          fileTypeStr = 'الدرجة: $gradeVal / $maxPoints';
          fileTypeColor = Colors.green;
          fileTypeIcon = Icons.grade;
        }
      } else if (isMissed) {
        statusText = 'انتهى الوقت';
        statusColor = Colors.red;
        tagText = 'فائتة';
        tagColor = Colors.red;
        tagIcon = Icons.error;
        showSubmitForm = false;
      } else {
        statusText = 'قيد التنفيذ';
        statusColor = Colors.orange;
        tagText = 'مطلوب';
        tagColor = Colors.orange;
        tagIcon = Icons.access_time;
        showSubmitForm = true;
      }

      final teacherFilePath = assignment['file_url']?.toString();
      final teacherFileName = assignment['file_name']?.toString();

      final cardId = assignment['assignment_id'] is int
          ? assignment['assignment_id'] as int
          : int.tryParse(assignment['assignment_id']?.toString() ?? '0') ?? 0;

      return _AssignmentCard(
        assignmentId: cardId,
        highlighted: _highlightedId != null && _highlightedId == cardId,
        title: assignment['title'] ?? 'بدون عنوان',
        subtitle: '${assignment['course_name'] ?? ''}',
        dueDate: 'آخر موعد: ${assignment['due_date'] ?? ''}',
        dueDateColor: isMissed ? Colors.red : null,
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
        initiallyExpanded: false,
        showSubmitForm: showSubmitForm,
        notes: notesVal,
        maxPoints: maxPoints,
        teacherFilePath: teacherFilePath,
        teacherFileName: teacherFileName,
        submissionFilePath: submission?['file_path']?.toString(),
        submissionFileName: submission?['file_path'] != null
            ? _cleanFileName(submission!['file_path'].toString())
            : null,
        submittedAt: submission?['submitted_at']?.toString(),
        submissionSolutionText: submission?['solution_text']?.toString(),
        submissionStudentNotes: submission?['student_notes']?.toString(),
        detailText: assignment['description'] ??
            'يرجى قراءة التعليمات المرفقة وتجهيز الحل بشكل منظم، ثم رفعه هنا قبل انتهاء الموعد المحدد.',
        onSubmitSuccess: () async {
          await _fetchAssignments();
          if (mounted) setState(() => _selectedFilter = 1);
        },
        grade: submission?['grade'] != null
            ? double.tryParse(submission!['grade'].toString())
            : null,
        feedback: submission?['feedback']?.toString(),
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
        resizeToAvoidBottomInset: false,
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
                      _buildFilterChip('قيد التنفيذ', 3, Icons.access_time, Colors.orange, isDark),
                      const SizedBox(width: 10),
                      _buildFilterChip('مكتملة', 1, Icons.check_circle, Colors.green, isDark),
                      const SizedBox(width: 10),
                      _buildFilterChip('فائتة', 2, Icons.access_time_filled, Colors.red, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 🌟 عرض دائرة التحميل أو البيانات 🌟
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFCC00),
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
                      color: const Color(0xFFFFCC00),
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
                              padding: EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 120 + MediaQuery.of(context).viewInsets.bottom,
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
              ? const Color(0xFFFFCC00)
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
                    color: const Color(0xFFFFCC00).withAlpha(76),
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
  final int assignmentId;
  final bool highlighted;
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
  final String notes;
  final int maxPoints;
  final VoidCallback? onSubmitSuccess;
  final double? grade;
  final String? feedback;
  final String? studentNotes;
  final String? teacherFilePath;
  final String? teacherFileName;
  final String? submissionFilePath;
  final String? submissionFileName;
  final String? submittedAt;
  final String? submissionSolutionText;
  final String? submissionStudentNotes;

  const _AssignmentCard({
    required this.assignmentId,
    this.highlighted = false,
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
    this.notes = '',
    this.maxPoints = 100,
    this.teacherFilePath,
    this.teacherFileName,
    this.submissionFilePath,
    this.submissionFileName,
    this.submittedAt,
    this.submissionSolutionText,
    this.submissionStudentNotes,
    this.detailText =
        'يرجى قراءة التعليمات المرفقة وتجهيز الحل بشكل منظم، ثم رفعه هنا قبل انتهاء الموعد المحدد.',
    this.onSubmitSuccess,
    this.grade,
    this.feedback,
    this.studentNotes,
  });

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  late bool isExpanded;
  PlatformFile? _pickedFile;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _solutionController.dispose();
    super.dispose();
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
                    backgroundColor: const Color(0xFFFFCC00),
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

  Future<void> _pickFile(String type) async {
    Navigator.pop(context);
    try {
      FilePickerResult? result;
      if (type == 'صورة') {
        result = await FilePicker.platform.pickFiles(type: FileType.image);
      } else if (type == 'فيديو') {
        result = await FilePicker.platform.pickFiles(type: FileType.video);
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'zip'],
        );
      }
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pickedFile = result!.files.first);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم اختيار: ${_pickedFile!.name}'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء اختيار الملف'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitAssignment() async {
    final solution = _solutionController.text.trim();
    final notes = _notesController.text.trim();

    if ((_pickedFile == null || _pickedFile!.path == null) && solution.isEmpty && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الحل أو إرفاق ملف أو إضافة ملاحظات أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ok = await StudentServices().submitAssignment(
        widget.assignmentId,
        _pickedFile?.path,
        _pickedFile?.name,
        notes,
        solution,
      );
      if (!mounted) return;
      if (ok) {
        _showSuccessDialog();
        setState(() {
          isExpanded = false;
          _pickedFile = null;
          _notesController.clear();
          _solutionController.clear();
        });
        widget.onSubmitSuccess?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الإرسال، حاول مجدداً'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في الاتصال'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String title,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _pickFile(title),
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
        border: widget.highlighted
            ? Border.all(color: const Color(0xFFFFCC00), width: 2.5)
            : null,
        boxShadow: [
          if (widget.highlighted)
            const BoxShadow(
              color: Color(0x55FFCC00),
              blurRadius: 16,
              spreadRadius: 2,
            )
          else
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
                    const SizedBox(height: 1),
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

          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, thickness: 1),
            ),
            
            // كرت تفاصيل الواجب والتعليمات
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withAlpha(20) : Colors.blue.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text('تفاصيل الواجب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'الدرجة القصوى: ${widget.maxPoints}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.detailText,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // كرت ملاحظات المعلم (إن وجدت)
            if (widget.notes.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.orange.withAlpha(20) : Colors.orange.withAlpha(10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('ملاحظات إضافية من المعلم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.notes,
                      style: TextStyle(
                        color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // كرت نتيجة التصحيح
          if (isExpanded && !widget.showSubmitForm && (widget.grade != null || (widget.feedback != null && widget.feedback!.isNotEmpty))) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.green.withAlpha(20) : Colors.green.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.green, size: 22),
                      const SizedBox(width: 8),
                      Text('نتيجة التقييم والتصحيح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      const Spacer(),
                      if (widget.grade != null)
                        Text(
                          '${widget.grade!.toStringAsFixed(widget.grade! % 1 == 0 ? 0 : 1)} / ${widget.maxPoints}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                    ],
                  ),
                  if (widget.feedback != null && widget.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.green.withAlpha(40)),
                    const SizedBox(height: 8),
                    Text(
                      'ملاحظات المصحح:',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.feedback!,
                      style: TextStyle(color: textColor, fontSize: 13, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // كرت ملفات وتفاصيل الحل المرسل
          if (isExpanded && (widget.teacherFilePath != null || widget.submissionFilePath != null || (widget.submissionSolutionText != null && widget.submissionSolutionText!.isNotEmpty) || (widget.submissionStudentNotes != null && widget.submissionStudentNotes!.isNotEmpty))) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.deepPurple.withAlpha(20) : Colors.deepPurple.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.done_all_rounded, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Text('تفاصيل تسليمك والحل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ملف المعلم
                  if (widget.teacherFilePath != null) ...[
                    _FileButton(
                      label: widget.teacherFileName ?? 'ملف الواجب',
                      sublabel: 'ملف المعلم المرفق',
                      color: Colors.blue,
                      icon: Icons.menu_book_rounded,
                      url: widget.teacherFilePath!,
                      isDark: isDark,
                    ),
                    if (widget.submissionFilePath != null || (widget.submissionSolutionText != null && widget.submissionSolutionText!.isNotEmpty) || (widget.submissionStudentNotes != null && widget.submissionStudentNotes!.isNotEmpty))
                      const SizedBox(height: 10),
                  ],

                  // ملف الطالب المُرسَل
                  if (widget.submissionFilePath != null) ...[
                    _FileButton(
                      label: widget.submissionFileName ?? 'ملف الحل',
                      sublabel: widget.submittedAt != null ? 'ملفك المرسل — ${widget.submittedAt}' : 'ملف تسليمك',
                      color: Colors.green,
                      icon: Icons.task_alt_rounded,
                      url: widget.submissionFilePath!,
                      isDark: isDark,
                    ),
                    if ((widget.submissionSolutionText != null && widget.submissionSolutionText!.isNotEmpty) || (widget.submissionStudentNotes != null && widget.submissionStudentNotes!.isNotEmpty))
                      const SizedBox(height: 10),
                  ],

                  // حل الطالب المكتوب
                  if (widget.submissionSolutionText != null && widget.submissionSolutionText!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(isDark ? 40 : 20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note_rounded, color: Colors.green, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'حلّك المكتوب:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.submissionSolutionText!,
                            style: TextStyle(color: textColor, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (widget.submissionStudentNotes != null && widget.submissionStudentNotes!.isNotEmpty)
                      const SizedBox(height: 10),
                  ],

                  // ملاحظات الطالب المرسلة
                  if (widget.submissionStudentNotes != null && widget.submissionStudentNotes!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notes_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'ملاحظاتك المرسلة:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.submissionStudentNotes!,
                            style: TextStyle(color: textColor, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (isExpanded && widget.showSubmitForm) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, thickness: 1),
            ),

            // ملف المعلم — يظهر دائماً إذا موجود
            if (widget.teacherFilePath != null) ...[
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('ملف الواجب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                ],
              ),
              const SizedBox(height: 10),
              _FileButton(
                label: widget.teacherFileName ?? 'ملف الواجب',
                sublabel: 'اضغط لفتح ملف المعلم',
                color: Colors.blue,
                icon: Icons.menu_book_rounded,
                url: widget.teacherFilePath!,
                isDark: isDark,
              ),
              const SizedBox(height: 15),
              Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, thickness: 1),
              const SizedBox(height: 10),
            ],
            if (_pickedFile != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_pickedFile!.name,
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          const Text('ملف محدد — اضغط لتغييره', style: TextStyle(color: Colors.green, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.swap_horiz_rounded, color: Colors.green.withAlpha(180), size: 20),
                      onPressed: _showAttachmentOptions,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _showAttachmentOptions,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_upload, color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey),
                      ),
                      const SizedBox(height: 10),
                      Text('اضغط لرفع ملف الحل',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                      const SizedBox(height: 1),
                      Text('PDF, JPG, Video, ZIP (Max 50MB)',
                          style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 15),

            Text(
              'نص الحل المكتوب',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _solutionController,
              maxLines: 5,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'اكتب إجابتك أو حل الواجب هنا بالتفصيل...',
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
              controller: _notesController,
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
                  backgroundColor: const Color(0xFFFFCC00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitAssignment,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _pickedFile != null ? 'إرسال: ${_pickedFile!.name}' : 'إرسال الحل',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
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

class _FileButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final String url;
  final bool isDark;

  const _FileButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 40 : 20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: color.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: color, size: 15),
          ],
        ),
      ),
    );
  }
}

String _cleanFileName(String? filePath) {
  if (filePath == null) return '';
  String fileName = filePath.split('/').last;
  final regExp = RegExp(r'^\d+_\d+_(.*)$');
  final match = regExp.firstMatch(fileName);
  if (match != null && match.groupCount >= 1) {
    return match.group(1)!;
  }
  return fileName;
}
