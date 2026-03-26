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
    return Directionality(
      textDirection: TextDirection.rtl, // لضمان ظهور العناصر من اليمين لليسار
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // خلفية فاتحة
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "تغيير كلمة السر",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          // ✅ تم ضبط سهم الرجوع ليؤشر لليمين بشكل صحيح
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // 1. الأيقونة المضيئة (Glowing Icon)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEFFF00).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sync_lock_rounded, // أيقونة مشابهة للقفل مع التحديث
                    size: 45,
                    color: Color(0xFFEFFF00),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 2. النص التوضيحي
              const Text(
                "قم بإنشاء كلمة مرور قوية لحماية حسابك الأكاديمي",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
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
                  setState(() {
                    _obscureCurrent = !_obscureCurrent;
                  });
                },
              ),

              const SizedBox(height: 25),

              // 4. كلمة السر الجديدة + تلميح (8 أحرف)
              _buildPasswordField(
                label: "كلمة السر الجديدة",
                hintText: "أدخل كلمة السر الجديدة",
                prefixIcon: Icons.key_outlined,
                obscureText: _obscureNew,
                onToggleVisibility: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
              const SizedBox(height: 8),
              // تلميح الحماية
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "8 أحرف على الأقل",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),

              const SizedBox(height: 50),

              // 6. زر حفظ التغييرات (الأصفر)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // 🌟 إظهار نافذة (Pop-up) لتأكيد نجاح العملية 🌟
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // يمنع إغلاق النافذة عند الضغط خارجها
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.green,
                                size: 70,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "تم بنجاح!",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "تم تغيير كلمة السر الخاصة بك بنجاح.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                height: 45,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                    ); // إغلاق النافذة المنبثقة
                                    Navigator.pop(
                                      context,
                                    ); // الرجوع لواجهة البروفايل
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEFFF00),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    "حسناً",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFFF00),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "حفظ التغييرات",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                child: const Text(
                  "إلغاء",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت مخصص لبناء حقول كلمة السر
  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الحقل
        Padding(
          padding: const EdgeInsets.only(right: 15, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
        // الحقل نفسه
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              // الأيقونة الأساسية (قفل، مفتاح، درع)
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.grey.shade500,
                size: 20,
              ),
              // أيقونة العين (إظهار/إخفاء)
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
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
