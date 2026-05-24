import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationPolling {
  static Timer? _timer;
  static int _lastKnownCount = -1;
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

      List raw = [];
      final data = res.data;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        if (data['data'] is List) raw = data['data'];
        else if (data['academic'] is List) {
          raw = [...(data['academic'] as List), ...(data['administrative'] as List? ?? [])];
        }
      }

      final unread = raw.where((n) {
        final r = n['is_read'];
        return r == false || r == 0;
      }).toList();

      final count = unread.length;
      unreadCount.value = count;

      if (_lastKnownCount >= 0 && count > _lastKnownCount && unread.isNotEmpty) {
        latestNew.value = Map<String, dynamic>.from(unread.first as Map);
      }
      _lastKnownCount = count;
    } catch (_) {}
  }
}
