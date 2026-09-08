import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordService {
  static final AudioRecordService _instance = AudioRecordService._internal();
  factory AudioRecordService() => _instance;
  AudioRecordService._internal();

  AudioRecorder? _audioRecorder;
  String? _currentRecordingPath;

  AudioRecorder get recorder {
    _audioRecorder ??= AudioRecorder();
    return _audioRecorder!;
  }

  /// فحص وطلب إذن الميكروفون
  Future<bool> hasPermission() async {
    try {
      return await recorder.hasPermission();
    } catch (e) {
      debugPrint("❌ Permission Check Error: $e");
      return false;
    }
  }

  /// بدء التسجيل الصوتي الفعلي
  Future<bool> startRecording() async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        debugPrint("❌ Microphone permission denied.");
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = "voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
      final filePath = "${tempDir.path}/$fileName";
      _currentRecordingPath = filePath;

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await recorder.start(config, path: filePath);
      debugPrint("🎙️ Audio recording started at: $filePath");
      return true;
    } catch (e) {
      debugPrint("❌ Error starting audio recording: $e");
      return false;
    }
  }

  /// إيقاف التسجيل وإرجاع مسار الملف الصوتي الفعلي
  Future<String?> stopRecording() async {
    try {
      final isRec = await recorder.isRecording();
      if (!isRec) return null;

      final path = await recorder.stop();
      final resolvedPath = path ?? _currentRecordingPath;

      if (resolvedPath != null && File(resolvedPath).existsSync()) {
        final size = await File(resolvedPath).length();
        debugPrint("✅ Audio recording saved ($size bytes): $resolvedPath");
        return resolvedPath;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error stopping audio recording: $e");
      return null;
    } finally {
      _currentRecordingPath = null;
    }
  }

  /// إلغاء التسجيل وحذف الملف المؤقت إن وجد
  Future<void> cancelRecording() async {
    try {
      if (await recorder.isRecording()) {
        await recorder.stop();
      }
      if (_currentRecordingPath != null) {
        final f = File(_currentRecordingPath!);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (e) {
      debugPrint("❌ Error cancelling recording: $e");
    } finally {
      _currentRecordingPath = null;
    }
  }

  /// التخلص من الموارد
  void dispose() {
    _audioRecorder?.dispose();
    _audioRecorder = null;
  }
}
