import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AffairsAppointmentsScreen extends StatefulWidget {
  const AffairsAppointmentsScreen({super.key});

  @override
  State<AffairsAppointmentsScreen> createState() => _AffairsAppointmentsScreenState();
}

class _AffairsAppointmentsScreenState extends State<AffairsAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AffairsServices _affairsServices = AffairsServices();

  bool _isLoadingMeetings = true;
  bool _isLoadingSummons = true;
  List<dynamic> _meetings = [];
  List<dynamic> _summons = [];
  String _filterStatus = 'all';

  // Metadata for summon creation
  List<dynamic> _studentsList = [];
  bool _isLoadingMetadata = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeetings();
    _loadSummons();
    _loadMetadata();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoadingMeetings = true);
    final data = await _affairsServices.getMeetingRequests();
    if (mounted) {
      setState(() {
        _meetings = data ?? [];
        _isLoadingMeetings = false;
      });
    }
  }

  Future<void> _loadSummons() async {
    setState(() => _isLoadingSummons = true);
    final data = await _affairsServices.getSummons();
    if (mounted) {
      setState(() {
        _summons = data ?? [];
        _isLoadingSummons = false;
      });
    }
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoadingMetadata = true);
    final data = await _affairsServices.getAppointmentsMetadata();
    if (mounted) {
      setState(() {
        if (data != null && data['students'] != null) {
          _studentsList = data['students'] as List<dynamic>;
        }
        _isLoadingMetadata = false;
      });
    }
  }

  List<dynamic> get _filteredMeetings {
    if (_filterStatus == 'all') return _meetings;
    return _meetings.where((m) => (m['status'] ?? 'pending').toString().toLowerCase() == _filterStatus).toList();
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.orange.shade800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'مواعيد واستدعاءات الشؤون',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0.5,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(icon: Icon(Icons.event_available_rounded), text: 'طلبات المواعيد الواردة'),
              Tab(icon: Icon(Icons.send_rounded), text: 'الاستدعاءات الرسمية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMeetingsTab(isDark),
            _buildSummonsTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsTab(bool isDark) {
    if (_isLoadingMeetings) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMeetings,
      child: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            child: Row(
              children: [
                const Text(
                  'التصفية:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', 'all', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('قيد المراجعة', 'pending', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('مقبولة', 'approved', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('مرفوضة', 'rejected', isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _filteredMeetings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات مواعيد حالياً',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMeetings.length,
                    itemBuilder: (context, index) {
                      final item = _filteredMeetings[index] as Map<String, dynamic>;
                      return _buildMeetingCard(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey, bool isDark) {
    final isSelected = _filterStatus == statusKey;
    final primaryColor = Colors.orange.shade800;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = statusKey);
      },
      selectedColor: primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> item, bool isDark) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final parentName = item['parent_name'] ?? 'ولي الأمر';
    final studentName = item['student_name'] ?? 'الطالب';
    final hodName = item['hod_name'] ?? 'رئيس القسم المعني';
    final subject = item['subject'] ?? 'بدون عنوان';
    final reason = item['reason'] ?? '';
    final preferredDate = item['preferred_date']?.toString();
    final scheduledAt = item['scheduled_at']?.toString();
    final adminNotes = item['admin_response']?.toString();
    final meetingId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'approved') {
      statusColor = Colors.green.shade600;
      statusText = 'مقبول ومحدد';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.red.shade600;
      statusText = 'مرفوض';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.orange.shade700;
      statusText = 'قيد المراجعة';
      statusIcon = Icons.pending_actions_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                if (item['created_at'] != null)
                  Text(
                    item['created_at'].toString().split(' ')[0],
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parent & Student Info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(Icons.person_rounded, color: Colors.orange.shade800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ولي أمر الطالب: $studentName',
                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // HOD Target
                Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 18, color: Colors.teal.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'المقابل المستهدف: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                    ),
                    Expanded(
                      child: Text(
                        'رئيس القسم ($hodName)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subject & Reason
                Text(
                  'الموضوع: $subject',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'السبب/التفاصيل: $reason',
                    style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),

                // Preferred Date
                if (preferredDate != null && preferredDate.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          'التاريخ المفضل من الأهل: $preferredDate',
                          style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // Confirmed Scheduled Date
                if (scheduledAt != null && scheduledAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'الموعد المحدد النهائي: $scheduledAt',
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                // Admin Notes if rejected/approved with notes
                if (adminNotes != null && adminNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ملاحظة الشؤون: $adminNotes',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: status == 'rejected' ? Colors.red.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],

                // Action Buttons for Pending Requests
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleApprove(meetingId, preferredDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('موافقة وتحديد موعد', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleReject(meetingId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('رفض الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleApprove(int meetingId, String? preferredDate) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    if (preferredDate != null && preferredDate.isNotEmpty) {
      final parsed = DateTime.tryParse(preferredDate);
      if (parsed != null) selectedDate = parsed;
    }

    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الموافقة على الطلب وتأكيد الموعد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preferredDate != null
                          ? 'التاريخ المفضل للأهل: $preferredDate. يمكنك تغييره أو اعتماده:'
                          : 'حدد موعد الزيارة المناسب لمقابلة رئيس القسم:',
                      style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Tile
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      leading: const Icon(Icons.calendar_month_rounded, color: Colors.green),
                      title: const Text('الموعد المحدد النهائي:'),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: sheetContext,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (pickedDate != null) {
                            final pickedTime = await showTimePicker(
                              context: sheetContext,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (pickedTime != null) {
                              setSheetState(() {
                                selectedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        child: const Text('تغيير التاريخ/الوقت'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optional Notes
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات موجه للأهل ورئيس القسم (اختياري)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setSheetState(() => isSubmitting = true);
                                final scheduledStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate);
                                final success = await _affairsServices.respondToMeetingRequest(
                                  meetingId,
                                  status: 'approved',
                                  scheduledAt: scheduledStr,
                                  adminResponse: notesController.text.trim(),
                                );
                                if (mounted) {
                                  Navigator.pop(sheetContext);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تمت الموافقة وتأكيد الموعد وإشعارهما بنجاح')),
                                    );
                                    _loadMeetings();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('حدث خطأ أثناء معالجة الطلب')),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('تأكيد الموافقة وإرسال الإشعارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleReject(int meetingId) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('رفض طلب الموعد', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('هل أنت أثق من عدم موافقة الشؤون على هذا الموعد؟'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'سبب الرفض (اختياري)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final success = await _affairsServices.respondToMeetingRequest(
                            meetingId,
                            status: 'rejected',
                            adminResponse: reasonController.text.trim(),
                          );
                          if (mounted) {
                            Navigator.pop(dialogContext);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم رفض الطلب وإرسال الإشعار لولي الأمر ورئيس القسم')),
                              );
                              _loadMeetings();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('حدث خطأ أثناء معالجة الطلب')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('تأكيد الرفض', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _summonFilterStatus = 'all';

  List<dynamic> get _filteredSummons {
    if (_summonFilterStatus == 'all') return _summons;
    if (_summonFilterStatus == 'pending') {
      return _summons.where((s) => (s['status'] ?? '').toString() == 'pending_affairs' || (s['status'] ?? '').toString() == 'pending_hod').toList();
    }
    return _summons.where((s) => (s['status'] ?? '').toString() == 'sent' || (s['status'] ?? '').toString() == 'approved' || (s['status'] ?? '').toString() == 'completed').toList();
  }

  Widget _buildSummonsTab(bool isDark) {
    if (_isLoadingSummons) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSummonSheet,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إصدار استدعاء جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummons,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  const Text('التصفية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('الكل'),
                            selected: _summonFilterStatus == 'all',
                            onSelected: (_) => setState(() => _summonFilterStatus = 'all'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('المعلقة'),
                            selected: _summonFilterStatus == 'pending',
                            onSelected: (_) => setState(() => _summonFilterStatus = 'pending'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('المنتهية / الصادرة'),
                            selected: _summonFilterStatus == 'completed',
                            onSelected: (_) => setState(() => _summonFilterStatus = 'completed'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _filteredSummons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_read_rounded, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد استدعاءات في هذا الفلتر حالياً',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSummons.length,
                      itemBuilder: (context, index) {
                        final item = _filteredSummons[index] as Map<String, dynamic>;
                        return _buildSummonCard(item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummonCard(Map<String, dynamic> item, bool isDark) {
    final studentName = item['student_name'] ?? 'الطالب';
    final parentName = item['parent_name'] ?? 'ولي الأمر المعني';
    final subject = item['subject'] ?? 'استدعاء ولي أمر';
    final reason = item['reason'] ?? '';
    final date = item['date']?.toString().split(' ')[0] ?? item['created_at']?.toString().split('T')[0] ?? '';
    final time = item['time'] ?? '';
    final status = (item['status'] ?? '').toString();
    final summonId = item['summon_id'] ?? item['id'];
    final isPendingAffairs = (status == 'pending_affairs');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.assignment_ind_rounded, color: Colors.orange.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'استدعاء ولي أمر: $studentName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'المستلم: $parentName',
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                ),
              if (date.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$date $time',
                    style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          Text(
            'العنوان: $subject',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'السبب: $reason',
              style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 12),
            ),
          ],
          if (isPendingAffairs) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _handleIssueSummon(summonId),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('اعتماد وإصدار الموعد لولي الأمر', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleIssueSummon(int summonId) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اعتماد وتاريخ الاستدعاء الرسمي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    leading: const Icon(Icons.calendar_today, color: Colors.orange),
                    title: const Text('تاريخ الحضور المحدد لولي الأمر:'),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: sheetCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (d != null) {
                        final t = await showTimePicker(
                          context: sheetCtx,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (t != null) {
                          setSheetState(() {
                            selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات إضافية (اختياري)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() => isSubmitting = true);
                              final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDate);
                              final ok = await ApiService().issueParentSummon(
                                summonId,
                                formatted,
                                notes: notesController.text.trim(),
                              );
                              if (mounted) {
                                Navigator.pop(sheetCtx);
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم إصدار الاستدعاء رسمياً وإشعار ولي الأمر والمعلم')),
                                  );
                                  _loadSummons();
                                }
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('اعتماد وإرسال الإشعار لولي الأمر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateSummonSheet() {
    int? selectedStudentId;
    final subjectController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'إصدار استدعاء رسمي لولي الأمر',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Student Dropdown
                      const Text('اختر الطالب المعني:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: selectedStudentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('حدد الطالب...'),
                        items: _studentsList.map((st) {
                          final name = st['student_name'] ?? 'طالب';
                          final parent = st['parent_name'] ?? 'ولي أمر غير مسجل';
                          final id = int.tryParse(st['student_id']?.toString() ?? '0');
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('$name (الأهل: $parent)'),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() => selectedStudentId = val),
                      ),
                      const SizedBox(height: 12),

                      // Subject
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          labelText: 'عنوان/موضوع الاستدعاء',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Reason/Details
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: 'تفاصيل السبب أو الملاحظات',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Date & Time pickers
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              title: const Text('تاريخ الحضور', style: TextStyle(fontSize: 12)),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: sheetContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 60)),
                                );
                                if (d != null) setSheetState(() => selectedDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              title: const Text('الوقت', style: TextStyle(fontSize: 12)),
                              subtitle: Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: sheetContext,
                                  initialTime: selectedTime,
                                );
                                if (t != null) setSheetState(() => selectedTime = t);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (selectedStudentId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('يرجى اختيار الطالب أولاً')),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSubmitting = true);
                                  final timeFormatted = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                                  final success = await _affairsServices.storeSummon({
                                    'student_id': selectedStudentId,
                                    'subject': subjectController.text.trim(),
                                    'reason': reasonController.text.trim(),
                                    'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                                    'time': timeFormatted,
                                  });

                                  if (mounted) {
                                    Navigator.pop(sheetContext);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم إصدار وإرسال الاستدعاء بنجاح')),
                                      );
                                      _loadSummons();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('حدث خطأ أثناء إصدار الاستدعاء')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('إرسال الاستدعاء لولي الأمر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
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
}
