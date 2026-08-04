import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';

class AffairsOfficerVacationsScreen extends StatefulWidget {
  const AffairsOfficerVacationsScreen({super.key});

  @override
  State<AffairsOfficerVacationsScreen> createState() => _AffairsOfficerVacationsScreenState();
}

class _AffairsOfficerVacationsScreenState extends State<AffairsOfficerVacationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AffairsServices _affairsServices = AffairsServices();

  bool _isLoading = true;
  List<dynamic> _allLeaves = [];
  List<dynamic> _pendingLeaves = [];
  List<dynamic> _historyLeaves = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaves() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _affairsServices.getLeaves();
      if (mounted) {
        setState(() {
          _allLeaves = data ?? [];
          _pendingLeaves = _allLeaves.where((l) => l['status'] == 'pending' || l['status'] == 'pending_affairs').toList();
          _historyLeaves = _allLeaves.where((l) => l['status'] == 'approved' || l['status'] == 'rejected').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading leaves: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUpdateStatus(int leaveId, String status) async {
    final bool isApprove = status == 'approved';
    final String label = isApprove ? 'موافقة' : 'رفض';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
        ),
      ),
    );

    final success = await _affairsServices.updateLeaveStatus(leaveId, status);

    if (!mounted) return;
    Navigator.pop(context); // Pop loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الـ $label بنجاح ✓', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: isApprove ? Colors.green : Colors.orange,
        ),
      );
      _loadLeaves();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الـ $label، يرجى المحاولة لاحقاً', style: const TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // الهيدر
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) => _loadLeaves());
                            },
                          ),
                        ),
                        Text(
                          "طلبات إجازة الطلاب",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // التبويبات: طلبات معلقة | سجل الإجازات
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
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
                      unselectedLabelColor: subColor,
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
                        Tab(text: 'طلبات معلقة'),
                        Tab(text: 'سجل الإجازات'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // محتوى التبويبات
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildVacationList(
                                _pendingLeaves,
                                isHistory: false,
                                cardColor: cardColor,
                                textColor: textColor,
                                subColor: subColor,
                                isDark: isDark,
                              ),
                              _buildVacationList(
                                _historyLeaves,
                                isHistory: true,
                                cardColor: cardColor,
                                textColor: textColor,
                                subColor: subColor,
                                isDark: isDark,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            // شريط التنقل السفلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen()),
                );
              },
              onProfileTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerProfileScreen()),
                );
              },
              onNotificationsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen()),
                );
              },
              onMessagesTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerMessagesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacationList(
    List<dynamic> leaves, {
    required bool isHistory,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
  }) {
    if (leaves.isEmpty) {
      return Center(
        child: Text(
          isHistory ? "سجل الإجازات فارغ" : "لا توجد طلبات إجازة معلقة حالياً",
          style: TextStyle(color: subColor, fontSize: 14, fontFamily: 'Noto Sans Arabic'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaves,
      color: const Color(0xFFFFCC00),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
        itemCount: leaves.length,
        itemBuilder: (context, index) {
          return _buildVacationCard(
            leaves[index],
            isHistory: isHistory,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildVacationCard(
    Map<String, dynamic> data, {
    required bool isHistory,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
  }) {
    final String initial = data['student_name'] != null && data['student_name'].isNotEmpty
        ? data['student_name'][0]
        : 'ط';
    final int leaveId = data['id'] ?? 0;
    final String status = data['status'] ?? 'pending';

    Color statusColor = Colors.orange;
    String statusLabel = 'قيد المراجعة';
    if (status == 'approved') {
      statusColor = Colors.green;
      statusLabel = 'مقبول';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'مرفوض';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['created_at'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data['student_name'] ?? 'طالب غير معروف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'معرف الطالب: ${data['student_id']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: subColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'التاريخ المستهدف: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        data['date'] ?? 'غير محدد',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: subColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'السبب: ${data['reason']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: subColor,
                            height: 1.5,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (isHistory)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'الحالة: $statusLabel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleUpdateStatus(leaveId, 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      label: const Text(
                        'رفض الإجازة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleUpdateStatus(leaveId, 'approved'),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text(
                        'قبول الإجازة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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