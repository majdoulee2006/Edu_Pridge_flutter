import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isAr = AppSettings.language.value == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  isAr ? 'تم إنشاء الحساب بنجاح ✓' : 'Account Created Successfully ✓',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  isAr
                      ? 'تم استلام طلب تسجيلك بنجاح.\nطلبك الآن قيد المراجعة، يرجى انتظار التفعيل وإشعار القبول من قِبل موظف الشؤون.'
                      : 'Your registration request has been received.\nYour request is under review, please await activation and approval notification from Student Affairs.',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.6,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    ),
                    child: Text(
                      isAr ? 'الذهاب لتسجيل الدخول' : 'Go to Sign In',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
