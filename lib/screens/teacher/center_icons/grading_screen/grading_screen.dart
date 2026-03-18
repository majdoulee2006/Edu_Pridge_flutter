import 'package:flutter/material.dart';
import '../../../../widgets/custom_speed_dial.dart';
import '../../messages_screen.dart';
import '../../profile_screen.dart';
import '../../teacher_home.dart';

class GradingScreen extends StatelessWidget {
  const GradingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryYellow = Color(0xFFEFFF00);
    const Color backgroundColor = Color(0xFFF7F7F7);
    const Color textDarkColor = Color(0xFF333333);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
          title: const Text(
            'تفاصيل الرد',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. كارد معلومات الطالب والواجب
              _buildStudentHeaderCard(),
              const SizedBox(height: 20),

              // 2. إجابة الطالب
              _buildSectionTitle("إجابة الطالب"),
              _buildResponseContent("مرحباً أستاذ، قمت بحل المسائل المطلوبة في الصفحة 45. بالنسبة للسؤال الثالث، استخدمت قانون حفظ الطاقة الميكانيكية للوصول للنتيجة النهائية. أرفقت ملف الحل وصورة للرسم البياني."),
              const SizedBox(height: 20),

              // 3. المرفقات
              _buildSectionTitle("المرفقات"),
              _buildAttachmentItem("حل_واجب_الفيزياء.pdf", "2.4 MB", Icons.picture_as_pdf, Colors.red),
              const SizedBox(height: 10),
              _buildAttachmentItem("رسم_بياني.jpg", "1.1 MB", Icons.image, Colors.orange),
              const SizedBox(height: 25),

              // 4. التصحيح (الدرجة والملاحظات)
              _buildGradingSection(primaryYellow),

              const SizedBox(height: 100), // مساحة إضافية عشان الـ Bottom Nav
            ],
          ),
        ),

        // الزر الدائري الأوسط
        floatingActionButton: CustomSpeedDialEduBridge(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // شريط التنقل السفلي كما في الصفحات السابقة
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  // --- ويجيت بناء الأجزاء المختلفة ---

  Widget _buildStudentHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFFDEBB8),
              child: Icon(Icons.person, color: Colors.orange),
            ),
            title: const Text("أحمد محمد علي", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("طالب - السنة الثانية", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const Divider(),
          const Text("الواجب المطلوب", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, color: Colors.yellow, size: 20),
              SizedBox(width: 8),
              Text("واجب الفيزياء: الطاقة الحركية", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Row(
        children: [
          Container(width: 4, height: 15, color: Colors.yellow),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResponseContent(String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Text(content, style: const TextStyle(color: Colors.grey, height: 1.5)),
    );
  }

  Widget _buildAttachmentItem(String name, String size, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(size, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.download, color: Colors.grey, size: 20), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildGradingSection(Color btnColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("الدرجة المستحقة (من 100)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: "0",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
        const Text("ملاحظات المعلم", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "اكتب ملاحظاتك للطالب هنا...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text("حفظ التصحيح", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 70,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home_outlined, "الرئيسية", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TeacherHomeScreen()))),
          _navItem(context, Icons.person_outline, "الملف", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))),
          const SizedBox(width: 40),
          _navItem(context, Icons.notifications_none, "الإشعارات", false, onTap: () {}),
          _navItem(context, Icons.chat_bubble_outline, "الرسائل", false, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen()))),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFFEFFF00) : Colors.grey),
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFFEFFF00) : Colors.grey)),
        ],
      ),
    );
  }
}