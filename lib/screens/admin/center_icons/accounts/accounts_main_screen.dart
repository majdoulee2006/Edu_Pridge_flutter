import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/admin_speed_dial.dart';

// استيراد شاشات الشريط السفلي
import 'package:edu_pridge_flutter/screens/admin/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/admin/nav_bar/messages_screen.dart';

// استيراد شاشات إدارة الحسابات
import 'users_management/student_management_screen.dart';
import 'users_management/parent_management_screen.dart';
import 'users_management/teacher_management_screen.dart';
import 'users_management/dept_head_management_screen.dart';
import 'users_management/student_affairs_management_screen.dart';

class AccountsMainScreen extends StatefulWidget {
  const AccountsMainScreen({super.key});

  @override
  State<AccountsMainScreen> createState() => _AccountsMainScreenState();
}

class _AccountsMainScreenState extends State<AccountsMainScreen> {
  int selectedTab = 0; // 0: إنشاء, 1: حذف

  bool get isAr => AppSettings.language.value == 'ar';

  @override
  void initState() {
    super.initState();
    AppSettings.language.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppSettings.language.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  final List<Map<String, dynamic>> accountTypes = [
    {"icon": Icons.school_outlined, "color": Colors.blue, "id": "student"},
    {
      "icon": Icons.family_restroom_outlined,
      "color": Colors.orange,
      "id": "parent",
    },
    {"icon": Icons.co_present_outlined, "color": Colors.green, "id": "teacher"},
    {
      "icon": Icons.manage_accounts_outlined,
      "color": Colors.purple,
      "id": "dept_head",
    },
    {"icon": Icons.badge_outlined, "color": Colors.red, "id": "staff"},
  ];

  String _getTypeTitle(String id) {
    if (isAr) {
      switch (id) {
        case 'student':
          return "طالب";
        case 'parent':
          return "ولي أمر";
        case 'teacher':
          return "معلم";
        case 'dept_head':
          return "رئيس قسم";
        case 'staff':
          return "موظف شؤون";
        default:
          return id;
      }
    } else {
      switch (id) {
        case 'student':
          return "Student";
        case 'parent':
          return "Parent";
        case 'teacher':
          return "Teacher";
        case 'dept_head':
          return "Department Head";
        case 'staff':
          return "Affairs Staff";
        default:
          return id;
      }
    }
  }

  void _navigateToNavScreen(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const AdminHomeScreen();
        break;
      case 1:
        screen = const AdminMessagesScreen();
        break;
      case 2:
        screen = const AdminNotificationsScreen();
        break;
      case 3:
        screen = const AdminProfileScreen();
        break;
      default:
        screen = const AdminHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
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
                  _buildHeader(textColor),
                  const SizedBox(height: 20),
                  _buildCustomTabs(primaryYellow, cardColor, textColor),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildCategoriesGrid(
                      cardColor,
                      textColor,
                      primaryYellow,
                    ),
                  ),
                ],
              ),
            ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const AdminSpeedDial(),
              onHomeTap: () => _navigateToNavScreen(0),
              onMessagesTap: () => _navigateToNavScreen(1),
              onNotificationsTap: () => _navigateToNavScreen(2),
              onProfileTap: () => _navigateToNavScreen(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              isAr ? Icons.arrow_back : Icons.arrow_back_ios_new,
              color: textColor,
              size: 26,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            isAr ? "الحسابات" : "Accounts",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFFFCC00)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            tooltip: isAr ? "الإعدادات" : "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabs(Color yellow, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(isAr ? "إنشاء" : "Create", 0, yellow),
          _buildTabItem(isAr ? "حذف" : "Delete", 1, yellow),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, Color yellow) {
    bool isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(Color cardColor, Color textColor, Color yellow) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: accountTypes.length,
      itemBuilder: (context, index) {
        final type = accountTypes[index];
        final String title = _getTypeTitle(type['id']);
        return GestureDetector(
          onTap: () => _navigateToManagement(type['id']),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: type['color'].withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type['icon'], color: type['color'], size: 35),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToManagement(String id) {
    String mode = "create";
    if (selectedTab == 1) mode = "delete";
    if (selectedTab == 2) mode = "request";

    Widget targetScreen;
    switch (id) {
      case 'student':
        targetScreen = StudentManagementScreen(mode: mode);
        break;
      case 'parent':
        targetScreen = ParentManagementScreen(mode: mode);
        break;
      case 'teacher':
        targetScreen = TeacherManagementScreen(mode: mode);
        break;
      case 'dept_head':
        targetScreen = DeptHeadManagementScreen(mode: mode);
        break;
      case 'staff':
        targetScreen = StudentAffairsManagementScreen(mode: mode);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
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