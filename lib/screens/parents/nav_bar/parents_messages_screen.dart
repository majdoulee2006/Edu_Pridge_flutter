import 'package:flutter/material.dart';
// استيراد الملفات اللازمة
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_profile_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parents_notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/parents/nav_bar/parent_home.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import '../../../widgets/parents_center_icon.dart';

class ParentsMessagesScreen extends StatefulWidget {
  const ParentsMessagesScreen({super.key});

  @override
  State<ParentsMessagesScreen> createState() => _ParentsMessagesScreenState();
}

class _ParentsMessagesScreenState extends State<ParentsMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    // 🎨 تعريف الألوان المتجاوبة مع الثيم
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            Column(
              children: [
                _buildChatHeader(context, cardColor, textColor),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildDateTag("اليوم", isDark),
                      _buildReceiverMessage("السلام عليكم أستاذ، يرجى تزويدي بتقرير الأداء الشهري للطلاب.", cardColor, textColor),
                      _buildSenderMessage("وعليكم السلام ورحمة الله،،"),
                      _buildSenderMessage("التقرير جاهز، سأقوم بإرساله الآن.", time: "09:42 ص", isRead: true),
                      _buildReceiverMessage("ممتاز، بانتظارك.", cardColor, textColor),
                      _buildFileMessage("تقرير_أكتوبر.pdf", "2.4 MB • PDF", "09:45 ص"),
                      const SizedBox(height: 120), // مساحة للناف بار
                    ],
                  ),
                ),
                _buildMessageInput(cardColor, textColor),
                const SizedBox(height: 100), // مساحة إضافية لرفع حقل الإدخال فوق الـ Nav
              ],
            ),

            // 2. الشريط السفلي الموحد (الذي تستخدمه صديقتك)
            CustomBottomNav(
              currentIndex: 3, // رقم صفحة الرسائل
              centerButton: const Parents_Center_Icon(),
              onHomeTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ParentsHomeScreen())),
              onProfileTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ParentsProfileScreen())),
              onNotificationsTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ParentsNotificationsScreen())),
              onMessagesTap: () {
                // نحن هنا بالفعل
              },
            ),
          ],
        ),
      ),
    );
  }

  // الهيدر العلوي (معدل ليدعم الألوان)
  Widget _buildChatHeader(BuildContext context, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFF0F0F0),
                child: Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text("المدير", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            ],
          ),
          const Spacer(),
          IconButton(icon: Icon(Icons.info_outline, color: textColor.withValues(alpha: 0.6)), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildDateTag(String text, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFF5F5F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  // رسالة الطرف الآخر (معدلة لتناسب اللون الخلفي)
  Widget _buildReceiverMessage(String message, Color cardColor, Color textColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 60),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(message, style: TextStyle(fontSize: 14, height: 1.6, color: textColor)),
      ),
    );
  }

  // رسالة المستخدم (تبقى بالأصفر لأنها هوية التطبيق)
  Widget _buildSenderMessage(String message, {String? time, bool isRead = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 5, right: 60),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEFFF00),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  if (isRead) ...[const SizedBox(width: 4), const Icon(Icons.done_all, size: 14, color: Colors.blue)],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(String fileName, String info, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEFFF00), borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.description, color: Colors.black)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                      Text(info, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.only(left: 10, top: 5), child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildMessageInput(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: textColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEFFF00),
              child: Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
            Expanded(
              child: TextField(
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: "اكتب رسالة...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.grey), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}