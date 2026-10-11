import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:edu_pridge_flutter/services/parent_services.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ParentService _parentService = ParentService();

  List<dynamic> _myRequests = [];
  List<dynamic> _summons = [];
  List<dynamic> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _parentService.getMyMeetingRequests();
      final summons = await _parentService.getMySummons();
      final children = await _parentService.getChildren();
      setState(() {
        _myRequests = requests;
        _summons = summons;
        _children = children;
      });
    } catch (e) {
      debugPrint("❌ Error loading appointments: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNewRequestBottomSheet() {
    final bool isAr = AppSettings.language.value == 'ar';
    int? selectedChildId;
    if (_children.isNotEmpty) {
      selectedChildId = int.tryParse(_children[0]['student_id']?.toString() ?? '');
    }

    final subjectController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime? selectedDate;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final selectedChild = _children.firstWhere(
              (c) => int.tryParse(c['student_id']?.toString() ?? '') == selectedChildId,
              orElse: () => null,
            );
            final String hodName = selectedChild?['hod_name'] ?? (isAr ? 'رئيس القسم المعني' : 'Concerned Dept Head');
            final String deptName = selectedChild?['department_name'] ?? '';

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Directionality(
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isAr ? "طلب موعد لقاء" : "Request a Meeting",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // 1. اختيار الابن المعني
                      Text(isAr ? "الابن المعني:" : "Concerned Child:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: selectedChildId,
                        dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: _children.map((child) {
                          final cId = int.tryParse(child['student_id']?.toString() ?? '');
                          return DropdownMenuItem<int>(
                            value: cId,
                            child: Text(child['full_name'] ?? (isAr ? 'بدون اسم' : 'No name')),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedChildId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. اسم رئيس القسم تبع الابن (تلقائي)
                      Text(isAr ? "رئيس القسم:" : "Department Head:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, color: Color(0xFFFFCC00)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "${isAr ? 'رئيس القسم :' : 'Dept Head:'} $hodName ${deptName.isNotEmpty ? '($deptName)' : ''}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. موضوع اللقاء
                      Text(isAr ? "موضوع اللقاء:" : "Meeting Subject:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          hintText: isAr ? "مثال: استفسار عن مستوى الطالب الدراسي" : "e.g., Inquiring about student's academic progress",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. تفاصيل أو السبب
                      Text(isAr ? "تفاصيل أو السبب:" : "Details or Reason:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: isAr ? "اكتب هنا تفاصيل المشكلة أو الاستفسار لتجهيز الملف..." : "Write details here so administration can prepare...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. التاريخ المفضل للزيارة
                      Text(isAr ? "التاريخ المفضل للزيارة:" : "Preferred Visit Date:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: modalContext,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                              sheetError = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDate != null
                                    ? intl.DateFormat('yyyy-MM-dd').format(selectedDate!)
                                    : (isAr ? "اختر التاريخ المفضل" : "Select preferred date"),
                                style: TextStyle(
                                  color: selectedDate != null
                                      ? (isDark ? Colors.white : Colors.black)
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xFFFFCC00)),
                            ],
                          ),
                        ),
                      ),
                      
                      if (sheetError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          sheetError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      
                      const SizedBox(height: 24),

                      // 6. زر الإرسال
                      ElevatedButton(
                        onPressed: () async {
                          debugPrint("🚀 [AppointmentsScreen] onPressed clicked!");
                          
                          if (subjectController.text.trim().isEmpty ||
                              reasonController.text.trim().isEmpty) {
                            setModalState(() {
                              sheetError = isAr
                                  ? "يرجى ملء جميع الحقول المطلوبة (الموضوع وتفاصيل الزيارة)"
                                  : "Please fill in all required fields (subject and details)";
                            });
                            return;
                          }

                          Navigator.pop(modalContext);
                          setState(() => _isLoading = true);

                          final success = await _parentService.requestMeeting(
                            subject: subjectController.text.trim(),
                            reason: reasonController.text.trim(),
                            studentId: selectedChildId,
                            targetPerson: 'hod',
                            preferredDate: selectedDate != null
                                ? intl.DateFormat('yyyy-MM-dd').format(selectedDate!)
                                : null,
                          );

                          if (success) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? "✅ تم إرسال طلب الموعد لرئيس القسم بنجاح" : "✅ Meeting request sent successfully"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadAllData();
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? "❌ فشل إرسال الطلب، يرجى المحاولة لاحقاً" : "❌ Failed to send request, please try again"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAr ? "إرسال طلب اللقاء" : "Send Meeting Request",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSummonResponse(int summonId, String status) async {
    final bool isAr = AppSettings.language.value == 'ar';
    setState(() => _isLoading = true);
    final success = await _parentService.respondToSummon(summonId, status);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'acknowledged'
              ? (isAr ? "✅ تم تأكيد حضورك وموافقتك للإدارة بنجاح" : "✅ Attendance confirmed successfully")
              : (isAr ? "✅ تم تسجيل اعتذارك للإدارة بنجاح" : "✅ Apology sent successfully")),
          backgroundColor: Colors.green,
        ),
      );
      _loadAllData();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? "❌ حدث خطأ أثناء إرسال ردك، حاول لاحقاً" : "❌ Error sending response, please try later"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAr = AppSettings.language.value == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? "اللقاءات والمواعيد" : "Meetings & Appointments",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(isAr ? Icons.arrow_back : Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFFCC00),
            labelColor: const Color(0xFFFFCC00),
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            tabs: [
              Tab(text: isAr ? "طلباتي (إلى الإدارة)" : "My Requests (To Admin)", icon: const Icon(Icons.person_pin)),
              Tab(text: isAr ? "دعوات الإدارة (الاستدعاءات)" : "Admin Summons", icon: const Icon(Icons.notifications_active)),
            ],
          ),
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                onPressed: _showNewRequestBottomSheet,
                backgroundColor: const Color(0xFFFFCC00),
                foregroundColor: Colors.black,
                child: const Icon(Icons.add, size: 28),
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMyRequestsTab(isDark, isAr),
                  _buildSummonsTab(isDark, isAr),
                ],
              ),
      ),
    );
  }

  String _myReqFilterStatus = 'all';

  List<dynamic> get _filteredMyRequests {
    if (_myReqFilterStatus == 'all') return _myRequests;
    if (_myReqFilterStatus == 'pending') {
      return _myRequests.where((r) => (r['status'] ?? '').toString() == 'pending').toList();
    }
    return _myRequests.where((r) => (r['status'] ?? '').toString() != 'pending').toList();
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _myReqFilterStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _myReqFilterStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFCC00)
                : (isDark ? Colors.white.withAlpha(18) : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFCC00).withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab(bool isDark, bool isAr) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                isAr ? "التصفية:" : "Filter:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterChip(isAr ? "الكل" : "All", "all", isDark),
              const SizedBox(width: 6),
              _buildFilterChip(isAr ? "المعلقة" : "Pending", "pending", isDark),
              const SizedBox(width: 6),
              _buildFilterChip(isAr ? "المكتملة/المعالجة" : "Completed", "completed", isDark),
            ],
          ),
        ),
        Expanded(
          child: _filteredMyRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 80, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? "لا توجد مواعيد في هذه القائمة حالياً." : "No appointments in this list currently.",
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showNewRequestBottomSheet,
                        icon: const Icon(Icons.add),
                        label: Text(isAr ? "اطلب موعداً الآن" : "Request Appointment Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredMyRequests.length,
                  itemBuilder: (context, index) {
                    final req = _filteredMyRequests[index];
                    final childName = _getChildName(req['student_id'], isAr);
                    final dateStr = req['preferred_date'] != null
                        ? intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(req['preferred_date']))
                        : (isAr ? 'غير محدد' : 'Not specified');
                    final status = req['status'] ?? 'pending';

                    Color statusColor = Colors.orange;
                    String statusText = isAr ? "قيد الانتظار" : "Pending";
                    if (status == 'approved') {
                      statusColor = Colors.green;
                      statusText = isAr ? "تمت الموافقة" : "Approved";
                    } else if (status == 'rejected') {
                      statusColor = Colors.red;
                      statusText = isAr ? "مرفوض" : "Rejected";
                    } else if (status == 'completed') {
                      statusColor = Colors.blue;
                      statusText = isAr ? "مكتمل" : "Completed";
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    req['subject'] ?? (isAr ? 'بدون عنوان' : 'Untitled'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${isAr ? 'بخصوص الطالب' : 'Regarding student'}: $childName",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (req['target_person'] == 'admin' ? Colors.blue : Colors.teal).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    req['target_person'] == 'admin'
                                        ? (isAr ? "الجهة: الإدارة العامة" : "Entity: General Admin")
                                        : (isAr ? "الجهة: رئيس القسم" : "Entity: Dept Head"),
                                    style: TextStyle(
                                      color: req['target_person'] == 'admin' ? Colors.blue : Colors.teal,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 4),
                            Text(
                              req['reason'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.event, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${isAr ? 'التاريخ المفضل' : 'Preferred date'}: $dateStr",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            if (req['scheduled_at'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.alarm_on, size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${isAr ? 'الموعد المثبت' : 'Scheduled time'}: ${_formatDateTime(req['scheduled_at'])}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (req['admin_response'] != null && req['admin_response'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade800),
                                ),
                                child: Text(
                                  "${isAr ? 'ملاحظة الإدارة' : 'Admin note'}: ${req['admin_response']}",
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummonsTab(bool isDark, bool isAr) {
    if (_summons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              isAr ? "لا توجد أي دعوات أو استدعاءات من الإدارة حالياً." : "No summons or invitations from admin currently.",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _summons.length,
      itemBuilder: (context, index) {
        final summon = _summons[index];
        final studentName = summon['student_name'] ?? (isAr ? 'بدون اسم' : 'Unnamed');
        final senderName = summon['sender_name'] ?? (isAr ? 'الإدارة' : 'Administration');
        final summonDate = summon['summon_date'] != null
            ? intl.DateFormat('yyyy-MM-dd').format(DateTime.parse(summon['summon_date']))
            : (isAr ? 'غير محدد' : 'Not specified');
        final status = summon['status'] ?? 'sent';

        Color statusColor = Colors.orange;
        String statusText = isAr ? "مرسل (بانتظار ردك)" : "Sent (Awaiting response)";
        if (status == 'acknowledged') {
          statusColor = Colors.green;
          statusText = isAr ? "تم الاطلاع وتأكيد الحضور" : "Attendance Confirmed";
        } else if (status == 'cancelled') {
          statusColor = Colors.red;
          statusText = isAr ? "معتذر عن الحضور" : "Declined Attendance";
        } else if (status == 'attended') {
          statusColor = Colors.blue;
          statusText = isAr ? "تم الحضور" : "Attended";
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        summon['reason_title'] ?? (isAr ? 'استدعاء ولي أمر' : 'Parent Summon'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${isAr ? 'المرسل' : 'Sender'}: $senderName | ${isAr ? 'بخصوص الطالب' : 'Regarding student'}: $studentName",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 4),
                Text(
                  summon['details'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      "${isAr ? 'التاريخ المطلوب' : 'Requested date'}: $summonDate",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (status == 'sent') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleSummonResponse(summon['id'], 'acknowledged'),
                          icon: const Icon(Icons.check),
                          label: Text(isAr ? "تأكيد الحضور" : "Confirm Attendance"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSummonResponse(summon['id'], 'cancelled'),
                          icon: const Icon(Icons.close),
                          label: Text(isAr ? "اعتذار عن الحضور" : "Decline Attendance"),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getChildName(dynamic id, bool isAr) {
    if (id == null) return isAr ? "كل الأبناء / عام" : "All Children / General";
    final match = _children.firstWhere(
      (c) => c['student_id']?.toString() == id.toString(),
      orElse: () => null,
    );
    return match != null ? match['full_name'] : (isAr ? "طالب غير معروف" : "Unknown student");
  }

  String _formatDateTime(String dtStr) {
    try {
      final parsed = DateTime.parse(dtStr);
      return intl.DateFormat('yyyy-MM-dd hh:mm A').format(parsed);
    } catch (_) {
      return dtStr;
    }
  }
}
