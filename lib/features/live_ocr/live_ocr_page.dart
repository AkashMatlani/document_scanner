import 'dart:io';

import 'package:camera/camera.dart';
import 'package:document_scanner/providers/app_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LiveOcrPage extends ConsumerStatefulWidget {
  const LiveOcrPage({super.key});

  @override
  ConsumerState<LiveOcrPage> createState() => _LiveOcrPageState();
}

class _LiveOcrPageState extends ConsumerState<LiveOcrPage> {
  CameraController? _camera;
  bool _busy = false;
  String _text = '';
  CameraDescription? _description;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _description = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      _description!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await controller.initialize();
    await controller.startImageStream(_processFrame);
    if (mounted) setState(() => _camera = controller);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_busy || _camera == null || _description == null) return;
    _busy = true;
    try {
      final input = _inputImageFromCameraImage(image);
      if (input != null) {
        final recognized = await ref
            .read(ocrServiceProvider)
            .recognizeInput(input);
        if (mounted && recognized.text.trim().isNotEmpty) {
          setState(() => _text = recognized.text.trim());
        }
      }
    } finally {
      _busy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _description!;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: metadata,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live Camera OCR')),
    body: _camera == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_camera!),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black87,
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: Text(
                      _text.isEmpty ? 'Point the camera at _text' : _text,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
  );

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }
}
