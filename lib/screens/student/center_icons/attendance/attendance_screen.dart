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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // لون خلفية أوف-وايت مريح
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('الحضور والغياب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    child: _selectedTab == 0 ? _buildAttendanceRecord() : _buildLeaveRequest(),
                  ),
                ),
              ],
            ),
            
            // الشريط السفلي والزر المنبثق
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

  // 1. التاب العلوي (مع النقطة الحمراء للتاب النشط)
  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive) ...[
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
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
        _buildRecordCard(date: '22 أكتوبر، الأحد', subject: 'فيزياء عامة', statusText: 'غائب بعذر', statusColor: const Color(0xFFFBC02D), bgColor: const Color(0xFFFFF9C4), icon: Icons.warning_amber_rounded),
        _buildRecordCard(date: '20 أكتوبر، الجمعة', subject: 'برمجة متقدمة', statusText: 'حاضر', statusColor: const Color(0xFF4CAF50), bgColor: const Color(0xFFE8F5E9), icon: Icons.check),
        _buildRecordCard(date: '19 أكتوبر، الخميس', subject: 'تاريخ العلوم', statusText: 'حاضر', statusColor: const Color(0xFF4CAF50), bgColor: const Color(0xFFE8F5E9), icon: Icons.check),
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
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // الهيدر (عند الضغط عليه يفتح/يغلق)
          GestureDetector(
            onTap: () => setState(() => _isExcuseExpanded = !_isExcuseExpanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_isExcuseExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('24 أكتوبر، الثلاثاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Text('رياضيات 101', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(5)),
                            child: const Text('غائب غير مبرر', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ],
            ),
          ),
          
          // المحتوى الداخلي (الفورم)
          if (_isExcuseExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: Colors.red.shade100, thickness: 1, height: 1),
            ),
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.red, size: 18),
                const SizedBox(width: 5),
                Text('تقديم عذر للغياب', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'يرجى كتابة سبب الغياب هنا...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 15),
            // صندوق إرفاق مستند
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // استخدمنا Solid للتبسيط
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.blueGrey, size: 20),
                  SizedBox(width: 8),
                  Text('إرفاق مستند (اختياري)', style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            // زر الإرسال
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFFF00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 8),
                    Text('إرسال التبرير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
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
  Widget _buildRecordCard({required String date, required String subject, required String statusText, required Color statusColor, required Color bgColor, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 5),
                Text(subject, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          )
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
          decoration: BoxDecoration(color: const Color(0xFFEDF4FC), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
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
                        const Text('طلب قيد المراجعة', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle)), // النقطة الحمراء
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text('لديك طلب إجازة معلق بتاريخ 25 أكتوبر. سيتم إشعارك فور اتخاذ القرار.', style: TextStyle(color: Colors.blue, fontSize: 11, height: 1.4)),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نوع الإجازة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 10),
              // أزرار التبديل
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    _buildToggleBtn('إجازة يوم كامل', 0),
                    _buildToggleBtn('إجازة ساعية', 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              const Text('التاريخ والوقت', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: 'mm/dd/yyyy',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              const Text('سبب الإجازة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 10),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اذكر سبب طلب الإجازة...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // زر الإرسال الأصفر
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFFF00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  onPressed: () {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.black, size: 18),
                      SizedBox(width: 8),
                      Text('إرسال الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
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
    bool isActive = _leaveType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _leaveType = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 12, color: isActive ? Colors.black : Colors.grey)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'الرئيسية', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()))),
          _buildNavItem(Icons.person_outline, 'حسابي', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          const SizedBox(width: 70),
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