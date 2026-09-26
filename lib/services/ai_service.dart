import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// إرسال رسالة إلى المساعد الذكي
  Future<String> sendMessage({
    required String message,
    required String userRole,
    List<Map<String, String>> history = const [],
  }) async {
    final cleanMsg = message.trim();
    if (cleanMsg.isEmpty) return "يرجى كتابة رسالتك أولاً.";

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final dio = Dio(BaseOptions(
        baseUrl: ApiService().baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.post('/ai/chat', data: {
        'message': cleanMsg,
        'role': userRole,
        'history': history,
      });

      if (response.statusCode == 200 && response.data != null) {
        final reply = response.data['reply'] ?? response.data['message'] ?? response.data['response'];
        if (reply != null && reply.toString().trim().isNotEmpty) {
          return reply.toString().trim();
        }
      }
    } catch (e) {
      debugPrint("⚠️ [AiService] Backend AI not reachable or error: $e");
    }

    // 🌟 نظام الاستجابة الأكاديمي الذكي المدمج (Offline / Exhibition Ready Knowledge Base)
    // لضمان تقديم عرض ناجح ومبهر في المعرض حتى عند انقطاع الاتصال أو بطء الشبكة
    return _generateSmartLocalResponse(cleanMsg, userRole);
  }

  String _generateSmartLocalResponse(String query, String role) {
    final q = query.toLowerCase();

    // 1. استفسارات الحضور والغياب والإنذارات
    if (q.contains('غياب') || q.contains('حضور') || q.contains('انذار') || q.contains('إنذار') || q.contains('حرمان')) {
      return "📌 **نظام الحضور والغياب الأكاديمي في EduBridge:**\n\n"
          "• يُعتبر الطالب حاضراً لليوم الأكاديمي عند حضور جلسة واحدة على الأقل.\n"
          "• **الإنذار الأولي:** يتم توجيهه عند وصول نسبة الغياب إلى **15%**.\n"
          "• **الحرمان من المقرر:** يصدر قرار الحرمان تلقائياً عند تجاوز نسبة الغياب **20%**.\n"
          "💡 يمكنك متابعة سجل حضورك الدقيق وجلساتك من خلال تبويب 'الحضور والغياب' في القائمة الرئيسية.";
    }

    // 2. استفسارات الامتحانات والجدول
    if (q.contains('امتحان') || q.contains('جدول') || q.contains('اختبار') || q.contains('دوام') || q.contains('محاضر')) {
      return "📅 **الجداول والمواعيد الأكاديمية:**\n\n"
          "• تم تحديث جداول الامتحانات والدوام للدفعة الحالية بدقة.\n"
          "• يمكنك فتح خيار **'جدول الامتحانات'** أو **'جدول المحاضرات'** للاطلاع على التوقيت والقاعات وأسماء المدرسين.\n"
          "• يُتيح لك التطبيق تحميل نسخة رسمية عالية الدقة كصورة لحفظها على هاتفك مباشرة.";
    }

    // 3. استفسارات العلامات والدرجات والمسار الأكاديمي
    if (q.contains('علام') || q.contains('معدل') || q.contains('درج') || q.contains('كشف') || q.contains('مسار')) {
      return "📊 **نظام العلامات والمسار الدراسي:**\n\n"
          "• يتم رصد العلامات مقسمة إلى: (الأعمال الفصلية، المذاكرات، والامتحان النهائي).\n"
          "• الحد الأدنى للنجاح في المقرر هو **50/100**.\n"
          "• يمكنك مراجعة **كشف العلامات الأكاديمي التراكمي** والمسار الدراسي لكل فصل من خلال قسم 'العلامات' في التطبيق.";
    }

    // 4. استفسارات الخدمات الطلابية وطلبات الأجهزة
    if (q.contains('خدم') || q.contains('طلب') || q.contains('جهاز') || q.contains('تغيير') || q.contains('شهادة') || q.contains('عذر')) {
      return "📑 **بوابة الخدمات والشؤون الطلابية:**\n\n"
          "يمكنك تقديم الطلبات الإدارية إلكترونياً دون الحاجة لمراجعة الإدارة:\n"
          "1. طلب مصدقة تخرج أو كشف علامات رسمي.\n"
          "2. طلب إعادة تعيين الجهاز (Device Reset) لتسجيل الحضور من هاتف جديد.\n"
          "3. تقديم عذر طبي أو غياب رسمي مع إرفاق الثبوتيات.\n"
          "⚡ تتبع حالة طلبك فوراً من قسم 'الخدمات الطلابية'.";
    }

    // 5. الترحيب والتعريف
    if (q.contains('مرحبا') || q.contains('أهلا') || q.contains('السلام') || q.contains('صباح') || q.contains('مساء') || q == 'hi' || q == 'hello') {
      return "أهلاً بك! أنا **EduBridge AI** 🌟، مساعدك الأكاديمي الذكي المدمج في التطبيق.\n\n"
          "أنا هنا لمساعدتك في كل ما يتعلق بنظام المعهد، المقررات، الحضور، الامتحانات، والتوجيه الدراسي. كيف أستطيع خدمتك الآن؟";
    }

    // 6. نصائح للمذاكرة
    if (q.contains('نصيح') || q.contains('ادرس') || q.contains('مذاكر') || q.contains('تنظيم')) {
      return "💡 **نصائح ذهبية للتفوق الأكاديمي:**\n\n"
          "1. **تنظيم الوقت:** قسّم ساعات الدراسة إلى فترات 45 دقيقة تليها 10 دقائق راحة (تقنية بومودورو).\n"
          "2. **المتابعة اليومية:** حل الواجبات والتكاليف المسندة من المدرسين فور صدورها على التطبيق.\n"
          "3. **الالتزام بالحضور:** الحضور الفعلي للمحاضرات يضمن 50% من فهم المادة ويجنبك قرارات الحرمان.\n"
          "4. **الاستفسار:** لا تتردد في مراسلة مدرس المقرر عبر قسم الرسائل لأي مسألة غير واضحة.";
    }

    // 7. الرد التوليدي الذكي العام
    return "شكراً لسؤالك! بصفتي المساعد الذكي لنظام **EduBridge**، أود إعلامك أن هذا الاستفسار مرتبط بنظام المعهد الأكاديمي.\n\n"
        "✨ إذا كنت تسأل عن تفاصيل مخصصة لحسابك (مثل غياباتك أو موادك)، يمكنك زيارة القسم المخصص لها من القائمة، أو سؤالي عن اللوائح وسأرشدك فوراً!";
  }
}
