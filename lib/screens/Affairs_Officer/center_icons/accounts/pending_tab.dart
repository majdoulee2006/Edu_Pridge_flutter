import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

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

  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _subTabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
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
        SnackBar(
          content: Text(
            isAr ? 'تم تفعيل الحساب والموافقة بنجاح' : 'Account approved and activated successfully',
            style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'فشل تفعيل الحساب، يرجى المحاولة لاحقاً' : 'Failed to activate account, please try again later',
            style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
          ),
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
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'تأكيد الرفض' : 'Confirm Rejection', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          content: Text(
            isAr
                ? 'هل أنت متأكد من رفض وحذف هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.'
                : 'Are you sure you want to reject and delete this request? This action cannot be undone.',
            style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                isAr ? 'نعم، ارفض' : 'Yes, Reject',
                style: const TextStyle(fontFamily: 'Noto Sans Arabic', color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;
if (!mounted) return;

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
        SnackBar(
          content: Text(
            isAr ? 'تم رفض الطلب وحذفه بنجاح' : 'Request rejected and deleted successfully',
            style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'فشل رفض الطلب، يرجى المحاولة لاحقاً' : 'Failed to reject request, please try again later',
            style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
          ),
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
                isAr ? "طلبات جديدة معلقة" : "New Pending Requests",
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
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAr ? '${_allRequests.length} طلبات' : '${_allRequests.length} Requests',
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
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
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
            tabs: [
              Tab(text: isAr ? 'طالب' : 'Student'),
              Tab(text: isAr ? 'ولي أمر' : 'Parent'),
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
          isAr ? "لا توجد طلبات طلاب معلقة حالياً" : "No pending student requests currently",
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
          isAr ? "لا توجد طلبات أولياء أمور معلقة حالياً" : "No pending parent requests currently",
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
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
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
                    data['full_name'] ?? (isAr ? 'بدون اسم' : 'Unnamed'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow(isAr ? 'البريد الإلكتروني' : 'Email Address', data['email'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.email),
                _buildDetailRow(isAr ? 'رقم الهاتف' : 'Phone Number', data['phone'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.phone),
                _buildDetailRow(isAr ? 'تاريخ الميلاد' : 'Date of Birth', data['birth_date'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.calendar_today),
                _buildDetailRow(isAr ? 'الجنس' : 'Gender', data['gender'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.person),
                if (data['role'] == 'student') ...[
                  _buildDetailRow(isAr ? 'القسم' : 'Department', data['department'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.school),
                  _buildDetailRow(isAr ? 'الفرع' : 'Branch', data['branch'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.account_tree),
                  _buildDetailRow(isAr ? 'السنة الدراسية' : 'Academic Year', data['academic_year'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.timeline),
                  _buildDetailRow(isAr ? 'معرّف تليجرام' : 'Telegram Chat ID', data['telegram_chat_id'] ?? (isAr ? 'غير متوفر' : 'N/A'), Icons.send),
                  _buildDetailRow(
                    isAr ? 'الرقم الجامعي' : 'University ID',
                    (data['university_id'] != null && data['university_id'].toString().isNotEmpty)
                        ? data['university_id']
                        : (isAr ? 'سيتم توليده تلقائياً عند الموافقة ✨' : 'Will be auto-generated upon approval ✨'),
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
                        child: Text(
                          isAr ? 'رفض الطلب' : 'Reject Request',
                          style: const TextStyle(
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
                        label: Text(
                          isAr ? 'موافقة وتفعيل' : 'Approve & Activate',
                          style: const TextStyle(
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
        : (isAr ? 'ط' : 'S');
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
                    data['full_name'] ?? (isAr ? 'بدون اسم' : 'Unnamed'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                Icon(
                  isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
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
        : (isAr ? 'أ' : 'P');
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
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
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
                        data['full_name'] ?? (isAr ? 'بدون اسم' : 'Unnamed'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['email'] ?? (isAr ? 'بدون بريد إلكتروني' : 'No Email'),
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
                      side: BorderSide(color: widget.subColor.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isAr ? 'رفض' : 'Reject',
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
                    label: Text(
                      isAr ? 'موافقة وتفعيل' : 'Approve & Activate',
                      style: const TextStyle(
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