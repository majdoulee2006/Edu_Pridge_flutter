import 'dart:io';

class NetworkHelper {
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return true; // Fallback to allow requests in local networks
    }
  }
}
