import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool isFrontCamera;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 5, 182, 96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final scaleX = size.width / imageSize.height;
    final scaleY = size.height / imageSize.width;

    for (var face in faces) {
      final rect = face.boundingBox;

      final left = isFrontCamera ? imageSize.height - rect.right : rect.left;

      final scaledRect = Rect.fromLTRB(
        left * scaleX,
        rect.top * scaleY,
        (left + rect.width) * scaleX,
        (rect.top + rect.height) * scaleY,
      );

      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
