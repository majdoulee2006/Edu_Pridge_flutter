import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

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

  // ═══════════════════════════════════════
  // بطاقة الطالب
  // ═══════════════════════════════════════
  Widget _buildStudentCard(Map<String, dynamic> data) {
    final String initial = data['full_name'] != null && data['full_name'].isNotEmpty
        ? data['full_name'][0]
        : 'ط';
    final int userId = data['user_id'] ?? 0;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    'الرقم الجامعي الكود',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data['university_id'] ?? 'غير متوفر',
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
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
    );
  }
}