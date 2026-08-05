import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class AdminServices {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ==========================================
  // 1. Dashboard Statistics
  // ==========================================
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/dashboard",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Dashboard Error: $e");
    }
    return null;
  }

  // ==========================================
  // 2. Users Management (GET, CREATE, UPDATE, DELETE)
  // ==========================================
  Future<List<dynamic>?> getUsers({int? roleId, String? role, String? status, bool all = true}) async {
    try {
      final token = await _getToken();
      final Map<String, dynamic> params = {};
      if (roleId != null) params['role_id'] = roleId;
      if (role != null) params['role'] = role;
      if (status != null) params['status'] = status;
      if (all) params['all'] = 1;

      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/users",
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map && data['data'] != null) {
          return data['data'];
        }
        return data as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Admin Get Users Error: $e");
    }
    return null;
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/users",
        data: userData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("❌ Admin Create User Error: $e");
      rethrow;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.put(
        "${ApiService().baseUrl}/admin/users/$id",
        data: userData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Update User Error: $e");
      rethrow;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/admin/users/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Delete User Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 3. Courses Management (GET, CREATE, UPDATE, DELETE)
  // ==========================================
  Future<List<dynamic>?> getCourses() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/courses",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map && data['data'] != null) {
          return data['data'];
        }
        return data as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Admin Get Courses Error: $e");
    }
    return null;
  }

  Future<bool> createCourse(Map<String, dynamic> courseData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/courses",
        data: courseData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("❌ Admin Create Course Error: $e");
      rethrow;
    }
  }

  Future<bool> updateCourse(int id, Map<String, dynamic> courseData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.put(
        "${ApiService().baseUrl}/admin/courses/$id",
        data: courseData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Update Course Error: $e");
      rethrow;
    }
  }

  Future<bool> deleteCourse(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/admin/courses/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Delete Course Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 4. Semesters Management (GET, CREATE, UPDATE, DELETE)
  // ==========================================
  Future<List<dynamic>?> getSemesters() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/semesters",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Get Semesters Error: $e");
    }
    return null;
  }

  Future<bool> createSemester(Map<String, dynamic> semData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/semesters",
        data: semData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("❌ Admin Create Semester Error: $e");
      rethrow;
    }
  }

  Future<bool> updateSemester(int id, Map<String, dynamic> semData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.put(
        "${ApiService().baseUrl}/admin/semesters/$id",
        data: semData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Update Semester Error: $e");
      rethrow;
    }
  }

  Future<bool> deleteSemester(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/admin/semesters/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Delete Semester Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 5. Departments Management (GET, CREATE, UPDATE, DELETE)
  // ==========================================
  Future<List<dynamic>?> getDepartments() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/departments",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Get Departments Error: $e");
    }
    return null;
  }

  // ==========================================
  // 6. Reports
  // ==========================================
  Future<List<dynamic>?> getReportsLog() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/reports/log",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Get Reports Log Error: $e");
    }
    return null;
  }

  Future<String?> downloadReport(int id, String format, String filename) async {
    try {
      final token = await _getToken();
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$filename";
      
      await _dio.download(
        "${ApiService().baseUrl}/admin/reports/export/$id?format=$format",
        filePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return filePath;
    } catch (e) {
      debugPrint("❌ Admin Download Report Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getSemestersSubjects({
    int? departmentId,
    int? programId,
    String? year,
    int? semesterId,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, dynamic>{};
      if (departmentId != null) queryParams['department_id'] = departmentId;
      if (programId != null) queryParams['program_id'] = programId;
      if (year != null && year.isNotEmpty) queryParams['year'] = year;
      if (semesterId != null) queryParams['semester_id'] = semesterId;

      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/semesters-subjects",
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Get Semesters Subjects Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getAssignHodData() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/assign-hod",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Get Assign HOD Data Error: $e");
    }
    return null;
  }

  Future<bool> assignHodExisting(int departmentId, int userId) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/assign-hod",
        data: {
          'department_id': departmentId,
          'user_id': userId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Assign Existing HOD Error: $e");
      rethrow;
    }
  }

  Future<bool> assignHodNew(Map<String, dynamic> hodData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/assign-hod/new",
        data: hodData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Assign New HOD Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createDepartment(Map<String, dynamic> deptData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/departments",
        data: deptData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true)) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Admin Create Department Error: $e");
      rethrow;
    }
  }

  Future<bool> assignProgramsToDepartment(int departmentId, List<int> programIds) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/departments/assign-programs",
        data: {
          'department_id': departmentId,
          'program_ids': programIds,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Assign Programs Error: $e");
      return false;
    }
  }

  Future<bool> updateDepartment(int id, Map<String, dynamic> deptData) async {
    try {
      final token = await _getToken();
      Response response = await _dio.put(
        "${ApiService().baseUrl}/admin/departments/$id",
        data: deptData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Update Department Error: $e");
      rethrow;
    }
  }

  Future<bool> deleteDepartment(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/admin/departments/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Delete Department Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 6. Reports Management
  // ==========================================
  Future<List<dynamic>?> getStudentsReport() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/reports/students",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Students Report Error: $e");
    }
    return null;
  }

  // ==========================================
  // 7. Profile Management (Self-service via general user routes)
  // ==========================================
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isEmpty) return null;
      
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/users/$userId",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Profile Fetch Error: $e");
    }
    return null;
  }

  Future<bool> updateAdminProfile(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isEmpty) return false;

      return await updateUser(int.parse(userId), userData);
    } catch (e) {
      debugPrint("❌ Admin Profile Update Error: $e");
    }
    return false;
  }

  // ==========================================
  // 8. Create Announcement (Post / General News)
  // ==========================================
  Future<bool> createAnnouncement({
    required String title,
    required String content,
    String? imagePath,
    String? targetAudience,
    int? departmentId,
    String? link,
  }) async {
    try {
      final token = await _getToken();
      
      Map<String, dynamic> data = {
        'title': title,
        'content': content,
        'target_audience': targetAudience ?? 'all',
      };
      if (link != null && link.isNotEmpty) {
        data['link_url'] = link;
      }
      if (departmentId != null) {
        data['department_id'] = departmentId;
      }
      
      if (imagePath != null && imagePath.isNotEmpty) {
        data['image'] = await MultipartFile.fromFile(imagePath);
      }
      
      FormData formData = FormData.fromMap(data);
      
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/announcements",
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
      );
      return response.statusCode == 201 || (response.statusCode == 200 && response.data['success'] == true);
    } catch (e) {
      debugPrint("❌ Admin Create Announcement Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 9. Send Broadcast (Administrative Circulars)
  // ==========================================
  Future<bool> sendBroadcast({
    required String recipientType,
    required String subject,
    required String message,
    List<int>? targetDepartments,
    List<int>? targetUsers,
  }) async {
    try {
      final token = await _getToken();
      
      Map<String, dynamic> data = {
        'recipient_type': recipientType,
        'subject': subject,
        'message': message,
      };
      
      if (targetDepartments != null && targetDepartments.isNotEmpty) {
        data['target_departments'] = targetDepartments;
      }
      
      if (targetUsers != null && targetUsers.isNotEmpty) {
        data['target_users'] = targetUsers;
      }
      
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/broadcast",
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Send Broadcast Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // 10. Pending Accounts Management
  // ==========================================
  Future<List<dynamic>?> getPendingAccounts() async {
    try {
      final token = await _getToken();
      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/pending-accounts",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("❌ Admin Pending Accounts Fetch Error: $e");
    }
    return null;
  }

  Future<bool> approveAccount(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/accounts/$id/approve",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Approve Account Error: $e");
    }
    return false;
  }

  Future<bool> rejectAccount(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/accounts/$id/reject",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Reject Account Error: $e");
    }
    return false;
  }

  // ==========================================
  // 11. Reports Management
  // ==========================================
  Future<Map<String, dynamic>?> getAttendanceReport(int? courseId, String? fromDate, String? toDate) async {
    try {
      final token = await _getToken();
      final Map<String, dynamic> params = {};
      if (courseId != null) params['course_id'] = courseId;
      if (fromDate != null) params['from_date'] = fromDate;
      if (toDate != null) params['to_date'] = toDate;

      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/reports/attendance",
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Admin Attendance Report Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getGradesReport(int? courseId, int? examId) async {
    try {
      final token = await _getToken();
      final Map<String, dynamic> params = {};
      if (courseId != null) params['course_id'] = courseId;
      if (examId != null) params['exam_id'] = examId;

      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/reports/grades",
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint("❌ Admin Grades Report Error: $e");
    }
    return null;
  }

  Future<bool> deleteAnnouncement(int id) async {
    try {
      final token = await _getToken();
      Response response = await _dio.delete(
        "${ApiService().baseUrl}/admin/announcements/$id",
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Delete Announcement Error: $e");
      return false;
    }
  }

  Future<bool> updateAnnouncement({
    required int id,
    required String title,
    required String content,
    String? targetAudience,
    int? departmentId,
    String? imagePath,
    String? link,
  }) async {
    try {
      final token = await _getToken();
      final formData = FormData.fromMap({
        'title': title,
        'content': content,
        if (targetAudience != null) 'target_audience': targetAudience,
        if (departmentId != null) 'department_id': departmentId,
        if (link != null && link.isNotEmpty) 'link_url': link,
        if (imagePath != null)
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
      });

      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/announcements/$id",
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Update Announcement Error: $e");
      rethrow;
    }
  }

  // ==========================================
  // Student Services (الخدمات والطلبات الطلابية للإدارة)
  // ==========================================
  Future<List<dynamic>?> getStudentServicesRequests({String? type, String? status}) async {
    try {
      final token = await _getToken();
      final Map<String, dynamic> params = {};
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (status != null && status.isNotEmpty) params['status'] = status;

      Response response = await _dio.get(
        "${ApiService().baseUrl}/admin/student-services",
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint("❌ Admin Get Student Services Error: $e");
    }
    return null;
  }

  Future<bool> processStudentServiceRequest({
    required int id,
    required String decision,
    required String notes,
  }) async {
    try {
      final token = await _getToken();
      Response response = await _dio.post(
        "${ApiService().baseUrl}/admin/student-services/$id/process",
        data: {
          'decision': decision,
          'notes': notes,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint("❌ Admin Process Student Service Error: $e");
      return false;
    }
  }
}

