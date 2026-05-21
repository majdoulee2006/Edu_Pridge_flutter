import 'package:flutter/material.dart';

class CorrectedResponsesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> submissions;
  const CorrectedResponsesScreen({super.key, this.submissions = const []});

  @override
  Widget build(BuildContext context) {
    // جلب ألوان الثيم لضمان توافق الوضع الليلي
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // 1. قسم التصفية (تصفية / الأحدث أولاً)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallFilterBtn(
                  context,
                  Icons.filter_list_rounded,
                  "تصفية",
                  cardColor,
                  textColor,
                  isDark,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 16,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "الأحدث أولاً",
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. قائمة الطلاب المصححة أعمالهم
          Expanded(
            child: submissions.isEmpty
                ? const Center(
                    child: Text('لا توجد ردود مصححة', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: submissions.length,
                    itemBuilder: (context, index) {
                      final s = submissions[index];
                      return _buildCorrectedCard(
                        context,
                        name:      s['student_name'] as String? ?? '',
                        task:      s['assignment_title'] as String? ?? '',
                        date:      s['submitted_at'] as String? ?? '',
                        grade:     '${s['grade'] ?? 0}',
                        total:     '${s['max_points'] ?? 100}',
                        isOnline:  false,
                        cardColor: cardColor,
                        textColor: textColor,
                        isDark:    isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ويدجيت كرت الطالب المصحح
  Widget _buildCorrectedCard(
    BuildContext context, {
    required String name,
    required String task,
    required String date,
    required String grade,
    required String total,
    required bool isOnline,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. صورة الطالب مع مؤشر الحالة
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                child: Icon(
                  Icons.person_rounded,
                  color: textColor.withValues(alpha: 0.3),
                  size: 30,
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),

          // 2. معلومات الطالب والواجب
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: Colors.green.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "تم التصحيح في: $date",
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. الدرجة (تصميم دائري أو مربع منحني)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00).withValues(alpha: isDark ? 0.1 : 0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  grade,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isDark ? const Color(0xFFFFCC00) : Colors.black,
                  ),
                ),
                Container(
                  height: 1,
                  width: 20,
                  color: textColor.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                Text(
                  total,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // زر التصفية العلوي
  Widget _buildSmallFilterBtn(
    BuildContext context,
    IconData icon,
    String text,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
