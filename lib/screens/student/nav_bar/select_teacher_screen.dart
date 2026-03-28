import 'package:edu_pridge_flutter/screens/student/nav_bar/chat_detail_screen.dart';
import 'package:flutter/material.dart';
//import '../../../core/constants/app_colors.dart';

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
    // 🌟 جلب حالة الوضع الليلي والألوان 🌟
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFFAFAFA);
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor, // 🌟 خلفية متجاوبة
        appBar: AppBar(
          backgroundColor: bgColor, // 🌟 متجاوبة
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor), // 🌟 أيقونة متجاوبة
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'بدء محادثة جديدة',
            style: TextStyle(
              color: textColor, // 🌟 نص متجاوب
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // شريط البحث
            _buildSearchBar(isDark, cardColor, textColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر مدرساً للمراسلة:',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey, // 🌟 متجاوب
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // قائمة المدرسين
            Expanded(
              child: ListView.builder(
                physics:
                    const BouncingScrollPhysics(), // لمسة جمالية عند التمرير
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return _buildTeacherCard(
                    context,
                    teacher,
                    isDark,
                    cardColor,
                    textColor,
                  );
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
        color: cardColor, // 🌟 متجاوب
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(40)
                : Colors.black.withAlpha(8), // 🌟 ظل متجاوب بـ withAlpha
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: textColor), // 🌟 لون النص المكتوب
        decoration: InputDecoration(
          hintText: 'ابحث عن مدرس...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey,
            fontSize: 14,
          ), // 🌟 متجاوب
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey.shade500 : Colors.grey,
          ), // 🌟 متجاوب
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTeacherCard(
    BuildContext context,
    Map<String, dynamic> teacher,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 متجاوب
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100,
        ), // 🌟 حد متجاوب
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
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
                    border: Border.all(
                      color: cardColor,
                      width: 2.5,
                    ), // 🌟 إطار يطابق لون الكارت الحالي
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          teacher['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ), // 🌟 متجاوب
        ),
        subtitle: Text(
          teacher['subject'],
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 12,
          ), // 🌟 متجاوب
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? Colors.grey.shade600 : Colors.grey, // 🌟 متجاوب
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
