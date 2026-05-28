import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';

class AffairsOfficerMessagesScreen extends StatefulWidget {
  const AffairsOfficerMessagesScreen({super.key});

  @override
  State<AffairsOfficerMessagesScreen> createState() => _AffairsOfficerMessagesScreenState();
}

class _AffairsOfficerMessagesScreenState extends State<AffairsOfficerMessagesScreen> {
  // 🔹 بيانات المحادثات (نفس شكل الصورة المرفقة)
  final List<Map<String, dynamic>> conversations = [
    {
      'name': 'د. خالد العمري',
      'message': 'السلام عليكم تم إرسال تقرير الأداء ال...',
      'time': '10:30 ص',
      'unreadCount': 2,
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'isOnline': true,
    },
    {
      'name': 'أ. سارة المنصور',
      'message': 'هل يمكن تأجيل ورشة العمل إلى الأسب...',
      'time': '09:15',
      'unreadCount': 1,
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'isOnline': true,
    },
    {
      'name': 'م. أحمد فؤاد',
      'message': 'شكراً جزيلاً لك.',
      'time': 'أمس',
      'unreadCount': 0,
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'isOnline': false,
    },
    {
      'name': 'فريق التدريب التقني',
      'message': 'تم تحديث المناهج الدراسية على المنصة',
      'time': 'الاثنين',
      'unreadCount': 0,
      'avatar': null,
      'isOnline': false,
      'isGroup': true,
    },
    {
      'name': 'أ. منى السيد',
      'message': 'بخصوص استفسار الطالب محمد علي...',
      'time': 'الأحد',
      'unreadCount': 0,
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان وثيم باقي المشروع
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor   = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ═══════════════════════════════════════
                  // الهيدر: زر رجوع (يمين) | العنوان (وسط) | إعدادات (يسار)
                  // ═══════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ✅ زر الإعدادات على اليسار
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                        // عنوان "الرسائل" بالمنتصف
                        Text(
                          "الرسائل",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                        // ✅ زر الرجوع على اليمين - سهم للخلف
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back, // ← سهم للخلف (سيكون متجهاً لليمين بسبب RTL)
                              color: textColor,
                              size: 26,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ═══════════════════════════════════════
                  // حقل البحث
                  // ═══════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 8),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Noto Sans Arabic',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'بحث عن مدير أو محادثة...',
                          hintStyle: TextStyle(
                            color: subColor,
                            fontFamily: 'Noto Sans Arabic',
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search, color: subColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ═══════════════════════════════════════
                  // قائمة المحادثات
                  // ═══════════════════════════════════════
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        return _buildConversationCard(
                          conversations[index],
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // الشريط السفلي الجاهز
            // ═══════════════════════════════════════
            CustomBottomNav(
              currentIndex: 3, // الرسائل ✅
              centerButton: AffairsOfficerSpeedDial(),
              onHomeTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerHomeScreen()),
                );
              },
              onProfileTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerProfileScreen()),
                );
              },
              onNotificationsTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerNotificationsScreen()),
                );
              },
              onMessagesTap: () {
                // أنت هون بالفعل
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // بطاقة المحادثة
  // ═══════════════════════════════════════
  Widget _buildConversationCard(
      Map<String, dynamic> data, {
        required Color cardColor,
        required Color textColor,
        required Color subColor,
        required bool isDark,
      }) {
    final bool hasUnread = (data['unreadCount'] ?? 0) > 0;
    final bool isOnline = data['isOnline'] ?? false;
    final String? avatarUrl = data['avatar'];
    final bool isGroup = data['isGroup'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: الانتقال لشاشة المحادثة الفردية
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ═══ الصورة الشخصية + حالة الاتصال ═══
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isGroup
                          ? const Color(0xFF0D9488)
                          : const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                      image: avatarUrl != null
                          ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? Icon(
                      isGroup ? Icons.groups : Icons.person,
                      color: isGroup ? Colors.white : Colors.grey.shade600,
                      size: 28,
                    )
                        : null,
                  ),
                  // نقطة الاتصال الخضراء
                  if (isOnline && !isGroup)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cardColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // ═══ النصوص (الاسم + الرسالة) ═══
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['message'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? textColor.withOpacity(0.8) : subColor,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ═══ الوقت + عداد الرسائل غير المقروءة ═══
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    data['time'],
                    style: TextStyle(
                      fontSize: 11,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasUnread)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${data['unreadCount']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}