import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationPolling {
  static Timer? _timer;
  static final ValueNotifier<int> unreadCount = ValueNotifier(0);
  static final ValueNotifier<Map<String, dynamic>?> latestNew = ValueNotifier(null);

  static void start(String apiPath) {
    _timer?.cancel();
    _fetch(apiPath);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch(apiPath));
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // مفتاح خاص بكل مستخدم
  static Future<String> _shownKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString() ?? 'guest';
    return 'notif_last_shown_id_$userId';
  }

  static Future<void> _fetch(String apiPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;

      final res = await Dio().get(
        "${ApiService().baseUrl}$apiPath",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200) return;

      // جمع كل الإشعارات
      List raw = [];
      final data = res.data;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        if (data['data'] is List) {
          raw = data['data'];
        } else if (data['data'] is Map) {
          final inner = data['data'] as Map;
          if (inner['all'] is List) {
            raw = inner['all'] as List;
          } else {
            raw = [
              ...(inner['academic']       as List? ?? []),
              ...(inner['administrative'] as List? ?? []),
            ];
          }
        } else if (data['academic'] is List) {
          raw = [
            ...(data['academic']       as List),
            ...(data['administrative'] as List? ?? []),
          ];
        }
      }

      // الإشعارات غير المقروءة
      final unread = raw.where((n) {
        final r = n['is_read'];
        return r == false || r == 0;
      }).toList();

      unreadCount.value = unread.length;

      if (unread.isEmpty) return;

      // أعلى ID بين الإشعارات غير المقروءة
      final maxId = unread
          .map((n) => (n['id'] as num?)?.toInt() ?? 0)
          .reduce(max);

      final key = await _shownKey();
      final lastShownId = prefs.getInt(key) ?? 0;

      // فقط إذا وصل إشعار بـ ID أحدث → اعرضه
      if (maxId > lastShownId) {
        final newest = unread.reduce((a, b) {
          final idA = (a['id'] as num?)?.toInt() ?? 0;
          final idB = (b['id'] as num?)?.toInt() ?? 0;
          return idA >= idB ? a : b;
        });
        latestNew.value = Map<String, dynamic>.from(newest as Map);
        await prefs.setInt(key, maxId);
      }
    } catch (_) {}
  }

  // مسح عند تسجيل الخروج
  static Future<void> clearLastShownId() async {
    final key = await _shownKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
