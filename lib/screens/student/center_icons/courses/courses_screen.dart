import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
import 'package:edu_pridge_flutter/screens/student/center_icons/lectures/lectures_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _isLoading = true;
  List<dynamic> _courses = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await StudentServices().getCourses();
      if (mounted) {
        setState(() {
          _courses = res ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "تعذر تحميل المواد الدراسية، يرجى التحقق من الشبكة.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "المواد الدراسية المسجلة",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCourses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchCourses, child: const Text("إعادة المحاولة")),
                    ],
                  ),
                )
              : _courses.isEmpty
                  ? Center(
                      child: Text(
                        "لا توجد مواد مسجلة حالياً",
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchCourses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.length,
                        itemBuilder: (context, index) {
                          final course = _courses[index] as Map<String, dynamic>;
                          final title = course['title'] ?? course['name'] ?? 'مادة بدون عنوان';
                          final teacherName = course['teacher_name'] ?? 'مدرس غير محدد';
                          final description = course['description'] ?? 'لا يوجد وصف';
                          final level = course['level'] ?? course['year'] ?? '';
                          final schedule = course['schedule'] as Map<String, dynamic>?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: cardColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LecturesScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(Icons.menu_book_rounded, color: primaryColor, size: 28),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                  fontFamily: 'Tajawal',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "المدرس: $teacherName",
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (level.toString().isNotEmpty)
                                          Chip(
                                            label: Text(
                                              "$level",
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: primaryColor.withOpacity(0.08),
                                          ),
                                      ],
                                    ),
                                    if (description.toString().isNotEmpty && description != 'لا يوجد وصف') ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        description,
                                        style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (schedule != null) ...[
                                      const Divider(height: 20),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, size: 16, color: primaryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${schedule['day'] ?? ''} ${schedule['start_time'] ?? ''} - ${schedule['end_time'] ?? ''}",
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const Spacer(),
                                          if (schedule['room'] != null)
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "القاعة: ${schedule['room']}",
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LecturesScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.folder_open, size: 18),
                                        label: const Text("استعراض المحاضرات والملفات"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
