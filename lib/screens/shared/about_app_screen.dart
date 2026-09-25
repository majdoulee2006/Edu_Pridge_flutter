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

  final List<_TabItem> _tabs = const [
    _TabItem(title: 'حول المنصة', icon: Icons.auto_awesome_rounded),
    _TabItem(title: 'فريق التطوير', icon: Icons.people_alt_rounded),
    _TabItem(title: 'سياسة الخصوصية', icon: Icons.shield_rounded),
    _TabItem(title: 'تواصل معنا', icon: Icons.headset_mic_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, _tabs.length - 1);
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
          final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

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
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
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
                                    color: const Color(0xFFFFCC00).withOpacity(0.35),
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
                                    "المنظومة الأكاديمية والطلابية الذكية المتكاملة",
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
                        // ─── Capsule / Pill Tab Bar ───────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: List.generate(_tabs.length, (index) {
                              final isSelected = _selectedTab == index;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: InkWell(
                                  onTap: () => _onTabSelected(index),
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFCC00)
                                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFFCC00)
                                            : borderColor,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFFCC00).withOpacity(0.3),
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
                                          _tabs[index].icon,
                                          size: 15,
                                          color: isSelected
                                              ? const Color(0xFF121212)
                                              : subColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _tabs[index].title,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF121212)
                                                : textColor,
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
                        _buildAboutTab(context, cardColor, textColor, subColor, borderColor, isDark),
                        _buildTeamTab(context, cardColor, textColor, subColor, borderColor, isDark),
                        _buildPrivacyTab(context, cardColor, textColor, subColor, borderColor, isDark),
                        _buildContactTab(context, cardColor, textColor, subColor, borderColor, isDark),
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
  // TAB 1: حول المنصة
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildAboutTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
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
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.format_quote_rounded, color: Color(0xFFEAB308), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "منصة Edu-Bridge هي نظام متكامل ومتقدم لإدارة الشؤون الأكاديمية والطلابية والمعاهد، تهدف لتسهيل التواجد، الخدمات الإلكترونية، ومتابعة المحاضرات والنتائج بكل يسر وسلاسة وأمان.",
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
          iconBg: const Color(0xFFEAB308).withOpacity(0.15),
          iconColor: const Color(0xFFEAB308),
          title: "إدارة أكاديمية شاملة",
          desc: "تنظيم المقررات، النتائج الامتحانية، الخطط الدراسية، وتقارير المتابعة الدقيقة لكل طالب.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.qr_code_scanner_rounded,
          iconBg: const Color(0xFF10B981).withOpacity(0.15),
          iconColor: const Color(0xFF10B981),
          title: "حضور ذكي بالـ QR وبصمة الوجه",
          desc: "تسجيل حضور إلكتروني فوري ومؤمّن يمنع التلاعب مع دعم كامل للعمل والمزامنة دون إنترنت.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.chat_bubble_outline_rounded,
          iconBg: const Color(0xFF3B82F6).withOpacity(0.15),
          iconColor: const Color(0xFF3B82F6),
          title: "تواصل ومحادثات فورية",
          desc: "غرف محادثة مباشرة ومشفرة بين الطلاب والمدرسين والإدارة لتبادل الملفات والاستفسارات.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.phone_iphone_rounded,
          iconBg: const Color(0xFFA855F7).withOpacity(0.15),
          iconColor: const Color(0xFFA855F7),
          title: "تجربة موحدة (ويب وموبايل)",
          desc: "تطبيق فلاتر فائق السرعة ولوحة تحكم ويب متجاوبة بالكامل لجميع أطراف العملية التعليمية.",
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
  // TAB 2: فريق التطوير (Ordered exactly: مجدولين، محمود، إسراء، شهد، هبة)
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildTeamTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    final team = const [
      _TeamMember(name: "مجدولين محمود", letter: "م", gradient: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      _TeamMember(name: "محمود غنّام", letter: "م", gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
      _TeamMember(name: "إسراء منوّر", letter: "إ", gradient: [Color(0xFF10B981), Color(0xFF059669)]),
      _TeamMember(name: "شهد زريقي", letter: "ش", gradient: [Color(0xFFEC4899), Color(0xFFDB2777)]),
      _TeamMember(name: "هبة عيسى", letter: "هـ", gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Section intro
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.laptop_chromebook_rounded, size: 14, color: Color(0xFFEAB308)),
                    SizedBox(width: 6),
                    Text(
                      "كفاءات هندسية متميزة",
                      style: TextStyle(
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
                "فريق التطوير والبرمجة",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "فريق العمل الهندسي القائم على تصميم وتطوير منصة Edu-Bridge",
                style: TextStyle(fontSize: 12.5, color: subColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Member Cards (Names ONLY + Colorful Avatar, NO subtext)
        ...team.map((member) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
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
                          color: member.gradient.first.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        member.letter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TAB 3: سياسة الخصوصية
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildPrivacyTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Privacy Hero Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "سياسة الخصوصية وأمان البيانات",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "نحن نلتزم بحماية بياناتك الشخصية والأكاديمية. تُستخدم البيانات المجمعة حصرياً لأغراض التحقق من الهوية والأداء الأكاديمي داخل المعهد.",
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
          title: "1. سرية وتشفير الحسابات والمعلومات",
          desc: "تخضع جميع كلمات المرور لجلسات تسجيل الدخول لتقنيات التشفير المتقدم (Bcrypt Hashing). لا يمكن لأي كادر تقني أو إداري الاطلاع على كلمة المرور الأصلية لأي مستخدم.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildPolicyCard(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF10B981),
          title: "2. الخصوصية الطلابية والبيانات الأكاديمية",
          desc: "سجلات الحضور، الدرجات الامتحانية، الإنذارات والتقارير المرفوعة هي بيانات محصورة بالجهات المعنية المحددة حصراً (الطالب صاحب الحساب، ولي أمره، وإدارة المعهد ذات الصلاحية).",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildPolicyCard(
          icon: Icons.face_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: "3. أمان التعرف بالوجه وتقنيات الحضور (Biometrics & QR)",
          desc: "معرفات الأجهزة وبيانات التعرف البصري تُعالج بأعلى معايير الحماية ولا يتم نقلها أو استخدامها لأي غرض خارج نطاق تأكيد التواجد الفعلي في قاعة المحاضرة.",
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),
        const SizedBox(height: 12),
        _buildPolicyCard(
          icon: Icons.handshake_rounded,
          iconColor: const Color(0xFFEF4444),
          title: "4. التزام تام بعدم مشاركة البيانات مع جهات خارجية",
          desc: "تتعهد منظومة Edu-Bridge بعدم تزويد أو بيع أو مشاركة أي جزء من البيانات الشخصية أو الأكاديمية مع أي طرف ثالث أو منصات إعلانية أو خارجية إطلاقاً.",
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
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.verified_rounded, size: 16, color: Color(0xFF22C55E)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "متوافق مع أفضل معايير أمن المعلومات والخصوصية الأكاديمية",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
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
  // TAB 4: تواصل معنا
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildContactTab(
    BuildContext context,
    Color cardColor,
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
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
                  color: const Color(0xFFFFCC00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCC00).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.headset_mic_rounded, size: 14, color: Color(0xFFEAB308)),
                    SizedBox(width: 6),
                    Text(
                      "دعم فني سريع ومباشر",
                      style: TextStyle(
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
                "تواصل مع إدارة النظام والمنصة",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "يسعدنا تلقي استفساراتك واقتراحاتك ومساعدتك عبر القنوات التالية:",
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
          iconBg: const Color(0xFFEF4444).withOpacity(0.15),
          iconColor: const Color(0xFFEF4444),
          type: "البريد الإلكتروني الرسمي",
          value: "edubridge2006@gmail.com",
          desc: "للمراسلات الرسمية، الدعم الفني، والملاحظات الأكاديمية.",
          actionText: "إرسال رسالة",
          actionColor: const Color(0xFFEF4444),
          onActionTap: () => _launchEmail("edubridge2006@gmail.com"),
          onCopyTap: () => _copyText(context, "edubridge2006@gmail.com", "تم نسخ البريد الإلكتروني"),
          cardColor: cardColor,
          textColor: textColor,
          subColor: subColor,
          borderColor: borderColor,
        ),

        const SizedBox(height: 14),

        // WhatsApp / Phone Card
        _buildContactCard(
          icon: Icons.chat_rounded,
          iconBg: const Color(0xFF22C55E).withOpacity(0.15),
          iconColor: const Color(0xFF22C55E),
          type: "الدعم الفني المباشر (واتساب / هاتف)",
          value: "0959031594",
          desc: "للمساعدة الفورية في الحسابات والأجهزة والدورات.",
          actionText: "محادثة واتساب",
          actionColor: const Color(0xFF22C55E),
          onActionTap: () => _launchWhatsApp("0959031594"),
          onCopyTap: () => _copyText(context, "0959031594", "تم نسخ رقم الهاتف"),
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
              "الجمهورية العربية السورية — نظام إدارة المؤسسات الأكاديمية",
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
                      style: TextStyle(fontSize: 11.5, color: subColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: subColor, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onCopyTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text("نسخ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyText(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
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
  final String name;
  final String letter;
  final List<Color> gradient;
  const _TeamMember({required this.name, required this.letter, required this.gradient});
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
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
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
