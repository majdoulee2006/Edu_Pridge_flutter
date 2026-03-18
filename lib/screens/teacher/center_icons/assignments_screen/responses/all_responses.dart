import 'package:flutter/material.dart';
import 'corrected_responses.dart';

class AllResponsesScreen extends StatefulWidget {
  const AllResponsesScreen({super.key});

  @override
  State<AllResponsesScreen> createState() => _AllResponsesScreenState();
}

class _AllResponsesScreenState extends State<AllResponsesScreen> {
  String selectedFilter = "جميع الردود";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // أزرار التبديل العلوية
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            children: [
              _buildFilterBtn("جميع الردود"),
              const SizedBox(width: 12),
              _buildFilterBtn("تم التصحيح"),
            ],
          ),
        ),

        Expanded(
          child: selectedFilter == "جميع الردود"
              ? _buildAllResponsesListView()
              : const CorrectedResponsesScreen(),
        ),
      ],
    );
  }

  Widget _buildAllResponsesListView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildResponseSlide(
          name: "أحمد محمد علي",
          task: "واجب الفيزياء: الطاقة",
          date: "2023-11-21 10:30 AM",
          status: "بانتظار التصحيح",
          isCorrected: false,
        ),
        _buildResponseSlide(
          name: "سارة يوسف كمال",
          task: "مشروع العلوم: الخلايا",
          date: "2023-11-20 09:15 AM",
          status: "تم التصحيح",
          isCorrected: true,
        ),
      ],
    );
  }

  // الويدجيت بعد قلب الاتجاهات (الصورة يمين، الحالة يسار)
  Widget _buildResponseSlide({
    required String name,
    required String task,
    required String date,
    required String status,
    required bool isCorrected,
  }) {
    Color mainColor = isCorrected ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    Color bgColor = isCorrected ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        // الشريط الملون على جهة اليمين
        border: Border(
          right: BorderSide(color: mainColor, width: 8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // 1. جهة اليمين: أيقونة البروفايل
                CircleAvatar(
                  radius: 22,
                  backgroundColor: bgColor,
                  child: Icon(Icons.person_outline, color: mainColor),
                ),
                const SizedBox(width: 12),

                // 2. المنتصف: اسم الطالب والواجب (محاذاة لليمين)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tajawal')
                      ),
                      Text(
                          task,
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Tajawal')
                      ),
                    ],
                  ),
                ),

                // 3. جهة اليسار: ملصق الحالة (بانتظار التصحيح / تم التصحيح)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: mainColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal'
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 0.5),
            // السطر السفلي (الوقت على اليمين والسهم على اليسار)
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Tajawal')
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBtn(String text) {
    bool isActive = selectedFilter == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFFF00) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
                text,
                style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black : Colors.grey
                )
            ),
          ),
        ),
      ),
    );
  }
}