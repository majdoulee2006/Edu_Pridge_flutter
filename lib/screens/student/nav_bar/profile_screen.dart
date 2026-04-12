import 'dart:io';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';

import 'student_home_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await Dio().get(
        "http://127.0.0.1:8000/api/student/profile",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint("Profile Data from Server: ${response.data}");
        setState(() {
          userData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب بيانات البروفايل: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 500,
      );
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : AppColors.background;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen())),
          ),
          title: Text('الملف الشخصي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => _showSuccessDialog(isDark),
              child: Text('حفظ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : Stack(
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
                      _InfoRow(
                        title: 'رقم الهاتف',
                        value: userData?['phone'] ?? "غير متوفر",
                        icon: Icons.phone_android,
                        isEditable: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPhoneScreen())),
                      ),
                      _InfoRow(
                        title: 'بريد الإلكتروني',
                        value: userData?['email'] ?? "غير متوفر",
                        icon: Icons.email,
                        isEditable: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditEmailScreen())),
                      ),
                    ],
                    cardColor, textColor, isDark,
                  ),

                  _buildSectionTitle('البيانات الأكاديمية'),
                  _buildInfoCard(
                    [
                      _InfoRow(
                        title: 'القسم',
                        value: userData?['department'] ?? 'غير متوفر',
                        icon: Icons.school,
                        isEditable: false,
                      ),
                      _InfoRow(
                        title: 'السنة الدراسية / الفرع',
                        // 🌟 حل مشكلة "غير محدد": التحقق من كلا المسميين الممكنين
                        value: userData?['academic_year']?.toString() ?? userData?['year']?.toString() ?? "غير محدد",
                        icon: Icons.account_tree_outlined,
                        isEditable: false,
                      ),
                    ],
                    cardColor, textColor, isDark,
                  ),

                  _buildSectionTitle('تفاصيل شخصية'),
                  _buildInfoCard(
                    [
                      _InfoRow(
                        title: 'تاريخ الميلاد',
                        // 🌟 حل مشكلة تنسيق التاريخ: إزالة الوقت الزائد (T00:00...)
                        value: userData?['birth_date'] != null
                            ? userData!['birth_date'].toString().split('T')[0]
                            : "00/00/0000",
                        icon: Icons.cake_outlined,
                        isEditable: false,
                      ),
                      _InfoRow(
                        title: 'الجنس',
                        value: userData?['gender'] ?? 'غير محدد',
                        icon: Icons.people_outline,
                        isEditable: false,
                      ),
                    ],
                    cardColor, textColor, isDark,
                  ),

                  _buildSectionTitle('الإعدادات'),
                  _buildSettingsItem(cardColor, textColor, isDark),
                ],
              ),
            ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen())),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
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
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 65,
                backgroundColor: const Color(0xFFFF7043),
                backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                child: _pickedImage == null ? const Icon(Icons.person, size: 70, color: Colors.white) : null,
              ),
            ),
            GestureDetector(
              onTap: () => _showImageSourceBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: bgColor, width: 2)),
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          userData?['name'] ?? userData?['full_name'] ?? "جاري التحميل...",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChip('طالب', isDark ? Colors.grey.shade800 : Colors.grey.shade100, isDark ? Colors.grey.shade300 : AppColors.textGrey),
            const SizedBox(width: 8),
            _buildChip('ID: ${userData?['university_id'] ?? '0000'}', isDark ? const Color(0xFF555000) : const Color(0xFFFCF9D1), isDark ? Colors.white : AppColors.textDark),
          ],
        ),
      ],
    );
  }

  void _showImageSourceBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('تغيير الصورة الشخصية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('اختيار من المعرض', style: TextStyle(color: textColor)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('التقاط صورة بالكاميرا', style: TextStyle(color: textColor)),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final dialogBgColor = isDark ? Theme.of(context).cardColor : Colors.white;
        final dialogTextColor = isDark ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 70),
              const SizedBox(height: 20),
              Text("تم الحفظ بنجاح!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dialogTextColor)),
              const SizedBox(height: 10),
              const Text("تم تحديث بيانات ملفك الشخصي وحفظ جميع التغييرات.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentHomeScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("حسناً", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows, Color cardColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(10), blurRadius: 10)],
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
                        decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade50, shape: BoxShape.circle),
                        child: Icon(entry.value.icon, color: isDark ? Colors.white70 : Colors.black87, size: 22),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value.title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(entry.value.value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                      ),
                      Icon(entry.value.isEditable ? Icons.edit : Icons.lock_outline, color: entry.value.isEditable ? AppColors.accent : (isDark ? Colors.grey.shade600 : Colors.grey.shade400), size: 20),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, indent: 20, endIndent: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem(Color cardColor, Color textColor, bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditPasswordScreen())),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(10), blurRadius: 10)]),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade50, shape: BoxShape.circle),
              child: Icon(Icons.history, color: isDark ? Colors.white70 : Colors.black87, size: 22),
            ),
            const SizedBox(width: 15),
            Text('تغيير كلمة المرور', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
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
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
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

  _InfoRow({required this.title, required this.value, required this.icon, required this.isEditable, this.onTap});
}