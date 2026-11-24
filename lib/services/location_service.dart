import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class LocationValidationResult {
  final bool isValid;
  final String message;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final String locationName;

  LocationValidationResult({
    required this.isValid,
    required this.message,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.locationName = '-',
  });
}

class LocationService {
  static Future<LocationValidationResult> validateCurrentLocation(
    List<OfficeLocation> offices,
  ) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return LocationValidationResult(
        isValid: false,
        message: 'GPS tidak aktif. Mohon nyalakan layanan lokasi perangkat.',
      );
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return LocationValidationResult(
        isValid: false,
        message: 'Izin lokasi ditolak. Aktifkan izin GPS untuk melakukan absensi.',
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    if (pos.isMocked) {
      return LocationValidationResult(
        isValid: false,
        message: 'Terdeteksi Fake GPS / Mock Location! Absensi ditolak.',
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }

    if (offices.isEmpty) {
      return LocationValidationResult(
        isValid: true,
        message: 'Lokasi GPS terekam (belum ada geofence kantor).',
        latitude: pos.latitude,
        longitude: pos.longitude,
        distanceMeters: 0,
        locationName: 'Lokasi Bebas',
      );
    }

    OfficeLocation? nearest;
    double nearestDist = double.infinity;
    for (final office in offices) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        office.latitude,
        office.longitude,
      );
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = office;
      }
    }

    if (nearest != null && nearestDist <= nearest.radiusMeters) {
      return LocationValidationResult(
        isValid: true,
        message: 'Dalam radius ${nearest.name} (${nearestDist.toStringAsFixed(0)} m).',
        latitude: pos.latitude,
        longitude: pos.longitude,
        distanceMeters: nearestDist,
        locationName: nearest.name,
      );
    }

    return LocationValidationResult(
      isValid: false,
      message:
          'Di luar radius ${nearest?.name ?? "kantor"} (jarak ${nearestDist.toStringAsFixed(0)} m, maks ${nearest?.radiusMeters.toStringAsFixed(0) ?? 0} m).',
      latitude: pos.latitude,
      longitude: pos.longitude,
      distanceMeters: nearestDist,
      locationName: nearest?.name ?? '-',
    );
  }
}
