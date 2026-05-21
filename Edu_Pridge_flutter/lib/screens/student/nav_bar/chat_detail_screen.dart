import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/models/message_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final int receiverId; // 🌟 ضفنا الـ ID تبع الشخص اللي عم نحكي معه (ضروري للسيرفر)
  final String name;
  final String imageUrl;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.receiverId, // 🌟 صار مطلوب
    required this.name,
    required this.imageUrl,
    this.isGroup = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  // 🌟 دالة جلب سجل الرسائل الحقيقي من السيرفر
  Future<void> _fetchMessages() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      // نجلب الـ ID تبع الطالب الحالي لنعرف مين المرسل ومين المستقبل
      int currentUserId = int.tryParse(prefs.get('user_id').toString()) ?? 0;

      Dio dio = Dio();
      // الرابط الحقيقي تبع اللارافل
      String url = "http://127.0.0.1:8000/api/student/messages/history/${widget.receiverId}";

      var response = await dio.get(
        url,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200) {
        var data = response.data['data'] as List;
        setState(() {
          // تحويل البيانات الجاية من اللارافل لموديل الفلاتر
          messages = data.map((e) => MessageModel.fromJson(e, currentUserId)).toList();
          isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("❌ خطأ في جلب الرسائل: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🌟 دالة إرسال رسالة حقيقية للسيرفر
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text;

    // 1. إضافة الرسالة محلياً فوراً (عشان سرعة الواجهة)
    setState(() {
      messages.add(MessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        text: text,
        isMe: true,
        time: 'الآن',
      ));
      _messageController.clear();
    });

    _scrollToBottom();

    // 2. إرسالها للارافل في الخلفية
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      Dio dio = Dio();
      String url = "http://127.0.0.1:8000/api/student/messages/send";

      var response = await dio.post(
        url,
        data: {
          "receiver_id": widget.receiverId,
          "message": text,
        },
        options: Options(
            headers: {
              "Authorization": "Bearer $token",
              "Accept": "application/json",
            }
        ),
      );

      if (response.statusCode == 201) {
        debugPrint("✅ تم إرسال الرسالة للسيرفر بنجاح");
      }
    } catch (e) {
      debugPrint("❌ خطأ في إرسال الرسالة: $e");
    }
  }

  // 🌟 النزول لآخر رسالة في المحادثة
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions(BuildContext context) {
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
            color: cardColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إرفاق ملف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(Icons.image, 'صورة', Colors.purple, isDark, textColor),
                  _buildAttachmentOption(Icons.videocam, 'فيديو', Colors.pink, isDark, textColor),
                  _buildAttachmentOption(Icons.insert_drive_file, 'مستند', Colors.blue, isDark, textColor),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, Color color, bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: color.withAlpha(isDark ? 50 : 25), shape: BoxShape.circle),
            child: Icon(icon, color: isDark ? color.withAlpha(200) : color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF7F9FC);
    final appBarColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: isDark ? 0 : 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                backgroundImage: NetworkImage(widget.imageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.isGroup ? 'مجموعة دراسية' : 'متصل الآن',
                      style: TextStyle(color: widget.isGroup ? Colors.grey : Colors.green, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  bool isMe = widget.isGroup ? false : msg.isMe;
                  return _buildMessageBubble(msg.text, isMe, msg.time, isDark);
                },
              ),
            ),
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
    Color bubbleColor = isMe ? const Color(0xFFEFFF00) : (isDark ? Theme.of(context).cardColor : Colors.white);
    Color messageTextColor = isMe ? Colors.black87 : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(12), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(text, style: TextStyle(fontSize: 14, color: messageTextColor, height: 1.4)),
            const SizedBox(height: 5),
            Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.black54 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        boxShadow: [BoxShadow(color: isDark ? Colors.black45 : Colors.black12, blurRadius: 10)],
      ),
      child: Text(
        'هذه المجموعة مخصصة للإعلانات، يقتصر الإرسال على المدرب.',
        textAlign: TextAlign.center,
        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final inputBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF2F2F2);
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [BoxShadow(color: isDark ? Colors.black45 : Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: isDark ? Colors.grey.shade400 : Colors.grey, size: 26),
              onPressed: () => _showAttachmentOptions(context),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFEFFF00), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.black, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}