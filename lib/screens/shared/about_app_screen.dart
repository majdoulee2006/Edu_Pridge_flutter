import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:edu_pridge_flutter/screens/shared/settings_screen.dart';

class AboutAppScreen extends StatefulWidget {
  final int initialTabIndex;

  const AboutAppScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  late int _selectedTab;
  late final PageController _pageController;
  int _selectedMemberIndex = 0;

  static const List<_TeamMember> _teamMembers = [
    _TeamMember(
      id: 1,
      nameAr: "مجدولين محمود",
      nameEn: "Majdouleen Mahmoud",
      roleAr: "قائدة الفريق ومسؤولة الربط البرمجي",
      roleEn: "Team Leader & Integration Specialist",
      descAr: "إدارة وتوجيه دورة حياة المشروع، هندسة وتكامل الأنظمة والربط البرمجي بين الخدمات.",
      descEn: "Project lifecycle leadership, system architecture, API integration, and cross-platform synergy.",
      initials: "MM",
      icon: Icons.hub_rounded,
      color: Color(0xFFF59E0B),
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      tags: ["Laravel", "System Architecture", "REST APIs Integration", "Security & Auth"],
    ),
    _TeamMember(
      id: 2,
      nameAr: "محمود غنام",
      nameEn: "Mahmoud Ghannam",
      roleAr: "مطوّر واجهات تطبيق الموبايل Flutter",
      roleEn: "Flutter Mobile App Developer",
      descAr: "بناء وتطوير واجهات تطبيق الموبايل عالي الأداء مع تجربة مستخدم سلسة وتقنيات الحضور الذكية.",
      descEn: "High-performance Flutter mobile client engineering, biometric attendance integration, and fluid UX.",
      initials: "MG",
      icon: Icons.phone_android_rounded,
      color: Color(0xFF0EA5E9),
      gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      tags: ["Flutter", "Dart", "Mobile Architecture", "QR & Biometrics", "Fluid UX"],
    ),
    _TeamMember(
      id: 3,
      nameAr: "اسراء منوّر",
      nameEn: "Israa Munawwar",
      roleAr: "مطوّرة خادم ومصممة APIs (Backend)",
      roleEn: "Backend & APIs Developer",
      descAr: "تطوير المنطق البرمجي للخادم، بناء وتأمين واجهات البرمجة التطبيقية (RESTful APIs) وإدارة العمليات.",
      descEn: "Robust server business logic, high-security RESTful APIs architecture, and transaction handling.",
      initials: "EM",
      icon: Icons.code_rounded,
      color: Color(0xFFA855F7),
      gradient: [Color(0xFFA855F7), Color(0xFF9333EA)],
      tags: ["PHP & Laravel", "RESTful APIs", "MySQL Database", "Backend Logic"],
    ),
    _TeamMember(
      id: 4,
      nameAr: "هبة الله عيسى",
      nameEn: "Hiba Issa",
      roleAr: "مطوّرة لوحة التحكم والإدارة Web",
      roleEn: "Web Admin Dashboard Developer",
      descAr: "تصميم وتطوير لوحات التحكم الإدارية ومواقع الويب المتجاوبة بكفاءة وأمان عاليين.",
      descEn: "Responsive web administration portals, role-based control panels, and enterprise management UI.",
      initials: "HA",
      icon: Icons.palette_rounded,
      color: Color(0xFF10B981),
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      tags: ["Admin Web UI", "Blade Templating", "Responsive Layouts", "JavaScript UX"],
    ),
    _TeamMember(
      id: 5,
      nameAr: "شهد زريقي",
      nameEn: "Shahd Zureki",
      roleAr: "محللة قواعد بيانات ومطوّرة واجهات",
      roleEn: "Database Analyst & UI Developer",
      descAr: "هندسة وتحليل جداول واستعلامات قواعد البيانات وبناء واجهات مستخدم تفاعلية متناسقة.",
      descEn: "Relational schema design, optimized database queries, data modeling, and responsive UI components.",
      initials: "SZ",
      icon: Icons.storage_rounded,
      color: Color(0xFFEAB308),
      gradient: [Color(0xFFEAB308), Color(0xFFCA8A04)],
      tags: ["Database Modeling", "SQL Optimization", "Relational Integrity", "UI Design"],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 3);
    _pageController = PageController(initialPage: _selectedTab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.isDarkMode,
      builder: (context, isDark, _) => ValueListenableBuilder<String>(
        valueListenable: AppSettings.language,
        builder: (context, lang, _) {
          final isAr = lang == 'ar';
          final bgColor = isDark ? const Color(0xFF141416) : const Color(0xFFF7F8FA);
          final cardColor = isDark ? const Color(0xFF1C1C20) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF18181B);
          final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
          final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

          final tabs = [
            _TabItem(title: isAr ? 'حول المنصة' : 'About Platform', icon: Icons.auto_awesome_rounded),
            _TabItem(title: isAr ? 'فريق التطوير' : 'Dev Team', icon: Icons.people_alt_rounded),
            _TabItem(title: isAr ? 'سياسة الخصوصية' : 'Privacy Policy', icon: Icons.shield_rounded),
            _TabItem(title: isAr ? 'تواصل معنا' : 'Contact Us', icon: Icons.headset_mic_rounded),
          ];

          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: cardColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(
                  isAr ? "حول المنصة" : "About Platform",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                leading: IconButton(
                  icon: Icon(
                    isAr ? Icons.arrow_back : Icons.arrow_back_ios_new_rounded,
                    color: textColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Container(color: borderColor, height: 1.0),
                ),
              ),
              body: Column(
                children: [
                  // ─── Header Branding ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFCC00), Color(0xFFF59E0B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFCC00).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Color(0xFF121212),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Edu-Bridge",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr
                                        ? "المنظومة الأكاديمية والطلابية الذكية المتكاملة"
                                        : "Integrated Smart Academic & Student System",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: subColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // ─── Capsule Tab Bar ─────────────────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: List.generate(tabs.length, (index) {
                              final isSelected = _selectedTab == index;
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: isAr ? 0 : 8,
                                  right: isAr ? 8 : 0,
                                ),
                                child: InkWell(
                                  onTap: () => _onTabSelected(index),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFCC00)
                                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFFCC00) : borderColor,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFFCC00).withValues(alpha: 0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          tabs[index].icon,
                                          size: 15,
                                          color: isSelected ? const Color(0xFF121212) : subColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          tabs[index].title,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? const Color(0xFF121212) : textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Pages ────────────────────────────────────────────────────
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _selectedTab = index),
                      children: [
                        _buildAboutTab(context, cardColor, textColor, subColor, borderColor, isDark, isAr),
                        _buildTeamTab(context, cardColor, textColor, subColor, borderColor, isDark, isAr),
                        _buildPrivacyTab(context, cardColor, textColor, subColor, borderColor, isDark, isAr),
                        _buildContactTab(context, cardColor, textColor, subColor, borderColor, isDark, isAr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 1: حول المنصة (About Platform)
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildAboutTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
    bool isAr,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Hero Quote Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C20) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.format_quote_rounded, color: Color(0xFFEAB308), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr
                      ? "منصة Edu-Bridge هي نظام متكامل ومتقدم لإدارة الشؤون الأكاديمية والطلابية والمعاهد، تهدف لتسهيل التواجد، الخدمات الإلكترونية، ومتابعة المحاضرات والنتائج بكل يسر وسلاسة وأمان."
                      : "Edu-Bridge is an integrated and advanced management ecosystem for institutes and universities, aiming to streamline attendance, electronic services, lecture schedules, and grade records with complete ease and security.",
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.65,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Features Grid / Items
        _buildFeatureItem(
          icon: Icons.layers_rounded,
          iconBg: const Color(0xFFEAB308).withValues(alpha: 0.15),
          iconColor: const Color(0xFFEAB308),
          title: isAr ? "إدارة أكاديمية شاملة" : "Comprehensive Academic Management",
          desc: isAr
              ? "تنظيم المقررات، النتائج الامتحانية، الخطط الدراسية، وتقارير المتابعة الدقيقة لكل طالب."
              : "Organizing courses, exam results, study plans, and meticulous follow-up reports for every student.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.qr_code_scanner_rounded,
          iconBg: const Color(0xFF10B981).withValues(alpha: 0.15),
          iconColor: const Color(0xFF10B981),
          title: isAr ? "حضور ذكي بالـ QR وبصمة الوجه" : "Smart QR & Facial Biometrics Attendance",
          desc: isAr
              ? "تسجيل حضور إلكتروني فوري ومؤمّن يمنع التلاعب مع دعم كامل للعمل والمزامنة دون إنترنت."
              : "Instant secure attendance recording that prevents tampering with offline biometric synchronization.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.chat_bubble_outline_rounded,
          iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          iconColor: const Color(0xFF3B82F6),
          title: isAr ? "تواصل ومحادثات فورية" : "Instant Live Messaging",
          desc: isAr
              ? "غرف محادثة مباشرة ومشفرة بين الطلاب والمدرسين والإدارة لتبادل الملفات والاستفسارات."
              : "Encrypted instant messaging rooms between students, teachers, and administration for discussions and files.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.phone_iphone_rounded,
          iconBg: const Color(0xFFA855F7).withValues(alpha: 0.15),
          iconColor: const Color(0xFFA855F7),
          title: isAr ? "تجربة موحدة (ويب وموبايل)" : "Unified Experience (Web & Mobile)",
          desc: isAr
              ? "تطبيق فلاتر فائق السرعة ولوحة تحكم ويب متجاوبة بالكامل لجميع أطراف العملية التعليمية."
              : "High-speed Flutter mobile app and fully responsive web admin dashboard for all educational stakeholders.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),

        const SizedBox(height: 22),

        // Tech Strip Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _TechTag(icon: Icons.code_rounded, label: "Flutter & Laravel"),
            _TechTag(icon: Icons.storage_rounded, label: "MySQL Cloud DB"),
            _TechTag(icon: Icons.lock_outline_rounded, label: "AES Encrypted"),
            _TechTag(icon: Icons.notifications_active_outlined, label: "Live Notifications"),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 2: فريق التطوير (Development Team - Matching Web 1:1)
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildTeamTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
    bool isAr,
  ) {
    final activeMember = _teamMembers[_selectedMemberIndex];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // ─── 1. Header & Badge ────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.laptop_chromebook_rounded, size: 14, color: Color(0xFFEAB308)),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? "كفاءات هندسية متميزة" : "Engineering Excellence",
                      style: const TextStyle(
                        color: Color(0xFFEAB308),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isAr ? "فريق التطوير والبرمجة" : "Development & Engineering Team",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? "فريق العمل الهندسي القائم على تصميم وتطوير منصة Edu-Bridge"
                    : "The engineering team behind the design and implementation of Edu-Bridge",
                style: TextStyle(fontSize: 12.5, color: subColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── 2. Interactive Team Grid Selector (Web edubridge-team-grid) ───────
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _teamMembers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final member = _teamMembers[index];
              final isSelected = _selectedMemberIndex == index;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMemberIndex = index);
                },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 125,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF242217) : const Color(0xFFFFFBEB))
                        : cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFCC00)
                          : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFFFCC00).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 14 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge Icon & Initials
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: member.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: member.color.withValues(alpha: 0.35)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(member.icon, size: 18, color: member.color),
                            Text(
                              member.initials,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: member.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Member Name
                      Text(
                        member.name(isAr),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? const Color(0xFFEAB308) : textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      // Member Role Subtitle
                      Text(
                        member.role(isAr),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: subColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ─── 3. Interactive Spotlight Detail Card (Web edubridge-member-spotlight) ─
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey<int>(activeMember.id),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: activeMember.color.withValues(alpha: 0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: activeMember.color.withValues(alpha: isDark ? 0.22 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Name + Role Badge Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: activeMember.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: activeMember.color.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(activeMember.icon, color: Colors.white, size: 24),
                          Text(
                            activeMember.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeMember.name(isAr),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeMember.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: activeMember.color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              activeMember.role(isAr),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: activeMember.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    activeMember.desc(isAr),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: textColor.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tech Tags Header
                Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 15, color: activeMember.color),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? "مجالات التخصص والمسؤوليات التقنية:" : "Specializations & Key Responsibilities:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Skill / Tech Tags Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeMember.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: activeMember.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: activeMember.color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 13, color: activeMember.color),
                          const SizedBox(width: 5),
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ─── 4. Full Team Overview Section ───────────────────────────────────
        Row(
          children: [
            Icon(Icons.people_alt_rounded, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              isAr ? "كادر الهندسة والبرمجة (5 مهندسين)" : "Engineering Team (5 Engineers)",
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // List of all members
        ..._teamMembers.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isSelected = _selectedMemberIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFCC00) : borderColor,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFFFCC00).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedMemberIndex = index);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: member.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: member.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(member.icon, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member.name(isAr),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? const Color(0xFFEAB308) : textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCC00),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isAr ? "المختار" : "Active",
                                      style: const TextStyle(
                                        color: Color(0xFF121212),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              member.role(isAr),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: member.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.desc(isAr),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: subColor,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isAr ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isSelected ? const Color(0xFFFFCC00) : subColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 3: سياسة الخصوصية (Privacy Policy)
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildPrivacyTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
    bool isAr,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Privacy Hero Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? "سياسة الخصوصية وأمان البيانات" : "Privacy Policy & Data Security",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAr
                          ? "نحن نلتزم بحماية بياناتك الشخصية والأكاديمية. تُستخدم البيانات المجمعة حصرياً لأغراض التحقق من الهوية والأداء الأكاديمي داخل المعهد."
                          : "We are committed to protecting your personal and academic data. Collected data is used strictly for identity verification and academic progress within the institute.",
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Policy Cards
        _buildPolicyCard(
          icon: Icons.key_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: isAr ? "1. سرية وتشفير الحسابات والمعلومات" : "1. Confidentiality & Account Encryption",
          desc: isAr
              ? "تخضع جميع كلمات المرور لجلسات تسجيل الدخول لتقنيات التشفير المتقدم (Bcrypt Hashing). لا يمكن لأي كادر تقني أو إداري الاطلاع على كلمة المرور الأصلية لأي مستخدم."
              : "All passwords and authentication sessions are secured with advanced encryption (Bcrypt Hashing). No technical or administrative personnel can view original passwords.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildPolicyCard(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF10B981),
          title: isAr ? "2. الخصوصية الطلابية والبيانات الأكاديمية" : "2. Student Privacy & Academic Records",
          desc: isAr
              ? "سجلات الحضور، الدرجات الامتحانية، الإنذارات والتقارير المرفوعة هي بيانات محصورة بالجهات المعنية المحددة حصراً (الطالب صاحب الحساب، ولي أمره، وإدارة المعهد ذات الصلاحية)."
              : "Attendance logs, exam marks, warnings, and reports are strictly restricted to authorized stakeholders (the student, guardian, and authorized institute staff).",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildPolicyCard(
          icon: Icons.face_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: isAr ? "3. أمان التعرف بالوجه وتقنيات الحضور (Biometrics & QR)" : "3. Biometrics & QR Attendance Security",
          desc: isAr
              ? "معرفات الأجهزة وبيانات التعرف البصري تُعالج بأعلى معايير الحماية ولا يتم نقلها أو استخدامها لأي غرض خارج نطاق تأكيد التواجد الفعلي في قاعة المحاضرة."
              : "Device identifiers and facial features are processed under strict safeguards and are never used outside the scope of physical lecture attendance confirmation.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildPolicyCard(
          icon: Icons.handshake_rounded,
          iconColor: const Color(0xFFEF4444),
          title: isAr ? "4. التزام تام بعدم مشاركة البيانات مع جهات خارجية" : "4. Strict No Third-Party Sharing Commitment",
          desc: isAr
              ? "تتعهد منظومة Edu-Bridge بعدم تزويد أو بيع أو مشاركة أي جزء من البيانات الشخصية أو الأكاديمية مع أي طرف ثالث أو منصات إعلانية أو خارجية إطلاقاً."
              : "Edu-Bridge pledges never to sell, distribute, or share any personal or academic data with third parties or external advertising networks.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),

        const SizedBox(height: 18),

        // Compliance Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isAr
                      ? "متوافق مع أفضل معايير أمن المعلومات والخصوصية الأكاديمية"
                      : "Compliant with industry-standard information security and academic privacy",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12.5,
              color: subColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 4: تواصل معنا (Contact Us)
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildContactTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
    bool isAr,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Intro
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.headset_mic_rounded, size: 14, color: Color(0xFFEAB308)),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? "دعم فني سريع ومباشر" : "Fast & Direct Tech Support",
                      style: const TextStyle(
                        color: Color(0xFFEAB308),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? "تواصل مع إدارة النظام والمنصة" : "Connect with System & Support Administration",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? "يسعدنا تلقي استفساراتك واقتراحاتك ومساعدتك عبر القنوات التالية:"
                    : "We are pleased to receive your inquiries, suggestions, and assistance via:",
                style: TextStyle(fontSize: 12.5, color: subColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Email Card
        _buildContactCard(
          icon: Icons.email_rounded,
          iconBg: const Color(0xFFEF4444).withValues(alpha: 0.15),
          iconColor: const Color(0xFFEF4444),
          type: isAr ? "البريد الإلكتروني الرسمي" : "Official Support Email",
          value: "edubridge2006@gmail.com",
          desc: isAr
              ? "للمراسلات الرسمية، الدعم الفني، والملاحظات الأكاديمية."
              : "For official correspondence, technical support, and academic feedback.",
          actionText: isAr ? "إرسال رسالة" : "Send Email",
          actionColor: const Color(0xFFEF4444),
          onActionTap: () => _launchEmail("edubridge2006@gmail.com"),
          onCopyTap: () => _copyText(context, "edubridge2006@gmail.com", isAr ? "تم نسخ البريد الإلكتروني" : "Email copied to clipboard"),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),

        const SizedBox(height: 14),

        // WhatsApp / Phone Card
        _buildContactCard(
          icon: Icons.chat_rounded,
          iconBg: const Color(0xFF22C55E).withValues(alpha: 0.15),
          iconColor: const Color(0xFF22C55E),
          type: isAr ? "الدعم الفني المباشر (واتساب / هاتف)" : "Direct Support (WhatsApp / Phone)",
          value: "0959031594",
          desc: isAr
              ? "للمساعدة الفورية في الحسابات والأجهزة والدورات."
              : "For instant assistance regarding accounts, devices, and courses.",
          actionText: isAr ? "محادثة واتساب" : "WhatsApp Chat",
          actionColor: const Color(0xFF22C55E),
          onActionTap: () => _launchWhatsApp("0959031594"),
          onCopyTap: () => _copyText(context, "0959031594", isAr ? "تم نسخ رقم الهاتف" : "Phone number copied to clipboard"),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),

        const SizedBox(height: 22),

        // Location info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFFEAB308), size: 16),
            const SizedBox(width: 6),
            Text(
              isAr
                  ? "الجمهورية العربية السورية — نظام إدارة المؤسسات الأكاديمية"
                  : "Syrian Arab Republic — Academic Management System",
              style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String type,
    required String value,
    required String desc,
    required String actionText,
    required Color actionColor,
    required VoidCallback onActionTap,
    required VoidCallback onCopyTap,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 18, color: subColor),
                onPressed: onCopyTap,
                tooltip: "نسخ",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: subColor, height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onActionTap,
              icon: Icon(icon, size: 16, color: Colors.white),
              label: Text(
                actionText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyText(BuildContext context, String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg),
        backgroundColor: const Color(0xFFFFCC00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String localPhone) async {
    final digitsOnly = localPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final withoutLeadingZero = digitsOnly.startsWith('0') ? digitsOnly.substring(1) : digitsOnly;
    final international = '963$withoutLeadingZero';
    final uri = Uri.parse('https://wa.me/$international');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting data classes & widgets
// ─────────────────────────────────────────────────────────────────────────────
class _TabItem {
  final String title;
  final IconData icon;
  const _TabItem({required this.title, required this.icon});
}

class _TeamMember {
  final int id;
  final String nameAr;
  final String nameEn;
  final String roleAr;
  final String roleEn;
  final String descAr;
  final String descEn;
  final String initials;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final List<String> tags;

  const _TeamMember({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.roleAr,
    required this.roleEn,
    required this.descAr,
    required this.descEn,
    required this.initials,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.tags,
  });

  String name(bool isAr) => isAr ? nameAr : nameEn;
  String role(bool isAr) => isAr ? roleAr : roleEn;
  String desc(bool isAr) => isAr ? descAr : descEn;
}

class _TechTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TechTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.isDarkMode.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFCC00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
