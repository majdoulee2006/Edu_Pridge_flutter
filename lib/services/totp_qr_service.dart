import 'dart:convert';
import 'package:crypto/crypto.dart';

/// محرك TOTP لتوليد وتدقيق رموز الحضور بدون إنترنت (المرحلة 2)
/// متطابق 100% مع TotpQrService في Laravel
class TotpQrService {
  static const String protocolPrefix = 'edu-bridge://attendance';
  static const int defaultStep = 30; // 30 ثانية لكل دورة رمز
  static const int truncationLength = 20; // 20 خانة Hex = 80 بت

  /// حساب رقم العداد للوقت المحدد بالثواني
  static int calculateCounter(int unixTime, {int step = defaultStep}) {
    return unixTime ~/ step;
  }

  /// توليد رمز HMAC-SHA256 المطابق لخوارزمية السيرفر
  static String generateToken({
    required String secret,
    required String sessionUuid,
    required int counter,
  }) {
    final message = 'edu-bridge-v2|$sessionUuid|$counter';
    final key = utf8.encode(secret);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(message));
    final hexString = digest.toString().toLowerCase();

    return hexString.substring(0, truncationLength);
  }

  /// توليد حمولة QR الكاملة للرمز المتغير
  static String generatePayload({
    required String secret,
    required String sessionUuid,
    required int unixTime,
    bool requireFace = true,
    int step = defaultStep,
  }) {
    final counter = calculateCounter(unixTime, step: step);
    final token = generateToken(
      secret: secret,
      sessionUuid: sessionUuid,
      counter: counter,
    );

    return '$protocolPrefix?v=2&sid=$sessionUuid&c=$counter&t=$token&rf=${requireFace ? 1 : 0}';
  }

  /// تحليل حمولة الـ QR المستخرجة عند المسح
  static Map<String, dynamic>? parsePayload(String payload) {
    final trimmed = payload.trim();
    if (!trimmed.startsWith(protocolPrefix) && !trimmed.contains('v=2&sid=')) {
      return null;
    }

    try {
      final uri = Uri.parse(trimmed);
      final params = uri.queryParameters;
      if (!params.containsKey('v') ||
          !params.containsKey('sid') ||
          !params.containsKey('c') ||
          !params.containsKey('t')) {
        return null;
      }

      return {
        'version': int.tryParse(params['v'] ?? '') ?? 0,
        'sid': params['sid'] ?? '',
        'counter': int.tryParse(params['c'] ?? '') ?? 0,
        'token': params['t'] ?? '',
        'require_face': params.containsKey('rf') ? params['rf'] != '0' : true,
      };
    } catch (_) {
      return null;
    }
  }
}
