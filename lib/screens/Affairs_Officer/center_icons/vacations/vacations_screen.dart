import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/widgets/Affairs_Officer_speed_dial.dart';
import 'package:edu_pridge_flutter/screens/shared/custom_bottom_nav.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/home_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/profile_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/notifications_screen.dart';
import 'package:edu_pridge_flutter/screens/Affairs_Officer/nav_bar/messages_screen.dart';

class AffairsOfficerVacationsScreen extends StatefulWidget {
  const AffairsOfficerVacationsScreen({super.key});

  @override
  State<AffairsOfficerVacationsScreen> createState() => _AffairsOfficerVacationsScreenState();
}

class _AffairsOfficerVacationsScreenState extends State<AffairsOfficerVacationsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // 🔹 بيانات الإجازات اليومية
  final List<Map<String, dynamic>> dailyVacations = [
    {
      'name': 'خالد عبدالرحمن',
      'major': 'علوم الحاسب - المستوى 3',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'date': '15 أكتوبر',
      'day': 'الثلاثاء',
      'reason': 'ظروف صحية طارئة تستدعي الراحة التامة حسب التقرير الطبي المرفق.',
      'deptHeadStatus': 'موافق', // رأي رئيس القسم
      'parentStatus': 'موافق',    // رأي الأهل
      'timeAgo': 'منذ 2 ساعة',
    },
    {
      'name': 'سارة العمري',
      'major': 'هندسة برمجيات - المستوى 4',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'date': '18 أكتوبر',
      'day': 'الجمعة',
      'reason': 'موعد مراجعة في المستشفى الجامعي لتجديد الملف الطبي.',
      'deptHeadStatus': 'غير موافق',
      'parentStatus': 'موافق',
      'timeAgo': 'أمس',
    },
  ];

  // 🔹 بيانات الإجازات الساعية
  final List<Map<String, dynamic>> hourlyVacations = [
    {
      'name': 'أحمد يوسف',
      'major': 'طب الأسنان - المستوى 2',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'time': '12:30', // الساعة فقط
      'duration': 'ساعتين',
      'reason': 'موعد عائلي طارئ يتطلب المغادرة مبكراً.',
      'deptHeadStatus': 'موافق',
      'parentStatus': 'غير موافق',
      'timeAgo': 'منذ ساعة',
    },
    {
      'name': 'نورة سعد',
      'major': 'التمريض - المستوى 3',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'time': '09:00',
      'duration': 'ساعة واحدة',
      'reason': 'مراجعة شخصية عاجلة.',
      'deptHeadStatus': 'موافق',
      'parentStatus': 'موافق',
      'timeAgo': 'منذ 3 ساعات',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 نفس ألوان وثيم باقي المشروع
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9F9F9);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subColor = isDark ? Colors.grey.shade400 : Colors.grey;

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
                        // عنوان "طلبات إجازة الطلاب" بالمنتصف - حجم 20
                        Text(
                          "طلبات إجازة الطلاب",
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
                              Icons.arrow_back,
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
                  // التبويبات: يومية | ساعية
                  // ═══════════════════════════════════════
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFFFCC00),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCC00).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: subColor,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'إجازات يومية'),
                        Tab(text: 'إجازات ساعية'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ═══════════════════════════════════════
                  // محتوى التبويبات (قابل للسحب)
                  // ═══════════════════════════════════════
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 🔹 تبويب الإجازات اليومية
                        _buildVacationList(
                          dailyVacations,
                          isDaily: true,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                        // 🔹 تبويب الإجازات الساعية
                        _buildVacationList(
                          hourlyVacations,
                          isDaily: false,
                          cardColor: cardColor,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════
            // الشريط السفلي الجاهز
            // ═══════════════════════════════════════
            CustomBottomNav(
              currentIndex: 0,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AffairsOfficerMessagesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // بناء قائمة الإجازات
  // ═══════════════════════════════════════
  Widget _buildVacationList(
      List<Map<String, dynamic>> vacations, {
        required bool isDaily,
        required Color cardColor,
        required Color textColor,
        required Color subColor,
        required bool isDark,
      }) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      itemCount: vacations.length,
      itemBuilder: (context, index) {
        return _buildVacationCard(
          vacations[index],
          isDaily: isDaily,
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          isDark: isDark,
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // بطاقة الإجازة
  // ═══════════════════════════════════════
  Widget _buildVacationCard(
      Map<String, dynamic> data, {
        required bool isDaily,
        required Color cardColor,
        required Color textColor,
        required Color subColor,
        required bool isDark,
      }) {
    final bool isDeptApproved = data['deptHeadStatus'] == 'موافق';
    final bool isParentApproved = data['parentStatus'] == 'موافق';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ الصف الأول: الوقت + الاسم + الصورة ═══
            Row(
              children: [
                // الوقت (منذ كذا)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['timeAgo'],
                    style: TextStyle(
                      fontSize: 11,
                      color: subColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                const Spacer(),
                // الاسم + التخصص
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['major'],
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // الصورة الشخصية
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(data['avatar']),
                  backgroundColor: Colors.grey.shade300,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ═══ المدة (يومية أو ساعية) ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المدة
                  Row(
                    children: [
                      Icon(
                        isDaily ? Icons.calendar_today_outlined : Icons.access_time,
                        size: 18,
                        color: subColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المدة: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      Text(
                        isDaily
                            ? '${data['day']} (${data['date']})'
                            : '${data['time']} (${data['duration']})',
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // السبب
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: subColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'السبب: ${data['reason']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: subColor,
                            height: 1.5,
                            fontFamily: 'Noto Sans Arabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ═══ الآراء: رئيس القسم + الأهل ═══
            Row(
              children: [
                // رأي رئيس القسم
                Expanded(
                  child: _buildStatusChip(
                    label: 'رأي رئيس القسم:',
                    status: data['deptHeadStatus'],
                    isApproved: isDeptApproved,
                  ),
                ),
                const SizedBox(width: 10),
                // رأي الأهل
                Expanded(
                  child: _buildStatusChip(
                    label: 'رأي الأهل:',
                    status: data['parentStatus'],
                    isApproved: isParentApproved,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ═══ أزرار القرار (موافقة / رفض) ═══
            Row(
              children: [
                // رفض
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    label: const Text(
                      'رفض',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // موافقة
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text(
                      'موافقة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // شريحة الحالة (موافق / غير موافق)
  // ═══════════════════════════════════════
  Widget _buildStatusChip({
    required String label,
    required String status,
    required bool isApproved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontFamily: 'Noto Sans Arabic',
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isApproved
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isApproved ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isApproved ? Colors.green : Colors.red,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}