import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';

import 'pending_tab.dart';
import 'add_id_tab.dart';
import 'photo_requests_tab.dart';
import 'create_account_screen.dart';

class AffairsOfficerAccountsScreen extends StatefulWidget {
  const AffairsOfficerAccountsScreen({super.key});

  @override
  State<AffairsOfficerAccountsScreen> createState() => _AffairsOfficerAccountsScreenState();
}

class _AffairsOfficerAccountsScreenState extends State<AffairsOfficerAccountsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _mainTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color subColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ═══════════════════════════════════════
                  // الهيدر
                  // ═══════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.settings, color: textColor, size: 26),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                        Text(
                          "الحسابات",
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
                            icon: Icon(Icons.arrow_back, color: textColor, size: 26),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ═══════════════════════════════════════
                  // التبويبات العلوية
                  // ═══════════════════════════════════════
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _mainTabController,
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
                        Tab(text: 'الطلبات المعلقة'),
                        Tab(text: 'إضافة رقم جامعي'),
                        Tab(text: 'طلبات الصورة'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ═══════════════════════════════════════
                  // محتوى التبويبات
                  // ═══════════════════════════════════════
                  Expanded(
                    child: TabBarView(
                      controller: _mainTabController,
                      children: [
                        PendingTab(
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                        AddIdTab(
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                        PhotoRequestsTab(
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

            // ═══════════════════════════════════════
            // زر + (بس بـ "الطلبات المعلقة")
            // ═══════════════════════════════════════
            AnimatedBuilder(
              animation: _mainTabController,
              builder: (context, child) {
                if (_mainTabController.index != 0) return const SizedBox.shrink();
                return Positioned(
                  bottom: 100,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                      );
                    },
                    backgroundColor: const Color(0xFFFFCC00),
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.black, size: 28),
                  ),
                );
              },
            ),

            // ═══════════════════════════════════════
            // الشريط السفلي
            // ═══════════════════════════════════════
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
}