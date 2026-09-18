import 'dart:io';

import 'package:camera/camera.dart';
import 'package:document_scanner/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_api_availability/google_api_availability.dart';

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
  String? _cameraError;

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (Platform.isAndroid) {
      final availability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      if (availability != GooglePlayServicesAvailability.success) {
        if (!mounted) return;
        await GoogleApiAvailability.instance.makeGooglePlayServicesAvailable();
        if (!mounted) return;

        final updatedAvailability = await GoogleApiAvailability.instance
            .checkGooglePlayServicesAvailability();
        if (!mounted) return;
        if (updatedAvailability != GooglePlayServicesAvailability.success) {
          setState(() {
            _cameraError =
                'Google Play services are required to use live OCR. Update them and try again.';
          });
          return;
        }
      }
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) throw StateError('No cameras available');

      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await _disposeController(controller);
        return;
      }

      await controller.startImageStream(_processFrame);
      if (!mounted) {
        await _disposeController(controller);
        return;
      }

      setState(() {
        _description = description;
        _camera = controller;
      });
    } catch (_) {
      await _disposeController(controller);
      if (!mounted) return;
      setState(() {
        _cameraError = 'Unable to start the camera. Check camera permissions and try again.';
      });
    }
  }

  Future<void> _disposeController(CameraController? controller) async {
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {
      }
    }
    try {
      await controller.dispose();
    } catch (_) {
    }
  }

  void _retryInit() {
    setState(() => _cameraError = null);
    _init();
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
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_camera!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation =
            (camera.sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (camera.sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (!Platform.isAndroid && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live Camera OCR')),
    body: _cameraError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_cameraError!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _retryInit,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        : _camera == null
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
                      _text.isEmpty ? 'Point the camera at text' : _text,
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
