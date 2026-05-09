import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'add_post.dart';   // ← تم استيراده

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic>? dashboardData;
  List<dynamic> latestNews = [];
  bool isLoading = true;
  String offlineName = "المدير";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // منطق الـ API الخاص بك يبقى كما هو
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FA);

    final adminData = dashboardData?['admin'];
    String displayName = adminData?['name'] ?? adminData?['full_name'] ?? offlineName;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            if (!isDark) _buildGridBackground(),

            SafeArea(
              child: Column(
                children: [
                  _buildAdminHeader(isDark, displayName),

                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                        : RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                        children: [
                          if (latestNews.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 50),
                                child: Text("لا توجد أخبار أو تنبيهات إدارية حالياً"),
                              ),
                            )
                          else
                            ...latestNews.asMap().entries.map((entry) {
                              int idx = entry.key;
                              var news = entry.value;
                              return idx == 0
                                  ? _buildMainNewsCard(news, isDark)
                                  : _buildSecondaryNewsCard(news, isDark);
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // الشريط السفلي
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => _loadDashboardData(),
              onProfileTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const AdminProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const AdminNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const AdminMessagesScreen())),
            ),
          ],
        ),

        // زر + الدائري (مربوط الآن بصفحة إنشاء المنشور)
        floatingActionButton: _buildCircularAddButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  // زر + الدائري المحدث
  Widget _buildCircularAddButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 95, left: 5),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        },
        backgroundColor: const Color(0xFFEFFF00),
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  // ====================== باقي الدوال (بدون تغيير) ======================
  Widget _buildAdminHeader(bool isDark, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                  color: Colors.amber,
                  height: 1.1,
                ),
              ),
              Text(
                'مرحباً بالإدارة، $name',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.amber, size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminProfileScreen()));
            },
            child: CircleAvatar(
              radius: 26,
              backgroundColor: isDark ? Colors.amber.withOpacity(0.1) : const Color(0xFF2D2A1A),
              child: const Icon(Icons.person, color: Colors.amber, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainNewsCard(dynamic news, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadge("إعلان إداري"),
                const SizedBox(height: 12),
                Text(news['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(news['content'] ?? '', maxLines: 2, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryNewsCard(dynamic news, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.admin_panel_settings, color: Colors.amber),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(news['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(news['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  Widget _buildGridBackground() {
    return Opacity(
      opacity: 0.03,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("assets/images/grid.png"), repeat: ImageRepeat.repeat),
        ),
      ),
    );
  }
}