import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/affairs_services.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';

class AffairsOfficerNotificationsScreen extends StatefulWidget {
  const AffairsOfficerNotificationsScreen({super.key});

  @override
  State<AffairsOfficerNotificationsScreen> createState() => _AffairsOfficerNotificationsScreenState();
}

class _AffairsOfficerNotificationsScreenState extends State<AffairsOfficerNotificationsScreen> {
  final AffairsServices _affairsServices = AffairsServices();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _affairsServices.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
        ),
      ),
    );

    final success = await _affairsServices.markAllNotificationsRead();
    if (!mounted) return;
    Navigator.pop(context); // Pop loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد جميع الإشعارات كمقروءة ✓', style: TextStyle(fontFamily: 'Noto Sans Arabic')),
          backgroundColor: Colors.green,
        ),
      );
      _loadNotifications();
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final success = await _affairsServices.markNotificationRead(notificationId);
    if (success && mounted) {
      _loadNotifications();
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'administrative':
        return const Color(0xFF2196F3);
      case 'urgent':
        return const Color(0xFFFF9800);
      case 'message':
        return const Color(0xFF9C27B0);
      case 'report_request':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'administrative':
        return Icons.campaign_outlined;
      case 'urgent':
        return Icons.warning_amber_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'report_request':
        return Icons.assignment_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

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
                              color: isDark ? const Color(0xFFFFCC00) : const Color(0xFFFFA000),
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              ).then((_) => _loadNotifications());
                            },
                          ),
                        ),
                        Text(
                          "الإشعارات",
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

                  // زر تحديد الكل كمقروء
                  if (_notifications.any((n) => n['is_read'] == 0 || n['is_read'] == false))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _markAllAsRead,
                          icon: const Icon(Icons.done_all, size: 18, color: Color(0xFFFFCC00)),
                          label: const Text(
                            'تحديد الكل كمقروء',
                            style: TextStyle(
                              color: Color(0xFFFFCC00),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ),
                      ),
                    ),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC00)),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            color: const Color(0xFFFFCC00),
                            child: _notifications.isEmpty
                                ? Center(
                                    child: Text(
                                      'لا توجد إشعارات حالياً',
                                      style: TextStyle(color: subColor, fontSize: 14, fontFamily: 'Noto Sans Arabic'),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                                    itemCount: _notifications.length,
                                    itemBuilder: (context, index) {
                                      return _buildNotificationCard(
                                        _notifications[index],
                                        cardColor,
                                        textColor,
                                        subColor,
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

  Widget _buildNotificationCard(
    Map<String, dynamic> data,
    Color cardColor,
    Color textColor,
    Color subColor,
  ) {
    final String type = data['type'] ?? 'administrative';
    final Color typeColor = _getTypeColor(type);
    final IconData iconData = _getTypeIcon(type);
    final bool isUnread = data['is_read'] == 0 || data['is_read'] == false;
    final int notificationId = data['id'] ?? 0;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          _markAsRead(notificationId);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? cardColor : cardColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isUnread ? 12 : 4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isUnread ? Border.all(color: typeColor.withOpacity(0.2), width: 1) : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isUnread ? typeColor : subColor.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data['created_at'] != null
                                      ? data['created_at'].toString().split('T')[0]
                                      : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: subColor,
                                    fontFamily: 'Noto Sans Arabic',
                                  ),
                                ),
                                if (isUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFCC00),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['title'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                color: textColor,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['message'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                                height: 1.4,
                                fontFamily: 'Noto Sans Arabic',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}