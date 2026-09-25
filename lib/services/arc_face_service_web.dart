import 'dart:math';
import 'package:flutter/foundation.dart';

/// Web Stub for ArcFaceService (TensorFlow Lite is not available in web browsers).
class ArcFaceService {
  /// Web stub: returns empty embedding vector gracefully.
  static Future<List<double>> extractArcFaceEmbedding(dynamic face, String imagePath) async {
    debugPrint("ℹ️ ArcFaceService: Face recognition model is not supported on Web. Returning empty embedding.");
    return [];
  }

  /// Calculates Cosine Similarity between two L2-normalized embedding vectors.
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

    final double cosSim = dotProduct / denom;
    return max(0.0, min(100.0, ((cosSim + 1.0) / 2.0) * 100.0));
  }
}
