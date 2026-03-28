import 'dart:io'; // ✅ إضافة استيراد للتعامل مع الملفات (الصورة)
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
// ✅ تم إضافة استدعاء واجهة تغيير كلمة المرور
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ✅ إضافة مكتبة اختيار الصور
import '../../../core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';

// استدعاء الصفحات للتنقل
import 'student_home_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // متغير لحفظ تاريخ الميلاد وتحديثه على الشاشة
  String dob = '15 مايو 2002';

  // ✅ متغير لحفظ ملف الصورة المختارة
  File? _pickedImage;
  // ✅ كائن للتعامل مع اختيار الصور
  final ImagePicker _picker = ImagePicker();

  // ✅ دالة لاختيار الصورة من المصدر (كاميرا أو معرض)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // تقليل الجودة قليلاً للحفاظ على الأداء
        maxWidth: 500, // تحديد أقصى عرض للصورة
      );
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path); // تحديث الحالة بالصورة الجديدة
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة')),
        );
      }
    }
  }

  // ✅ دالة لإظهار القائمة السفلية لاختيار مصدر الصورة
  void _showImageSourceBottomSheet(BuildContext context) {
    // 🌟 جلب الثيم للقائمة السفلية
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor, // 🌟 لون متجاوب
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'تغيير الصورة الشخصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: Text(
                  'اختيار من المعرض',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context); // إغلاق القائمة
                  _pickImage(ImageSource.gallery); // اختيار من المعرض
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(
                  'التقاط صورة بالكاميرا',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.pop(context); // إغلاق القائمة
                  _pickImage(ImageSource.camera); // التقاط بالكاميرا
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // دالة فتح التقويم مع شرط العمر (18 سنة فما فوق)
  // 📝 ملاحظة: هذه الدالة لم تعد مستخدمة ولكن تم الإبقاء عليها بناءً على الطلب
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    // حساب أقصى تاريخ مسموح (اليوم الحالي ناقص 18 سنة)
    final DateTime maxDate = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: DateTime(1950),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dob = '${picked.year}/${picked.month}/${picked.day}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب حالة الوضع الليلي والألوان المتجاوبة 🌟
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : AppColors.background;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor, // 🌟 متجاوب
        appBar: AppBar(
          backgroundColor: bgColor, // 🌟 متجاوب
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor), // 🌟 متجاوب
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentHomeScreen(),
              ),
            ),
          ),
          title: Text(
            'الملف الشخصي',
            style: TextStyle(
              color: textColor, // 🌟 متجاوب
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                // 🌟 إظهار النافذة المنبثقة عند الضغط على زر حفظ 🌟
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // يمنع الإغلاق عند الضغط خارج النافذة
                  builder: (BuildContext context) {
                    final dialogBgColor = isDark
                        ? Theme.of(context).cardColor
                        : Colors.white;
                    final dialogTextColor = isDark
                        ? Colors.white
                        : Colors.black;

                    return AlertDialog(
                      backgroundColor: dialogBgColor, // 🌟 متجاوب
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
                          Text(
                            "تم الحفظ بنجاح!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: dialogTextColor, // 🌟 متجاوب
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "تم تحديث بيانات ملفك الشخصي وحفظ جميع التغييرات.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // 1. إغلاق النافذة
                                Navigator.pushReplacement(
                                  // 2. الرجوع لشاشة الهوم
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentHomeScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.accent, // استخدام لون التطبيق
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "حسناً",
                                style: TextStyle(
                                  color: Colors
                                      .black, // النص أسود دائماً للتباين مع الأصفر
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
              child: Text(
                'حفظ',
                style: TextStyle(
                  color: textColor, // 🌟 متجاوب
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileHeader(bgColor, textColor, isDark),
                  const SizedBox(height: 30),

                  _buildSectionTitle('معلومات التواصل'),
                  _buildInfoCard(
                    [
                      // الانتقال لواجهة تعديل الهاتف
                      _InfoRow(
                        title: 'رقم الهاتف',
                        value: '4567 123 050',
                        icon: Icons.phone_android,
                        isEditable: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditPhoneScreen(),
                            ),
                          );
                        },
                      ),
                      // ✅ تم تفعيل الضغط للانتقال لواجهة تعديل الإيميل
                      _InfoRow(
                        title: 'بريد الإلكتروني',
                        value: 'ahmed.ali@institute.edu',
                        icon: Icons.email,
                        isEditable: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditEmailScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    cardColor,
                    textColor,
                    isDark,
                  ),

                  _buildSectionTitle('البيانات الأكاديمية'),
                  _buildInfoCard(
                    [
                      _InfoRow(
                        title: 'القسم',
                        value: 'هندسة الحاسوب',
                        icon: Icons.school,
                        isEditable: false,
                      ),
                      _InfoRow(
                        title: 'السنة الدراسية / الفرع',
                        value: 'السنة الثالثة',
                        icon: Icons.account_tree_outlined,
                        isEditable: false,
                      ),
                    ],
                    cardColor,
                    textColor,
                    isDark,
                  ),

                  _buildSectionTitle('تفاصيل شخصية'),
                  _buildInfoCard(
                    [
                      _InfoRow(
                        title: 'تاريخ الميلاد',
                        value: dob,
                        icon: Icons.cake_outlined,
                        isEditable:
                            false, // 🔒 تم التغيير لـ false لمنع التعديل
                        onTap: null, // 🔒 إزالة حدث الضغط
                      ),
                      _InfoRow(
                        title: 'الجنس',
                        value: 'ذكر',
                        icon: Icons.people_outline,
                        isEditable: false,
                      ),
                    ],
                    cardColor,
                    textColor,
                    isDark,
                  ),

                  _buildSectionTitle('الإعدادات'),
                  _buildSettingsItem(cardColor, textColor, isDark),
                ],
              ),
            ),

            // 🌟 استدعاء الشريط الموحد هنا بدلاً من الأكواد الطويلة 🌟
            CustomBottomNav(
              currentIndex: 1, // 1 = الملف الشخصي مفعّل
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              ),
              onProfileTap: () {}, // نحن بالفعل هنا
              onNotificationsTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              onMessagesTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color bgColor, Color textColor, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: bgColor, // 🌟 لون متجاوب للحدود
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundColor: const Color(0xFFFF7043),
                // ✅ عرض الصورة المختارة إذا وجدت، وإلا عرض الأيقونة الافتراضية
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : null,
                child: _pickedImage == null
                    ? const Icon(Icons.person, size: 70, color: Colors.white)
                    : null,
              ),
            ),
            // ✅ جعل زر الكاميرا قابلاً للضغط
            GestureDetector(
              onTap: () => _showImageSourceBottomSheet(
                context,
              ), // فتح قائمة اختيار الصورة
              child: Positioned(
                right: 5,
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bgColor,
                      width: 2,
                    ), // 🌟 لون الإطار متجاوب
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors
                        .black, // الأيقونة سوداء دائماً لتباينها مع الأصفر
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'أحمد محمد علي',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor, // 🌟 متجاوب
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChip(
              'طالب',
              isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              isDark ? Colors.grey.shade300 : AppColors.textGrey,
            ),
            const SizedBox(width: 8),
            _buildChip(
              'ID: 202300159',
              isDark ? const Color(0xFF555000) : const Color(0xFFFCF9D1),
              isDark ? Colors.white : AppColors.textDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    List<_InfoRow> rows,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor, // 🌟 متجاوب
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // 🌟 استخدام withAlpha لتجنب التحذيرات 🌟
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : Colors.black.withAlpha(10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          bool isLast = entry.key == rows.length - 1;
          return InkWell(
            onTap: entry.value.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.grey.shade50, // 🌟 متجاوب
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entry.value.icon,
                          color: isDark
                              ? Colors.white70
                              : Colors.black87, // 🌟 متجاوب
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.title,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.value.value,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor, // 🌟 متجاوب
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        entry.value.isEditable
                            ? Icons.edit
                            : Icons.lock_outline,
                        color: entry.value.isEditable
                            ? AppColors.accent
                            : (isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100, // 🌟 متجاوب
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem(Color cardColor, Color textColor, bool isDark) {
    return InkWell(
      // ✅ تم إضافة InkWell لتفعيل الضغط والانتقال للواجهة
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditPasswordScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor, // 🌟 متجاوب
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(50)
                  : Colors.black.withAlpha(10),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.grey.shade50, // 🌟 متجاوب
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                color: isDark ? Colors.white70 : Colors.black87,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Text(
              'تغيير كلمة المرور',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ), // 🌟 متجاوب
            ),
            const Spacer(),
            const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final String title;
  final String value;
  final IconData icon;
  final bool isEditable;
  final VoidCallback? onTap;

  _InfoRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.isEditable,
    this.onTap,
  });
}
