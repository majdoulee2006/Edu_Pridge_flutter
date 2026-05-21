import 'package:flutter/material.dart';
// استيراد الشاشات والقطع الموحدة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import '../../../../widgets/parents_center_icon.dart';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<dynamic> permissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
  }

  Future<void> _fetchPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? sId = prefs.getInt('selected_student_id');
      String? token = prefs.getString('token');

      if (sId != null && token != null) {
        var response = await Dio().get(
          "${ApiService().baseUrl}/parent/student/$sId/permissions",
          options: Options(headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token"
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            permissions = response.data;
            isLoading = false;
          });
        }
      } else {
         setState(() => isLoading = false);
      }
    } catch (e) {
      print("خطأ في جلب الأذونات: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _respondToPermission(int requestId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await Dio().post(
        "${ApiService().baseUrl}/parent/permissions/$requestId/respond",
        data: {"status": status},
        options: Options(headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token"
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التحديث بنجاح")));
        _fetchPermissions(); // Refresh
      }
    } catch (e) {
      print("Error responding to permission: $e");
    }
  }
  Widget build(BuildContext context) {
    // 🎨 تعريف الألوان المتجاوبة مع الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
              isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFEFFF00)))
                  : permissions.isEmpty
                      ? const Center(child: Text("لا توجد أذونات مسجلة"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(15),
                          itemCount: permissions.length + 1,
                          itemBuilder: (context, index) {
                            if (index == permissions.length) {
                              return Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Center(child: Text("نهاية القائمة", style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 12))),
                                  const SizedBox(height: 150),
                                ],
                              );
                            }

                            var item = permissions[index];
                            if (item['status'] == 'pending') {
                              return _buildDetailedCard(item, cardColor, textColor);
                            } else {
                              return _buildSimpleCard(
                                  title: "إذن معالج",
                                  date: item['date']?.toString().substring(0, 10) ?? "",
                                  icon: Icons.history,
                                  iconCol: item['status'] == 'approved' ? Colors.green : Colors.red,
                                  cardColor: cardColor,
                                  textColor: textColor,
                                  statusText: item['status'] == 'approved' ? 'موافق عليه' : 'مرفوض',
                                  statusColor: item['status'] == 'approved' ? Colors.green : Colors.red
                              );
                            }
                          },
                        ),

            // 2. الشريط السفلي الموحد
            CustomBottomNav(
              currentIndex: 0, // تتبع للرئيسية
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "أذونات الطالب",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withValues(alpha: 0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_forward, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // بناء البطاقة المفصلة (طلب نشط)
  Widget _buildDetailedCard(dynamic item, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFFEFFF00), width: 2),
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.medical_services_outlined, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text("طلب إذن جديد", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                ],
              ),
              _statusTag("قيد الانتظار", Colors.orange),
            ],
          ),
          const SizedBox(height: 5),
          Text(item['date']?.toString().substring(0, 10) ?? "", style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              item['reason'] ?? "بدون سبب",
              style: TextStyle(fontSize: 13, height: 1.5, color: textColor.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () => _respondToPermission(item['request_id'], 'rejected'),
                child: _actionBtn("رفض", Colors.red, isOutlined: true)
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => _respondToPermission(item['request_id'], 'approved'),
                child: _actionBtn("موافقة", Colors.black, btnColor: const Color(0xFFEFFF00))
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard({
    required String title,
    required String date,
    required IconData icon,
    required Color iconCol,
    required Color cardColor,
    required Color textColor,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconCol.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconCol, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(date, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          _statusTag(statusText, statusColor),
          const SizedBox(width: 10),
          Icon(Icons.keyboard_arrow_left, color: textColor.withValues(alpha: 0.2), size: 18),
        ],
      ),
    );
  }

  Widget _statusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(String label, Color textCol, {Color? btnColor, bool isOutlined = false}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: btnColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: isOutlined ? Border.all(color: textCol.withValues(alpha: 0.3)) : null,
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
      ),
    );
  }
}