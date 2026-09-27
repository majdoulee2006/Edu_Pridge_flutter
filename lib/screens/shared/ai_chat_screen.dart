import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'time': time.toIso8601String(),
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}

class _ChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  List<_ChatMessage> messages;

  _ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory _ChatSession.fromJson(Map<String, dynamic> json) {
    return _ChatSession(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'محادثة',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => _ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<_ChatSession> _sessions = [];
  _ChatSession? _currentSession;
  bool _isTyping = false;
  bool _isLoading = true;

  String get _storageKey => 'ai_chat_sessions_${widget.userRole}';
  String get _activeSessionKey => 'ai_chat_active_id_${widget.userRole}';

  @override
  void initState() {
    super.initState();
    _loadHistoryAndSession();
  }

  Future<void> _loadHistoryAndSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_storageKey);
      final activeId = prefs.getString(_activeSessionKey);

      _sessions.clear();
      if (rawData != null && rawData.isNotEmpty) {
        final decoded = jsonDecode(rawData) as List<dynamic>;
        for (final item in decoded) {
          _sessions.add(_ChatSession.fromJson(item as Map<String, dynamic>));
        }
      }

      // فرز الجلسات من الأحدث إلى الأقدم
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (_sessions.isNotEmpty) {
        // محاولة استرجاع الجلسة النشطة الأخيرة أو أول جلسة
        _currentSession = _sessions.firstWhere(
          (s) => s.id == activeId,
          orElse: () => _sessions.first,
        );
        _messages.clear();
        _messages.addAll(_currentSession!.messages);
      } else {
        // إنشاء جلسة أولى جديدة للمستخدم مع رسالة الترحيب
        _createNewSessionInternal(autoSave: true);
      }
    } catch (e) {
      debugPrint("⚠️ Error loading chat sessions: $e");
      if (_sessions.isEmpty) {
        _createNewSessionInternal(autoSave: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  _ChatMessage _buildWelcomeMessage() {
    String greeting;
    switch (widget.userRole) {
      case 'teacher':
        greeting = "أهلاً بك يا أستاذ! أنا مساعد **EduBridge AI** للتعليم الذكي. يمكنني مساعدتك في تنظيم المحاضرات، صياغة أفكار للاختبارات، أو متابعة لوائح التقويم الأكاديمي.";
        break;
      case 'parent':
        greeting = "مرحباً بك ولي أمر الطالب العزيز! أنا مساعد **EduBridge AI**. يمكنني إرشادك حول كيفية متابعة دوام ابنك، درجاته، واللوائح الامتحانية في المعهد.";
        break;
      case 'boss':
      case 'head':
        greeting = "أهلاً بك رئيس القسم! أنا مساعدك الإداري والأكاديمي الذكي لنظام EduBridge. جاهز لدعمك في الأنظمة، التقارير، والقرارات الأكاديمية.";
        break;
      case 'affairs':
        greeting = "مرحباً بك زميلنا في شؤون الطلاب! أنا المساعد الذكي لمتابعة اللوائح والخدمات الطلابية وتسهيل الإجراءات الإدارية.";
        break;
      default:
        greeting = "أهلاً بك يا ${widget.userName}! أنا مساعدك الأكاديمي الذكي **EduBridge AI** 🌟.\n\nكيف يمكنني مساعدتك اليوم؟ يمكنك سؤالي عن لوائح الغياب، الامتحانات، العلامات، أو طلب نصائح دراسية!";
    }

    return _ChatMessage(
      text: greeting,
      isUser: false,
      time: DateTime.now(),
    );
  }

  void _createNewSessionInternal({bool autoSave = true}) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final welcomeMsg = _buildWelcomeMessage();
    final newSession = _ChatSession(
      id: newId,
      title: 'محادثة جديدة',
      updatedAt: DateTime.now(),
      messages: [welcomeMsg],
    );

    _sessions.insert(0, newSession);
    _currentSession = newSession;
    _messages.clear();
    _messages.add(welcomeMsg);

    if (autoSave) {
      _saveSessions();
    }
  }

  void _createNewSession() {
    setState(() {
      _createNewSessionInternal(autoSave: true);
    });
    _scrollToBottom();
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      if (_currentSession != null) {
        await prefs.setString(_activeSessionKey, _currentSession!.id);
      }
    } catch (e) {
      debugPrint("⚠️ Error saving chat sessions: $e");
    }
  }

  void _switchToSession(_ChatSession session) {
    setState(() {
      _currentSession = session;
      _messages.clear();
      _messages.addAll(session.messages);
    });
    _saveSessions();
    _scrollToBottom();
  }

  void _deleteSession(_ChatSession session) {
    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
      if (_currentSession?.id == session.id) {
        if (_sessions.isNotEmpty) {
          _currentSession = _sessions.first;
          _messages.clear();
          _messages.addAll(_currentSession!.messages);
        } else {
          _createNewSessionInternal(autoSave: false);
        }
      }
    });
    _saveSessions();
  }

  void _clearAllSessions() {
    setState(() {
      _sessions.clear();
      _createNewSessionInternal(autoSave: false);
    });
    _saveSessions();
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
      case 'head':
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

    final userMsg = _ChatMessage(
      text: text,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      if (_currentSession != null) {
        _currentSession!.messages.add(userMsg);
        _currentSession!.updatedAt = DateTime.now();
        // تسمية الجلسة تلقائياً بأول سؤال للمستخدم
        if (_currentSession!.title == 'محادثة جديدة' || _currentSession!.title.isEmpty) {
          _currentSession!.title = text.length > 32 ? '${text.substring(0, 32)}...' : text;
        }
      }
      _isTyping = true;
    });

    _saveSessions();
    _scrollToBottom();

    // تجهيز السجل للمساعد من الرسائل السابقة فقط (آخر رسالتين فقط لضمان التركيز)
    final priorMessages = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <_ChatMessage>[];
    final recentMessages = priorMessages.length > 2
        ? priorMessages.sublist(priorMessages.length - 2)
        : priorMessages;
    final history = recentMessages
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
      final aiMsg = _ChatMessage(
        text: response,
        isUser: false,
        time: DateTime.now(),
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMsg);
        if (_currentSession != null) {
          _currentSession!.messages.add(aiMsg);
          _currentSession!.updatedAt = DateTime.now();
        }
      });

      _saveSessions();
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

  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final isYesterday = now.difference(dt).inDays == 1 || (now.day - dt.day == 1 && now.month == dt.month);

    final hourInt = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'م' : 'ص';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hourInt:$minuteStr $period';

    if (isToday) {
      return 'اليوم $timeStr';
    } else if (isYesterday) {
      return 'أمس $timeStr';
    } else {
      return '${dt.day}/${dt.month} $timeStr';
    }
  }

  void _showChatHistoryBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFCC00);
    final cardColor = isDark ? const Color(0xFF1E2026) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // مقبض السحب
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // الهيدر
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.history_rounded, color: Color(0xFFB8860B), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "سجلات المحادثة",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${_sessions.length} محادثة محفوظة",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(bottomSheetContext);
                              _createNewSession();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("تم بدء محادثة جديدة ✨"),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.black),
                            label: const Text(
                              "محادثة جديدة",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryYellow,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 16),

                    // قائمة المحادثات
                    Expanded(
                      child: _sessions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    "لا توجد سجلات محادثة سابقة",
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _sessions.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final session = _sessions[index];
                                final isActive = session.id == _currentSession?.id;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(bottomSheetContext);
                                      if (!isActive) {
                                        _switchToSession(session);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? primaryYellow.withOpacity(isDark ? 0.15 : 0.08)
                                            : (isDark ? const Color(0xFF252830) : Colors.grey.shade50),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isActive
                                              ? primaryYellow
                                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                          width: isActive ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? primaryYellow
                                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              isActive ? Icons.chat_rounded : Icons.chat_bubble_outline_rounded,
                                              color: isActive ? Colors.black : Colors.grey.shade600,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        session.title,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                                          color: textColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isActive)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        margin: const EdgeInsets.only(right: 6),
                                                        decoration: BoxDecoration(
                                                          color: primaryYellow,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          "الحالية",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatSessionTime(session.updatedAt),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "•  ${session.messages.length} رسالة",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                            tooltip: "حذف المحادثة",
                                            onPressed: () {
                                              _deleteSession(session);
                                              setSheetState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // الفوتر
                    if (_sessions.length > 1)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text("مسح كافة السجلات"),
                                content: const Text("هل أنت متأكد من رغبتك في حذف جميع سجلات المحادثات السابقة؟"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text("إلغاء"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);
                                      Navigator.pop(bottomSheetContext);
                                      _clearAllSessions();
                                    },
                                    child: const Text("مسح الكل", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                          label: const Text(
                            "مسح كافة السجلات",
                            style: TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryYellow.withOpacity(0.6), width: 1.2),
                ),
                child: const Icon(Icons.history_rounded, color: Color(0xFFB8860B), size: 21),
              ),
              tooltip: "سجلات المحادثة",
              onPressed: _showChatHistoryBottomSheet,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                ),
              )
            : Column(
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
    final detectedUrl = _extractUrl(msg.text);

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
            child: GestureDetector(
              onLongPress: () => _copyMessage(msg.text),
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
                    SelectableText(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: isUser ? Colors.black : textColor,
                      ),
                    ),
                    if (detectedUrl != null)
                      _buildLinkChip(detectedUrl, isDark, primaryYellow),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _copyMessage(msg.text),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: isUser ? Colors.black54 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "نسخ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isUser ? Colors.black54 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          "${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? Colors.black54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
            SizedBox(width: 8),
            Text("تم نسخ الرسالة إلى الحافظة 📋"),
          ],
        ),
        backgroundColor: const Color(0xFF22252A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _extractUrl(String text) {
    final match = RegExp(r'https?://[^\s`*()<>]+').firstMatch(text);
    return match?.group(0);
  }

  Widget _buildLinkChip(String url, bool isDark, Color primaryYellow) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E24) : const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryYellow.withOpacity(0.6), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("تم نسخ الرابط: $url", maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1B1E24),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: Color(0xFFB8860B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    url,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2979FF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 12, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        "نسخ الرابط",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
