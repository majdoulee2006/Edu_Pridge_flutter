import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'create_teacher_screen.dart';
import 'create_head_screen.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // 🔹 بس معلم ورئيس قسم
    final List<Map<String, dynamic>> options = [
      {
        'title': 'معلم',
        'icon': Icons.person_outline,
        'color': Colors.green,
        'screen': const CreateTeacherScreen(),
      },
      {
        'title': 'رئيس قسم',
        'icon': Icons.manage_accounts_outlined,
        'color': Colors.purple,
        'screen': const CreateHeadScreen(),
      },
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ═══════════════════════════════════════
              // الهيدر
              // ═══════════════════════════════════════
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.settings, color: textColor, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ),
                    Text(
                      "إنشاء حساب جديد",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ═══════════════════════════════════════
              // شبكة الأيقونات
              // ═══════════════════════════════════════
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return _buildOptionCard(
                        context,
                        title: option['title'],
                        icon: option['icon'] as IconData,
                        color: option['color'] as Color,
                        screen: option['screen'] as Widget,
                        cardColor: cardColor,
                        textColor: textColor,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // بطاقة الأيقونة
  // ═══════════════════════════════════════
  Widget _buildOptionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required Widget screen,
        required Color cardColor,
        required Color textColor,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                Theme.of(context).brightness == Brightness.dark ? 30 : 8,
              ),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Noto Sans Arabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}