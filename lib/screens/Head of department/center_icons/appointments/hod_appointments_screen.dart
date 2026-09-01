import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class HodAppointmentsScreen extends StatefulWidget {
  const HodAppointmentsScreen({super.key});

  @override
  State<HodAppointmentsScreen> createState() => _HodAppointmentsScreenState();
}

class _HodAppointmentsScreenState extends State<HodAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ));

  bool _isLoading = true;
  List<dynamic> _meetings = [];
  List<dynamic> _summons = [];
  String _meetingsFilter = 'all'; // all, pending, completed
  String _summonsFilter = 'all';   // all, pending, completed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHodData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _loadHodData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final options = Options(headers: {'Authorization': 'Bearer $token'});

      // Fetch meetings
      final meetingsRes = await _dio.get('${ApiService().baseUrl}/department-head/appointments/meetings?status=$_meetingsFilter', options: options);
      // Fetch summons
      final summonsRes = await _dio.get('${ApiService().baseUrl}/department-head/appointments/summons?status=$_summonsFilter', options: options);

      if (mounted) {
        setState(() {
          if (meetingsRes.statusCode == 200 && meetingsRes.data['success'] == true) {
            _meetings = meetingsRes.data['data'] ?? [];
          }
          if (summonsRes.statusCode == 200 && summonsRes.data['success'] == true) {
            _summons = summonsRes.data['data'] ?? [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ HodAppointmentsScreen load error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFilterChips(String current, Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterChip(
            label: const Text('الكل'),
            selected: current == 'all',
            onSelected: (_) => onSelect('all'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('المعلقة'),
            selected: current == 'pending',
            onSelected: (_) => onSelect('pending'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('المنتهية'),
            selected: current == 'completed',
            onSelected: (_) => onSelect('completed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.teal.shade700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'مواعيد واستدعاءات رئيس القسم',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0.5,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.event_available_rounded), text: 'طلبات مواعيد أولياء الأمور'),
              Tab(icon: Icon(Icons.mark_email_read_rounded), text: 'استدعاءات الأهل والمدربين'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    children: [
                      _buildFilterChips(_meetingsFilter, (val) {
                        setState(() => _meetingsFilter = val);
                        _loadHodData();
                      }),
                      Expanded(child: _buildMeetingsList(isDark)),
                    ],
                  ),
                  Column(
                    children: [
                      _buildFilterChips(_summonsFilter, (val) {
                        setState(() => _summonsFilter = val);
                        _loadHodData();
                      }),
                      Expanded(child: _buildSummonsList(isDark)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMeetingsList(bool isDark) {
    if (_meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد مواعيد أولياء أمور مسجلة للقسم حالياً',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHodData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _meetings.length,
        itemBuilder: (context, index) {
          final item = _meetings[index] as Map<String, dynamic>;
          final parentName = item['parent_name'] ?? 'ولي الأمر';
          final studentName = item['student_name'] ?? 'الطالب';
          final subject = item['subject'] ?? '';
          final reason = item['reason'] ?? '';
          final status = (item['status'] ?? 'pending').toString().toLowerCase();
          final preferredDate = item['preferred_date']?.toString();
          final scheduledAt = item['scheduled_at']?.toString();
          final adminNotes = item['admin_response']?.toString();

          Color statusColor;
          String statusText;
          if (status == 'approved') {
            statusColor = Colors.green.shade600;
            statusText = 'موافق عليه ومحدد الموعد';
          } else if (status == 'rejected') {
            statusColor = Colors.red.shade600;
            statusText = 'مرفوض';
          } else {
            statusColor = Colors.orange.shade700;
            statusText = 'قيد المراجعة';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                    CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(Icons.person_rounded, color: Colors.teal.shade800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(parentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('ولي أمر الطالب: $studentName', style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 6),
                Text('الموضوع: $subject', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('التفاصيل: $reason', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                if (scheduledAt != null && scheduledAt.isNotEmpty) ...[
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
                          'الموعد المعتمد للزيارة: $scheduledAt',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ] else if (preferredDate != null && preferredDate.isNotEmpty) ...[
                  Text(
                    'التاريخ المفضل من الأهل: $preferredDate',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
                if (adminNotes != null && adminNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'ملاحظة الشؤون الإدارية: $adminNotes',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummonsList(bool isDark) {
    if (_summons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد استدعاءات في هذا الفلتر حالياً',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHodData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _summons.length,
        itemBuilder: (context, index) {
          final item = _summons[index] as Map<String, dynamic>;
          final studentName = item['student_name'] ?? 'الطالب';
          final teacherName = item['teacher_name'];
          final subject = item['reason_title'] ?? item['subject'] ?? 'استدعاء ولي أمر';
          final details = item['details'] ?? item['reason'] ?? '';
          final date = item['created_at']?.toString() ?? '';
          final status = (item['status'] ?? 'sent').toString();
          final summonId = item['summon_id'] ?? item['id'];

          final isTeacherSummon = (status == 'pending_hod');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('الطالب: $studentName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    if (isTeacherSummon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'طلب من المعلم',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                if (teacherName != null) ...[
                  const SizedBox(height: 4),
                  Text('المعلم المربي: $teacherName', style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 6),
                Text('السبب: $subject', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('التفاصيل: $details', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('تاريخ الطلب: ${date.split('T')[0]}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    if (isTeacherSummon)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () async {
                          final ok = await ApiService().forwardSummonToAffairs(summonId);
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم التحويل المباشر للشؤون بنجاح')),
                            );
                            _loadHodData();
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                        label: const Text('تحويل مباشر للشؤون', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
