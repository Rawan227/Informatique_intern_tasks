import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePaintWidget extends StatelessWidget {
  final List<Face> faces;
  final Size imageSize; 
  final bool isFrontCamera;
  const FacePaintWidget({
    super.key,
    required this.faces,
    required this.imageSize,
    required this.isFrontCamera,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: widgetSize,
          painter: FacePainter(
            faces: faces,
            imageSize: imageSize,
            widgetSize: widgetSize,
            isFrontCamera: isFrontCamera,
          ),
        );
      },
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize; 
  final Size widgetSize;
  final bool isFrontCamera;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.widgetSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final face in faces) {
      final rect = _scaleRect(face.boundingBox);
      canvas.drawRect(rect, paint);
    }
  }

  Rect _scaleRect(Rect boundingBox) {
    double scaleX;
    double scaleY;

    // Android: camera image is rotated 90 degrees → swap width & height
    final isPortraitMode = widgetSize.height > widgetSize.width;
    final imageRotated = Platform.isAndroid && isPortraitMode;

    final double originalImageWidth = imageRotated
        ? imageSize.height
        : imageSize.width;
    final double originalImageHeight = imageRotated
        ? imageSize.width
        : imageSize.height;

    scaleX = widgetSize.width / originalImageWidth;
    scaleY = widgetSize.height / originalImageHeight;

    double left = boundingBox.left;
    double top = boundingBox.top;
    double right = boundingBox.right;
    double bottom = boundingBox.bottom;

    // Flip horizontally if using front camera
    if (isFrontCamera) {
      left = originalImageWidth - boundingBox.right;
      right = originalImageWidth - boundingBox.left;
    }

    // Apply scaling
    return Rect.fromLTRB(
      left * scaleX,
      top * scaleY,
      right * scaleX,
      bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) =>
      oldDelegate.faces != faces ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.widgetSize != widgetSize ||
      oldDelegate.isFrontCamera != isFrontCamera;
}
