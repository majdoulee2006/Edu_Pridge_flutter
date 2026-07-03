import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AffairsServices {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // 1. Dashboard Stats & Announcements
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/dashboard",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getDashboardStats Error: $e");
    }
    return null;
  }

  // 2. Pending Accounts
  Future<List<dynamic>?> getPendingAccounts() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/pending-accounts",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getPendingAccounts Error: $e");
    }
    return null;
  }

  Future<bool> approveAccount(int userId) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/accounts/$userId/approve",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ approveAccount Error: $e");
      return false;
    }
  }

  Future<bool> rejectAccount(int userId) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/accounts/$userId/reject",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ rejectAccount Error: $e");
      return false;
    }
  }

  // 3. Predefined University IDs
  Future<List<dynamic>?> getUniversityIds() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/university-ids",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getUniversityIds Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> addUniversityId(FormData formData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/university-ids",
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message'] ?? 'فشل الإضافة'};
    } on DioException catch (e) {
      debugPrint("❌ addUniversityId Error: $e");
      final msg = e.response?.data['message'] ?? 'حدث خطأ في الشبكة';
      return {'success': false, 'message': msg};
    }
  }

  Future<bool> deleteUniversityId(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/affairs/university-ids/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ deleteUniversityId Error: $e");
      return false;
    }
  }

  // 4. Accounts list & Reset device
  Future<List<dynamic>?> getAccounts() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/accounts",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getAccounts Error: $e");
    }
    return null;
  }

  Future<bool> toggleAccountStatus(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/accounts/$id/toggle",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ toggleAccountStatus Error: $e");
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/affairs/accounts/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ deleteAccount Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> updateAccount(int id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/accounts/$id/update",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': response.statusCode == 200, 'message': response.data['message']};
    } on DioException catch (e) {
      debugPrint("❌ updateAccount Error: $e");
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل التحديث'};
    }
  }

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/accounts/create",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': response.statusCode == 200 && response.data['success'] == true, 'message': response.data['message']};
    } on DioException catch (e) {
      debugPrint("❌ createAccount Error: $e");
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل إنشاء الحساب'};
    }
  }

  Future<bool> resetStudentDevice(int studentId) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/students/$studentId/reset-device",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ resetStudentDevice Error: $e");
      return false;
    }
  }

  // Metadata for Dropdowns
  Future<Map<String, dynamic>?> getMetadata() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/metadata",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getMetadata Error: $e");
    }
    return null;
  }

  // 5. Leaves / Vacations
  Future<List<dynamic>?> getLeaves() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/leaves",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getLeaves Error: $e");
    }
    return null;
  }

  Future<bool> updateLeaveStatus(int leaveId, String status) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/leaves/$leaveId/status",
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ updateLeaveStatus Error: $e");
      return false;
    }
  }

  // 6. Calendar Events
  Future<List<dynamic>?> getCalendarEvents() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/calendar",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getCalendarEvents Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> addCalendarEvent(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/calendar/events",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ addCalendarEvent Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateCalendarEvent(int id, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/calendar/events/update/$id",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ updateCalendarEvent Error: $e");
    }
    return null;
  }

  Future<bool> deleteCalendarEvent(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/calendar/events/delete/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ deleteCalendarEvent Error: $e");
      return false;
    }
  }

  // 7. Messages
  Future<Map<String, dynamic>?> getMessagesContacts() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/messages",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getMessagesContacts Error: $e");
    }
    return null;
  }

  Future<List<dynamic>?> getConversation(int userId) async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/messages/conversation/$userId",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getConversation Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendMessage(int receiverId, String text) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/messages",
        data: {'receiver_id': receiverId, 'message': text},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ sendMessage Error: $e");
    }
    return null;
  }

  // 8. Notifications
  Future<List<dynamic>?> getNotifications() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/notifications",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getNotifications Error: $e");
    }
    return null;
  }

  Future<bool> markNotificationRead(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/notifications/$id/read",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ markNotificationRead Error: $e");
      return false;
    }
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/notifications/read-all",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ markAllNotificationsRead Error: $e");
      return false;
    }
  }

  // 9. Profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/affairs/profile",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ getProfile Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/profile/update",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': response.statusCode == 200 && response.data['success'] == true, 'message': response.data['message']};
    } on DioException catch (e) {
      debugPrint("❌ updateProfile Error: $e");
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل تحديث البروفايل'};
    }
  }

  Future<Map<String, dynamic>> updatePassword(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/affairs/profile/password",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return {'success': response.statusCode == 200 && response.data['success'] == true, 'message': response.data['message']};
    } on DioException catch (e) {
      debugPrint("❌ updatePassword Error: $e");
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل تغيير كلمة المرور'};
    }
  }
}
