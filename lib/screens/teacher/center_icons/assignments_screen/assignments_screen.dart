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
import 'responses/all_responses.dart';
import 'add_assignment.dart';
import '../grading_screen/grading_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  final int? openSubmissionsForId;
  const AssignmentsScreen({super.key, this.openSubmissionsForId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _autoOpenSubmissions() async {
    if (widget.openSubmissionsForId == null) return;
    final assignment = _assignments.firstWhere(
      (a) => a['id'].toString() == widget.openSubmissionsForId.toString(),
      orElse: () => {},
    );
    if (assignment.isNotEmpty && mounted) {
      _showSubmissions(context, assignment);
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await Dio().get(
        "${ApiService().baseUrl}/teacher/assignments",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _assignments = (response.data['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoOpenSubmissions());
      }
    } catch (e) {
      debugPrint('⛔ Assignments Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف الواجب', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد من حذف هذا الواجب؟ لا يمكن التراجع عن هذا الإجراء.'),
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
        "${ApiService().baseUrl}/teacher/assignments/$assignmentId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      _fetchAssignments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف الواجب بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('⛔ Delete Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحذف'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _editAssignment(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAssignmentScreen(assignment: assignment)),
    ).then((refreshed) {
      if (refreshed == true) _fetchAssignments();
    });
  }

  void _showSubmissions(BuildContext context, Map<String, dynamic> assignment) async {
    final assignmentId    = assignment['id'];
    final assignmentTitle = assignment['title'] as String? ?? 'الواجب';
    final courseName      = assignment['course_name'] as String? ?? '';
    final textColor       = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor       = Theme.of(context).cardColor;
    final isDark          = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmissionsBottomSheet(
        assignmentId:    assignmentId.toString(),
        assignmentTitle: assignmentTitle,
        courseName:      courseName,
        textColor:       textColor,
        cardColor:       cardColor,
        isDark:          isDark,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'نشط':           return Colors.green;
      case 'قيد الإنتظار': return Colors.orange;
      case 'قيد التصحيح':  return Colors.blue;
      case 'مكتمل':        return Colors.grey;
      default:              return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color yellow  = Color(0xFFFFCC00);
    final bgColor       = Theme.of(context).scaffoldBackgroundColor;
    final cardColor     = Theme.of(context).cardColor;
    final textColor     = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark        = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: bgColor,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('الواجبات والمشاريع',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: yellow,
              indicatorWeight: 3,
              labelColor: isDark ? yellow : Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [Tab(text: 'قائمة الواجبات'), Tab(text: 'ردود الطلاب')],
            ),
          ),
          body: Stack(
            children: [
              TabBarView(
                children: [
                  _buildAssignmentsList(cardColor, textColor, isDark),
                  const AllResponsesScreen(),
                ],
              ),

              // زر الإضافة — يظهر فقط في تبويب قائمة الواجبات
              Builder(
                builder: (ctx) {
                  final tabController = DefaultTabController.of(ctx);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (_, w) => tabController.index == 0
                        ? Positioned(
                            bottom: 100,
                            left: 20,
                            child: FloatingActionButton(
                              heroTag: "add_assignment_btn",
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
                              ).then((refreshed) {
                                if (refreshed == true) _fetchAssignments();
                              }),
                              backgroundColor: yellow,
                              elevation: 6,
                              child: const Icon(Icons.add, color: Colors.black, size: 30),
                            ),
                          )
                        : const SizedBox.shrink(),
                  );
                },
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
      ),
    );
  }

  Widget _buildAssignmentsList(Color cardColor, Color textColor, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)));
    }
    if (_assignments.isEmpty) {
      return const Center(
        child: Text('لا توجد واجبات', style: TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _assignments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = _assignments[index];
        final status = a['status'] as String? ?? '';
        return _buildCard(
          context,
          assignment:  a,
          title:       a['title'] as String? ?? '',
          subject:     a['course_name'] as String? ?? '',
          date:        a['due_date'] as String? ?? '',
          progress:    '${a['submissions_count'] ?? 0} طالب قدم الحل',
          statusText:  status,
          statusColor: _statusColor(status),
          cardColor:   cardColor,
          textColor:   textColor,
          isDark:      isDark,
          hasGlow:     status == 'نشط',
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required Map<String, dynamic> assignment,
    required String title,
    required String subject,
    required String date,
    required String progress,
    required String statusText,
    required Color statusColor,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    bool hasGlow = false,
  }) {
    final assignmentId = assignment['id']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: hasGlow
            ? Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.5), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: hasGlow
                ? const Color(0xFFFFCC00).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSubmissions(context, assignment),
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
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFFF0E35F), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                            Text(subject, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(statusText, statusColor),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    children: [
                      // تاريخ + عدد التقديمات
                      Icon(Icons.calendar_today_outlined, size: 13, color: textColor.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(date,
                            style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.45))),
                      ),
                      Icon(Icons.people_outline, size: 15, color: textColor.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(progress,
                          style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.45))),
                      const SizedBox(width: 12),

                      // زر التعديل
                      _actionIcon(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        onTap: () => _editAssignment(assignment),
                      ),
                      const SizedBox(width: 6),

                      // زر الحذف
                      _actionIcon(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        onTap: () => _deleteAssignment(assignmentId),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom Sheet — تقديمات واجب معين
// ─────────────────────────────────────────────────────────────
class _SubmissionsBottomSheet extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String courseName;
  final Color textColor;
  final Color cardColor;
  final bool isDark;

  const _SubmissionsBottomSheet({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.courseName,
    required this.textColor,
    required this.cardColor,
    required this.isDark,
  });

  @override
  State<_SubmissionsBottomSheet> createState() => _SubmissionsBottomSheetState();
}

class _SubmissionsBottomSheetState extends State<_SubmissionsBottomSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/assignments/${widget.assignmentId}/submissions",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _submissions = (res.data['data'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⛔ Submissions Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFFFFCC00)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.assignmentTitle,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: widget.textColor),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_submissions.length} تقديم',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFCC00))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                  : _submissions.isEmpty
                      ? const Center(child: Text('لا توجد تقديمات بعد', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _submissions.length,
                          itemBuilder: (ctx, i) => _buildSubmissionTile(ctx, _submissions[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionTile(BuildContext context, Map<String, dynamic> s) {
    final isGraded   = s['is_graded'] == true || s['grade'] != null;
    final statusColor = isGraded ? Colors.green : Colors.orange;
    final name        = s['student_name'] as String? ?? '---';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.textColor)),
        subtitle: Text(s['submitted_at'] as String? ?? '',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGraded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${s['grade'] ?? 0}/${s['max_points'] ?? 100}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFCC00))),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('بانتظار التصحيح',
                    style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_back_ios, size: 13, color: widget.textColor.withValues(alpha: 0.3)),
          ],
        ),
        onTap: () {
          final enriched = {
            ...s,
            'assignment_title': s['assignment_title'] ?? widget.assignmentTitle,
            'course_name':      s['course_name']      ?? widget.courseName,
          };
          final nav = Navigator.of(context);
          nav.pop();
          nav.push(MaterialPageRoute(
            builder: (ctx) => GradingScreen(submission: enriched),
          ));
        },
      ),
    );
  }
}
