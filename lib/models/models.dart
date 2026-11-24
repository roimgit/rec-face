import 'dart:convert';

class Department {
  final int? id;
  final String code;
  final String name;
  final String description;

  Department({
    this.id,
    required this.code,
    required this.name,
    this.description = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
      };

  factory Department.fromMap(Map<String, dynamic> m) => Department(
        id: m['id'] as int?,
        code: m['code'] as String,
        name: m['name'] as String,
        description: (m['description'] ?? '') as String,
      );
}

class WorkShift {
  final int? id;
  final String name;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final int lateToleranceMinutes;

  WorkShift({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.lateToleranceMinutes = 15,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
        'late_tolerance_minutes': lateToleranceMinutes,
      };

  factory WorkShift.fromMap(Map<String, dynamic> m) => WorkShift(
        id: m['id'] as int?,
        name: m['name'] as String,
        startTime: m['start_time'] as String,
        endTime: m['end_time'] as String,
        lateToleranceMinutes: (m['late_tolerance_minutes'] ?? 15) as int,
      );
}

class OfficeLocation {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  OfficeLocation({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
      };

  factory OfficeLocation.fromMap(Map<String, dynamic> m) => OfficeLocation(
        id: m['id'] as int?,
        name: m['name'] as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        radiusMeters: ((m['radius_meters'] ?? 100) as num).toDouble(),
      );
}

class Employee {
  final int? id;
  final String nik;
  final String fullName;
  final String position;
  final int? departmentId;
  final int? shiftId;
  final String phone;
  final bool isActive;
  final List<double>? faceVector;
  final String? departmentName;
  final String? shiftName;

  Employee({
    this.id,
    required this.nik,
    required this.fullName,
    required this.position,
    this.departmentId,
    this.shiftId,
    this.phone = '',
    this.isActive = true,
    this.faceVector,
    this.departmentName,
    this.shiftName,
  });

  bool get hasFaceRegistered => faceVector != null && faceVector!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nik': nik,
        'full_name': fullName,
        'position': position,
        'department_id': departmentId,
        'shift_id': shiftId,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
        'face_vector': faceVector != null ? jsonEncode(faceVector) : null,
      };

  factory Employee.fromMap(Map<String, dynamic> m) {
    List<double>? vec;
    final raw = m['face_vector'] as String?;
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      vec = decoded.map((e) => (e as num).toDouble()).toList();
    }
    return Employee(
      id: m['id'] as int?,
      nik: m['nik'] as String,
      fullName: m['full_name'] as String,
      position: (m['position'] ?? '') as String,
      departmentId: m['department_id'] as int?,
      shiftId: m['shift_id'] as int?,
      phone: (m['phone'] ?? '') as String,
      isActive: (m['is_active'] ?? 1) == 1,
      faceVector: vec,
      departmentName: m['department_name'] as String?,
      shiftName: m['shift_name'] as String?,
    );
  }
}

class AttendanceLog {
  final int? id;
  final int employeeId;
  final String employeeName;
  final String employeeNik;
  final String departmentName;
  final String checkType; // 'IN' or 'OUT'
  final DateTime timestamp;
  final double similarityScore; // 0.0 - 1.0
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final String locationName;
  final String status; // 'Tepat Waktu', 'Terlambat', 'Pulang'
  final String notes;

  AttendanceLog({
    this.id,
    required this.employeeId,
    this.employeeName = '',
    this.employeeNik = '',
    this.departmentName = '',
    required this.checkType,
    required this.timestamp,
    required this.similarityScore,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.locationName = '',
    required this.status,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'employee_id': employeeId,
        'check_type': checkType,
        'timestamp': timestamp.toIso8601String(),
        'similarity_score': similarityScore,
        'latitude': latitude,
        'longitude': longitude,
        'distance_meters': distanceMeters,
        'location_name': locationName,
        'status': status,
        'notes': notes,
      };

  factory AttendanceLog.fromMap(Map<String, dynamic> m) => AttendanceLog(
        id: m['id'] as int?,
        employeeId: m['employee_id'] as int,
        employeeName: (m['employee_name'] ?? '') as String,
        employeeNik: (m['employee_nik'] ?? '') as String,
        departmentName: (m['department_name'] ?? '') as String,
        checkType: m['check_type'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        similarityScore: ((m['similarity_score'] ?? 0) as num).toDouble(),
        latitude: m['latitude'] != null ? (m['latitude'] as num).toDouble() : null,
        longitude: m['longitude'] != null ? (m['longitude'] as num).toDouble() : null,
        distanceMeters: m['distance_meters'] != null ? (m['distance_meters'] as num).toDouble() : null,
        locationName: (m['location_name'] ?? '') as String,
        status: (m['status'] ?? 'Tepat Waktu') as String,
        notes: (m['notes'] ?? '') as String,
      );
}
