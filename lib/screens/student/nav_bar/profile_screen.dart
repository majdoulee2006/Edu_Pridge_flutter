import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_email_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_phone_screen.dart';
import 'package:edu_pridge_flutter/screens/shared/editing_screens/edit_password_screen.dart';
import 'package:edu_pridge_flutter/widgets/student_speed_dial.dart';
import 'package:edu_pridge_flutter/services/student_services.dart';
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
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentServices().getProfileData();
      if (data != null && mounted) setState(() { userData = data; _isLoading = false; });
    } catch (e) {
      debugPrint("خطأ في جلب بيانات البروفايل: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final ok = await StudentServices().updateProfileImage(bytes, 'avatar.jpg');
      if (ok && mounted) {
        await _fetchUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تحديث الصورة الشخصية', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Color(0xFFFFCC00),
          ));
        }
      }
    } catch (e) {
      debugPrint('Avatar error: $e');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('الملف الشخصي',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const StudentHomeScreen())),
          ),
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildProfileHeader(textColor),
                        const SizedBox(height: 30),

                        _buildSectionTitle("معلومات التواصل", textColor),
                        _buildInfoCard(cardColor, [
                          _buildClickableRow(
                            label: "رقم الهاتف",
                            value: userData?['phone'] ?? 'غير محدد',
                            icon: Icons.phone_android_rounded,
                            color: Colors.green,
                            textColor: textColor,
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const EditPhoneScreen()));
                              _fetchUserProfile();
                            },
                          ),
                          _buildDivider(textColor),
                          _buildClickableRow(
                            label: "البريد الإلكتروني",
                            value: userData?['email'] ?? 'غير محدد',
                            icon: Icons.alternate_email_rounded,
                            color: Colors.blue,
                            textColor: textColor,
                            onTap: () async {
                              await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const EditEmailScreen()));
                              _fetchUserProfile();
                            },
                          ),
                        ]),

                        const SizedBox(height: 25),
                        _buildSectionTitle("البيانات الأكاديمية", textColor),
                        _buildInfoCard(cardColor, [
                          _buildStaticRow(
                            label: "القسم",
                            value: userData?['department'] ?? 'غير محدد',
                            icon: Icons.account_balance_rounded,
                            color: Colors.purple,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "السنة الدراسية",
                            value: userData?['academic_year']?.toString() ?? 'غير محدد',
                            icon: Icons.auto_awesome_mosaic_rounded,
                            color: Colors.orange,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "تاريخ الميلاد",
                            value: userData?['birth_date'] != null
                                ? userData!['birth_date'].toString().split('T')[0]
                                : 'غير محدد',
                            icon: Icons.cake_outlined,
                            color: Colors.pink,
                            textColor: textColor,
                          ),
                          _buildDivider(textColor),
                          _buildStaticRow(
                            label: "الجنس",
                            value: userData?['gender'] ?? 'غير محدد',
                            icon: Icons.people_outline_rounded,
                            color: Colors.teal,
                            textColor: textColor,
                          ),
                        ]),

                        const SizedBox(height: 25),
                        _buildSectionTitle("الأمان والإعدادات", textColor),
                        _buildClickableSettingCard(
                          title: "تغيير كلمة المرور",
                          icon: Icons.lock_reset_rounded,
                          color: Colors.redAccent,
                          cardColor: cardColor,
                          textColor: textColor,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EditPasswordScreen())),
                        ),

                        const SizedBox(height: 150),
                      ],
                    ),
                  ),

            CustomBottomNav(
              currentIndex: 1,
              centerButton: const CustomSpeedDialEduBridge(),
              onHomeTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const StudentHomeScreen())),
              onProfileTap: () {},
              onNotificationsTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              onMessagesTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color textColor) {
    final avatarUrl = userData?['avatar'] as String?;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC00), width: 3),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFFF7043),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator(color: Colors.white)
                      : (avatarUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null),
                ),
              ),
            ),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFCC00),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          userData?['name'] ?? userData?['full_name'] ?? '—',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo'),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChip('طالب', const Color(0xFF263238), Colors.white70),
            const SizedBox(width: 8),
            _buildChip(
              'ID: ${userData?['student_code'] ?? userData?['username'] ?? '—'}',
              const Color(0xFFFFCC00).withValues(alpha: 0.2),
              const Color(0xFFFFCC00),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 5, bottom: 10),
        child: Text(title,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildInfoCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(Color textColor) {
    return Divider(height: 1, color: textColor.withValues(alpha: 0.1), indent: 20, endIndent: 20);
  }

  Widget _buildClickableRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildIconBubble(icon, color),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Cairo')),
                ],
              ),
            ),
            Icon(Icons.edit_note_rounded, color: color.withValues(alpha: 0.6), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildIconBubble(icon, color),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Cairo')),
                Text(value,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: textColor, fontFamily: 'Cairo')),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildClickableSettingCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            _buildIconBubble(icon, color),
            const SizedBox(width: 15),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: textColor, fontFamily: 'Cairo')),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBubble(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
