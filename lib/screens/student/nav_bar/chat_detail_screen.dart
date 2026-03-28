import 'package:flutter/material.dart';
//import '../../../core/constants/app_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    this.isGroup = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {'text': 'أهلاً بك، كيف يمكنني مساعدتك؟', 'isMe': false, 'time': '10:00 ص'},
    {
      'text': 'أهلاً بك، هل يمكنني تسليم الوظيفة غداً؟',
      'isMe': true,
      'time': '10:02 ص',
    },
    {'text': 'نعم، لا مشكلة في ذلك.', 'isMe': false, 'time': '10:05 ص'},
  ];

  // دالة لإظهار قائمة المرفقات
  void _showAttachmentOptions(BuildContext context) {
    // 🌟 جلب الثيم للقائمة السفلية
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor, // 🌟 خلفية متجاوبة
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إرفاق ملف',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ), // 🌟 نص متجاوب
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    Icons.image,
                    'صورة',
                    Colors.purple,
                    isDark,
                    textColor,
                  ),
                  _buildAttachmentOption(
                    Icons.videocam,
                    'فيديو',
                    Colors.pink,
                    isDark,
                    textColor,
                  ),
                  _buildAttachmentOption(
                    Icons.insert_drive_file,
                    'مستند',
                    Colors.blue,
                    isDark,
                    textColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String title,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              // 🌟 استخدام withAlpha لتجنب التحذيرات
              color: color.withAlpha(isDark ? 50 : 25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? color.withAlpha(200) : color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ), // 🌟 نص متجاوب
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 جلب حالة الوضع الليلي والألوان 🌟
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF7F9FC);
    final appBarColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor, // 🌟 خلفية متجاوبة
        appBar: AppBar(
          backgroundColor: appBarColor, // 🌟 لون الأب بار متجاوب
          elevation: isDark ? 0 : 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor), // 🌟 أيقونة متجاوبة
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                backgroundImage: NetworkImage(widget.imageUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      color: textColor, // 🌟 نص متجاوب
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isGroup ? 'مجموعة دراسية' : 'متصل الآن',
                    style: TextStyle(
                      color: widget.isGroup ? Colors.grey : Colors.green,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // إذا كانت مجموعة، نعتبر كل الرسائل مستلمة (isMe: false) لغرض العرض
                  bool isMe = widget.isGroup ? false : msg['isMe'];
                  return _buildMessageBubble(
                    msg['text'],
                    isMe,
                    msg['time'],
                    isDark,
                  );
                },
              ),
            ),

            // 🌟 السحر هنا: إذا كانت جروب، نعرض رسالة للقراءة فقط، وإلا نعرض حقل الكتابة 🌟
            if (widget.isGroup)
              _buildReadOnlyBanner(isDark)
            else
              _buildMessageInput(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time, bool isDark) {
    // 🌟 تحديد لون الفقاعات المتجاوب
    Color bubbleColor;
    Color messageTextColor;

    if (isMe) {
      bubbleColor = const Color(0xFFEFFF00); // رسائلي دائماً صفراء
      messageTextColor = Colors.black87; // النص داخل الأصفر دائماً داكن
    } else {
      bubbleColor = isDark
          ? Theme.of(context).cardColor
          : Colors.white; // رسائل الطرف الآخر متجاوبة
      messageTextColor = isDark ? Colors.white : Colors.black87;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe
                ? const Radius.circular(20)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(50)
                  : Colors.black.withAlpha(12), // 🌟 ظل متجاوب مع withAlpha
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: messageTextColor, // 🌟 لون نص الرسالة
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.black54 : Colors.grey,
              ), // لون الوقت
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 رسالة الجروبات 🌟
  Widget _buildReadOnlyBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).cardColor
            : Colors.white, // 🌟 خلفية متجاوبة
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        'هذه المجموعة مخصصة للإعلانات، يقتصر الإرسال على المدرب.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey, // 🌟 نص متجاوب
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🌟 حقل الكتابة للمحادثات الفردية 🌟
  Widget _buildMessageInput(bool isDark) {
    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final inputBgColor = isDark
        ? Colors.grey.shade800
        : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor, // 🌟 متجاوب
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // زر المرفقات يفتح قائمة الرفع
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                size: 26,
              ),
              onPressed: () => _showAttachmentOptions(context),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: inputBgColor, // 🌟 متجاوب
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  autofocus: false,
                  style: TextStyle(color: textColor), // 🌟 لون النص المكتوب
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            GestureDetector(
              onTap: () {
                if (_messageController.text.isNotEmpty) {
                  // منطق إرسال الرسالة
                  setState(() {
                    messages.add({
                      'text': _messageController.text,
                      'isMe': true,
                      'time': 'الآن',
                    });
                    _messageController.clear();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFFF00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.black, // الأيقونة سوداء لتباينها مع الأصفر
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
