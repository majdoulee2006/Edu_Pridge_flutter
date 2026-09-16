import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black;
          final subColor = isDark ? Colors.grey.shade400 : Colors.grey;

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "حول التطبيق" : "About App",
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.school_rounded, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Edu-Bridge",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "إصدار v1.0.2",
                        style: TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      isAr
                          ? "منصة Edu-Bridge هي نظام متكامل لإدارة الشؤون الأكاديمية والطلابية والمعاهد، تهدف لتسهيل التواجد، الخدمات الإلكترونية، ومتابعة المحاضرات والنتائج بكل يسر وأمان."
                          : "Edu-Bridge is a comprehensive platform for managing academic and student affairs, providing seamless e-services, attendance tracking, and grades management.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subColor, fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle(isAr ? "فريق التطوير" : "Development Team", textColor),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTeamRow("مجدولين محمود", textColor, subColor),
                          _buildDivider(subColor),
                          _buildTeamRow("إسراء منوّر", textColor, subColor),
                          _buildDivider(subColor),
                          _buildTeamRow("محمود غنّام", textColor, subColor),
                          _buildDivider(subColor),
                          _buildTeamRow("شهد زريقي", textColor, subColor),
                          _buildDivider(subColor),
                          _buildTeamRow("هبة الله عيسى", textColor, subColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle(isAr ? "تواصل معنا" : "Contact Us", textColor),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildContactRow(
                            icon: Icons.email_outlined,
                            label: "edubridge2006@gmail.com",
                            textColor: textColor,
                            onTap: () => _launchEmail("edubridge2006@gmail.com"),
                          ),
                          _buildDivider(subColor),
                          _buildContactRow(
                            icon: Icons.chat_outlined,
                            label: "0959031594",
                            textColor: textColor,
                            onTap: () => _launchWhatsApp("0959031594"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildDivider(Color subColor) {
    return Divider(height: 1, thickness: 0.5, color: subColor.withValues(alpha: 0.2));
  }

  Widget _buildTeamRow(String name, Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: subColor, size: 20),
          const SizedBox(width: 12),
          Text(name, style: TextStyle(fontSize: 14.5, color: textColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFCC00), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 14.5, color: textColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String localPhone) async {
    // 🇸🇾 تحويل الرقم المحلي (0959031594) لصيغة دولية (963959031594) عبر
    // حذف الصفر الأول وإضافة مفتاح سوريا +963، وهاي الصيغة يلي بيحتاجها
    // رابط wa.me حتى يفتح واتساب صح.
    final digitsOnly = localPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final withoutLeadingZero = digitsOnly.startsWith('0') ? digitsOnly.substring(1) : digitsOnly;
    final international = '963$withoutLeadingZero';

    final uri = Uri.parse('https://wa.me/$international');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
