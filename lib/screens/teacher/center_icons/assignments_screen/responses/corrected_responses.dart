import 'package:flutter/material.dart';

class CorrectedResponsesScreen extends StatelessWidget {
  const CorrectedResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // محتوى صافي بدون Scaffold ليركب بداخل التبويب الأساسي
    return Column(
      children: [
        // قسم التصفية (تصفية / الأحدث أولاً)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallFilterBtn(Icons.filter_list, "تصفية"),
              const Text(
                "الأحدث أولاً",
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.grey
                ),
              ),
            ],
          ),
        ),

        // قائمة الطلاب المصححة أعمالهم
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCorrectedCard(
                name: "سارة أحمد علي",
                task: "مشروع الفيزياء: الطاقة المتجددة",
                date: "20 أكتوبر - 10:30 ص",
                grade: "95/100",
                isOnline: true,
              ),
              _buildCorrectedCard(
                name: "محمد خالد العتيبي",
                task: "واجب الرياضيات: التفاضل والتكامل",
                date: "19 أكتوبر - 09:00 ص",
                grade: "88/100",
                isOnline: false,
              ),
              _buildCorrectedCard(
                name: "يوسف عمر عبد الله",
                task: "بحث التاريخ: العصر العباسي",
                date: "18 أكتوبر - 02:15 م",
                grade: "92/100",
                isOnline: false,
              ),
              _buildCorrectedCard(
                name: "نورة سالم الدوسري",
                task: "اختبار قصير: اللغة الإنجليزية",
                date: "17 أكتوبر - 11:00 ص",
                grade: "100/100",
                isOnline: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ويدجيت كرت الطالب المصحح (تم ضبط الاتجاهات يمين/يسار)
  Widget _buildCorrectedCard({
    required String name,
    required String task,
    required String date,
    required String grade,
    bool isOnline = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. جهة اليمين: صورة الطالب مع مؤشر الحالة
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey, size: 30),
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
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // 2. المنتصف: معلومات الطالب والواجب
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Tajawal'
                  ),
                ),
                Text(
                  task,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Tajawal'
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontFamily: 'Tajawal'
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. جهة اليسار: العلامة (الدرجة)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7B8), // اللون الأصفر الهادئ للدرجة
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              grade,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Tajawal'
              ),
            ),
          ),
        ],
      ),
    );
  }

  // زر التصفية الصغير العلوي
  Widget _buildSmallFilterBtn(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 6),
          Text(
              text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'
              )
          ),
        ],
      ),
    );
  }
}