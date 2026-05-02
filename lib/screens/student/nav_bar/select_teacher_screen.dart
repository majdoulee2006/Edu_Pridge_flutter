import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/models/teacher_model.dart';

class SelectTeacherScreen extends StatefulWidget {
  const SelectTeacherScreen({super.key});

  @override
  State<SelectTeacherScreen> createState() => _SelectTeacherScreenState();
}

class _SelectTeacherScreenState extends State<SelectTeacherScreen> {
  String searchQuery = '';
  List<TeacherModel> allTeachers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  // 🌟 دالة جلب قائمة المدرسين من اللارافل
  Future<void> _fetchTeachers() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Dio dio = Dio();
      // رابط الـ API لجلب المدرسين (سنقوم بإنشائه في اللارافل)
      String url = "http://127.0.0.1:8000/api/student/teachers";

      var response = await dio.get(
        url,
        options: Options(
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            }
        ),
      );

      if (response.statusCode == 200) {
        var data = response.data['data'] as List;
        setState(() {
          allTeachers = data.map((e) => TeacherModel.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب المدرسين: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFAFAFA);
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    // خوارزمية البحث
    List<TeacherModel> filteredTeachers = allTeachers.where((teacher) {
      return teacher.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          teacher.subject.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('بدء محادثة جديدة', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildSearchBar(isDark, cardColor, textColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('اختر مدرساً للمراسلة:', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : filteredTeachers.isEmpty
                  ? Center(child: Text('لم يتم العثور على مدرسين', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)))
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: filteredTeachers.length,
                itemBuilder: (context, index) {
                  return _buildTeacherCard(context, filteredTeachers[index], isDark, cardColor, textColor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        style: TextStyle(color: textColor),
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'ابحث عن مدرس أو مادة...',
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey.shade500 : Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context, TeacherModel teacher, bool isDark, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              backgroundImage: NetworkImage(teacher.imageUrl),
            ),
            if (teacher.isOnline)
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardColor, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(teacher.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        subtitle: Text(teacher.subject, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                receiverId: teacher.id, // 🌟 التعديل الجوهري لتعمل شاشة المحادثة بدون أخطاء
                name: teacher.name,
                imageUrl: teacher.imageUrl,
                isGroup: false,
              ),
            ),
          );
        },
      ),
    );
  }
}