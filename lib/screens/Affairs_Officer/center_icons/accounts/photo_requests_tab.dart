import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class PhotoRequestsTab extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color subColor;
  final bool isDark;

  const PhotoRequestsTab({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subColor,
    required this.isDark,
  });

  @override
  State<PhotoRequestsTab> createState() => _PhotoRequestsTabState();
}

class _PhotoRequestsTabState extends State<PhotoRequestsTab> {
  final Dio _dio = Dio();
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final res = await _dio.get(
        '${_api.baseUrl}/affairs/photo-change-requests',
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(res.data['data']);
        });
      }
    } catch (e) {
      debugPrint('Load photo requests error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(int id, String action) async {
    try {
      final token = await _getToken();
      await _dio.post(
        '${_api.baseUrl}/affairs/photo-change-requests/$id/$action',
        options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            action == 'approve' ? 'تمت الموافقة على تغيير الصورة ✓' : 'تم رفض الطلب',
            style: const TextStyle(fontFamily: 'Noto Sans Arabic'),
          ),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
        ));
        _load();
      }
    } catch (e) {
      debugPrint('Respond error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC00)));
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 60, color: widget.subColor),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات تغيير صورة',
              style: TextStyle(color: widget.subColor, fontSize: 16, fontFamily: 'Noto Sans Arabic'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
      itemCount: _requests.length,
      itemBuilder: (_, i) => _buildRequestCard(_requests[i]),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final oldUrl = ApiService.fixMediaUrl(req['old_photo_url'] as String?);
    final newUrl = ApiService.fixMediaUrl(req['new_photo_url'] as String?);
    final id = req['id'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم الطالب
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, color: Color(0xFFFFCC00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req['full_name'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor,
                      fontFamily: 'Noto Sans Arabic',
                    ),
                  ),
                ),
                Text(
                  req['created_at']?.toString().substring(0, 10) ?? '',
                  style: TextStyle(fontSize: 11, color: widget.subColor, fontFamily: 'Noto Sans Arabic'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // الصور جنب بعض
            Row(
              children: [
                Expanded(child: _photoBox('الصورة الحالية', oldUrl, Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFCC00), size: 28),
                const SizedBox(width: 12),
                Expanded(child: _photoBox('الصورة الجديدة', newUrl, const Color(0xFFFFCC00))),
              ],
            ),
            const SizedBox(height: 14),

            // أزرار الموافقة والرفض
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respond(id, 'reject'),
                    icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                    label: const Text('رفض', style: TextStyle(color: Colors.red, fontFamily: 'Noto Sans Arabic')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respond(id, 'approve'),
                    icon: const Icon(Icons.check_rounded, color: Colors.black, size: 18),
                    label: const Text('موافقة', style: TextStyle(color: Colors.black, fontFamily: 'Noto Sans Arabic')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoBox(String label, String? url, Color borderColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: widget.subColor, fontFamily: 'Noto Sans Arabic')),
        const SizedBox(height: 6),
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
            color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (ctx, e, st) => Icon(Icons.person_outline, color: widget.subColor, size: 40),
                  )
                : Icon(Icons.person_outline, color: widget.subColor, size: 40),
          ),
        ),
      ],
    );
  }
}
