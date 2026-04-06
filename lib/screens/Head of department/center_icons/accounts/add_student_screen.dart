import 'package:flutter/material.dart';

class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);

    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء حساب طالب جديد", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("المعلومات الأساسية", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 20),
              _buildInput(label: "اسم الطالب الكامل", icon: Icons.person_outline, isDark: isDark),
              _buildInput(label: "الرقم الأكاديمي", icon: Icons.numbers, isDark: isDark),
              _buildInput(label: "المستوى الدراسي / السنة", icon: Icons.grade_outlined, isDark: isDark),
              _buildInput(label: "البريد الإلكتروني", icon: Icons.email_outlined, isDark: isDark),
              _buildInput(label: "كلمة المرور", icon: Icons.lock_outline, isDark: isDark, isPass: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // الربط مع الـ API لاحقاً
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("تأكيد وحفظ البيانات", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, required bool isDark, bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}