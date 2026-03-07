import 'package:flutter/material.dart';

class AppColors {
  // 1. اللون الأخضر الأساسي (المستخدم في العناوين والنجاح)
  static const Color primary = Color(0xFF2E7D32);

  // 2. اللون الأصفر المميز (المستخدم في الزر العائم)
  static const Color accent = Color(0xFFEFFF00);

  // 3. ألوان الخلفية
  static const Color background = Color(0xFFF9F9F7);
  static const Color white = Colors.white;

  // 4. ألوان النصوص
  static const Color textDark = Color(0xFF212121); // للخطوط العريضة والأسماء
  static const Color textGrey = Color(0xFF9E9E9E); // للنصوص الثانوية والتاريخ

  // 5. ألوان التنبيهات
  static const Color error = Color(0xFFD32F2F);   // للخطأ أو التنبيهات الهامة
  static const Color success = Color(0xFF4CAF50); // لعمليات الحفظ الناجحة
}