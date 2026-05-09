import 'package:flutter/material.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _postController = TextEditingController();
  String selectedAudience = "عام";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFEFFF00);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1E2633) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
          elevation: 0,
          title: const Text(
            "إنشاء منشور جديد",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.settings_outlined, color: textColor),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الناشر
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Text(
                              "ع",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "المدير عبد الله",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // يمكن إضافة BottomSheet لاختيار الجمهور لاحقاً
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.public, size: 16),
                                    const SizedBox(width: 6),
                                    Text(selectedAudience),
                                    const Icon(Icons.arrow_drop_down, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // حقل كتابة المنشور
                    TextField(
                      controller: _postController,
                      maxLines: null,
                      style: TextStyle(fontSize: 22, height: 1.4, color: textColor),
                      decoration: const InputDecoration(
                        hintText: "بما تفكر؟",
                        hintStyle: TextStyle(fontSize: 22, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // شريط إضافة المحتوى
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "إضافة إلى منشورك",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      // أزرار الإضافات
                      _buildMediaButton(Icons.photo_library, Colors.green, "صورة/فيديو"),
                      const SizedBox(width: 12),
                      _buildMediaButton(Icons.sentiment_satisfied, Colors.orange, "شعور"),
                      const SizedBox(width: 12),
                      _buildMediaButton(Icons.more_horiz, Colors.grey, ""),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // زر النشر الثابت في الأسفل
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // هنا سيتم تنفيذ نشر المنشور
                if (_postController.text.trim().isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم نشر المنشور بنجاح")),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "نشر",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.send, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, Color color, String tooltip) {
    return GestureDetector(
      onTap: () {
        // يمكن توسيع الوظائف لاحقاً
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}