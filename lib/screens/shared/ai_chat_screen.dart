import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/core/constants/app_colors.dart';
import 'package:edu_pridge_flutter/services/ai_service.dart';

class AiChatScreen extends StatefulWidget {
  final String userRole; // 'student', 'teacher', 'parent', 'boss', 'affairs'
  final String userName;

  const AiChatScreen({
    super.key,
    this.userRole = 'student',
    this.userName = 'المستخدم',
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    String greeting;
    switch (widget.userRole) {
      case 'teacher':
        greeting = "أهلاً بك يا أستاذ! أنا مساعد **EduBridge AI** للتعليم الذكي. يمكنني مساعدتك في تنظيم المحاضرات، صياغة أفكار للاختبارات، أو متابعة لوائح التقويم الأكاديمي.";
        break;
      case 'parent':
        greeting = "مرحباً بك ولي أمر الطالب العزيز! أنا مساعد **EduBridge AI**. يمكنني إرشادك حول كيفية متابعة دوام ابنك، درجاته، واللوائح الامتحانية في المعهد.";
        break;
      case 'boss':
        greeting = "أهلاً بك رئيس القسم! أنا مساعدك الإداري والأكاديمي الذكي لنظام EduBridge. جاهز لدعمك في الأنظمة، التقارير، والقرارات الأكاديمية.";
        break;
      case 'affairs':
        greeting = "مرحباً بك زميلنا في شؤون الطلاب! أنا المساعد الذكي لمتابعة اللوائح والخدمات الطلابية وتسهيل الإجراءات الإدارية.";
        break;
      default:
        greeting = "أهلاً بك يا ${widget.userName}! أنا مساعدك الأكاديمي الذكي **EduBridge AI** 🌟.\n\nكيف يمكنني مساعدتك اليوم؟ يمكنك سؤالي عن لوائح الغياب، الامتحانات، العلامات، أو طلب نصائح دراسية!";
    }

    _messages.add(_ChatMessage(
      text: greeting,
      isUser: false,
      time: DateTime.now(),
    ));
  }

  List<String> _getSuggestions() {
    switch (widget.userRole) {
      case 'teacher':
        return [
          "ما هي نسبة الحرمان من المقرر؟",
          "كيف أصيغ أسئلة اختبار متوازنة؟",
          "نصائح لتعزيز تفاعل الطلاب",
        ];
      case 'parent':
        return [
          "كيف أتابع غياب ابني بدقة؟",
          "ما هي درجات النجاح المعتمدة؟",
          "مواعيد الامتحانات القادمة",
        ];
      case 'boss':
        return [
          "ما هي لوائح الإنذار الأكاديمي؟",
          "شروط فتح شعبة دراسية إضافية",
          "إجراءات تقديم الأعذار المقبولة",
        ];
      default: // student
        return [
          "متى يتم توجيه إنذار الغياب؟",
          "كيف أستعلم عن علاماتي والمسار؟",
          "طريقة طلب إعادة تعيين الجهاز",
          "أفضل نصائح لتنظيم وقت الدراسة",
        ];
    }
  }

  void _sendMessage([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // تجهيز السجل للمساعد من الرسائل السابقة فقط (دون تكرار الرسالة الحالية)
    final priorMessages = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <_ChatMessage>[];
    final history = priorMessages
        .take(8)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    final response = await AiService().sendMessage(
      message: text,
      userRole: widget.userRole,
      history: history,
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: response,
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);
    final bgColor = isDark ? const Color(0xFF121316) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF1E2026) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryYellow,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryYellow.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "EduBridge AI",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: primaryYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryYellow, width: 0.8),
                        ),
                        child: const Text(
                          "PRO",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "المساعد الأكاديمي نشط",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              tooltip: "محادثة جديدة",
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _initWelcomeMessage();
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // ─── قائمة الرسائل ───
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator(cardColor, primaryYellow, isDark);
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, cardColor, primaryYellow, textColor, isDark);
                },
              ),
            ),

            // ─── مقترحات سريعة ───
            if (_messages.length <= 3 && !_isTyping)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _getSuggestions().map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ActionChip(
                        label: Text(s),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        backgroundColor: cardColor,
                        side: BorderSide(
                          color: primaryYellow.withOpacity(0.5),
                          width: 1,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () => _sendMessage(s),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ─── حقل الإدخال السفلي ───
            _buildInputArea(cardColor, primaryYellow, textColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    _ChatMessage msg,
    Color cardColor,
    Color primaryYellow,
    Color textColor,
    bool isDark,
  ) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, left: 8),
              decoration: BoxDecoration(
                color: primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryYellow
                    : (isDark ? const Color(0xFF262930) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: isUser ? Colors.black : textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      "${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.black54 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Color cardColor, Color primaryYellow, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2, left: 8),
            decoration: BoxDecoration(
              color: primaryYellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262930) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "EduBridge AI يفكّر ويكتب...",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color cardColor, Color primaryYellow, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16181C) : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "اسأل المساعد الذكي أي شيء...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryYellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryYellow.withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
