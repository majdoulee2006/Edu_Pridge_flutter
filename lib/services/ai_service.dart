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
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 40),
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

    // 0. فحص الصلاحيات
    if (role == 'student' && (q.contains('رصد') || q.contains('تعديل درجات') || q.contains('تعديل علامات') || q.contains('حسابات') || q.contains('لوحة المدير') || q.contains('لوحة المعلم'))) {
      return "عذراً، هذه البيانات والإجراءات ليست من صلاحياتك للاطلاع عليها أو إدارتها، وليس من صلاحياتي إخبارك بها أو بتفاصيلها. يرجى مراجعة إدارة المعهد أو المعنيين بذلك.";
    }

    // 1. التحيات والمحادثات الودية
    if (q == 'كيفك' || q == 'كيفك اليوم' || q == 'مرحبا' || q == 'أهلا' || q == 'اهلين' || q.contains('شو أخبارك') || q.contains('شو اخبارك') || q.contains('كيف حالك')) {
      return "يا أهلاً وسهلاً بك! أنا بأفضل حال والحمد لله، وكلي طاقة وسعادة لأني معك اليوم. تسلم على سؤالك اللطيف! ❤️\n\n"
          "طمني عنك كيف حالك؟ أنا جاهز بكل سرور لأساعدك بأي استفسار عن جدولك، محاضراتك، غيابك، أو أي ميزة بالمنظومة! 😊✨";
    }

    // 1.5 روابط وتسجيل الدخول على منصة الويب المخصصة لكل دور
    if (q.contains('تسجيل دخول') || q.contains('تسجيل الدخول') || q.contains('رابط الدخول') || q.contains('رابط الويب') || q.contains('رابط تسجيل') || q.contains('بوابة الويب') || q.contains('بوابة الدخول') || q.contains('فوت عالويب') || q.contains('ادخل عالويب') || q.contains('موقع المعهد') || q.contains('رابط المنصة')) {
      String base = ApiService.baseHttpUrl;
      if (base.contains('127.0.0.1') || base.contains('localhost')) {
        base = 'http://10.102.114.209:8000';
      }
      final roleClean = role.toLowerCase();
      if (roleClean == 'teacher') {
        return "🌐 **بوابة تسجيل الدخول الخاصة بالأستاذ / المدرس على الويب:**\n\n"
            "• يمكنك نسخ هذا الرابط ولصقه مباشرة في شريط عنوان المتصفح:\n"
            "🔗 **`$base/teacher/login`**\n\n"
            "• يتيح لك رصد الحضور التفاعلي، رفع المحاضرات، ونشر وتصحيح الواجبات.\n"
            "• كما يتوفر الرابط العام الموحد كبديل: `$base/login`.";
      } else if (roleClean == 'parent') {
        return "🌐 **بوابة تسجيل الدخول الخاصة بولي الأمر على الويب:**\n\n"
            "• يمكنك نسخ هذا الرابط ولصقه مباشرة في شريط عنوان المتصفح:\n"
            "🔗 **`$base/parent/login`**\n\n"
            "• يتيح لك متابعة دوام الأبناء والواجبات وعلاماتهم وتقديم أذونات الغياب.\n"
            "• كما يتوفر الرابط العام الموحد كبديل: `$base/login`.";
      } else if (roleClean == 'hod' || roleClean == 'boss' || roleClean == 'head') {
        return "🌐 **بوابة تسجيل الدخول الخاصة برئيس القسم على الويب:**\n\n"
            "• يمكنك نسخ هذا الرابط ولصقه مباشرة في شريط عنوان المتصفح:\n"
            "🔗 **`$base/hod/login`**\n\n"
            "• لإدارة التنظيم الأكاديمي وجداول المحاضرات وتوزيع القاعات والمراقبين.\n"
            "• كما يتوفر الرابط العام الموحد كبديل: `$base/login`.";
      } else if (roleClean == 'affairs') {
        return "🌐 **بوابة تسجيل الدخول الخاصة بشؤون الطلاب على الويب:**\n\n"
            "• يمكنك نسخ هذا الرابط ولصقه مباشرة في شريط عنوان المتصفح:\n"
            "🔗 **`$base/affairs/login`**\n\n"
            "• لمعالجة طلبات إعادة تعيين الأجهزة، تثقيل المواد، المصدقات، وترفيع الطلاب.\n"
            "• كما يتوفر الرابط العام الموحد كبديل: `$base/login`.";
      } else if (roleClean == 'admin') {
        return "🌐 **بوابة تسجيل الدخول الخاصة بالإدارة العامة على الويب:**\n\n"
            "• يمكنك نسخ هذا الرابط ولصقه مباشرة في شريط عنوان المتصفح:\n"
            "🔗 **`$base/admin/login`**\n\n"
            "• لإدارة الحسابات، الأقسام، السجلات الأمنية، ومتابعة النظام الشامل.\n"
            "• كما يتوفر الرابط العام الموحد كبديل: `$base/login`.";
      } else {
        return "🌐 **بوابة تسجيل الدخول الخاصة بالطالب على الويب:**\n\n"
            "• يمكنك نسخ هذا الرابط ولصقه مباشرة في شريط عنوان المتصفح:\n"
            "🔗 **`$base/student/login`**\n\n"
            "• تدعم البوابة الدخول بالرقم الجامعي، بالإضافة لخدمات التحقق بالوجه والـ OTP عبر تيليغرام.\n"
            "• كما يتوفر الرابط العام الموحد كبديل: `$base/login`.";
      }
    }

    // 2. استفسارات المحاضرات والدوام
    if (q.contains('محاضر') || q.contains('كم محاضرة') || q.contains('دوام') || q.contains('مقرر')) {
      return "📚 **المحاضرات وجدول الدوام الأسبوعي:**\n\n"
          "📱 **عبر الموبايل:**\n"
          "• لمعرفة مواعيد محاضراتك والقاعات، اضغط على الزر المركزي (Speed Dial) ➡️ **'الجدول'** ويمكنك حفظه كصورة PNG عالية الدقة بجهازك.\n"
          "• لتصفح المواد وتحميل ملفات المحاضرات، اختر من الزر المركزي **'المحاضرات'**.\n\n"
          "💻 **عبر الويب:**\n"
          "• تجد جدول محاضراتك كاملاً في لوحة الطالب عبر الرابط: `/student/schedule`، وموادك عبر `/student/courses`.";
    }

    // 3. استفسارات الحضور والغياب والإنذارات
    if (q.contains('غياب') || q.contains('حضور') || q.contains('انذار') || q.contains('إنذار') || q.contains('حرمان')) {
      return "📌 **نظام الحضور والغياب الأكاديمي في EduBridge:**\n\n"
          "• يُعتبر الطالب حاضراً لليوم الأكاديمي عند حضور جلسة واحدة على الأقل.\n"
          "• **الإنذار الأولي:** يتم توجيهه عند وصول نسبة الغياب إلى **15%**.\n"
          "• **الحرمان من المقرر:** يصدر قرار الحرمان تلقائياً عند تجاوز نسبة الغياب **20%**.\n\n"
          "📱 **عبر الموبايل:** افتح الزر المركزي (Speed Dial) ➡️ **'الحضور والغياب'** لرؤية تفاصيل جلساتك وتقديم الأعذار.\n"
          "💻 **عبر الويب:** عبر صفحتي `/student/attendance` و `/student/warnings`.";
    }

    // 4. استفسارات الامتحانات الرسمية
    if (q.contains('امتحان') || q.contains('اختبار') || q.contains('برنامج الامتحان')) {
      return "📅 **جداول الامتحانات الرسمية:**\n\n"
          "• تم اعتماد ونشر جداول الامتحانات للدفعة الحالية بدقة.\n\n"
          "📱 **عبر الموبايل:** اضغط على الزر المركزي (Speed Dial) ➡️ **'الجدول'** واستعرض مواعيد امتحاناتك وقاعاتك.\n"
          "💻 **عبر الويب:** عبر الرابط: `/student/schedule` ويمكنك تصدير الجدول كصورة.";
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
