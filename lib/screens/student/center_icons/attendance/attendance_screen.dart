import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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

  // 🌟 متحكم حقل التاريخ 🌟
  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEFFF00), // لون رأس التقويم
              onPrimary: Colors.black, // لون النص في رأس التقويم
              onSurface: Colors.black, // لون الأيام
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

  // 🌟 دالة لعرض النافذة المنبثقة (Pop-up) للنجاح 🌟
  void _showSuccessDialog(String message) {
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
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                'إرفاق مستند',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, Color color) {
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // لون خلفية أوف-وايت مريح
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          // ✅ تم تعديل السهم ليؤشر للاتجاه الصحيح
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الحضور والغياب',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

            // الشريط السفلي والزر المنبثق
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

  // 1. التاب العلوي (تم التعديل ليصبح ملون بالأصفر)
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
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
                color: isActive ? Colors.black : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 2. واجهة "سجل الحضور والغياب"
  // ----------------------------------------------------------------
  Widget _buildAttendanceRecord() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      children: [
        _buildUnexcusedAbsenceCard(), // الكرت القابل للتوسيع (الأحمر)
        _buildRecordCard(
          date: '22 أكتوبر، الأحد',
          subject: 'فيزياء عامة',
          statusText: 'غائب بعذر',
          statusColor: const Color(0xFFFBC02D),
          bgColor: const Color(0xFFFFF9C4),
          icon: Icons.warning_amber_rounded,
        ),
        _buildRecordCard(
          date: '20 أكتوبر، الجمعة',
          subject: 'برمجة متقدمة',
          statusText: 'حاضر',
          statusColor: const Color(0xFF4CAF50),
          bgColor: const Color(0xFFE8F5E9),
          icon: Icons.check,
        ),
        _buildRecordCard(
          date: '19 أكتوبر، الخميس',
          subject: 'تاريخ العلوم',
          statusText: 'حاضر',
          statusColor: const Color(0xFF4CAF50),
          bgColor: const Color(0xFFE8F5E9),
          icon: Icons.check,
        ),
      ],
    );
  }

  // كرت الغياب غير المبرر (قابل للتوسيع وفيه فورم)
  Widget _buildUnexcusedAbsenceCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // الهيدر (عند الضغط عليه يفتح/يغلق)
          GestureDetector(
            onTap: () => setState(() => _isExcuseExpanded = !_isExcuseExpanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isExcuseExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '24 أكتوبر، الثلاثاء',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'غائب غير مبرر',
                              style: TextStyle(
                                color: Colors.red,
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ],
            ),
          ),

          // المحتوى الداخلي (الفورم)
          if (_isExcuseExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(
                color: Colors.red.shade100,
                thickness: 1,
                height: 1,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.red, size: 18),
                const SizedBox(width: 5),
                Text(
                  'تقديم عذر للغياب',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'يرجى كتابة سبب الغياب هنا...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                contentPadding: const EdgeInsets.all(12),
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

            // صندوق إرفاق مستند (تفاعلي)
            InkWell(
              onTap: _showAttachmentOptions,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'إرفاق مستند (اختياري)',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // زر الإرسال مع الـ Pop-up
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
                  setState(
                    () => _isExcuseExpanded = false,
                  ); // إغلاق الكرت بعد الإرسال
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

  // كرت الحضور أو الغياب العادي
  Widget _buildRecordCard({
    required String date,
    required String subject,
    required String statusText,
    required Color statusColor,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
  }

  // ----------------------------------------------------------------
  // 3. واجهة "طلب إجازة"
  // ----------------------------------------------------------------
  Widget _buildLeaveRequest() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      children: [
        // بانر طلب قيد المراجعة
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF4FC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'طلب قيد المراجعة',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ), // النقطة الحمراء
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'لديك طلب إجازة معلق بتاريخ 25 أكتوبر. سيتم إشعارك فور اتخاذ القرار.',
                      style: TextStyle(
                        color: Colors.blue,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نوع الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              // أزرار التبديل
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
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

              const Text(
                'التاريخ والوقت',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),

              // حقل التاريخ (يفتح التقويم)
              TextField(
                controller: _dateController,
                readOnly: true, // يمنع الكتابة اليدوية
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  hintText: 'اختر التاريخ...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  suffixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'سبب الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اذكر سبب طلب الإجازة...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // زر الإرسال مع الـ Pop-up
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

  // تم التعديل ليصبح لون التاب المختار أصفر
  Widget _buildToggleBtn(String label, int index) {
    bool isActive = _leaveType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _leaveType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFEFFF00)
                : Colors.transparent, // اللون الأصفر بدل الأبيض
            borderRadius: BorderRadius.circular(15),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // 4. الشريط السفلي الموحد
  // ----------------------------------------------------------------
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
