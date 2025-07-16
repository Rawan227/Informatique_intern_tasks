import 'package:flutter/material.dart';
import 'screens/camera_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: CameraPreviewScreen()),
  );
}
