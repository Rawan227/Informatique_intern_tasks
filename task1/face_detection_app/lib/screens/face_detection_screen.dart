import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_detection_service.dart';
import '../utils/image_converter.dart';

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _cameraController;
  List<Face> _faces = [];
  late CameraDescription _camera;
  late FaceDetectionService _faceDetectionService;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _faceDetectionService = FaceDetectionService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      _camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_processCameraImage);

    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = ImageConverter.toInputImage(
        image,
        _camera,
        _cameraController!.value.deviceOrientation,
      );
      if (inputImage != null) {
        final faces = await _faceDetectionService.detectFaces(inputImage);
        setState(() => _faces = faces);
      }
    } catch (e) {
      print('Face detection error: $e');
    }

    _isDetecting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: CameraPreview(_cameraController!)),
          const SizedBox(height: 25),
          Center(
            child: Text(
              'Faces detected: ${_faces.length}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          if (_faces.isNotEmpty)
            Center(
              child: const Text(
                'What a pretty face',
                style: TextStyle(fontSize: 20, color: Colors.green),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
