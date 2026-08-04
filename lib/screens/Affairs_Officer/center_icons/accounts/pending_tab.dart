import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class PendingTab extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const PendingTab({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  State<PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<PendingTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final AffairsServices _affairsServices = AffairsServices();

  bool _isLoading = true;
  List<dynamic> _allRequests = [];
  List<dynamic> _studentRequests = [];
  List<dynamic> _parentRequests = [];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _affairsServices.getPendingAccounts();
      if (mounted) {
        setState(() {
          _allRequests = data ?? [];
          _studentRequests = _allRequests.where((r) => r['role'] == 'student').toList();
          _parentRequests = _allRequests.where((r) => r['role'] == 'parent').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading pending requests: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleApprove(int userId) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
        ),
      ),
    );

    final success = await _affairsServices.approveAccount(userId);
    if (!mounted) return;
    Navigator.pop(context); // Pop loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل الحساب والموافقة بنجاح', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: Colors.green,
        ),
      );
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تفعيل الحساب، يرجى المحاولة لاحقاً', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(int userId) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الرفض', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          content: const Text('هل أنت متأكد من رفض وحذف هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم، ارفض', style: TextStyle(fontFamily: 'Noto Sans Arabic', color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
        ),
      ),
    );

    final success = await _affairsServices.rejectAccount(userId);
    if (!mounted) return;
    Navigator.pop(context); // Pop loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض الطلب وحذفه بنجاح', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: Colors.orange,
        ),
      );
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل رفض الطلب، يرجى المحاولة لاحقاً', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ═══════════════════════════════════════
        // عنوان + عداد
        // ═══════════════════════════════════════
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "طلبات جديدة معلقة",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_allRequests.length} طلبات',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
              ),
            ],
          ),
        ),

        // ═══════════════════════════════════════
        // التبويبات السفلية (طالب / ولي أمر)
        // ═══════════════════════════════════════
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TabBar(
            controller: _subTabController,
            indicator: BoxDecoration(
              color: const Color(0xFFFFCC00),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFCC00).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.black,
            unselectedLabelColor: widget.subColor,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Noto Sans Arabic',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Noto Sans Arabic',
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'طالب'),
              Tab(text: 'ولي أمر'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ═══════════════════════════════════════
        // محتوى التبويبات السفلية
        // ═══════════════════════════════════════
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
                  ),
                )
              : TabBarView(
                  controller: _subTabController,
                  children: [
                    _buildStudentList(),
                    _buildParentList(),
                  ],
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // قائمة الطلاب
  // ═══════════════════════════════════════
  Widget _buildStudentList() {
    if (_studentRequests.isEmpty) {
      return Center(
        child: Text(
          "لا توجد طلبات طلاب معلقة حالياً",
          style: TextStyle(color: widget.subColor, fontSize: 14, fontFamily: 'Noto Sans Arabic'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: const Color(0xFFFFCC00),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
        itemCount: _studentRequests.length,
        itemBuilder: (context, index) {
          return _buildStudentCard(_studentRequests[index]);
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // قائمة أولياء الأمور
  // ═══════════════════════════════════════
  Widget _buildParentList() {
    if (_parentRequests.isEmpty) {
      return Center(
        child: Text(
          "لا توجد طلبات أولياء أمور معلقة حالياً",
          style: TextStyle(color: widget.subColor, fontSize: 14, fontFamily: 'Noto Sans Arabic'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: const Color(0xFFFFCC00),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
        itemCount: _parentRequests.length,
        itemBuilder: (context, index) {
          return _buildParentCard(_parentRequests[index]);
        },
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> data) {
    final avatarUrl = ApiService.fixMediaUrl(data['avatar']);
    final int userId = data['user_id'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    data['full_name'] ?? 'بدون اسم',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('البريد الإلكتروني', data['email'] ?? 'غير متوفر', Icons.email),
                _buildDetailRow('رقم الهاتف', data['phone'] ?? 'غير متوفر', Icons.phone),
                _buildDetailRow('تاريخ الميلاد', data['birth_date'] ?? 'غير متوفر', Icons.calendar_today),
                _buildDetailRow('الجنس', data['gender'] ?? 'غير متوفر', Icons.person),
                if (data['role'] == 'student') ...[
                  _buildDetailRow('القسم', data['department'] ?? 'غير متوفر', Icons.school),
                  _buildDetailRow('الفرع', data['branch'] ?? 'غير متوفر', Icons.account_tree),
                  _buildDetailRow('السنة الدراسية', data['academic_year'] ?? 'غير متوفر', Icons.timeline),
                  _buildDetailRow('معرّف تليجرام', data['telegram_chat_id'] ?? 'غير متوفر', Icons.send),
                  _buildDetailRow(
                    'الرقم الجامعي',
                    (data['university_id'] != null && data['university_id'].toString().isNotEmpty)
                        ? data['university_id']
                        : 'سيتم توليده تلقائياً عند الموافقة ✨',
                    Icons.badge,
                  ),
                ],
                const SizedBox(height: 24),

                // زري الإجراءات (موافقة / رفض)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleReject(userId);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'رفض الطلب',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleApprove(userId);
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                        label: const Text(
                          'موافقة وتفعيل',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFFFCC00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.subColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // بطاقة الطالب (صورة + اسم فقط)
  // ═══════════════════════════════════════
  Widget _buildStudentCard(Map<String, dynamic> data) {
    final String initial = data['full_name'] != null && data['full_name'].isNotEmpty
        ? data['full_name'][0]
        : 'ط';
    final String? avatarUrl = ApiService.fixMediaUrl(data['avatar']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showUserDetails(data),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    data['full_name'] ?? 'بدون اسم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: widget.subColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // بطاقة ولي الأمر
  // ═══════════════════════════════════════
  Widget _buildParentCard(Map<String, dynamic> data) {
    final String initial = data['full_name'] != null && data['full_name'].isNotEmpty
        ? data['full_name'][0]
        : 'أ';
    final int userId = data['user_id'] ?? 0;
    final String? avatarUrl = ApiService.fixMediaUrl(data['avatar']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showUserDetails(data),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['full_name'] ?? 'بدون اسم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['email'] ?? 'بدون بريد إلكتروني',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: widget.subColor),
                          const SizedBox(width: 4),
                          Text(
                            data['created_at'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.subColor,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReject(userId),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.subColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'رفض',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(userId),
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text(
                      'موافقة وتفعيل',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}