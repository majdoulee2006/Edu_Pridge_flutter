import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:edu_pridge_flutter/services/session_guard.dart';

/// رد المساعد مع مصدره، ليعرف المستخدم هل الجواب من الخادم أم رسالة عدم اتصال.
class AiReply {
  final String text;

  /// false = لم نصل للخادم (الرد رسالة محلية مختصرة وليس جواباً عن بيانات المستخدم).
  final bool isOnline;

  /// 'gemini' | 'local_engine' | 'offline' | 'error'
  final String source;

  const AiReply(this.text, {required this.isOnline, required this.source});
}

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // يمر على SingleSessionInterceptor ليُعالَج 401 (تسجيل الدخول من جهاز آخر) كباقي الشاشات
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    // الخادم قد يجرّب حتى 3 موديلات (12 ثانية لكل منها)
    receiveTimeout: const Duration(seconds: 50),
  ))
    ..interceptors.add(SingleSessionInterceptor());

  /// إرسال رسالة إلى المساعد الذكي. الدور الفعلي يحدده الخادم من التوكن.
  Future<AiReply> sendMessage({
    required String message,
    required String userRole,
    List<Map<String, String>> history = const [],
  }) async {
    final cleanMsg = message.trim();
    if (cleanMsg.isEmpty) {
      return const AiReply('يرجى كتابة رسالتك أولاً.', isOnline: true, source: 'error');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await _dio.post(
        '${ApiService().baseUrl}/ai/chat',
        data: {
          'message': cleanMsg,
          'role': userRole,
          'history': history,
          'server_url': ApiService.baseHttpUrl,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        }),
      );

      final reply = response.data is Map ? response.data['reply'] : null;
      if (reply != null && reply.toString().trim().isNotEmpty) {
        return AiReply(
          reply.toString().trim(),
          isOnline: true,
          source: (response.data['source'] ?? 'local_engine').toString(),
        );
      }
    } on DioException catch (e) {
      debugPrint('⚠️ [AiService] ${e.response?.statusCode} ${e.message}');
      final code = e.response?.statusCode;
      if (code == 429) {
        return const AiReply('أرسلت رسائل كثيرة بسرعة 😅 انتظر دقيقة ثم حاول مجدداً.', isOnline: true, source: 'error');
      }
      if (code == 401) {
        // SingleSessionInterceptor يتولى إعادة المستخدم لشاشة الدخول
        return const AiReply('انتهت جلستك، الرجاء تسجيل الدخول مجدداً.', isOnline: true, source: 'error');
      }
      if (code == 422) {
        return const AiReply('الرسالة طويلة جداً أو غير صالحة، اختصرها وحاول مجدداً.', isOnline: true, source: 'error');
      }
    } catch (e) {
      debugPrint('⚠️ [AiService] $e');
    }

    return const AiReply(_offlineMessage, isOnline: false, source: 'offline');
  }

  static const String _offlineMessage = '⚠️ **تعذّر الاتصال بالخادم حالياً.**\n\n'
      'لا أستطيع قراءة بياناتك (جدولك، غيابك، علاماتك) بدون اتصال، وتحقق من الشبكة ثم أعد المحاولة.\n\n'
      'في الأثناء، أبرز اللوائح:\n'
      '• إنذار أول عند 7 أيام غياب غير معذور، وثانٍ مع استدعاء ولي الأمر عند 10، ونهائي وإحالة للإدارة عند 15.\n'
      '• الغياب بعذر معتمد لا يُحتسب، والعذر الطبي يُقدَّم خلال 48 ساعة.\n'
      '• الحد الأدنى للنجاح 50/100.';

  /// يمسح كل محادثات المساعد المحفوظة على الجهاز (تُستدعى عند تسجيل الخروج حفاظاً على الخصوصية).
  static Future<void> clearLocalChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith('ai_chat_')).toList()) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('⚠️ [AiService] clearLocalChats: $e');
    }
  }
}
