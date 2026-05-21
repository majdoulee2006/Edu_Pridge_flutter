import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';

import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'add_trainer_screen.dart';
import 'add_student_screen.dart';
import 'add_parent_screen.dart';

class AccountsManagementScreen extends StatefulWidget {
  const AccountsManagementScreen({super.key});

  @override
  State<AccountsManagementScreen> createState() => _AccountsManagementScreenState();
}

class _AccountsManagementScreenState extends State<AccountsManagementScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;

  static const _endpoints = [
    '/department-head/users/trainers',
    '/department-head/users/students',
    '/department-head/users/parents',
  ];

  static const _addScreens = [AddTrainerScreen(), AddStudentScreen(), AddParentScreen()];
  static const _addLabels  = ["إضافة حساب مدرب جديد", "إضافة حساب طالب جديد", "إضافة حساب ولي أمر"];
  static const _emptyLabels = ["لا يوجد مدربون مسجلون", "لا يوجد طلاب مسجلون", "لا يوجد أولياء أمور مسجلون"];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}${_endpoints[_selectedIndex]}",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200) {
        final raw = res.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] != null) {
          list = raw['data'] as List<dynamic>;
        }
        setState(() {
          _accounts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Fetch Accounts Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchTab(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _accounts = [];
    });
    _fetchAccounts();
  }

  String _subtitle(Map<String, dynamic> account) {
    if (_selectedIndex == 0) return account['specialization'] as String? ?? account['email'] as String? ?? '';
    if (_selectedIndex == 1) return account['academic_number'] as String? ?? account['email'] as String? ?? '';
    return account['phone'] as String? ?? account['email'] as String? ?? '';
  }

  String _detail(Map<String, dynamic> account) {
    if (_selectedIndex == 0) return account['email'] as String? ?? '';
    if (_selectedIndex == 1) return "المستوى: ${account['level'] as String? ?? '-'}";
    return "صلة القرابة: ${account['relation'] as String? ?? '-'}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    const Color primaryYellow = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, isDark, textColor),
                  const SizedBox(height: 10),
                  _buildTabs(isDark, primaryYellow, cardColor),
                  const SizedBox(height: 15),
                  _buildAddButton(cardColor, textColor, primaryYellow),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                        : RefreshIndicator(
                            onRefresh: _fetchAccounts,
                            color: const Color(0xFFFFCC00),
                            child: _accounts.isEmpty
                                ? ListView(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 60),
                                        child: Column(
                                          children: [
                                            Icon(Icons.person_search_outlined, size: 70, color: Colors.grey.withValues(alpha: 0.5)),
                                            const SizedBox(height: 12),
                                            Text(
                                              _emptyLabels[_selectedIndex],
                                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _accounts.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final acc = _accounts[index];
                                      final name = acc['full_name'] as String? ?? acc['name'] as String? ?? '---';
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 26,
                                              backgroundColor: primaryYellow.withValues(alpha: 0.2),
                                              child: Text(
                                                name.isNotEmpty ? name[0] : '?',
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                                  const SizedBox(height: 3),
                                                  Text(_subtitle(acc), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                  const SizedBox(height: 2),
                                                  Text(_detail(acc), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey.withValues(alpha: 0.5)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),

              CustomBottomNav(
                currentIndex: 0,
                centerButton: const Boss_Center_Icon(),
                onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeptHeadHomeScreen())),
                onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossProfileScreen())),
                onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossNotificationScreen())),
                onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BossMessageScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(Color cardColor, Color textColor, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => _addScreens[_selectedIndex]));
          _fetchAccounts();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: Icon(Icons.add, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(_addLabels[_selectedIndex], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark, Color primary, Color cardColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 55,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _tabItem("مدرب / معلم", 0, primary),
          _tabItem("طالب",        1, primary),
          _tabItem("أهل",         2, primary),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index, Color primary) {
    final bool isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? Colors.black : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(userName: "رئيس القسم", userRole: "إدارة النظام"))),
          ),
          Text("إدارة الحسابات", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
