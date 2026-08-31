import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/announcement_detail_screen.dart';

import 'package:edu_pridge_flutter/screens/parents/center_icons/appointments_screen/appointments_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/center_icons/vacations/vacations_screen.dart';

class AffairsOfficerNotificationsScreen extends StatefulWidget {
  const AffairsOfficerNotificationsScreen({super.key});

  @override
  State<AffairsOfficerNotificationsScreen> createState() =>
      _AffairsOfficerNotificationsScreenState();
}

class _AffairsOfficerNotificationsScreenState
    extends State<AffairsOfficerNotificationsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isMarkingAll = false;
  List<Map<String, dynamic>> _notifications = [];
  String _currentFilter = 'all';
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchMoreNotifications();
      }
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _notifications.clear();
    }
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final res = await Dio().get(
        "${ApiService().baseUrl}/affairs/notifications",
        queryParameters: {'page': _currentPage, 'filter': _currentFilter},
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        }),
      );
      if (res.statusCode == 200 && mounted) {
        final raw = res.data;
        final List list = raw is List ? raw : (raw['data'] ?? []);
        setState(() {
          _notifications =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _hasMore = raw is Map ? (raw['has_more'] ?? false) : false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("⛔ Affairs notifications error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreNotifications() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final token = await _getToken();
      final res = await Dio().get(
        "${ApiService().baseUrl}/affairs/notifications",
        queryParameters: {'page': _currentPage, 'filter': _currentFilter},
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        }),
      );
      if (res.statusCode == 200 && mounted) {
        final raw = res.data;
        final List list = raw is List ? raw : (raw['data'] ?? []);
        setState(() {
          _notifications.addAll(
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
          _hasMore = raw is Map ? (raw['has_more'] ?? false) : false;
        });
      }
    } catch (e) {
      debugPrint("⛔ Load More Error: $e");
      if (mounted) setState(() => _currentPage--);
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _changeFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _fetchNotifications(refresh: true);
  }

  Future<void> _markAsRead(int id, int index) async {
    if (_notifications[index]['is_read'] == true) return;
    try {
      final token = await _getToken();
      await Dio().post(
        "${ApiService().baseUrl}/affairs/notifications/$id/read",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        }),
      );
      if (mounted) setState(() => _notifications[index]['is_read'] = true);
    } catch (e) {
      debugPrint("⛔ Affairs mark read error: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      final token = await _getToken();
      await Dio().post(
        "${ApiService().baseUrl}/affairs/notifications/read-all",
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        }),
      );
      if (mounted) {
        setState(() {
          for (final n in _notifications) {
            n['is_read'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint("⛔ Affairs mark all read error: $e");
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

  void _onTap(Map<String, dynamic> n, int index) {
    final int id = (n['id'] as num?)?.toInt() ?? 0;
    _markAsRead(id, index);

    final type = n['type']?.toString() ?? '';
    if (type == 'announcement' || type == 'administrative') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: {
            'title': n['title']?.toString() ?? '',
            'content': n['message']?.toString() ?? '',
            'body': n['message']?.toString() ?? '',
            'time_ago': n['created_at']?.toString().split('T')[0] ?? '',
            'created_at': n['created_at']?.toString() ?? '',
            'author_name': 'الإدارة',
          }),
        ),
      );
    } else if (type == 'meeting_request' || type == 'summon') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AppointmentsScreen(),
        ),
      );
    } else if (type == 'leave_request' || type == 'leave') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AffairsOfficerVacationsScreen(),
        ),
      );
    }
  }

  Map<String, dynamic> _styleFor(String? type) {
    switch (type) {
      case 'announcement':
      case 'administrative':
        return {'color': const Color(0xFFCCAA00), 'icon': Icons.campaign_outlined, 'label': 'إعلان'};
      case 'leave_request':
        return {'color': Colors.blue, 'icon': Icons.description_outlined, 'label': 'طلب إجازة'};
      case 'meeting_request':
        return {'color': Colors.teal, 'icon': Icons.calendar_month_outlined, 'label': 'طلب موعد'};
      case 'summon':
        return {'color': Colors.deepOrange, 'icon': Icons.person_add_alt_1_outlined, 'label': 'استدعاء إداري'};
      case 'report':
        return {'color': Colors.orange, 'icon': Icons.assignment_turned_in_rounded, 'label': 'تقرير'};
      case 'attendance':
        return {'color': Colors.red, 'icon': Icons.person_off, 'label': 'حضور وغياب'};
      case 'message':
        return {'color': Colors.teal, 'icon': Icons.chat_bubble_outline, 'label': 'رسالة'};
      default:
        return {'color': Colors.blueGrey, 'icon': Icons.notifications_active, 'label': 'إشعار'};
    }
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _currentFilter == value;
    return GestureDetector(
      onTap: () => _changeFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFCC00) : (isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFFCC00).withAlpha(80), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.settings, color: isDark ? const Color(0xFFFFCC00) : const Color(0xFFFFA000), size: 26),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                        Row(
                          children: [
                            Text("الإشعارات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                            if (_unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFFCC00), borderRadius: BorderRadius.circular(10)),
                                child: Text('$_unreadCount', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (_unreadCount > 0)
                              _isMarkingAll
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFCC00)))
                                  : TextButton(
                                      onPressed: _markAllAsRead,
                                      child: Text('تمييز الكل', style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                            else
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: textColor, size: 26),
                                onPressed: () => Navigator.pop(context),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // شريط الفلترة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFilterChip('الكل', 'all', isDark),
                        _buildFilterChip('غير المقروءة', 'unread', isDark),
                        _buildFilterChip('المقروءة', 'read', isDark),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                        : RefreshIndicator(
                            onRefresh: () => _fetchNotifications(refresh: true),
                            color: const Color(0xFFFFCC00),
                            child: _notifications.isEmpty
                                ? ListView(children: [
                                    SizedBox(
                                      height: 400,
                                      child: Center(
                                        child: Text("لا توجد إشعارات حالياً",
                                            style: TextStyle(color: textColor.withValues(alpha: 0.5))),
                                      ),
                                    )
                                  ])
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                                    itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _notifications.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(color: Color(0xFFFFCC00)),
                                          ),
                                        );
                                      }
                                      final n = _notifications[index];
                                      return GestureDetector(
                                        onTap: () => _onTap(n, index),
                                        child: _buildCard(n, cardColor, textColor, isDark),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 2,
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AffairsOfficerHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AffairsOfficerProfileScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AffairsOfficerMessagesScreen())),
              onNotificationsTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> n, Color cardColor, Color textColor, bool isDark) {
    final style = _styleFor(n['type']?.toString());
    final Color color = style['color'] as Color;
    final bool isUnread = n['is_read'] != true;
    final String dateStr = n['formatted_date']?.toString() ?? n['time_ago']?.toString() ?? (n['created_at']?.toString() ?? '').split('T')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.05))
            : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isUnread ? Border.all(color: color.withValues(alpha: 0.3), width: 1) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5))),
                          const SizedBox(height: 4),
                          Text(
                            n['title']?.toString() ?? 'إشعار',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n['message']?.toString() ?? '',
                            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6), height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(style['label'] as String, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(style['icon'] as IconData, color: color, size: 19),
                        ),
                        if (isUnread) ...[
                          const SizedBox(height: 6),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF5722), shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}