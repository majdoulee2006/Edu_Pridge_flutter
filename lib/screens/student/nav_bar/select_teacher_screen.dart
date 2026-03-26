import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SelectTeacherScreen extends StatelessWidget {
  const SelectTeacherScreen({super.key});

  // بيانات تجريبية للمدرسين
  final List<Map<String, dynamic>> teachers = const [
    {
      'name': 'د. سارة الأحمد',
      'subject': 'مادة الرياضيات المتقدمة',
      'isOnline': true,
      'image': 'https://i.pravatar.cc/150?u=sarah',
    },
    {
      'name': 'م. خالد العلي',
      'subject': 'مادة البرمجة الكيانية',
      'isOnline': false,
      'image': 'https://i.pravatar.cc/150?u=khaled',
    },
    {
      'name': 'أ. ليلى حسن',
      'subject': 'اللغة الإنجليزية التخصصية',
      'isOnline': true,
      'image': 'https://i.pravatar.cc/150?u=laila',
    },
    {
      'name': 'د. محمد الراوي',
      'subject': 'الفيزياء الحديثة',
      'isOnline': true,
      'image': 'https://i.pravatar.cc/150?u=mohammed',
    },
    {
      'name': 'أ. منى زكي',
      'subject': 'تحليل النظم',
      'isOnline': false,
      'image': 'https://i.pravatar.cc/150?u=mona',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'بدء محادثة جديدة',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // شريط البحث
            _buildSearchBar(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر مدرساً للمراسلة:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // قائمة المدرسين
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return _buildTeacherCard(context, teacher);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'ابحث عن مدرس...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context, Map<String, dynamic> teacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(teacher['image']),
            ),
            if (teacher['isOnline'])
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          teacher['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          teacher['subject'],
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          // ✅ تم حل المشكلة هنا: استخدمنا teacher بدل chat ومسحنا سطر الـ type
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                name: teacher['name'],
                imageUrl: teacher['image'],
                isGroup: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
