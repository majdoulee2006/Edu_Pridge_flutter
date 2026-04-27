import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// ✅ استيراد الملفات الخاصة بمشروعك
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsNotificationsScreen extends StatefulWidget {
  const ParentsNotificationsScreen({super.key});

  @override
  State<ParentsNotificationsScreen> createState() => _ParentsNotificationsScreenState();
}

class _ParentsNotificationsScreenState extends State<ParentsNotificationsScreen> {

  // ✅ جلب البيانات كقائمة (List)
  Future<List<dynamic>> _getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. جلب الـ ID المخزن
      String? userId = prefs.getString('user_id');

      if (userId == null) {
        debugPrint("🚨 لم يتم العثور على user_id في الذاكرة");
        return [];
      }

      // 2. إرسال الطلب مع الـ ID في الرابط مباشرة
      var response = await Dio().get("${ApiService().baseUrl}/parent/notifications/$userId");

      if (response.statusCode == 200 && response.data != null) {
        debugPrint("✅ تم جلب البيانات: ${response.data}");
        return response.data as List<dynamic>;
      }
    } catch (e) {
      debugPrint("🚨 خطأ في الاتصال: $e");
    }
    return [];
  }

  // ✅ دالة لعرض تفاصيل التقرير عند الضغط عليه
  void _showReportDetails(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text("📄 تفاصيل التقرير",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_rounded, size: 60, color: Colors.orange),
            const SizedBox(height: 15),
            Text(item['message'] ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const Divider(height: 30),
            // بيانات افتراضية توضح النتيجة للأب
            _buildReportRow(Icons.check_circle_outline, "حالة الحضور", "ممتاز (95%)", Colors.green),
            _buildReportRow(Icons.star_border, "المستوى الدراسي", "جيد جداً", Colors.blue),
            const SizedBox(height: 20),
            const Text("التوصية: يستمر الطالب في التحسن، ننصح بمتابعة الواجبات اليومية.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت مساعد لبناء صفوف التقرير داخل الـ Dialog
  Widget _buildReportRow(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ✅ دالة ديناميكية لتحديد الستايل بناءً على النوع
  Map<String, dynamic> _getStyleByType(String? type) {
    switch (type?.toLowerCase()) {
      case 'report':
        return {'color': Colors.orange, 'icon': Icons.assignment_turned_in_rounded, 'label': 'تقرير أداء'};
      case 'attendance':
        return {'color': Colors.red, 'icon': Icons.person_off, 'label': 'حضور وغياب'};
      case 'leave_request':
        return {'color': Colors.blue, 'icon': Icons.description_outlined, 'label': 'طلب إجازة'};
      case 'marks':
        return {'color': Colors.amber, 'icon': Icons.grade_rounded, 'label': 'نتائج امتحانات'};
      case 'holiday':
        return {'color': Colors.green, 'icon': Icons.beach_access_rounded, 'label': 'عطلة رسمية'};
      case 'event':
        return {'color': Colors.purple, 'icon': Icons.event_available, 'label': 'فعالية مدرسية'};
      default:
        return {'color': Colors.blueGrey, 'icon': Icons.notifications_active, 'label': 'إشعار'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, textColor),
        body: Stack(
          children: [
            FutureBuilder<List<dynamic>>(
              future: _getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFEFFF00)));
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text("حدث خطأ في جلب البيانات", style: TextStyle(color: textColor)));
                }

                final notifications = snapshot.data!;

                if (notifications.isEmpty) {
                  return Center(child: Text("لا توجد إشعارات حالياً", style: TextStyle(color: textColor.withOpacity(0.5))));
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      // ✅ تم إضافة InkWell هنا لجعل الكارت قابلاً للنقر
                      return InkWell(
                        onTap: () {
                          if (notifications[index]['type'] == 'report') {
                            _showReportDetails(context, notifications[index]);
                          }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: _buildNotificationCard(context, notifications[index], cardColor, textColor),
                      );
                    },
                  ),
                );
              },
            ),

            CustomBottomNav(
              currentIndex: 2,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () {},
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
      elevation: 0, centerTitle: true,
      title: Text("الإشعارات", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: textColor.withOpacity(0.6)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
      actions: [
        IconButton(icon: Icon(Icons.arrow_forward, color: textColor), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, dynamic item, Color cardColor, Color textColor) {
    final style = _getStyleByType(item['type']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(right: 0, top: 0, bottom: 0, child: Container(width: 5, color: style['color'])),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: style['color'].withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(style['icon'], color: style['color'], size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['title']?.toString() ?? "إشعار", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            _buildTimeBadge(item['created_at']?.toString().split('T')[0] ?? "--", textColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['message']?.toString() ?? "",
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, height: 1.4)),
                        const SizedBox(height: 10),
                        Text(
                          style['label'],
                          style: TextStyle(color: style['color'], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String time, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: textColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Text(time, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 10)),
    );
  }
}