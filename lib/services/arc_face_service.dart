import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// MobileFaceNet Deep Feature Extractor Service.
/// Runs a real on-device TFLite MobileFaceNet model (112x112 RGB input,
/// 192-dimensional embedding output) — see assets/models/NOTICE.md for
/// the model's source and provenance.
class ArcFaceService {
  static const int _modelInputSize = 112;
  static const int _embeddingSize = 192;

  static Interpreter? _interpreter;
  static bool _isLoading = false;

  static Future<Interpreter> _getInterpreter() async {
    if (_interpreter != null) return _interpreter!;
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (_interpreter != null) return _interpreter!;

    _isLoading = true;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobile_face_net.tflite');
      return _interpreter!;
    } finally {
      _isLoading = false;
    }
  }

  /// Extract a MobileFaceNet 192-dimensional deep embedding vector from a detected Face.
  static Future<List<double>> extractArcFaceEmbedding(Face face, String imagePath) async {
    try {
      final File file = File(imagePath);
      if (!await file.exists()) return [];

      final Uint8List bytes = await file.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return [];

      // 1. Correct EXIF Camera Orientation
      img.Image orientedImage = img.bakeOrientation(originalImage);

      // 2. Crop Face region with 20% spatial padding for facial contours
      final box = face.boundingBox;
      final int padX = (box.width * 0.20).toInt();
      final int padY = (box.height * 0.20).toInt();

      final int x = max(0, box.left.toInt() - padX);
      final int y = max(0, box.top.toInt() - padY);
      final int w = min(orientedImage.width - x, box.width.toInt() + padX * 2);
      final int h = min(orientedImage.height - y, box.height.toInt() + padY * 2);

      if (w <= 10 || h <= 10) return [];

      img.Image croppedFace = img.copyCrop(orientedImage, x: x, y: y, width: w, height: h);

      // 3. Roll angle alignment if detected
      if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 2) {
        croppedFace = img.copyRotate(croppedFace, angle: -face.headEulerAngleZ!);
      }

      // 4. Resize to MobileFaceNet input size (112x112 RGB)
      final img.Image resizedFace = img.copyResize(
        croppedFace,
        width: _modelInputSize,
        height: _modelInputSize,
      );

      // 5. Run real MobileFaceNet TFLite inference to get the 192-dim embedding
      final List<double> embedding = await _runInference(resizedFace);
      if (embedding.isEmpty) return [];

      // 6. L2 Unit Vector Normalization (Length = 1.0)
      return _l2Normalize(embedding);
    } catch (e) {
      debugPrint("❌ MobileFaceNet Extraction Error: $e");
      return [];
    }
  }

  static Future<List<double>> _runInference(img.Image face112) async {
    final interpreter = await _getInterpreter();

    // Input tensor: [1, 112, 112, 3] Float32, normalized to (pixel - 128) / 128
    final input = List.generate(
      1,
      (_) => List.generate(
        _modelInputSize,
        (y) => List.generate(_modelInputSize, (x) {
          final pixel = face112.getPixel(x, y);
          return [
            (pixel.r - 128.0) / 128.0,
            (pixel.g - 128.0) / 128.0,
            (pixel.b - 128.0) / 128.0,
          ];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0));

    interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  /// Performs L2 Normalization so vector length = 1.0
  static List<double> _l2Normalize(List<double> vector) {
    if (vector.isEmpty) return [];

    double sumSq = 0.0;
    for (final double v in vector) {
      sumSq += v * v;
    }

    final double norm = sqrt(sumSq);
    if (norm == 0 || norm.isNaN) return vector;

    return vector.map((v) => v / norm).toList();
  }

  /// Calculates Cosine Similarity between two L2-normalized embedding vectors.
  /// Returns a score from 0.0 to 100.0 %.
  static double calculateArcFaceSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.isEmpty || vecB.isEmpty) return 0.0;
    final int len = min(vecA.length, vecB.length);
    if (len == 0) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < len; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    final double denom = sqrt(normA) * sqrt(normB);
    if (denom == 0) return 0.0;

    final double cosSim = dotProduct / denom; // Range [-1.0, 1.0]
    // Map cosine similarity to 0 - 100% scale
    return max(0.0, min(100.0, ((cosSim + 1.0) / 2.0) * 100.0));
  }
}
