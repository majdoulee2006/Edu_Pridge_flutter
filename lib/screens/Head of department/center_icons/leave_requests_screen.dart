import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';

class LeaveRequestsScreen extends StatefulWidget {
  final String fromSource;
  final int? highlightId;

  const LeaveRequestsScreen({super.key, this.fromSource = "home", this.highlightId});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  bool isDailyLeave = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> allRequests = [];
  final ScrollController _scrollController = ScrollController();

  bool get isAr => AppSettings.language.value == 'ar';

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  void _handleBackNavigation(BuildContext context) {
    if (widget.fromSource == "profile") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossProfileScreen()));
    } else if (widget.fromSource == "notification") {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _fetchLeaveRequests();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await Dio().get(
        "${ApiService().baseUrl}/department-head/leave-requests",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        setState(() {
          allRequests = data.map<Map<String, dynamic>>((r) {
            final typeVal = (r['type'] ?? '').toString();
            final isDaily = typeVal == 'full_day' || typeVal == 'daily' || typeVal == 'يوم كامل' || typeVal.isEmpty;
            return {
              'id': r['id'],
              'name': r['requester_name'] ?? r['user_name'] ?? r['name'] ?? '',
              'role': r['requester_type'] ?? r['role'] ?? '',
              'date': r['date'] ?? '',
              'reason': r['reason'] ?? '',
              'status': r['status'] ?? 'pending',
              'type': isDaily ? 'daily' : 'hourly',
              'isDaily': isDaily,
              'image': r['avatar'] ?? '',
            };
          }).toList();
        });

        if (widget.highlightId != null) {
          _jumpToHighlighted();
        }
      }
    } catch (e) {
      debugPrint('⛔ Leave Requests Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _jumpToHighlighted() {
    final req = allRequests.firstWhere(
      (r) => r['id'] == widget.highlightId,
      orElse: () => {},
    );
    if (req.isEmpty) return;

    final isDaily = req['isDaily'] as bool? ?? true;
    if (isDailyLeave != isDaily) {
      setState(() => isDailyLeave = isDaily);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filtered = allRequests.where((r) => r['isDaily'] == isDaily).toList();
      final idx = filtered.indexWhere((r) => r['id'] == widget.highlightId);
      if (idx >= 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          idx * 200.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _respondToRequest(int requestId, String status) async {
    try {
      final token = await _getToken();
      await Dio().put(
        "${ApiService().baseUrl}/department-head/leave-requests/$requestId/respond",
        data: {'status': status},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (mounted) {
        setState(() {
          final idx = allRequests.indexWhere((r) => r['id'] == requestId);
          if (idx != -1) {
            allRequests[idx] = {...allRequests[idx], 'status': status};
          }
        });
        final msg = status == 'approved'
            ? (isAr ? '✅ تمت الموافقة' : '✅ Approved')
            : (isAr ? '❌ تم الرفض' : '❌ Rejected');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('⛔ Respond Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, please try again')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    final filteredRequests = allRequests.where((req) => req['isDaily'] == isDailyLeave).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context, isDark, textColor),
                  const SizedBox(height: 10),
                  _buildToggleTab(cardColor),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFCCAA00)))
                        : filteredRequests.isEmpty
                            ? Center(child: Text(isAr ? "لا توجد طلبات حالياً" : "No requests found", style: TextStyle(color: textColor)))
                            : RefreshIndicator(
                                onRefresh: _fetchLeaveRequests,
                                color: const Color(0xFFCCAA00),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: filteredRequests.length,
                                  itemBuilder: (context, index) {
                                    final req = filteredRequests[index];
                                    final isHighlighted = widget.highlightId != null && req['id'] == widget.highlightId;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 15),
                                      child: _buildLeaveCard(isDark, cardColor, textColor, req, isHighlighted),
                                    );
                                  },
                                ),
                              ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),

              CustomBottomNav(
                currentIndex: widget.fromSource == "profile" ? 1 : 0,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossNotificationScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
                userName: isAr ? "رئيس القسم" : "Department Head",
                userRole: isAr ? "رئيس القسم الأكاديمي" : "Academic Department Head",
                onProfileTap: () => Navigator.pop(context),
              )));
            },
          ),
          Text(
            isAr ? "طلبات الإجازة" : "Leave Requests",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: Icon(isAr ? Icons.arrow_forward : Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => _handleBackNavigation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(Color cardColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          _buildTabButton(isAr ? "إجازات يومية" : "Daily Leaves", isDailyLeave, () => setState(() => isDailyLeave = true)),
          _buildTabButton(isAr ? "إجازات ساعية" : "Hourly Leaves", !isDailyLeave, () => setState(() => isDailyLeave = false)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFCC00) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveCard(bool isDark, Color cardColor, Color textColor, Map<String, dynamic> data, bool isHighlighted) {
    final String rawName = (data['name'] ?? '').toString();
    final String name = rawName.isNotEmpty ? rawName : (isAr ? 'غير معروف' : 'Unknown');
    final String role = (data['role'] ?? '').toString();
    final String image = (data['image'] ?? '').toString();
    final String rawReason = (data['reason'] ?? '').toString();
    final String reason = rawReason.isNotEmpty ? rawReason : (isAr ? 'لا يوجد سبب' : 'No reason provided');
    final bool isDaily = data['isDaily'] as bool? ?? true;
    final String type = isDaily ? (isAr ? 'يوم كامل' : 'Full Day') : (isAr ? 'ساعية' : 'Hourly');
    final String status = (data['status'] ?? 'pending').toString();
    final int requestId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;
    final bool isPending = status == 'pending_hod' || status == 'pending' || status == 'pending_parent';
    final bool isRejected = status == 'rejected';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: isHighlighted ? Border.all(color: const Color(0xFFFFCC00), width: 2.5) : null,
        boxShadow: [
          if (isHighlighted)
            const BoxShadow(color: Color(0x55FFCC00), blurRadius: 15, spreadRadius: 1)
          else
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFCCAA00),
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty
                    ? Text(name.isNotEmpty ? name[0] : '؟',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  if (role.isNotEmpty) Text(role, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(type, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(reason, style: TextStyle(fontSize: 14, height: 1.4, color: textColor)),
          ),
          const SizedBox(height: 15),
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToRequest(requestId, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(isAr ? "موافقة" : "Approve", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToRequest(requestId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(isAr ? "رفض" : "Reject", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isRejected
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  isRejected
                      ? (isAr ? '❌ تم رفض الطلب' : '❌ Request Rejected')
                      : (isAr ? '✅ تمت الموافقة' : '✅ Approved'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRejected ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
