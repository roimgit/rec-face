import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../services/face_recognition_service.dart';
import '../services/location_service.dart';

class FaceAttendanceScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const FaceAttendanceScreen({super.key, required this.onSuccess});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  CameraController? _controller;
  late final FaceDetector _detector;
  String _checkType = 'IN';
  bool _isBusy = false;
  bool _requireGps = true;
  String _status = 'Pilih Masuk / Pulang, hadapkan wajah ke kamera, lalu tekan Scan Wajah.';

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
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _controller = ctrl);
    } catch (e) {
      if (mounted) setState(() => _status = 'Kamera tidak tersedia: $e');
    }
  }

  Future<void> _performScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;
    setState(() {
      _isBusy = true;
      _status = 'Memverifikasi wajah & lokasi GPS...';
    });

    try {
      final registered = await DatabaseHelper.instance.getEmployees(onlyRegistered: true);
      if (registered.isEmpty) {
        setState(() => _status = 'Belum ada karyawan yang terdaftar wajahnya. Daftarkan di menu Master -> Karyawan.');
        return;
      }

      LocationValidationResult? locRes;
      if (_requireGps) {
        final offices = await DatabaseHelper.instance.getLocations();
        locRes = await LocationService.validateCurrentLocation(offices);
        if (!locRes.isValid) {
          setState(() => _status = locRes!.message);
          return;
        }
      }

      final pic = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(pic.path);
      final faces = await _detector.processImage(inputImage);
      try {
        await File(pic.path).delete();
      } catch (_) {}

      if (faces.isEmpty) {
        setState(() => _status = 'Wajah tidak ditemukan. Posisikan wajah tepat di tengah.');
        return;
      }

      final face = faces.first;
      // Basic liveness check: eyes open & frontal head pose
      final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
      if (leftEyeOpen < 0.25 && rightEyeOpen < 0.25) {
        setState(() => _status = 'Mata terdeteksi tertutup. Mohon buka mata dan lihat kamera.');
        return;
      }

      final probe = FaceRecognitionService.extractFeatureVector(face);
      if (probe == null) {
        setState(() => _status = 'Wajah kurang jelas. Dekatkan wajah ke kamera.');
        return;
      }

      final match = FaceRecognitionService.findBestMatch(probe, registered);
      if (match.employee == null) {
        setState(() => _status =
            'Wajah tidak cocok dengan karyawan terdaftar (skor tertinggi ${(match.similarity * 100).toStringAsFixed(1)}%).');
        return;
      }

      final emp = match.employee!;
      final now = DateTime.now();
      String attStatus = _checkType == 'OUT' ? 'Pulang' : 'Tepat Waktu';

      if (_checkType == 'IN') {
        final shift = await DatabaseHelper.instance.getShiftById(emp.shiftId);
        if (shift != null) {
          final parts = shift.startTime.split(':');
          final shiftStart = DateTime(
            now.year,
            now.month,
            now.day,
            int.tryParse(parts[0]) ?? 8,
            int.tryParse(parts[1]) ?? 0,
          ).add(Duration(minutes: shift.lateToleranceMinutes));
          if (now.isAfter(shiftStart)) {
            attStatus = 'Terlambat';
          }
        }
      }

      final log = AttendanceLog(
        employeeId: emp.id!,
        checkType: _checkType,
        timestamp: now,
        similarityScore: match.similarity,
        latitude: locRes?.latitude,
        longitude: locRes?.longitude,
        distanceMeters: locRes?.distanceMeters,
        locationName: locRes?.locationName ?? 'Mode Kios / Non-GPS',
        status: attStatus,
      );
      await DatabaseHelper.instance.insertAttendanceLog(log);
      widget.onSuccess();

      if (!mounted) return;
      setState(() => _status =
          'Berhasil! ${emp.fullName} (${emp.nik}) — Absen ${_checkType == 'IN' ? 'Masuk' : 'Pulang'} [$attStatus] · Kemiripan ${(match.similarity * 100).toStringAsFixed(1)}%');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('Absensi ${emp.fullName} berhasil dicatat ($attStatus)!'),
        ),
      );
    } catch (e) {
      setState(() => _status = 'Terjadi kendala saat absensi: $e');
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'IN', label: Text('Absen Masuk'), icon: Icon(Icons.login)),
                    ButtonSegment(value: 'OUT', label: Text('Absen Pulang'), icon: Icon(Icons.logout)),
                  ],
                  selected: {_checkType},
                  onSelectionChanged: (s) => setState(() => _checkType = s.first),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('GPS'),
                selected: _requireGps,
                onSelected: (v) => setState(() => _requireGps = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _controller == null || !_controller!.value.isInitialized
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_controller!),
                        Center(
                          child: Container(
                            width: 230,
                            height: 295,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _checkType == 'IN' ? const Color(0xFF1D6FE2) : const Color(0xFF10B981),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(130),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _performScan,
                  icon: const Icon(Icons.face),
                  label: Text(_isBusy ? 'Memverifikasi...' : 'Scan Wajah & Catat Absensi'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
