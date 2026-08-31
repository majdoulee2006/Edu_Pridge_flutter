import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {

  // ==========================================
  // 🌟 اكتشاف السيرفر تلقائياً على الشبكة المحلية
  // ==========================================
  static String _serverIp = '127.0.0.1'; // PC Localhost (ADB Reversed)
  static const String _port = '8001';
  static bool _isDiscovering = false;

  static String get serverIp => _serverIp;

  static Future<void> setServerIp(String ip) async {
    _serverIp = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

  // تهيئة الإعدادات وتحميل آخر آي بي تم اكتشافه، ثم بدء البحث التلقائي
  static Future<void> init() async {
    try {
      // 1. فحص الاتصال الفوري عبر ADB Reverse (127.0.0.1)
      final usb = await _tryConnect('127.0.0.1');
      if (usb != null) {
        _serverIp = '127.0.0.1';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_ip', '127.0.0.1');
        debugPrint("🎯 ApiService initialized instantly via 127.0.0.1:8000");
        return;
      }

      // 2. فحص آي بي الكمبيوتر المباشر على الواي فاي (172.20.10.3 & 192.168.21.53)
      final wifiHotspot = await _tryConnect('172.20.10.3');
      if (wifiHotspot != null) {
        _serverIp = '172.20.10.3';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_ip', '172.20.10.3');
        debugPrint("🎯 ApiService initialized instantly via 172.20.10.3:8000");
        return;
      }

      final wifiCurrent = await _tryConnect('192.168.21.53');
      if (wifiCurrent != null) {
        _serverIp = '192.168.21.53';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_ip', '192.168.21.53');
        debugPrint("🎯 ApiService initialized instantly via 192.168.21.53:8000");
        return;
      }

      final wifiOld = await _tryConnect('192.168.1.110');
      if (wifiOld != null) {
        _serverIp = '192.168.1.110';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_ip', '192.168.1.110');
        debugPrint("🎯 ApiService initialized instantly via 192.168.1.110:8000");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      _serverIp = prefs.getString('server_ip') ?? '192.168.1.110';
      debugPrint("📡 ApiService initialized. Last known IP: $_serverIp");
      
      // بدء الاكتشاف التلقائي في الخلفية
      autoDiscoverServer();
    } catch (e) {
      debugPrint("🚨 Error initializing ApiService: $e");
      _serverIp = '192.168.1.110';
    }
  }

  // البحث التلقائي عن السيرفر في الشبكة المحلية عبر فحص الـ Subnet
  static Future<void> autoDiscoverServer() async {
    if (kIsWeb) {
      _serverIp = '127.0.0.1';
      _isDiscovering = false;
      return;
    }
    if (_isDiscovering) return;
    _isDiscovering = true;
    debugPrint("🔍 Starting server discovery...");

    // أولاً: فحص الاتصال بالمضيف المحلي 127.0.0.1 (ADB Reverse USB)
    final usbResult = await _tryConnect('127.0.0.1');
    if (usbResult != null) {
      _serverIp = '127.0.0.1';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', '127.0.0.1');
      debugPrint("🎯 Server connected via USB ADB Reverse (127.0.0.1:8000)");
      _isDiscovering = false;
      return;
    }
    
    try {
      // 1. تجربة الآيبيهات المعروفة بسرعة أولاً
      final knownIps = ['192.168.1.100', '172.20.10.3', '127.0.0.1', '192.168.1.101', '192.168.1.109', '192.168.1.103', '192.168.21.53', '192.168.21.75', '192.168.137.1', '192.168.137.242', '10.0.2.2', '10.63.70.164', '192.168.137.66'];
      for (final ip in knownIps) {
        final res = await _tryConnect(ip);
        if (res != null) {
          _serverIp = res;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('server_ip', res);
          debugPrint("🎯 Server found at known IP: $res");
          _isDiscovering = false;
          return;
        }
      }

      final localIp = await _getLocalIp();
      if (localIp != null && localIp.contains('.')) {
        final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
        debugPrint("🌐 Device Local IP: $localIp, Scanning subnet: $subnet.*");
        
        final futures = <Future<String?>>[];
        for (int i = 1; i <= 254; i++) {
          final targetIp = '$subnet.$i';
          futures.add(_tryConnect(targetIp));
        }
        
        final results = await Future.wait(futures);
        for (var res in results) {
          if (res != null) {
            _serverIp = res;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('server_ip', res);
            debugPrint("🎯 Server discovered successfully at: $res");
            _isDiscovering = false;
            return;
          }
        }
      }
      _serverIp = '127.0.0.1';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', '127.0.0.1');
      debugPrint("⚠️ Auto-discovery completed: Server not found. Resetting fallback to 127.0.0.1");
    } catch (e) {
      debugPrint("🚨 Error during auto-discovery: $e");
      _serverIp = '127.0.0.1';
    }
    _isDiscovering = false;
  }

  static Future<String?> _getLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ip = addr.address;
            // التحقق من أن الآي بي يقع ضمن شبكة محلية خاصة قياسية
            if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
              return ip;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _tryConnect(String ip) async {
    try {
      // محاولة فتح اتصال TCP سريع على منفذ السيرفر بمهلة زمنية مناسبة (1.5 ثانية)
      final socket = await Socket.connect(ip, int.parse(_port), timeout: const Duration(milliseconds: 1500));
      socket.destroy();
      return ip;
    } catch (_) {
      return null;
    }
  }

  String get baseUrl {
    return "http://192.168.126.25:$_port/api";
  }

  // تصليح روابط الميديا الراجعة من السيرفر
  static String? fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    String hardcodedIp = '192.168.126.25';
    if (!kIsWeb) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        String cleanUrl = url.startsWith('/') ? url.substring(1) : url;
        return 'http://$hardcodedIp:$_port/$cleanUrl';
      }
      return url
          .replaceFirst('http://127.0.0.1:', 'http://$hardcodedIp:')
          .replaceFirst('http://localhost:', 'http://$hardcodedIp:')
          .replaceFirst('http://localhost/', 'http://$hardcodedIp:$_port/')
          .replaceFirst('http://127.0.0.1/', 'http://$hardcodedIp:$_port/');
    }
    return url;
  }

  final Dio _dio = Dio();

  // ==========================================
  // 1. دالة تسجيل الدخول
  // ==========================================
  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      _dio.options.headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      Response response = await _dio.post(
        "$baseUrl/login",
        data: {
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        String token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (response.data['user'] != null) {
          await prefs.setString('role', response.data['user']['role']);
          await prefs.setString('user_id', response.data['user']['user_id']?.toString() ?? '');
        }
        return response.data;
      }
    } on DioException catch (e) {
      debugPrint("Login Error: ${e.response?.data['message'] ?? 'فشل الاتصال'}");
      return null;
    }
    return null;
  }

  // ==========================================
  // 2. دالة جلب بيانات الطالب للداشبورد
  // ==========================================
  Future<Map<String, dynamic>?> getStudentDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.get(
        "$baseUrl/student/dashboard",
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
    }
    return null;
  }

  // ==========================================
  // 3. دوال الخدمات الطلابية
  // ==========================================

  // جلب الطلبات السابقة للطالب (مع إمكانية الفلترة حسب النوع)
  Future<List<dynamic>?> getStudentServiceRequests({String? type}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      String url = "$baseUrl/student/services/requests";
      if (type != null) {
        url += "?type=$type";
      }

      Response response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getStudentServiceRequests Error: $e");
    }
    return null;
  }

  // إرسال طلب خدمة طلابية جديد
  Future<Map<String, dynamic>?> submitStudentServiceRequest(String type, String details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      Response response = await _dio.post(
        "$baseUrl/student/services/requests",
        data: {
          'type': type,
          'details': details,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      debugPrint("submitStudentServiceRequest DioError: ${e.response?.data}");
      return e.response?.data;
    } catch (e) {
      debugPrint("submitStudentServiceRequest Error: $e");
    }
    return null;
  }

  // ==========================================
  // دوال رئيس القسم (HOD)
  // ==========================================

  Future<List<dynamic>?> getHeadLeaveRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/department-head/leave-requests",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getHeadLeaveRequests Error: $e");
    }
    return null;
  }

  Future<bool> respondHeadLeaveRequest(int id, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.put(
        "$baseUrl/department-head/leave-requests/$id/respond",
        data: {'status': status},
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      return (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("respondHeadLeaveRequest Error: $e");
      return false;
    }
  }

  Future<List<dynamic>?> getHeadGradeReportRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/department-head/grade-report-requests",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getHeadGradeReportRequests Error: $e");
    }
    return null;
  }

  Future<List<dynamic>?> getHeadReportRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/department-head/report-requests",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getHeadReportRequests Error: $e");
    }
    return null;
  }

  Future<List<dynamic>?> getHeadStudentServiceRequests(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/department-head/student-service-requests?type=$type",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getHeadStudentServiceRequests Error: $e");
    }
    return null;
  }

  Future<bool> respondHeadStudentServiceRequest(int id, String status, {String notes = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.put(
        "$baseUrl/department-head/student-service-requests/$id/respond",
        data: {'status': status, 'notes': notes},
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      return (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("respondHeadStudentServiceRequest Error: $e");
      return false;
    }
  }

  // ── Head of Department Appointments & Summons ──────────────────────────
  Future<List<dynamic>?> getMeetingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/department-head/appointments/meetings",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getMeetingRequests Error: $e");
    }
    return null;
  }

  Future<List<dynamic>?> getSummons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/department-head/appointments/summons",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getSummons Error: $e");
    }
    return null;
  }

  Future<bool> respondToMeetingRequest(int id, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.put(
        "$baseUrl/department-head/appointments/meetings/$id/respond",
        data: {'status': status},
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      return (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("respondToMeetingRequest Error: $e");
      return false;
    }
  }

  // ── Educator / Teacher Parent Summons APIs ──────────────────────────
  Future<List<dynamic>?> getEducatorStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/teacher/educator-students",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getEducatorStudents Error: $e");
    }
    return null;
  }

  Future<bool> requestTeacherParentSummon(int studentId, String reasonTitle, String details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.post(
        "$baseUrl/teacher/parent-summons/request",
        data: {
          'student_id': studentId,
          'reason_title': reasonTitle,
          'details': details,
        },
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      return (response.statusCode == 200 || response.statusCode == 201) && (response.data['success'] == true);
    } catch (e) {
      debugPrint("requestTeacherParentSummon Error: $e");
      return false;
    }
  }

  Future<List<dynamic>?> getTeacherSummonsHistory({String status = 'all'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.get(
        "$baseUrl/teacher/parent-summons-history?status=$status",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("getTeacherSummonsHistory Error: $e");
    }
    return null;
  }

  Future<bool> forwardSummonToAffairs(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.post(
        "$baseUrl/department-head/appointments/summons/$id/forward",
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      return (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("forwardSummonToAffairs Error: $e");
      return false;
    }
  }

  Future<bool> issueParentSummon(int id, String summonDate, {String notes = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      Response response = await _dio.post(
        "$baseUrl/affairs/appointments/summons/$id/issue",
        data: {'summon_date': summonDate, 'notes': notes},
        options: Options(headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      );
      return (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("issueParentSummon Error: $e");
      return false;
    }
  }
}
