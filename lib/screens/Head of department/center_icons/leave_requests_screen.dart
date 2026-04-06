import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/widgets/boss_center_icon.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_profile.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_notification.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_massega.dart';
import 'package:edu_pridge_flutter/screens/Head%20of%20department/nav_bar/boss_home.dart';

class LeaveRequestsScreen extends StatefulWidget {
  // 🚀 استقبال مصدر الدخول (home أو profile)
  final String fromSource;

  const LeaveRequestsScreen({super.key, this.fromSource = "home"});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  bool isDailyLeave = true;

  // 🛠️ منطق الرجوع الذكي
  void _handleBackNavigation(BuildContext context) {
    if (widget.fromSource == "profile") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BossProfileScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DeptHeadHomeScreen()),
      );
    }
  }

  // بيانات تجريبية
  final List<Map<String, dynamic>> allRequests = [
    {
      "name": "أحمد محمد",
      "role": "مدرب | قسم علوم الحاسوب",
      "date": "12 أكتوبر 2023",
      "reason": "ظرف عائلي طارئ يتطلب تواجدي خارج المدينة. لقد قمت بترتيب بديل للمحاضرة.",
      "type": "يوم كامل",
      "isDaily": true,
      "image": "https://api.dicebear.com/7.x/avataaars/png?seed=Ahmed"
    },
    {
      "name": "سارة خالد",
      "role": "طالبة | الرياضيات 101",
      "date": "14 أكتوبر 2023",
      "reason": "موعد طبي في المستشفى الجامعي.",
      "type": "ساعتين",
      "isDaily": false,
      "image": "https://api.dicebear.com/7.x/avataaars/png?seed=Sara"
    },
  ];

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
        textDirection: TextDirection.rtl,
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
                    child: filteredRequests.isEmpty
                        ? Center(child: Text("لا توجد طلبات حالياً", style: TextStyle(color: textColor)))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _buildLeaveCard(isDark, cardColor, textColor, filteredRequests[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),

              // 🌟 التعديل الأساسي هنا لضبط تلوين الأيقونات
              CustomBottomNav(
                // يتلون البروفايل (1) إذا كنتِ جاية منه، وإلا يتلون الهوم (0)
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
                userName: "رئيس القسم",
                userRole: "رئيس القسم الأكاديمي",
                onProfileTap: () => Navigator.pop(context),
              )));
            },
          ),
          Text("طلبات الإجازة", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : Colors.black),
            onPressed: () => _handleBackNavigation(context), // 🚀 العودة للمصدر الصحيح
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          _buildTabButton("إجازات يومية", isDailyLeave, () => setState(() => isDailyLeave = true)),
          _buildTabButton("إجازات ساعية", !isDailyLeave, () => setState(() => isDailyLeave = false)),
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
            color: isActive ? const Color(0xFFEFFF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveCard(bool isDark, Color cardColor, Color textColor, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: NetworkImage(data['image'])),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  Text(data['role'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(data['type'], style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(data['reason'], style: TextStyle(fontSize: 14, height: 1.4, color: textColor)),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("موافقة", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("رفض", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}