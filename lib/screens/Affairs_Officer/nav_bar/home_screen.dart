import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/calendar/calendar_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/activities/activities_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/vacations/vacations_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/accounts/accounts_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';

class AffairsOfficerHomeScreen extends StatefulWidget {
  const AffairsOfficerHomeScreen({super.key});

  @override
  State<AffairsOfficerHomeScreen> createState() => _AffairsOfficerHomeScreenState();
}

class _AffairsOfficerHomeScreenState extends State<AffairsOfficerHomeScreen> {
  final AffairsServices _affairsServices = AffairsServices();
  bool _isLoading = true;
  String _officerName = '';
  Map<String, dynamic>? _stats;
  List<dynamic> _posts = [];

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final statsData = await _affairsServices.getDashboardStats();
      final profileData = await _affairsServices.getProfile();

      if (mounted) {
        setState(() {
          if (statsData != null) {
            _stats = statsData['stats'];
            _posts = statsData['posts'] ?? [];
          }
          if (profileData != null && profileData['user'] != null) {
            _officerName = profileData['user']['full_name'] ?? '';
          } else {
            _officerName = 'موظف الشؤون';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    AppSettings.language.addListener(_onLangChange);
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    final isAr = AppSettings.language.value == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- الهيدر ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? "أهلاً، ${_officerName.isNotEmpty ? _officerName : 'موظف الشؤون'}"
                                  : "Hello, ${_officerName.isNotEmpty ? _officerName : 'Affairs Officer'}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFCC00),
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr ? "لوحة تحكم شؤون الطلاب" : "Student Affairs Dashboard",
                              style: TextStyle(
                                fontSize: 13,
                                color: subColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Color(0xFFFFCC00),
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            ).then((_) => _loadDashboardData());
                          },
                        ),
                      ],
                    ),
                  ),

                  // --- اختصارات سريعة (سكرول أفقي) ---
                  SizedBox(
                    height: 105,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildShortcut(
                          context,
                          Icons.manage_accounts_outlined,
                          'الحسابات',
                          const Color(0xFFFFCC00),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AffairsOfficerAccountsScreen()),
                          ).then((_) => _loadDashboardData()),
                        ),
                        _buildShortcut(
                          context,
                          Icons.event_available_outlined,
                          'الإجازات',
                          const Color(0xFF4DB6AC),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AffairsOfficerVacationsScreen()),
                          ).then((_) => _loadDashboardData()),
                        ),
                        _buildShortcut(
                          context,
                          Icons.calendar_month_outlined,
                          'التقويم',
                          const Color(0xFF7E57C2),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AffairsOfficerCalendarScreen()),
                          ).then((_) => _loadDashboardData()),
                        ),
                        _buildShortcut(
                          context,
                          Icons.local_activity_outlined,
                          'الأنشطة',
                          const Color(0xFFEF5350),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AffairsOfficerActivitiesScreen()),
                          ).then((_) => _loadDashboardData()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- المحتوى ---
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDashboardData,
                            color: const Color(0xFFFFCC00),
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                              children: [
                                // قسم الإحصائيات
                                _buildStatsGrid(cardColor, textColor, subColor),
                                const SizedBox(height: 24),

                                // عنوان الإعلانات/الأخبار
                                Row(
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
                                      isAr ? "آخر الإعلانات والأخبار" : "Latest Announcements",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontFamily: 'Noto Sans Arabic',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // قائمة الإعلانات
                                if (_posts.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        isAr ? "لا توجد إعلانات حالياً" : "No announcements available",
                                        style: TextStyle(color: subColor, fontSize: 14),
                                      ),
                                    ),
                                  )
                                else
                                  ..._posts.map((post) => _buildAnnouncementCard(
                                        post,
                                        cardColor: cardColor,
                                        textColor: textColor,
                                        subColor: subColor,
                                        isDark: isDark,
                                        isAr: isAr,
                                      )),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // شريط التنقل السفلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () {},
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

  Widget _buildShortcut(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Color cardColor, Color textColor, Color subColor) {
    final totalStudents = _stats?['totalStudents'] ?? 0;
    final totalTeachers = _stats?['totalTeachers'] ?? 0;
    final totalStaff = _stats?['totalStaff'] ?? 0;
    final pendingLeaves = _stats?['pendingLeaves'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('الطلاب المسجلين', totalStudents.toString(), Icons.school_outlined, Colors.blue, cardColor, textColor, subColor),
        _buildStatCard('أعضاء التدريس', totalTeachers.toString(), Icons.co_present_outlined, Colors.green, cardColor, textColor, subColor),
        _buildStatCard('إجمالي الكادر', totalStaff.toString(), Icons.badge_outlined, Colors.orange, cardColor, textColor, subColor),
        _buildStatCard('طلبات غياب معلقة', pendingLeaves.toString(), Icons.assignment_late_outlined, Colors.red, cardColor, textColor, subColor),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color cardColor, Color textColor, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: subColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    Map<String, dynamic> data, {
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
    required bool isAr,
  }) {
    final String badgeText = data['type'] == 'general' ? 'إعلان عام' : 'إعلان خاص';
    final Color badgeBg = data['type'] == 'general' ? const Color(0xFF0D9488) : Colors.orange;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: data),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((data['image_url'] as String?)?.isNotEmpty == true)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                ApiService.fixMediaUrl(data['image_url'] as String?) ?? '',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: (data['image_url'] as String?)?.isNotEmpty == true
                    ? Radius.zero
                    : const Radius.circular(20),
                topRight: (data['image_url'] as String?)?.isNotEmpty == true
                    ? Radius.zero
                    : const Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  isDark ? const Color(0xFF1E2638) : const Color(0xFFEEF2F6),
                  isDark ? const Color(0xFF151B26) : const Color(0xFFE2E8F0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeBg.withOpacity(0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeBg,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                Text(
                  data['created_at'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['content'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: subColor,
                    height: 1.6,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.withOpacity(0.1)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'الناشر: ${data['user_name']}' : 'Publisher: ${data['user_name']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: subColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
