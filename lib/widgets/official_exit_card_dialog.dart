import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';

class OfficialExitCardDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? notificationMessage;

  const OfficialExitCardDialog({
    super.key,
    required this.data,
    this.notificationMessage,
  });

  static Future<void> show(BuildContext context, Map<String, dynamic> data, {String? notificationMessage}) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => OfficialExitCardDialog(data: data, notificationMessage: notificationMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF141417) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF1E1E24) : const Color(0xFFF4F4F6);
    final innerBoxColor = isDark ? const Color(0xFF18181D) : const Color(0xFFFAFAFC);
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final String studentName = data['student_name'] ?? data['name'] ?? 'محمود غنام';
    final String studentCode = data['student_code'] ?? data['university_id'] ?? '202601';
    final String department  = data['department'] ?? 'نظم معلومات';
    final String permitNumber= data['permit_number'] ?? "EX-${(data['id'] ?? 1).toString().padLeft(5, '0')}#";
    final String date        = data['formatted_date'] ?? data['date'] ?? '2026-08-15';
    final String reasonText  = (data['reason'] != null && data['reason'].toString().isNotEmpty)
        ? "[${data['type'] ?? 'إذن يومي'}] - ${data['reason']}"
        : "[${data['type'] ?? 'إذن يومي'}]";
    final String? avatarPath = ApiService.fixMediaUrl(data['avatar'] as String?);

    final bool isApproved = data['status'] == 'approved' || data['affairs_approved'] == true;
    final bool parentApproved = data['parent_approved'] ?? true;
    final bool hodApproved = data['hod_approved'] ?? true;
    final bool affairsApproved = isApproved;

    final String qrContent = "EDU-BRIDGE-VERIFY:${data['id'] ?? 1}:$studentCode:$date";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: bgColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: const Color(0xFFFFCC00).withAlpha(140), width: 1.5),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: subTextColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFCC00).withAlpha(30),
                              border: Border.all(color: const Color(0xFFFFCC00), width: 2),
                            ),
                            child: const Icon(Icons.school_rounded, color: Color(0xFFFFCC00), size: 26),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                              children: const [
                                TextSpan(text: 'Edu-Bridge ', style: TextStyle(color: Color(0xFFFFCC00))),
                                TextSpan(text: '| بطاقة خروج رسمية'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'نظام التراخيص والتصاريح الأكاديمية',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Status Banner (Yellow Capsule)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isApproved ? const Color(0xFFFFCC00) : Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isApproved ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isApproved
                                    ? 'تصريح خروج معتمد نهائياً - يُسمح بالمغادرة ✓'
                                    : (data['status_text'] ?? 'طلب الإذن قيد المراجعة الإدارية'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFCC00), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFFFFCC00).withAlpha(40),
                                backgroundImage: avatarPath != null ? NetworkImage(avatarPath) : null,
                                child: avatarPath == null
                                    ? const Icon(Icons.person_rounded, size: 28, color: Color(0xFFFFCC00))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'الرقم الجامعي $studentCode',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                  Text(
                                    'القسم الأكاديمي $department',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Details Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: innerBoxColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('تاريخ الإذن:', date, Icons.calendar_today_rounded, textColor, subTextColor),
                            const Divider(height: 16, thickness: 0.5),
                            _buildInfoRow('سبب الخروج:', reasonText, Icons.sticky_note_2_outlined, textColor, subTextColor),
                            const Divider(height: 16, thickness: 0.5),
                            _buildInfoRow('رقم التصريح:', permitNumber, Icons.tag_rounded, textColor, subTextColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Approval Chain Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: innerBoxColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: Color(0xFFFFCC00), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'تسلسل الاعتمادات الرسمية:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildApprovalStep('موافقة ولي الأمر:', parentApproved, isDark),
                            const SizedBox(height: 6),
                            _buildApprovalStep('موافقة رئيس القسم:', hodApproved, isDark),
                            const SizedBox(height: 6),
                            _buildApprovalStep('اعتماد شؤون الطلاب:', affairsApproved, isDark, isFinal: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Security QR Code Section
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10),
                              ],
                            ),
                            child: QrImageView(
                              data: qrContent,
                              version: QrVersions.auto,
                              size: 90,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'رمز التحقق الأمني المعتمد لحراس البوابة الإلكترونية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جاري تجهيز بطاقة الخروج للطباعة...', style: TextStyle(fontFamily: 'Cairo')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('طباعة البطاقة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFFCC00)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalStep(String label, bool isDone, bool isDark, {bool isFinal = false}) {
    final color = isDone ? const Color(0xFF10B981) : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    final text = isDone
        ? (isFinal ? 'تمت الموافقة وتثبيت الخروج' : 'تمت بنجاح')
        : 'قيد الانتظار';

    return Row(
      children: [
        Icon(
          isDone ? Icons.check_rounded : Icons.hourglass_top_rounded,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
        ),
        Text(
          text,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
