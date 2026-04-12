import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/models/notification_model.dart';

import 'student_home_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> academicNotifications = [];
  List<AppNotification> administrativeNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Dio dio = Dio();
      // تأكدي من أن الـ IP يطابق جهازك
      String url = "http://127.0.0.1:8000/api/student/notifications";

      var response = await dio.get(
        url,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        var data = response.data['data'];
        setState(() {
          academicNotifications = (data['academic'] as List)
              .map((e) => AppNotification.fromJson(e))
              .toList();
          administrativeNotifications = (data['administrative'] as List)
              .map((e) => AppNotification.fromJson(e))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب الإشعارات: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFAFAFA),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
              ),
            ),
            title: Text('الإشعارات', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: _buildCustomTabBar(isDark),
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : Stack(
            children: [
              TabBarView(
                children: [
                  _NotificationsListView(notifications: academicNotifications),
                  _NotificationsListView(notifications: administrativeNotifications),
                ],
              ),
              CustomBottomNav(
                currentIndex: 2,
                centerButton: const CustomSpeedDialEduBridge(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                onNotificationsTap: () {},
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        // 🌟 إرجاع خصائص شريط التنقل الأصلية 🌟
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFFEFFF00),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [Tab(text: 'رسائل أكاديمية'), Tab(text: 'رسائل إدارية')],
        dividerColor: Colors.transparent,
      ),
    );
  }
}

class _NotificationsListView extends StatelessWidget {
  final List<AppNotification> notifications;
  const _NotificationsListView({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(child: Text("لا توجد إشعارات حالياً", style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: () async => (context.findAncestorStateOfType<_NotificationsScreenState>())?._fetchNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notify = notifications[index];
          return _buildNotificationCard(context, notify);
        },
      ),
    );
  }

  // 🌟 إرجاع تصميم الكرت الأصلي وإصلاح الوقت 🌟
  Widget _buildNotificationCard(BuildContext context, AppNotification notify) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notify.getIconColor().withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(notify.getIcon(), color: notify.getIconColor(), size: 26),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notify.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        notify.timeAgo,
                        style: TextStyle(
                          color: notify.isRead ? Colors.grey.shade500 : Colors.amber.shade700,
                          fontSize: 11,
                          fontWeight: notify.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notify.message,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}