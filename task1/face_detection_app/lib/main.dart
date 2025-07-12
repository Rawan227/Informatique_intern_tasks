import 'package:flutter/material.dart';
import 'face_detection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home:FaceDetectionScreen(),
    ),
  );
}
