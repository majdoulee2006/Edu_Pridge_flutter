import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _fontSize = 1.0;
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  bool _isSoundsEnabled = true; // جديد
  bool _isVibrationEnabled = false; // جديد

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("الإعدادات",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كرت البروفايل العلوي
              _buildProfileCard(),
              const SizedBox(height: 25),

              _buildSectionTitle("المظهر"),
              _buildFontSizeSlider(),
              _buildSwitchTile(Icons.dark_mode_outlined, "الوضع الداكن", _isDarkMode, (val) => setState(() => _isDarkMode = val)),

              const SizedBox(height: 25),
              _buildSectionTitle("اللغة"),
              _buildLanguageTile(),

              const SizedBox(height: 25),
              _buildSectionTitle("الإشعارات"),
              _buildSwitchTile(Icons.notifications_none_outlined, "تفعيل الإشعارات", _isNotificationsEnabled, (val) => setState(() => _isNotificationsEnabled = val)),
              _buildSwitchTile(Icons.volume_up_outlined, "الأصوات", _isSoundsEnabled, (val) => setState(() => _isSoundsEnabled = val)),
              _buildSwitchTile(Icons.vibration_outlined, "الاهتزاز", _isVibrationEnabled, (val) => setState(() => _isVibrationEnabled = val)),

              const SizedBox(height: 40),

              // قسم شعار التطبيق والإصدار (بناءً على صورتك)
              _buildAppInfoSection(),

              const SizedBox(height: 30),

              // زر تسجيل الخروج
              _buildLogoutButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("أ. أحمد محمد", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("عضو هيئة تدريس", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.verified_user, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.text_fields, color: Colors.black),
              SizedBox(width: 10),
              Text("حجم الخط", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _fontSize,
            divisions: 2,
            activeColor: const Color(0xFFEFFF00),
            inactiveColor: Colors.grey[200],
            onChanged: (val) => setState(() => _fontSize = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("صغير", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("متوسط", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("كبير", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Switch(
          value: value,
          activeThumbColor: const Color(0xFFEFFF00),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const Icon(Icons.language, color: Colors.black),
        title: const Text("لغة التطبيق", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
          child: const Text("عربي", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // قسم معلومات التطبيق الجديد (Edu-Bridge)
  Widget _buildAppInfoSection() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFF00),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.school, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 15),
          const Text("Edu-Bridge",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("التطبيق الرسمي لإدارة شؤون الطلاب\nوالمحاضرات والواجبات.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Version 1.0.2",
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        // منطق تسجيل الخروج هنا
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE), // لون أحمر فاتح جداً خلف الزر
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text("تسجيل الخروج",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}