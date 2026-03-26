import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:flutter/material.dart';
//import '../../widgets/student_speed_dial.dart';
//import '../../widgets/teacher_speed_dial.dart';
import '../teacher/teacher_home.dart';
import '../student/nav_bar/student_home_screen.dart';
import 'forgot_password_screen.dart';
// ✅ استيراد صفحة إنشاء الحساب الجديدة
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // متغير للتحكم بإظهار أو إخفاء كلمة المرور
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان دعم اللغة العربية والاتجاهات
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // 1. الشعار (الأيقونة العلوية)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF9E7), // لون أصفر فاتح جداً للخلفية
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      size: 50,
                      color: Color(0xFFD4AC0D), // لون ذهبي/أصفر غامق للأيقونة
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 2. نصوص الترحيب
                const Text(
                  "مرحباً بك مجدداً",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "بوابة المعهد الجامعي للطلاب والمعلمين",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 3. حقول الإدخال
                _buildTextField(
                  label: "اسم المستخدم",
                  hint: "أدخل اسم المستخدم",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: "رقم الهاتف",
                  hint: "05x xxx xxxx",
                  icon: Icons.phone_iphone_outlined, // أيقونة الجوال
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: "كلمة المرور",
                  hint: "........",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 10),

                // 4. زر هل نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // ✅ الربط بصفحة استعادة كلمة المرور
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "هل نسيت كلمة المرور؟",
                      style: TextStyle(
                        color: Color(0xFFA4A000), // لون أصفر مخضر مطابق للصورة
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. زر تسجيل الدخول الأساسي
                ElevatedButton(
                  onPressed: () {
                    // الانتقال لواجهة المعلم ومنع الرجوع للخلف (تعدل لاحقاً حسب الصلاحيات)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00), // لون الزر الأصفر
                    foregroundColor: Colors.black, // لون النص
                    minimumSize: const Size(
                      double.infinity,
                      55,
                    ), // عرض الزر وارتفاعه
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        30,
                      ), // حواف دائرية بالكامل
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // السهم الذي يؤشر لليسار
                      const Icon(
                        Icons.arrow_forward,
                        size: 22,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "تسجيل الدخول",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 6. الفاصل (أو / OR)
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "أو",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 7. زر إنشاء حساب جديد
                OutlinedButton(
                  onPressed: () {
                    // ✅ تم ربط صفحة إنشاء حساب جديد هنا
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateAccountScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ), // إطار رمادي فاتح
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "إنشاء حساب جديد",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // ==========================================
                // أزرار مؤقتة للمطورين (تُحذف قبل تسليم المشروع)
                // ==========================================
                const SizedBox(height: 40),
                const Divider(),
                const Text(
                  "اختصارات للمطورين (للتجربة فقط):",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10, // المسافة الأفقية بين الأزرار
                  runSpacing: 10, // المسافة العمودية بين الأزرار
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentHomeScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'دخول كطالب',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeacherHomeScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'دخول كمدرب',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // لون مميز لولي الأمر
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            // ✅ استدعاء واجهة الأهل
                            builder: (context) => const ParentsHomeScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'دخول كولي أمر',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت لبناء حقل الإدخال المخصص بتصميم مطابق للصورة
  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // للواجهة العربية (RTL) يبدأ من اليمين
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            obscureText: isPassword ? _obscurePassword : false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              // الأيقونة الأساسية تظهر على اليسار (في الواجهة العربية نستخدم suffixIcon)
              suffixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(icon, color: Colors.grey.shade600, size: 22),
              ),
              // أيقونة إظهار/إخفاء الباسوورد تظهر على اليمين (في الواجهة العربية نستخدم prefixIcon)
              prefixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
