import 'dart:io';
import 'package:face_detection_app/widgets/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_detection_service.dart';
import '../utils/image_converter.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _cameraController;
  List<Face> _faces = [];
  late CameraDescription _camera;
  late List<CameraDescription> _cameras;
  int _cameraIndex = 0;
  late FaceDetectionService _faceDetectionService;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _faceDetectionService = FaceDetectionService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    if (_cameraIndex == -1) _cameraIndex = 0;
    _camera = _cameras[_cameraIndex];

    _cameraController = CameraController(
      _camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _flipCamera() async {
    try {
      // Mark camera as not ready to prevent UI rendering
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }

      // Stop stream and dispose
      await _cameraController?.stopImageStream();
      await _cameraController?.dispose();

      _cameraController = null;
      _faces.clear();

      // Switch camera index
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      _camera = _cameras[_cameraIndex];

      // Create new controller
      final newController = CameraController(
        _camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await newController.initialize();
      await newController.startImageStream(_processCameraImage);

      // Set new controller only if widget still mounted
      if (mounted) {
        setState(() {
          _cameraController = newController;
          _isCameraInitialized = true;
        });
      } else {
        await newController.dispose(); // Prevent memory leaks
      }
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !_isCameraInitialized) return;
    _isProcessing = true;

    try {
      final inputImage = await ImageConverter.toInputImage(image, _camera);
      if (inputImage != null) {
        final faces = await _faceDetectionService.detectFaces(inputImage);
        if (mounted) {
          setState(() {
            _faces = faces;
          });
        }
      }
    } catch (e) {
      print('Face detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection'),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.flip_camera_android),
          onPressed: _flipCamera,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: (_cameraController != null && _isCameraInitialized)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(
                        _cameraController!,
                        child: FacePaintWidget(
                          faces: _faces,
                          imageSize: _cameraController!.value.previewSize!,
                          isFrontCamera:
                              _camera.lensDirection ==
                              CameraLensDirection.front,
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Faces detected: ${_faces.length}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
