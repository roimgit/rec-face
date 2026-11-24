import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/models.dart';

class FaceMatchResult {
  final Employee? employee;
  final double similarity;

  FaceMatchResult({this.employee, required this.similarity});
}

class FaceRecognitionService {
  static const double matchThreshold = 0.90;

  /// Extract a scale- & translation-invariant geometric feature vector from ML Kit landmarks.
  static List<double>? extractFeatureVector(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;

    if (leftEye == null ||
        rightEye == null ||
        noseBase == null ||
        leftMouth == null ||
        rightMouth == null ||
        bottomMouth == null) {
      return null;
    }

    final interOcular = _dist(leftEye, rightEye);
    if (interOcular < 10.0) return null;

    final box = face.boundingBox;
    final aspectRatio = box.width / max(box.height, 1.0);

    final pts = <Point<int>>[
      leftEye,
      rightEye,
      noseBase,
      leftMouth,
      rightMouth,
      bottomMouth,
      if (leftCheek != null) leftCheek else leftMouth,
      if (rightCheek != null) rightCheek else rightMouth,
    ];

    // Normalized pairwise ratios + bounding aspect ratio
    final vec = <double>[aspectRatio];
    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        vec.add(_dist(pts[i], pts[j]) / interOcular);
      }
    }

    // L2 normalize for stable cosine similarity
    final norm = sqrt(vec.fold<double>(0.0, (sum, v) => sum + v * v));
    if (norm == 0) return null;
    return vec.map((v) => v / norm).toList();
  }

  static List<double> averageVectors(List<List<double>> samples) {
    final len = samples.first.length;
    final avg = List<double>.filled(len, 0.0);
    for (final s in samples) {
      for (int i = 0; i < len; i++) {
        avg[i] += s[i] / samples.length;
      }
    }
    final norm = sqrt(avg.fold<double>(0.0, (sum, v) => sum + v * v));
    return avg.map((v) => v / max(norm, 1e-9)).toList();
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot.clamp(0.0, 1.0);
  }

  static FaceMatchResult findBestMatch(List<double> probe, List<Employee> registered) {
    Employee? best;
    double bestScore = 0.0;
    for (final emp in registered) {
      if (!emp.hasFaceRegistered) continue;
      final score = cosineSimilarity(probe, emp.faceVector!);
      if (score > bestScore) {
        bestScore = score;
        best = emp;
      }
    }
    if (best != null && bestScore >= matchThreshold) {
      return FaceMatchResult(employee: best, similarity: bestScore);
    }
    return FaceMatchResult(employee: null, similarity: bestScore);
  }

  static double _dist(Point<int> a, Point<int> b) {
    final dx = (a.x - b.x).toDouble();
    final dy = (a.y - b.y).toDouble();
    return sqrt(dx * dx + dy * dy);
  }
}
