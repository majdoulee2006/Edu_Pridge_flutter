
import 'package:flutter/material.dart';

class AddTrainerScreen extends StatelessWidget {
  const AddTrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إنشاء حساب مدرب"), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _customField("اسم المدرب الكامل", Icons.person),
              _customField("التخصص الأكاديمي", Icons.school),
              _customField("البريد الإلكتروني", Icons.email),
              _customField("كلمة المرور", Icons.lock, isPass: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: const Color(0xFFEFFF00),
                ),
                child: const Text("حفظ البيانات", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _customField(String hint, IconData icon, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}