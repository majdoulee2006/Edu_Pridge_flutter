import 'package:flutter/material.dart';

class EditPasswordScreen extends StatefulWidget {
  const EditPasswordScreen({super.key});

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  // للتحكم بإظهار أو إخفاء كلمات المرور
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف المتغيرات اللونية بناءً على الثيم الحالي
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryYellow = const Color(0xFFEFFF00);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "تغيير كلمة السر",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 1. الأيقونة المضيئة (تتكيف مع الخلفية)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryYellow.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.sync_lock_rounded,
                    size: 45,
                    color: primaryYellow,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. النص التوضيحي
              Text(
                "قم بإنشاء كلمة مرور قوية لحماية حسابك الأكاديمي",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              // 3. كلمة السر الحالية
              _buildPasswordField(
                label: "كلمة السر الحالية",
                hintText: "********",
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscureCurrent,
                onToggleVisibility: () {
                  setState(() => _obscureCurrent = !_obscureCurrent);
                },
                textColor: textColor,
                cardColor: cardColor,
              ),

              const SizedBox(height: 25),

              // 4. كلمة السر الجديدة
              _buildPasswordField(
                label: "كلمة السر الجديدة",
                hintText: "أدخل كلمة السر الجديدة",
                prefixIcon: Icons.key_outlined,
                obscureText: _obscureNew,
                onToggleVisibility: () {
                  setState(() => _obscureNew = !_obscureNew);
                },
                textColor: textColor,
                cardColor: cardColor,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    "8 أحرف على الأقل",
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. تأكيد كلمة السر الجديدة
              _buildPasswordField(
                label: "تأكيد كلمة السر الجديدة",
                hintText: "أعد إدخال كلمة السر",
                prefixIcon: Icons.shield_outlined,
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
                textColor: textColor,
                cardColor: cardColor,
              ),

              const SizedBox(height: 50),

              // 6. زر حفظ التغييرات
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _showSuccessDialog(context, primaryYellow, cardColor, textColor, subTextColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "حفظ التغييرات",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.save_outlined, color: Colors.black, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 7. زر الإلغاء
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "إلغاء",
                  style: TextStyle(color: subTextColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // دالة إظهار نافذة النجاح مع مراعاة الثيم
  void _showSuccessDialog(BuildContext context, Color primaryYellow, Color cardColor, Color textColor, Color subTextColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 70),
              const SizedBox(height: 20),
              Text(
                "تم بنجاح!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 10),
              Text(
                "تم تغيير كلمة السر الخاصة بك بنجاح.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // إغلاق الدايلوج
                    Navigator.pop(context); // العودة للخلف
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    "حسناً",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required Color textColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            obscureText: obscureText,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              prefixIcon: Icon(prefixIcon, color: textColor.withValues(alpha: 0.5), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: textColor.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
}