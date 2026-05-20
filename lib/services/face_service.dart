import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: false,
      enableClassification: true, // eyes open, smiling prob
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.25,
    ),
  );

  static Future<FaceCheckResult> checkFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceCheckResult(
          success: false,
          message: 'No face detected. Please look directly at the camera.',
        );
      }

      if (faces.length > 1) {
        return FaceCheckResult(
          success: false,
          message: 'Multiple faces detected. Only one person allowed.',
        );
      }

      final face = faces.first;

      // Liveness check — eyes must be open
      final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 0;

      if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
        return FaceCheckResult(
          success: false,
          message: 'Eyes not detected as open. Please keep your eyes open.',
        );
      }

      // Head pose check — must be looking roughly forward
      final headY = face.headEulerAngleY ?? 0;
      final headZ = face.headEulerAngleZ ?? 0;

      if (headY.abs() > 30 || headZ.abs() > 30) {
        return FaceCheckResult(
          success: false,
          message: 'Please look directly at the camera.',
        );
      }

      return FaceCheckResult(
        success: true,
        message: 'Face verified successfully.',
        faceBox: face.boundingBox,
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
      );
    } catch (e) {
      return FaceCheckResult(
        success: false,
        message: 'Face detection error: ${e.toString()}',
      );
    }
  }

  static void dispose() {
    _detector.close();
  }
}

class FaceCheckResult {
  final bool success;
  final String message;
  final dynamic faceBox;
  final double leftEyeOpen;
  final double rightEyeOpen;

  FaceCheckResult({
    required this.success,
    required this.message,
    this.faceBox,
    this.leftEyeOpen = 0,
    this.rightEyeOpen = 0,
  });
}
