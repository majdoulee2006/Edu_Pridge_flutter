import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:edu_pridge_flutter/services/api_service.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gradeYellow = Color(0xFFFFCC00);

class GradeEntriesScreen extends StatefulWidget {
  final dynamic event;
  const GradeEntriesScreen({super.key, required this.event});

  @override
  State<GradeEntriesScreen> createState() => _GradeEntriesScreenState();
}

class _GradeEntriesScreenState extends State<GradeEntriesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _entries = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _noteControllers = {};
  String _teacherName = '';

  double get _maxScore {
    final v = widget.event['max_score'];
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 100.0;
  }
  double get _passMark => _maxScore / 2;

  // الحد الأعلى المسموح به حسب نوع التقييم
  double get _allowedMax {
    final type = widget.event['type'] as String? ?? '';
    if (type == 'oral' || type == 'quiz') return 25.0;
    if (type == 'exam') return 50.0;
    return _maxScore;
  }

  String? _validateScore(String text) {
    if (text.trim().isEmpty) return null;
    final v = double.tryParse(text.trim());
    if (v == null) return 'قيمة غير صالحة';
    if (v < 0) return 'لا يمكن إدخال علامة سالبة';
    if (v > _allowedMax) return 'الحد الأعلى هو ${_allowedMax.toStringAsFixed(0)}';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fetchEntries();
    _loadTeacherName();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    for (final c in _noteControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _teacherName = prefs.getString('user_name') ?? prefs.getString('full_name') ?? '');
  }

  Future<void> _fetchEntries() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id = widget.event['id'];
      final res = await Dio().get(
        "${ApiService().baseUrl}/teacher/grades/events/$id/entries",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final entries = res.data['entries'] as List;
        setState(() {
          _entries = entries;
          for (final e in entries) {
            final sid = e['student_id'] as int;
            final score = e['score'];
            _controllers[sid] = TextEditingController(
              text: score != null ? score.toString() : '',
            );
            _noteControllers[sid] = TextEditingController(
              text: e['notes'] as String? ?? '',
            );
          }
        });
      }
    } catch (e) {
      debugPrint('fetchEntries error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isFail(int sid) {
    final text = _controllers[sid]?.text.trim() ?? '';
    final score = double.tryParse(text);
    if (score == null) return false;
    return score < _passMark;
  }

  Future<void> _saveAll() async {
    // تحقق من صحة جميع العلامات قبل الحفظ
    for (final e in _entries) {
      final sid = e['student_id'] as int;
      final text = _controllers[sid]?.text.trim() ?? '';
      final err = _validateScore(text);
      if (err != null) {
        final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name: $err'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final id = widget.event['id'];

      final entries = _entries.map((e) {
        final sid = e['student_id'] as int;
        final scoreText = _controllers[sid]?.text.trim() ?? '';
        final note = _noteControllers[sid]?.text.trim() ?? '';
        return {
          'student_id': sid,
          'score': scoreText.isEmpty ? null : double.tryParse(scoreText),
          'notes': note.isEmpty ? null : note,
        };
      }).toList();

      final res = await Dio().post(
        "${ApiService().baseUrl}/teacher/grades/events/$id/entries",
        data: {'entries': entries},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        if (res.statusCode == 200 && res.data['success'] == true) {
          setState(() {}); // لتحديث الألوان
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ العلامات'), backgroundColor: Colors.green),
          );
          await _fetchEntries();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════
  // إحصائيات
  // ═══════════════════════════════════════════════════

  Map<String, dynamic> _calcStats() {
    final scores = _entries
        .map((e) {
          final sid = e['student_id'] as int;
          return double.tryParse(_controllers[sid]?.text.trim() ?? '');
        })
        .whereType<double>()
        .toList();

    if (scores.isEmpty) return {'total': _entries.length, 'graded': 0};

    final passed = scores.where((s) => s >= _passMark).length;
    final failed = scores.length - passed;
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final highest = scores.reduce(math.max);
    final lowest = scores.reduce(math.min);

    return {
      'total': _entries.length,
      'graded': scores.length,
      'passed': passed,
      'failed': failed,
      'avg': avg,
      'highest': highest,
      'lowest': lowest,
      'passRate': scores.isEmpty ? 0.0 : (passed / scores.length * 100),
      'failRate': scores.isEmpty ? 0.0 : (failed / scores.length * 100),
    };
  }

  // ═══════════════════════════════════════════════════
  // تصدير Excel
  // ═══════════════════════════════════════════════════

  Future<Uint8List> _buildExcelBytes() async {
    final excel = Excel.createExcel();
    final sheet = excel['كشف العلامات'];

    final title = widget.event['title'] ?? '';
    final courseTitle = widget.event['course_title'] ?? '';
    final date = widget.event['date'] ?? '';
    final type = widget.event['type'] == 'exam' ? 'امتحان' : widget.event['type'] == 'oral' ? 'شفهي' : 'مذاكرة';
    final stats = _calcStats();

    // رأس الملف
    sheet.appendRow([TextCellValue('الدورة/المادة:'), TextCellValue(courseTitle)]);
    sheet.appendRow([TextCellValue('نوع التقييم:'), TextCellValue('$type — $title')]);
    sheet.appendRow([TextCellValue('الأستاذ:'), TextCellValue(_teacherName)]);
    sheet.appendRow([TextCellValue('التاريخ:'), TextCellValue(date)]);
    sheet.appendRow([TextCellValue('العلامة القصوى:'), TextCellValue(_maxScore.toString())]);
    sheet.appendRow([TextCellValue('علامة النجاح:'), TextCellValue(_passMark.toString())]);
    sheet.appendRow([TextCellValue('')]);

    // رأس الجدول
    sheet.appendRow([
      TextCellValue('#'),
      TextCellValue('الرقم الجامعي'),
      TextCellValue('اسم الطالب'),
      TextCellValue('العلامة'),
      TextCellValue('من'),
      TextCellValue('النتيجة'),
      TextCellValue('ملاحظة'),
    ]);

    // بيانات الطلاب
    int i = 1;
    for (final e in _entries) {
      final sid = e['student_id'] as int;
      final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';
      final uid = e['university_id'] ?? '';
      final scoreText = _controllers[sid]?.text.trim() ?? '';
      final score = double.tryParse(scoreText);
      final result = score == null ? '—' : (score >= _passMark ? 'ناجح' : 'راسب');
      final note = _noteControllers[sid]?.text.trim() ?? '';

      sheet.appendRow([
        IntCellValue(i++),
        TextCellValue(uid),
        TextCellValue(name),
        TextCellValue(scoreText.isEmpty ? '—' : scoreText),
        TextCellValue(_maxScore.toString()),
        TextCellValue(result),
        TextCellValue(note),
      ]);
    }

    // إحصائيات
    if (stats['graded'] > 0) {
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([TextCellValue('=== الإحصائيات ===')]);
      sheet.appendRow([TextCellValue('إجمالي الطلاب:'), IntCellValue(stats['total'])]);
      sheet.appendRow([TextCellValue('المصنّفون:'), IntCellValue(stats['graded'])]);
      sheet.appendRow([TextCellValue('الناجحون:'), IntCellValue(stats['passed'])]);
      sheet.appendRow([TextCellValue('الراسبون:'), IntCellValue(stats['failed'])]);
      sheet.appendRow([TextCellValue('نسبة النجاح:'), TextCellValue('${stats['passRate'].toStringAsFixed(1)}%')]);
      sheet.appendRow([TextCellValue('نسبة الرسوب:'), TextCellValue('${stats['failRate'].toStringAsFixed(1)}%')]);
      sheet.appendRow([TextCellValue('المعدل:'), TextCellValue(stats['avg'].toStringAsFixed(2))]);
      sheet.appendRow([TextCellValue('الأعلى:'), TextCellValue(stats['highest'].toString())]);
      sheet.appendRow([TextCellValue('الأدنى:'), TextCellValue(stats['lowest'].toString())]);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  Future<void> _exportExcel({bool share = false}) async {
    try {
      final bytes = await _buildExcelBytes();
      final title = (widget.event['title'] ?? '').toString().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'grades_$title.xlsx';

      if (kIsWeb) {
        // على Web: نستخدم FilePicker لتحميل الملف مباشرة
        await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ كشف العلامات (Excel)',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          bytes: bytes,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ ✓'), backgroundColor: Colors.green));
      } else {
        // على موبايل: احفظ مؤقتاً ثم Share
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'كشف العلامات — ${widget.event['title']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // تصدير PDF احترافي
  // ═══════════════════════════════════════════════════

  Future<Uint8List> _buildPdfBytes() async {
    // تحميل خط عربي
    final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final boldData    = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final arabicFont     = pw.Font.ttf(regularData);
    final arabicFontBold = pw.Font.ttf(boldData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: arabicFont,
        bold: arabicFontBold,
      ),
    );
    final title = widget.event['title'] ?? '';
    final courseTitle = widget.event['course_title'] ?? '';
    final date = widget.event['date'] ?? '';
    final type = widget.event['type'] == 'exam' ? 'امتحان' : widget.event['type'] == 'oral' ? 'شفهي' : 'مذاكرة';
    final stats = _calcStats();

    final graded = stats['graded'] as int;
    final passed = graded > 0 ? stats['passed'] as int : 0;
    final failed = graded > 0 ? stats['failed'] as int : 0;
    final avg = graded > 0 ? (stats['avg'] as double) : 0.0;
    final highest = graded > 0 ? (stats['highest'] as double) : 0.0;
    final lowest = graded > 0 ? (stats['lowest'] as double) : 0.0;
    final passRate = graded > 0 ? (stats['passRate'] as double) : 0.0;
    final failRate = graded > 0 ? (stats['failRate'] as double) : 0.0;

    // ألوان
    const primaryColor = PdfColor.fromInt(0xFF1A237E);
    const accentColor = PdfColor.fromInt(0xFFFFCC00);
    const passColor = PdfColor.fromInt(0xFF2E7D32);
    const failColor = PdfColor.fromInt(0xFFC62828);
    const lightGrey = PdfColor.fromInt(0xFFF5F5F5);
    const midGrey = PdfColor.fromInt(0xFF9E9E9E);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // رأس الصفحة
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('كشف العلامات',
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('$type — $title',
                          style: const pw.TextStyle(fontSize: 13, color: accentColor)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('المادة: $courseTitle',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300)),
                      pw.Text('الأستاذ: $_teacherName',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300)),
                      pw.Text('التاريخ: $date',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (ctx) => [
          // ── إحصائيات سريعة ──
          if (graded > 0) ...[
            pw.Row(
              children: [
                _statBox('إجمالي الطلاب', '${stats['total']}', PdfColors.blueGrey700),
                pw.SizedBox(width: 8),
                _statBox('ناجح', '$passed', passColor),
                pw.SizedBox(width: 8),
                _statBox('راسب', '$failed', failColor),
                pw.SizedBox(width: 8),
                _statBox('المعدل', avg.toStringAsFixed(1), primaryColor),
                pw.SizedBox(width: 8),
                _statBox('الأعلى', highest.toStringAsFixed(0), passColor),
                pw.SizedBox(width: 8),
                _statBox('الأدنى', lowest.toStringAsFixed(0), failColor),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── رسم بياني شريطي للنجاح/الرسوب ──
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('توزيع النتائج',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 10),
                  // شريط النجاح
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 60,
                        child: pw.Text('ناجح', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Stack(
                          children: [
                            pw.Container(height: 16, color: PdfColors.grey300),
                            pw.Container(
                              height: 16,
                              width: (passRate / 100) * 400,
                              color: passColor,
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('${passRate.toStringAsFixed(1)}%',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: passColor)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  // شريط الرسوب
                  pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 60,
                        child: pw.Text('راسب', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Stack(
                          children: [
                            pw.Container(height: 16, color: PdfColors.grey300),
                            pw.Container(
                              height: 16,
                              width: (failRate / 100) * 400,
                              color: failColor,
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('${failRate.toStringAsFixed(1)}%',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: failColor)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── جدول الطلاب ──
          pw.Text('قائمة الطلاب والعلامات',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(44),
              4: const pw.FixedColumnWidth(36),
              5: const pw.FixedColumnWidth(44),
              6: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: primaryColor),
                children: [
                  _th('#'),
                  _th('الرقم الجامعي'),
                  _th('اسم الطالب'),
                  _th('العلامة'),
                  _th('من'),
                  _th('النتيجة'),
                  _th('ملاحظة'),
                ],
              ),
              ..._entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final sid = e['student_id'] as int;
                final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';
                final uid = e['university_id'] ?? '';
                final scoreText = _controllers[sid]?.text.trim() ?? '';
                final score = double.tryParse(scoreText);
                final isPassed = score != null && score >= _passMark;
                final isFailed = score != null && score < _passMark;
                final note = _noteControllers[sid]?.text.trim() ?? '';
                final rowColor = idx.isEven ? PdfColors.white : lightGrey;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _td('${idx + 1}', align: pw.TextAlign.center),
                    _td(uid, align: pw.TextAlign.center),
                    _td(name),
                    _td(
                      scoreText.isEmpty ? '—' : scoreText,
                      align: pw.TextAlign.center,
                      color: isFailed ? failColor : (isPassed ? passColor : PdfColors.black),
                      bold: true,
                    ),
                    _td(_maxScore.toStringAsFixed(0), align: pw.TextAlign.center),
                    _tdResult(score == null ? '—' : (isPassed ? 'ناجح' : 'راسب'), isPassed, isFailed),
                    _td(note.isEmpty ? '—' : note),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 24),

          // ── ملاحظة ──
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: accentColor, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'علامة النجاح: ${_passMark.toStringAsFixed(0)} / ${_maxScore.toStringAsFixed(0)}  |  '
              'تم إنشاء هذا التقرير بواسطة نظام Edu Bridge',
              style: const pw.TextStyle(fontSize: 9, color: midGrey),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Text(value,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey300)),
          ],
        ),
      ),
    );
  }

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: pw.Text(text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            textAlign: pw.TextAlign.center),
      );

  pw.Widget _td(String text,
      {pw.TextAlign align = pw.TextAlign.right, PdfColor? color, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9,
                color: color ?? PdfColors.black,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
            textAlign: align),
      );

  pw.Widget _tdResult(String text, bool isPassed, bool isFailed) {
    final color = isPassed
        ? const PdfColor.fromInt(0xFF2E7D32)
        : isFailed
            ? const PdfColor.fromInt(0xFFC62828)
            : PdfColors.grey600;
    final bg = isPassed
        ? const PdfColor.fromInt(0xFFE8F5E9)
        : isFailed
            ? const PdfColor.fromInt(0xFFFFEBEE)
            : PdfColors.white;

    return pw.Container(
      margin: const pw.EdgeInsets.all(3),
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color),
          textAlign: pw.TextAlign.center),
    );
  }

  Future<void> _exportPdf({bool share = false}) async {
    try {
      final bytes = await _buildPdfBytes();
      final title = (widget.event['title'] ?? '').toString().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final fileName = 'grades_$title.pdf';

      if (kIsWeb) {
        await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ كشف العلامات (PDF)',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: bytes,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ ✓'), backgroundColor: Colors.green));
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'كشف العلامات — ${widget.event['title']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final type = widget.event['type'] == 'exam' ? 'امتحان' : widget.event['type'] == 'oral' ? 'شفهي' : 'مذاكرة';
    final typeColor = widget.event['type'] == 'exam' ? Colors.orange : widget.event['type'] == 'oral' ? Colors.purple : Colors.blue;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(type,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor)),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.event['title'] ?? '',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.event['course_title'] ?? ''}  •  ${widget.event['date'] ?? ''}  •  من $_maxScore',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _gradeYellow))
            : _entries.isEmpty
                ? Center(child: Text('لا يوجد طلاب مسجلون', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _entries.length,
                    itemBuilder: (ctx, i) {
                      final e = _entries[i];
                      final sid = e['student_id'] as int;
                      final name = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}';
                      final uid = e['university_id'] ?? '';
                      final fail = _isFail(sid);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: fail
                              ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: fail ? Colors.red.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                            color: fail ? Colors.red : Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                                      Text(uid, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                // حقل العلامة
                                Builder(builder: (ctx) {
                                  final err = _validateScore(_controllers[sid]?.text ?? '');
                                  final hasErr = err != null;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 70,
                                        child: TextField(
                                          controller: _controllers[sid],
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16,
                                            color: hasErr ? Colors.red : (_isFail(sid) ? Colors.red : Colors.green.shade700),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            hintText: '—',
                                            hintStyle: const TextStyle(color: Colors.grey),
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: hasErr ? Colors.red : _gradeYellow, width: 2),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: hasErr ? Colors.red : Colors.grey.shade300),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (hasErr)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Text(err, style: const TextStyle(color: Colors.red, fontSize: 9), textAlign: TextAlign.center),
                                        ),
                                    ],
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text('/ ${_allowedMax.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextField(
                                controller: _noteControllers[sid],
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'ملاحظة...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: _gradeYellow, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                // Excel
                Expanded(
                  child: _exportBtn(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    color: const Color(0xFF1D6F42),
                    onSave: () => _exportExcel(),
                    onShare: () => _exportExcel(share: true),
                  ),
                ),
                const SizedBox(width: 10),
                // PDF
                Expanded(
                  child: _exportBtn(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    color: Colors.red.shade700,
                    onSave: () => _exportPdf(),
                    onShare: () => _exportPdf(share: true),
                  ),
                ),
                const SizedBox(width: 10),
                // حفظ
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gradeYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _saveAll,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _exportBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onSave,
    required VoidCallback onShare,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onSave,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 36, color: color.withValues(alpha: 0.3)),
          InkWell(
            onTap: onShare,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(13),
              bottomLeft: Radius.circular(13),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Icon(Icons.share_outlined, color: color, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
