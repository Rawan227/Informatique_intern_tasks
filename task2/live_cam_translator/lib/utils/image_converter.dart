import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class ImageConverter {

  static Future<int> getDeviceOrientation() async {
    final orientation = await NativeDeviceOrientationCommunicator().orientation(
      useSensor: true,
    );

    switch (orientation) {
      case NativeDeviceOrientation.portraitUp:
        return 0;
      case NativeDeviceOrientation.portraitDown:
        return 180;
      case NativeDeviceOrientation.landscapeLeft:
        return 90;
      case NativeDeviceOrientation.landscapeRight:
        return 270;
      default:
        return 0;
    }
  }

  static Future<InputImage?> toInputImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final sensorOrientation = camera.sensorOrientation;
    int orientation = await getDeviceOrientation();
    int? rotationValue;
    if (Platform.isAndroid) {
      int? rotationCompensation = orientation;
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotationValue = rotationCompensation;
    } else {
      rotationValue = sensorOrientation;
    }

    final rotation = InputImageRotationValue.fromRawValue(rotationValue);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (rotation == null || format == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}
