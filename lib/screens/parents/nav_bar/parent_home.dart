import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_messages_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsHomeScreen extends StatefulWidget {
  const ParentsHomeScreen({super.key});

  @override
  State<ParentsHomeScreen> createState() => _ParentsHomeScreenState();
}

class _ParentsHomeScreenState extends State<ParentsHomeScreen> {
  String _parentName = "جارِ التحميل...";
  int? selectedChildId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentName = prefs.getString('user_name') ??
          prefs.getString('full_name') ??
          "ولي أمر";
    });
  }

  // دالة جلب الأبناء (تأخذ رقم الأب من الذاكرة تلقائياً)
  Future<List<dynamic>> _fetchChildrenFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // جلب parent_id الفعلي الذي حفظناه في اللوجن
      int? pId = prefs.getInt('parent_id');

      if (pId != null && pId != 0) {
        var response = await Dio().get(
          "http://127.0.0.1:8000/api/parent/children/$pId",
          options: Options(headers: {"Accept": "application/json"}),
        );

        if (response.statusCode == 200) {
          return response.data;
        }
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في جلب الأبناء: $e");
    }
    return [];
  }

  void _showAddStudentDialog() {
    TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ربط ابن جديد", textAlign: TextAlign.right),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: "أدخل كود الطالب (مثل: 2026100)"),
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();

              // ✨ سحب رقم الأب من الذاكرة (سيكون 1 كما في حالتك)
              int? pId = prefs.getInt('parent_id');

              if (pId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("خطأ: لم يتم العثور على معرف الأب، يرجى إعادة تسجيل الدخول"))
                );
                return;
              }

              try {
                var response = await Dio().post(
                  "http://127.0.0.1:8000/api/parent/add-student",
                  data: {
                    "student_code": codeController.text,
                    "parent_id": pId // يرسل المعرف المخزن تلقائياً
                  },
                  options: Options(headers: {"Accept": "application/json"}),
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  // 🔥 تحديث الواجهة لجلب الأبناء مجدداً
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ تم ربط الابن بنجاح")),
                  );
                }
              } on DioException catch (e) {
                String errorMsg = e.response?.data['message'] ?? "فشل الربط: تأكد من الكود";
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(context, textColor, cardColor),
                  const SizedBox(height: 25),
                  _buildSectionTitle("الأبناء", textColor),

                  FutureBuilder<List<dynamic>>(
                    future: _fetchChildrenFromServer(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator(color: Color(0xFFD4E000))));
                      }

                      final children = snapshot.data ?? [];

                      return SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: children.length + 1,
                          itemBuilder: (context, index) {
                            if (index < children.length) {
                              final child = children[index];
                              return GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    selectedChildId = child['student_id'];
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setInt('selected_student_id', child['student_id']);
                                },
                                child: Stack(
                                  children: [
                                    _buildStudentCard(
                                      child['full_name'] ?? "بدون اسم",
                                      child['level'] ?? "غير محدد",
                                      "3.8",
                                      "نشط",
                                      cardColor,
                                      textColor,
                                      isSelected: selectedChildId == child['student_id'],
                                    ),
                                    if (selectedChildId == child['student_id'])
                                      const Positioned(
                                        top: 20,
                                        right: 20,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Color(0xFFEFFF00),
                                          child: Icon(Icons.check, size: 16, color: Colors.black),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            } else {
                              return _buildAddButton(cardColor);
                            }
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  _buildSectionTitle("أخبار المعهد والفعاليات", textColor),
                  _buildNewsCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            CustomBottomNav(
              currentIndex: 0,
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () {},
              onProfileTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ParentsMessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // --- المكونات الرسومية ---

  Widget _buildHeader(BuildContext context, Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edu-Bridge", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: "مرحباً، ",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                  children: [
                    TextSpan(text: _parentName, style: const TextStyle(color: Color(0xFFD4E000))),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(userName: _parentName, userRole: "ولي أمر"))),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
              child: const Icon(Icons.settings_outlined, color: Color(0xFFF1C40F), size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const Text("عرض الكل", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String name, String major, String gpa, String status, Color cardColor, Color textColor, {bool isSelected = false}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isSelected ? const Color(0xFFEFFF00) : const Color(0xFFE8F200).withOpacity(0.3),
          width: isSelected ? 3 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 35, backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.person, size: 40, color: Colors.indigo)),
          const SizedBox(height: 12),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          Text(major, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == "نشط" ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: TextStyle(color: status == "نشط" ? Colors.green : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text("معدل: $gpa", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAddButton(Color cardColor) {
    return GestureDetector(
      onTap: () => _showAddStudentDialog(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 65, height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
          const SizedBox(height: 8),
          const Text("إضافة", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B67D1), Color(0xFF2A4B9A)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Stack(
        children: [
          Positioned(bottom: 25, right: 25, child: Text("انطلاق فعاليات الأسبوع الثقافي...", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}