import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/admin_services.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/admin/admin_services_menu_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/ai_floating_button.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'add_post.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic>? dashboardData;
  List<dynamic> latestNews = [];
  bool isLoading = true;
  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
    _loadDashboardData();
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      final data = await AdminServices().getDashboardData();
      if (mounted) {
        setState(() {
          dashboardData = data;
          latestNews = data?['announcements'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _confirmDeleteAnnouncement(Map<String, dynamic> news) {
    final annId = news['announcement_id'] ?? news['id'];
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              isAr ? "تأكيد الحذف" : "Confirm Deletion",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              isAr
                  ? "هل أنت متأكد من حذف الإعلان '${news['title'] ?? ''}'؟"
                  : "Are you sure you want to delete the announcement '${news['title'] ?? ''}'?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAr ? "إلغاء" : "Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (annId != null) {
                    final success = await AdminServices().deleteAnnouncement(
                      annId,
                    );
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? "تم حذف الإعلان بنجاح"
                                  : "Announcement deleted successfully",
                            ),
                          ),
                        );
                      }
                      _loadDashboardData();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? "فشل حذف الإعلان"
                                  : "Failed to delete announcement",
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(
                  isAr ? "حذف الإعلان" : "Delete Announcement",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditAnnouncement(Map<String, dynamic> news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPostScreen(announcement: news),
      ),
    ).then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    const primaryYellow = Color(0xFFFFCC00);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            if (!isDark) _buildGridBackground(),

            SafeArea(
              child: Column(
                children: [
                  _buildAdminHeader(isDark),

                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFCC00),
                            ),
                          )
                        : RefreshIndicator(
                            color: primaryYellow,
                            onRefresh: _loadDashboardData,
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                120,
                              ),
                              children: [
                                // 1. قسم الإحصائيات والأجمليات (Dashboard Totals)
                                _buildSectionTitle(
                                  isAr
                                      ? "لوحة التحكم والإحصائيات"
                                      : "Dashboard & Statistics",
                                  Icons.analytics_outlined,
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                _buildStatsGrid(
                                  isDark,
                                  cardColor,
                                  primaryYellow,
                                ),

                                const SizedBox(height: 25),

                                // 2. بطاقة الفصل الدراسي النشط
                                _buildActiveSemesterCard(
                                  isDark,
                                  cardColor,
                                  primaryYellow,
                                ),

                                const SizedBox(height: 25),

                                // 3. قسم أخبار المعهد والفعاليات
                                _buildSectionTitle(
                                  isAr
                                      ? "أخبار المعهد والفعاليات"
                                      : "Institute News & Events",
                                  Icons.campaign_outlined,
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                _buildNewsAndEventsSection(
                                  isDark,
                                  cardColor,
                                  primaryYellow,
                                ),

                                const SizedBox(height: 25),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // إضافة منشور على اليسار، والمساعد الذكي على اليمين
            Positioned(
              bottom: 100,
              left: 20,
              child: SizedBox(
                width: 56,
                height: 56,
                child: _buildCircularAddButton(),
              ),
            ),
            AiFloatingButton(
              userRole: 'admin',
              userName: (dashboardData?['user']?['full_name'] as String?) ?? 'Admin',
              bottom: 100,
              right: 20,
            ),

            // الشريط السفلي الأصلي المعتمد
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => _loadDashboardData(),
              onProfileTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfileScreen(),
                ),
              ),
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminMessagesScreen(),
                ),
              ),
            ),
          ],
        ),

        // زر إضافة منشور جديد
        floatingActionButton: _buildCircularAddButton(),
        floatingActionButtonLocation: isAr
            ? FloatingActionButtonLocation.startFloat
            : FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildCircularAddButton() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 95,
        left: isAr ? 5 : 0,
        right: isAr ? 0 : 5,
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          ).then((_) => _loadDashboardData());
        },
        backgroundColor: const Color(0xFFFFCC00),
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildAdminHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edu-Bridge',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFCC00),
                  height: 1.1,
                ),
              ),
              Text(
                isAr
                    ? 'مرحباً بك في لوحة الإدارة العامة 👋'
                    : 'Welcome to General Administration 👋',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFFFFCC00),
              size: 28,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminServicesMenuScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFFCC00), size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark, Color cardColor, Color primaryYellow) {
    final int teachersCount = dashboardData?['counts']?['teachers'] ?? 0;
    final int studentsCount = dashboardData?['counts']?['students'] ?? 0;
    final int coursesCount = dashboardData?['counts']?['courses'] ?? 0;
    final int deptsCount = dashboardData?['counts']?['departments'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          isAr ? "الطلاب المسجلين" : "Registered Students",
          studentsCount.toString(),
          Icons.school_outlined,
          Colors.blue,
          cardColor,
          isDark,
        ),
        _buildStatCard(
          isAr ? "الكادر التدريسي" : "Teaching Staff",
          teachersCount.toString(),
          Icons.people_outline,
          Colors.orange,
          cardColor,
          isDark,
        ),
        _buildStatCard(
          isAr ? "المواد الدراسية" : "Courses",
          coursesCount.toString(),
          Icons.book_outlined,
          Colors.green,
          cardColor,
          isDark,
        ),
        _buildStatCard(
          isAr ? "الأقسام الأكاديمية" : "Academic Departments",
          deptsCount.toString(),
          Icons.account_balance_outlined,
          Colors.purple,
          cardColor,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color cardColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSemesterCard(
    bool isDark,
    Color cardColor,
    Color primaryYellow,
  ) {
    final activeSemester = dashboardData?['active_semester'];
    final String semesterName =
        activeSemester?['name'] ??
        (isAr
            ? 'لا يوجد فصل دراسي نشط حالياً'
            : 'No active semester currently');
    final String startDate = activeSemester?['start_date'] ?? '';
    final String endDate = activeSemester?['end_date'] ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryYellow.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryYellow.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: primaryYellow,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isAr ? "الفصل الدراسي الحالي" : "Current Semester",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (activeSemester != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr ? "نشط" : "Active",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  semesterName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    isAr ? "من $startDate إلى $endDate" : "From $startDate to $endDate",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsAndEventsSection(
    bool isDark,
    Color cardColor,
    Color primaryYellow,
  ) {
    if (latestNews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.newspaper_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? "لا توجد أخبار أو فعاليات منشورة حالياً"
                  : "No news or events published currently",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? "يمكنك إضافة إعلان أو فعالية جديدة بالضغط على زر (+) الأصفر"
                  : "You can add an announcement or event by tapping the yellow (+) button",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: latestNews.asMap().entries.map((entry) {
        int idx = entry.key;
        var news = Map<String, dynamic>.from(entry.value);
        return idx == 0
            ? _buildFeaturedNewsCard(news, isDark, cardColor, primaryYellow)
            : _buildStandardNewsCard(news, isDark, cardColor, primaryYellow);
      }).toList(),
    );
  }

  Widget _buildFeaturedNewsCard(
    Map<String, dynamic> news,
    bool isDark,
    Color cardColor,
    Color primaryYellow,
  ) {
    final String title =
        news['title'] ?? (isAr ? 'إعلان جديد' : 'New Announcement');
    final String content = news['content'] ?? '';
    final String category =
        news['category'] ??
        news['type'] ??
        (isAr ? 'إعلان عام' : 'General Announcement');
    final String rawAuthor =
        news['author_name'] ??
        news['publisher_name'] ??
        news['created_by'] ??
        (isAr ? 'إدارة المعهد' : 'Administration');
    final String author = isAr
        ? (rawAuthor.startsWith('نشر') ? rawAuthor : 'نشر بواسطة: $rawAuthor')
        : (rawAuthor.toLowerCase().startsWith('posted')
            ? rawAuthor
            : 'Posted by: $rawAuthor');
    final String time = news['created_at'] ?? '';

    final String rawImg =
        news['image_url'] ??
        news['image_path'] ??
        news['image'] ??
        news['attachment'] ??
        '';
    final String? imageUrl = ApiService.fixMediaUrl(rawImg);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge(category, primaryYellow),
                    Row(
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        if (news['is_mine'] == true) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            onPressed: () => _openEditAnnouncement(news),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: isAr ? "تعديل الإعلان" : "Edit Announcement",
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => _confirmDeleteAnnouncement(news),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: isAr ? "حذف الإعلان" : "Delete Announcement",
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnnouncementDetailScreen(announcement: news),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.person_pin_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardNewsCard(
    Map<String, dynamic> news,
    bool isDark,
    Color cardColor,
    Color primaryYellow,
  ) {
    final String title =
        news['title'] ?? (isAr ? 'خبر إداري' : 'Administrative News');
    final String content = news['content'] ?? '';
    final String time = news['created_at'] ?? '';

    final String rawImg =
        news['image_url'] ??
        news['image_path'] ??
        news['image'] ??
        news['attachment'] ??
        '';
    final String? imageUrl = ApiService.fixMediaUrl(rawImg);

    final String rawAuthor = news['author_name'] ??
        news['publisher_name'] ??
        news['created_by'] ??
        (isAr ? 'الإدارة' : 'Admin');
    final String authorText = isAr
        ? "نشر بواسطة: $rawAuthor • $time"
        : "Posted by: $rawAuthor • $time";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: primaryYellow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnnouncementDetailScreen(announcement: news),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (news['is_mine'] == true)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                      onPressed: () => _openEditAnnouncement(news),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isAr ? "تعديل الإعلان" : "Edit Announcement",
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      onPressed: () => _confirmDeleteAnnouncement(news),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isAr ? "حذف الإعلان" : "Delete Announcement",
                    ),
                  ],
                ),
            ],
          ),
          if (time.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 6,
                right: isAr ? 56 : 0,
                left: isAr ? 0 : 56,
              ),
              child: Text(
                authorText,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color yellow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGridBackground() {
    return Opacity(
      opacity: 0.03,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/grid.png"),
            repeat: ImageRepeat.repeat,
          ),
        ),
      ),
    );
  }
}
