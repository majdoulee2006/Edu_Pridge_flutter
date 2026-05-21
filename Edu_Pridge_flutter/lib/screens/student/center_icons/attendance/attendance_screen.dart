import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import '../../../../widgets/student_speed_dial.dart';
// مسارات شاشات الـ nav_bar بعد التعديل
import '../../nav_bar/student_home_screen.dart';
import '../../nav_bar/profile_screen.dart';
import '../../nav_bar/notifications_screen.dart';
import '../../nav_bar/messages_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedTab = 0; // 0 = سجل الحضور، 1 = طلب إجازة
  int _leaveType = 0; // 0 = يوم كامل، 1 = ساعية
  bool _isExcuseExpanded = true; // للتحكم بفتح وإغلاق كرت تقديم العذر

  // 🌟 متحكمات حقول التاريخ والوقت 🌟
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController =
      TextEditingController(); // ✅ تمت إضافة متحكم الوقت

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose(); // ✅ تنظيف متحكم الوقت
    super.dispose();
  }

  // 🌟 دالة لفتح التقويم 🌟
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // لا يمكن اختيار تاريخ ماضي للإجازة
      lastDate: DateTime(2030),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFEFFF00),
                    onPrimary: Colors.black,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFFEFFF00),
                    onPrimary: Colors.black,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}/${picked.month}/${picked.day}";
      });
    }
  }

  // 🌟 دالة لفتح ساعة اختيار الوقت (للإجازة الساعية) 🌟
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFEFFF00),
                    onPrimary: Colors.black,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFFEFFF00),
                    onPrimary: Colors.black,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  // 🌟 دالة لعرض النافذة المنبثقة (Pop-up) للنجاح 🌟
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark
              ? Theme.of(context).cardColor
              : Colors.white, // 🌟 متجاوب
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
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87, // 🌟 متجاوب
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).cardColor
                  : Colors.white, // 🌟 متجاوب
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إرفاق مستند',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.camera_alt,
                      'الكاميرا',
                      Colors.blue,
                    ),
                    _buildAttachmentOption(
                      Icons.photo_library,
                      'المعرض',
                      Colors.purple,
                    ),
                    _buildAttachmentOption(
                      Icons.insert_drive_file,
                      'ملف',
                      Colors.orange,
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

  Widget _buildAttachmentOption(IconData icon, String title, Color color) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم اختيار $title بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 50 : 25), // 🌟 متجاوب
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
                  color: isDark ? Colors.white : Colors.black, // 🌟 متجاوب
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF8F9FA);
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
            'الحضور والغياب',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildCustomTabBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _selectedTab == 0
                        ? _buildAttendanceRecord()
                        : _buildLeaveRequest(),
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

  Widget _buildCustomTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(title: 'سجل الحضور والغياب', index: 0),
          _buildTabItem(title: 'طلب إجازة', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFFF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.black
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecord() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      children: [
        _buildUnexcusedAbsenceCard(),
        _buildRecordCard(
          date: '22 أكتوبر، الأحد',
          subject: 'فيزياء عامة',
          statusText: 'غائب بعذر',
          statusColor: isDark ? Colors.amber.shade300 : const Color(0xFFFBC02D),
          bgColor: isDark
              ? Colors.amber.withAlpha(30)
              : const Color(0xFFFFF9C4),
          icon: Icons.warning_amber_rounded,
        ),
        _buildRecordCard(
          date: '20 أكتوبر، الجمعة',
          subject: 'برمجة متقدمة',
          statusText: 'حاضر',
          statusColor: isDark ? Colors.green.shade400 : const Color(0xFF4CAF50),
          bgColor: isDark
              ? Colors.green.withAlpha(30)
              : const Color(0xFFE8F5E9),
          icon: Icons.check,
        ),
        _buildRecordCard(
          date: '19 أكتوبر، الخميس',
          subject: 'تاريخ العلوم',
          statusText: 'حاضر',
          statusColor: isDark ? Colors.green.shade400 : const Color(0xFF4CAF50),
          bgColor: isDark
              ? Colors.green.withAlpha(30)
              : const Color(0xFFE8F5E9),
          icon: Icons.check,
        ),
      ],
    );
  }

  Widget _buildUnexcusedAbsenceCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.red.withAlpha(50) : Colors.red.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.red.withAlpha(13),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExcuseExpanded = !_isExcuseExpanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isExcuseExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '24 أكتوبر، الثلاثاء',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text(
                            'رياضيات 101',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.red.withAlpha(30)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'غائب غير مبرر',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.red.shade300
                                    : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.red.withAlpha(30)
                        : const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: isDark ? Colors.red.shade300 : Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          if (_isExcuseExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(
                color: isDark ? Colors.red.withAlpha(50) : Colors.red.shade100,
                thickness: 1,
                height: 1,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: isDark ? Colors.red.shade300 : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  'تقديم عذر للغياب',
                  style: TextStyle(
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'يرجى كتابة سبب الغياب هنا...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.all(12),
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

            InkWell(
              onTap: _showAttachmentOptions,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(30)
                        : Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.blueGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'إرفاق مستند (اختياري)',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.blueGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFFF00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  _showSuccessDialog('تم إرسال التبرير بنجاح\nشاكرين تعاونكم');
                  setState(() => _isExcuseExpanded = false);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'إرسال التبرير',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildRecordCard({
    required String date,
    required String subject,
    required String statusText,
    required Color statusColor,
    required Color bgColor,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subject,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: statusColor, size: 20),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // 3. واجهة "طلب إجازة"
  // ----------------------------------------------------------------
  Widget _buildLeaveRequest() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      children: [
        // بانر طلب قيد المراجعة
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.blue.withAlpha(25) : const Color(0xFFEDF4FC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.blue.withAlpha(50) : Colors.blue.shade100,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: isDark ? Colors.blue.shade300 : Colors.blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'طلب قيد المراجعة',
                          style: TextStyle(
                            color: isDark ? Colors.blue.shade300 : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.shade400
                                : const Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'لديك طلب إجازة معلق بتاريخ 25 أكتوبر. سيتم إشعارك فور اتخاذ القرار.',
                      style: TextStyle(
                        color: isDark ? Colors.blue.shade200 : Colors.blue,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),

        // فورم تقديم الإجازة
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
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
              Text(
                'نوع الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              // أزرار التبديل
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(15)
                      : const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn('إجازة يوم كامل', 0),
                    _buildToggleBtn('إجازة ساعية', 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🌟 تبديل النص بين التاريخ والوقت بذكاء 🌟
              Text(
                _leaveType == 0 ? 'التاريخ' : 'الوقت',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),

              // 🌟 حقل التاريخ (لليوم الكامل) أو حقل الوقت (للساعية) 🌟
              if (_leaveType == 0)
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'اختر التاريخ...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(15)
                        : const Color(0xFFF5F6F8),
                    suffixIcon: Icon(
                      Icons.calendar_today_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              else
                TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: () => _selectTime(context),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'اختر الوقت...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade600 : Colors.grey,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withAlpha(15)
                        : const Color(0xFFF5F6F8),
                    suffixIcon: Icon(
                      Icons.access_time_outlined,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                'سبب الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 4,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'اذكر سبب طلب الإجازة...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade600 : Colors.grey,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withAlpha(15)
                      : const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _showSuccessDialog(
                      'تم إرسال طلبكم بنجاح\nالطلب قيد المعالجة حالياً',
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.black, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'إرسال الطلب',
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
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isActive = _leaveType == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _leaveType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFFF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 5)]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: isActive
                    ? Colors.black
                    : (isDark ? Colors.grey.shade400 : Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
