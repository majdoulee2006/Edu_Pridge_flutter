import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../../widgets/teacher_speed_dial.dart';
import '../../messages_screen.dart';
import '../../notifications_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';
import 'add_lecture_screen.dart';

class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});

  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _lectures = [];

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  Future<void> _fetchLectures() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/lessons",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _lectures = (res.data['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Lectures Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLecture(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف المحاضرة', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد من حذف هذه المحاضرة؟ لا يمكن التراجع.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await Dio().delete(
        "${ApiService().baseUrl}/teacher/lessons/$id",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      _fetchLectures();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف المحاضرة'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحذف'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color yellow = Color(0xFFFFCC00);
    final bgColor   = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark    = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('المحاضرات',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : RefreshIndicator(
                    onRefresh: _fetchLectures,
                    color: yellow,
                    child: _lectures.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 200),
                              Center(
                                child: Text('لا توجد محاضرات بعد',
                                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                            itemCount: _lectures.length,
                            separatorBuilder: (_, i) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final l = _lectures[i];
                              return _buildCard(l, cardColor, textColor, isDark);
                            },
                          ),
                  ),

            // زر الإضافة
            Positioned(
              bottom: 100,
              left: 20,
              child: FloatingActionButton(
                heroTag: "add_lecture_btn",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLectureScreen()),
                ).then((refreshed) {
                  if (refreshed == true) _fetchLectures();
                }),
                backgroundColor: yellow,
                elevation: 6,
                child: const Icon(Icons.add, color: Colors.black, size: 30),
              ),
            ),

            CustomBottomNav(
              currentIndex: -1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const TeacherHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> l, Color cardColor, Color textColor, bool isDark) {
    final id          = l['id']?.toString() ?? '';
    final title       = l['title'] as String? ?? '';
    final courseName  = l['course_name'] as String?
                     ?? (l['course'] as Map?)?['title'] as String? ?? '';
    final description = l['description'] as String? ?? '';
    final createdAt   = (l['created_at'] as String? ?? '').split('T').first;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFFFFCC00), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      if (courseName.isNotEmpty)
                        Text(courseName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13)),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: textColor.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(createdAt,
                      style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.45))),
                ),
                _actionIcon(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFFFFCC00),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddLectureScreen(lecture: l)),
                  ).then((refreshed) {
                    if (refreshed == true) _fetchLectures();
                  }),
                ),
                const SizedBox(width: 8),
                _actionIcon(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: () => _deleteLecture(id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
