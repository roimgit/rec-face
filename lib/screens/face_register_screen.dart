import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../services/face_recognition_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  final Employee employee;
  const FaceRegisterScreen({super.key, required this.employee});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _controller;
  late final FaceDetector _detector;
  final List<List<double>> _samples = [];
  bool _isBusy = false;
  String _status = 'Posisikan wajah lurus di tengah bingkai, lalu tekan Ambil Sampel (0/3).';

  @override
  void initState() {
    super.initState();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final ctrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await ctrl.initialize();
    if (!mounted) return;
    setState(() => _controller = ctrl);
  }

  Future<void> _captureSample() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;
    setState(() {
      _isBusy = true;
      _status = 'Menganalisis titik wajah...';
    });

    try {
      final pic = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(inputImage);
      try {
        await File(pic.path).delete();
      } catch (_) {}

      if (faces.isEmpty) {
        setState(() => _status = 'Wajah tidak terdeteksi. Pastikan pencahayaan cukup.');
        return;
      }
      if (faces.length > 1) {
        setState(() => _status = 'Terdeteksi lebih dari 1 wajah. Pastikan hanya 1 orang di kamera.');
        return;
      }

      final vec = FaceRecognitionService.extractFeatureVector(faces.first);
      if (vec == null) {
        setState(() => _status = 'Landmark wajah kurang jelas. Hadapkan wajah lurus ke kamera.');
        return;
      }

      _samples.add(vec);
      if (_samples.length < 3) {
        setState(() => _status = 'Sampel ${_samples.length}/3 tersimpan! Gerakkan kepala sedikit lalu ambil lagi.');
      } else {
        final avgVec = FaceRecognitionService.averageVectors(_samples);
        final updated = Employee(
          id: widget.employee.id,
          nik: widget.employee.nik,
          fullName: widget.employee.fullName,
          position: widget.employee.position,
          departmentId: widget.employee.departmentId,
          shiftId: widget.employee.shiftId,
          phone: widget.employee.phone,
          isActive: widget.employee.isActive,
          faceVector: avgVec,
        );
        await DatabaseHelper.instance.updateEmployee(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wajah ${widget.employee.fullName} berhasil didaftarkan!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _status = 'Gagal memproses kamera: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrasi Wajah: ${widget.employee.fullName}')),
      body: Column(
        children: [
          Expanded(
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      Center(
                        child: Container(
                          width: 240,
                          height: 310,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1D6FE2), width: 3),
                            borderRadius: BorderRadius.circular(140),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                LinearProgressIndicator(value: _samples.length / 3.0),
                const SizedBox(height: 12),
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _captureSample,
                    icon: const Icon(Icons.face_retouching_natural),
                    label: Text(_isBusy ? 'Memproses...' : 'Ambil Sampel Wajah (${_samples.length}/3)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
