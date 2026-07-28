import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {

  // ==========================================
  // 🌟 اكتشاف السيرفر تلقائياً على الشبكة المحلية
  // ==========================================
  static String _serverIp = '192.168.137.242'; // آي بي اللابتوب الحالي على الـ Wi-Fi
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
      final prefs = await SharedPreferences.getInstance();
      _serverIp = prefs.getString('server_ip') ?? '192.168.137.242';
      debugPrint("📡 ApiService initialized. Last known IP: $_serverIp");
      
      // بدء الاكتشاف التلقائي في الخلفية
      autoDiscoverServer();
    } catch (e) {
      debugPrint("🚨 Error initializing ApiService: $e");
    }
  }

  // البحث التلقائي عن السيرفر في الشبكة المحلية عبر فحص الـ Subnet
  static Future<void> autoDiscoverServer() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    debugPrint("🔍 Starting auto-discovery for Edu-Bridge server on local network...");
    
    try {
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
      debugPrint("⚠️ Auto-discovery completed: Server not found. Using fallback/last known IP: $_serverIp");
    } catch (e) {
      debugPrint("🚨 Error during auto-discovery: $e");
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
    if (kIsWeb) {
      return "http://127.0.0.1:$_port/api";
    } else {
      return "http://$_serverIp:$_port/api";
    }
  }

  // تصليح روابط الميديا الراجعة من السيرفر
  static String? fixMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (!kIsWeb) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        String cleanUrl = url.startsWith('/') ? url.substring(1) : url;
        return 'http://$_serverIp:$_port/$cleanUrl';
      }
      return url
          .replaceFirst('http://127.0.0.1:', 'http://$_serverIp:')
          .replaceFirst('http://localhost:', 'http://$_serverIp:')
          .replaceFirst('http://localhost/', 'http://$_serverIp:$_port/')
          .replaceFirst('http://127.0.0.1/', 'http://$_serverIp:$_port/');
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
}
