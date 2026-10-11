import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../shared/settings_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'ar';

  @override
  void initState() {
    super.initState();
    _selectedLang = AppSettings.language.value;
  }

  Future<void> _handleContinue() async {
    await AppSettings.setLanguage(_selectedLang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selected', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryYellow = Color(0xFFFFCC00);
    final textColor = isDark ? Colors.white : Colors.black87;
    final isAr = _selectedLang == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Logo & Icon
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark
                        ? primaryYellow.withValues(alpha: 0.12)
                        : const Color(0xFFFEF9E7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryYellow.withValues(alpha: isDark ? 0.2 : 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: primaryYellow,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Edu-Bridge",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  isAr ? "اختر لغة التطبيق للمتابعة" : "Choose your preferred language",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                ),

                const Spacer(flex: 2),

                // Language Card: Arabic
                _buildLanguageCard(
                  langCode: 'ar',
                  flag: '🇸🇦',
                  title: 'العربية',
                  subTitle: 'Arabic',
                  isSelected: _selectedLang == 'ar',
                  isDark: isDark,
                  primaryYellow: primaryYellow,
                  textColor: textColor,
                ),

                const SizedBox(height: 16),

                // Language Card: English
                _buildLanguageCard(
                  langCode: 'en',
                  flag: '🇬🇧',
                  title: 'English',
                  subTitle: 'الإنجليزية',
                  isSelected: _selectedLang == 'en',
                  isDark: isDark,
                  primaryYellow: primaryYellow,
                  textColor: textColor,
                ),

                const Spacer(flex: 3),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      foregroundColor: Colors.black,
                      elevation: 4,
                      shadowColor: primaryYellow.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isAr ? "متابعة" : "Continue",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String langCode,
    required String flag,
    required String title,
    required String subTitle,
    required bool isSelected,
    required bool isDark,
    required Color primaryYellow,
    required Color textColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _selectedLang = langCode;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? primaryYellow.withValues(alpha: 0.15)
                      : const Color(0xFFFFF9DB))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? primaryYellow
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: primaryYellow.withValues(alpha: isDark ? 0.2 : 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Flag badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 16),

                // Language titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),

                // Radio/Check Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryYellow : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primaryYellow
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.black,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
