import 'package:flutter/material.dart';

class AddIdTab extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const AddIdTab({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  State<AddIdTab> createState() => _AddIdTabState();
}

class _AddIdTabState extends State<AddIdTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // 🔹 بيانات الأرقام الجامعية
  List<Map<String, dynamic>> universityIds = [
    {
      'name': 'محمد علي حسن',
      'id': '20241001',
    },
    {
      'name': 'سارة أحمد محمود',
      'id': '20241002',
    },
    {
      'name': 'عمر فاروق',
      'id': '20241003',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      children: [
        // ═══════════════════════════════════════
        // مربع البحث
        // ═══════════════════════════════════════
        Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 20 : 5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: widget.textColor,
              fontFamily: 'Noto Sans Arabic',
            ),
            decoration: InputDecoration(
              hintText: 'البحث برقم جامعي...',
              hintStyle: TextStyle(
                color: widget.subColor,
                fontFamily: 'Noto Sans Arabic',
              ),
              prefixIcon: Icon(Icons.search, color: widget.subColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),

        const SizedBox(height: 24),

        // ═══════════════════════════════════════
        // عنوان "إضافة رقم جامعي جديد"
        // ═══════════════════════════════════════
        Text(
          'إضافة رقم جامعي جديد',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
            fontFamily: 'Noto Sans Arabic',
          ),
        ),

        const SizedBox(height: 16),

        // ═══════════════════════════════════════
        // الفورم
        // ═══════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 20 : 5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // حقل اسم الطالب
              TextField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: widget.textColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
                decoration: InputDecoration(
                  hintText: 'اسم الطالب',
                  hintStyle: TextStyle(
                    color: widget.subColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 12),

              // حقل الرقم الجامعي
              TextField(
                controller: _idController,
                textDirection: TextDirection.rtl,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: widget.textColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
                decoration: InputDecoration(
                  hintText: 'الرقم الجامعي',
                  hintStyle: TextStyle(
                    color: widget.subColor,
                    fontFamily: 'Noto Sans Arabic',
                  ),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // زر الإضافة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty && _idController.text.isNotEmpty) {
                      setState(() {
                        universityIds.add({
                          'name': _nameController.text,
                          'id': _idController.text,
                        });
                        _nameController.clear();
                        _idController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'إضافة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ═══════════════════════════════════════
        // عنوان "الأرقام الجامعية المضافة"
        // ═══════════════════════════════════════
        Row(
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
              'الأرقام الجامعية المضافة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
                fontFamily: 'Noto Sans Arabic',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ═══════════════════════════════════════
        // قائمة الأرقام
        // ═══════════════════════════════════════
        ..._buildIdList(),
      ],
    );
  }

  // ═══════════════════════════════════════
  // بناء قائمة الأرقام
  // ═══════════════════════════════════════
  List<Widget> _buildIdList() {
    final filteredList = _searchController.text.isEmpty
        ? universityIds
        : universityIds.where((item) => item['id'].contains(_searchController.text)).toList();

    return filteredList.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(widget.isDark ? 20 : 5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // أيقونة الطالب (يمين)
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.blue,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // الاسم + الرقم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['id'],
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.subColor,
                        fontFamily: 'Noto Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),

              // أزرار التعديل والحذف (يسار)
              Row(
                children: [
                  // تعديل
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.amber, size: 20),
                    onPressed: () => _showEditDialog(item),
                  ),
                  // حذف
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _showDeleteDialog(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════
  // نافذة التعديل
  // ═══════════════════════════════════════
  void _showEditDialog(Map<String, dynamic> item) {
    final nameEditController = TextEditingController(text: item['name']);
    final idEditController = TextEditingController(text: item['id']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تعديل الرقم الجامعي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEditController,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
                decoration: InputDecoration(
                  labelText: 'اسم الطالب',
                  labelStyle: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idEditController,
                textDirection: TextDirection.rtl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: widget.textColor, fontFamily: 'Noto Sans Arabic'),
                decoration: InputDecoration(
                  labelText: 'الرقم الجامعي',
                  labelStyle: TextStyle(color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: widget.subColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  item['name'] = nameEditController.text;
                  item['id'] = idEditController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // نافذة تأكيد الحذف
  // ═══════════════════════════════════════
  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تأكيد الحذف',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف ${item['name']}؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.subColor,
              fontFamily: 'Noto Sans Arabic',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: widget.subColor,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  universityIds.remove(item);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Sans Arabic',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}