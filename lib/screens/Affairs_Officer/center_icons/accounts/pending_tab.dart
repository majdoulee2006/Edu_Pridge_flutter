import 'package:flutter/material.dart';

class PendingTab extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const PendingTab({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  State<PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<PendingTab>
    with SingleTickerProviderStateMixin {

  late TabController _subTabController;

  // 🔹 بيانات طلاب
  final List<Map<String, dynamic>> studentRequests = [
    {
      'name': 'محمد علي حسن',
      'grade': 'الصف الخامس الابتدائي - أ',
      'timeAgo': 'منذ 15 دقيقة',
      'idNumber': '1029384756',
      'birthDate': '2013-05-14',
      'avatarLetter': 'م',
      'avatarColor': Colors.blue,
    },
    {
      'name': 'سارة أحمد محمود',
      'grade': 'الصف الثاني المتوسط - ب',
      'timeAgo': 'منذ ساعتين',
      'idNumber': '1092837465',
      'birthDate': '2010-11-20',
      'avatarLetter': 'س',
      'avatarColor': Colors.purple,
    },
  ];

  // 🔹 بيانات أولياء الأمور
  final List<Map<String, dynamic>> parentRequests = [
    {
      'name': 'عمر فاروق',
      'grade': 'الصف الأول الثانوي',
      'timeAgo': 'أمس',
      'avatarLetter': 'ع',
      'avatarColor': Colors.orange,
      'status': 'قيد المراجعة',
    },
  ];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ═══════════════════════════════════════
        // عنوان + عداد
        // ═══════════════════════════════════════
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "طلبات جديدة",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${studentRequests.length + parentRequests.length} طلبات',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                    fontFamily: 'Noto Sans Arabic',
                  ),
                ),
              ),
            ],
          ),
        ),

        // ═══════════════════════════════════════
        // التبويبات السفلية (طالب / ولي أمر)
        // ═══════════════════════════════════════
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TabBar(
            controller: _subTabController,
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
            unselectedLabelColor: widget.subColor,
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
              Tab(text: 'طالب'),
              Tab(text: 'ولي أمر'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ═══════════════════════════════════════
        // محتوى التبويبات السفلية
        // ═══════════════════════════════════════
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildStudentList(),
              _buildParentList(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // قائمة الطلاب
  // ═══════════════════════════════════════
  Widget _buildStudentList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      itemCount: studentRequests.length,
      itemBuilder: (context, index) {
        return _buildStudentCard(studentRequests[index]);
      },
    );
  }

  // ═══════════════════════════════════════
  // قائمة أولياء الأمور
  // ═══════════════════════════════════════
  Widget _buildParentList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      itemCount: parentRequests.length,
      itemBuilder: (context, index) {
        return _buildParentCard(parentRequests[index]);
      },
    );
  }

  // ═══════════════════════════════════════
  // بطاقة الطالب
  // ═══════════════════════════════════════
  Widget _buildStudentCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // الصف الأول: أيقونة + اسم + نقاط
            Row(
              children: [
                // أيقونة الحساب (يمين)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (data['avatarColor'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      data['avatarLetter'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: data['avatarColor'] as Color,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // الاسم + الصف
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['grade'],
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: widget.subColor),
                          const SizedBox(width: 4),
                          Text(
                            data['timeAgo'],
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.subColor,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // النقاط الثلاث (يسار)
                IconButton(
                  icon: Icon(Icons.more_vert, color: widget.subColor),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            // التفاصيل: رقم الهوية + تاريخ الميلاد
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'رقم الهوية',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data['idNumber'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'تاريخ الميلاد',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data['birthDate'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // الأزرار: رفض (يسار) | إنشاء حساب (يمين)
            Row(
              children: [
                // رفض (يسار)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.subColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'رفض',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // إنشاء حساب (يمين)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text(
                      'إنشاء حساب',
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
  // بطاقة ولي الأمر
  // ═══════════════════════════════════════
  Widget _buildParentCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(widget.isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // الصف الأول: أيقونة + اسم + نقاط
            Row(
              children: [
                // أيقونة الحساب (يمين)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (data['avatarColor'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      data['avatarLetter'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: data['avatarColor'] as Color,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // الاسم + الصف
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['grade'],
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.subColor,
                          fontFamily: 'Noto Sans Arabic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: widget.subColor),
                          const SizedBox(width: 4),
                          Text(
                            data['timeAgo'],
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.subColor,
                              fontFamily: 'Noto Sans Arabic',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // النقاط الثلاث (يسار)
                IconButton(
                  icon: Icon(Icons.more_vert, color: widget.subColor),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الأزرار: رفض (يسار) | إنشاء حساب (يمين)
            Row(
              children: [
                // رفض (يسار)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.subColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'رفض',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // إنشاء حساب (يمين)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text(
                      'إنشاء حساب',
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
}