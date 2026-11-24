import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sol_it_absensi.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        late_tolerance_minutes INTEGER NOT NULL DEFAULT 15
      )
    ''');

    await db.execute('''
      CREATE TABLE office_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meters REAL NOT NULL DEFAULT 150
      )
    ''');

    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nik TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        position TEXT,
        department_id INTEGER,
        shift_id INTEGER,
        phone TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        face_vector TEXT,
        FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE SET NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        check_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        similarity_score REAL NOT NULL,
        latitude REAL,
        longitude REAL,
        distance_meters REAL,
        location_name TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE
      )
    ''');

    // Seed initial master data so app is immediately ready to test
    await db.insert('departments', {
      'code': 'HQ',
      'name': 'Kantor Pusat',
      'description': 'Administrasi & Manajemen',
    });
    await db.insert('departments', {
      'code': 'OPS',
      'name': 'Operasional & Outlet',
      'description': 'Tim Lapangan / Restoran / Pabrik',
    });

    await db.insert('shifts', {
      'name': 'Shift Pagi',
      'start_time': '08:00',
      'end_time': '17:00',
      'late_tolerance_minutes': 15,
    });
    await db.insert('shifts', {
      'name': 'Shift Siang',
      'start_time': '14:00',
      'end_time': '22:00',
      'late_tolerance_minutes': 15,
    });

    await db.insert('office_locations', {
      'name': 'Kantor Pusat Sol-IT (Jakarta Selatan)',
      'latitude': -6.2567,
      'longitude': 106.8019,
      'radius_meters': 200.0,
    });
  }

  // ---------- DEPARTMENTS CRUD ----------
  Future<List<Department>> getDepartments() async {
    final db = await database;
    final rows = await db.query('departments', orderBy: 'name ASC');
    return rows.map(Department.fromMap).toList();
  }

  Future<int> insertDepartment(Department d) async {
    final db = await database;
    return db.insert('departments', d.toMap()..remove('id'));
  }

  Future<int> updateDepartment(Department d) async {
    final db = await database;
    return db.update('departments', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<int> deleteDepartment(int id) async {
    final db = await database;
    return db.delete('departments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- SHIFTS CRUD ----------
  Future<List<WorkShift>> getShifts() async {
    final db = await database;
    final rows = await db.query('shifts', orderBy: 'start_time ASC');
    return rows.map(WorkShift.fromMap).toList();
  }

  Future<int> insertShift(WorkShift s) async {
    final db = await database;
    return db.insert('shifts', s.toMap()..remove('id'));
  }

  Future<int> updateShift(WorkShift s) async {
    final db = await database;
    return db.update('shifts', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteShift(int id) async {
    final db = await database;
    return db.delete('shifts', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- OFFICE LOCATIONS CRUD ----------
  Future<List<OfficeLocation>> getLocations() async {
    final db = await database;
    final rows = await db.query('office_locations', orderBy: 'name ASC');
    return rows.map(OfficeLocation.fromMap).toList();
  }

  Future<int> insertLocation(OfficeLocation loc) async {
    final db = await database;
    return db.insert('office_locations', loc.toMap()..remove('id'));
  }

  Future<int> updateLocation(OfficeLocation loc) async {
    final db = await database;
    return db.update('office_locations', loc.toMap(), where: 'id = ?', whereArgs: [loc.id]);
  }

  Future<int> deleteLocation(int id) async {
    final db = await database;
    return db.delete('office_locations', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- EMPLOYEES CRUD ----------
  Future<List<Employee>> getEmployees({String query = '', bool onlyRegistered = false}) async {
    final db = await database;
    final whereClauses = <String>[];
    final args = <dynamic>[];
    if (query.trim().isNotEmpty) {
      whereClauses.add('(e.full_name LIKE ? OR e.nik LIKE ? OR e.position LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }
    if (onlyRegistered) {
      whereClauses.add('e.face_vector IS NOT NULL AND e.is_active = 1');
    }
    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT e.*, d.name AS department_name, s.name AS shift_name
      FROM employees e
      LEFT JOIN departments d ON e.department_id = d.id
      LEFT JOIN shifts s ON e.shift_id = s.id
      $whereSql
      ORDER BY e.full_name ASC
    ''', args);
    return rows.map(Employee.fromMap).toList();
  }

  Future<int> insertEmployee(Employee emp) async {
    final db = await database;
    return db.insert('employees', emp.toMap()..remove('id'));
  }

  Future<int> updateEmployee(Employee emp) async {
    final db = await database;
    return db.update('employees', emp.toMap(), where: 'id = ?', whereArgs: [emp.id]);
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return db.delete('employees', where: 'id = ?', whereArgs: [id]);
  }

  Future<WorkShift?> getShiftById(int? id) async {
    if (id == null) return null;
    final db = await database;
    final rows = await db.query('shifts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkShift.fromMap(rows.first);
  }

  // ---------- ATTENDANCE LOGS ----------
  Future<int> insertAttendanceLog(AttendanceLog log) async {
    final db = await database;
    return db.insert('attendance_logs', log.toMap()..remove('id'));
  }

  Future<int> deleteAttendanceLog(int id) async {
    final db = await database;
    return db.delete('attendance_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AttendanceLog>> getAttendanceLogs({
    DateTime? startDate,
    DateTime? endDate,
    String query = '',
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final args = <dynamic>[];
    if (startDate != null) {
      whereClauses.add('a.timestamp >= ?');
      args.add(DateTime(startDate.year, startDate.month, startDate.day).toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('a.timestamp <= ?');
      args.add(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String());
    }
    if (query.trim().isNotEmpty) {
      whereClauses.add('(e.full_name LIKE ? OR e.nik LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q]);
    }
    final whereSql = whereClauses.isEmpty ? '' : 'WHERE ${whereClauses.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT a.*, e.full_name AS employee_name, e.nik AS employee_nik,
             COALESCE(d.name, '-') AS department_name
      FROM attendance_logs a
      INNER JOIN employees e ON a.employee_id = e.id
      LEFT JOIN departments d ON e.department_id = d.id
      $whereSql
      ORDER BY a.timestamp DESC
    ''', args);
    return rows.map(AttendanceLog.fromMap).toList();
  }

  Future<Map<String, int>> getTodaySummary() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final totalEmp = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM employees WHERE is_active = 1'),
        ) ??
        0;
    final registeredFace = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM employees WHERE is_active = 1 AND face_vector IS NOT NULL'),
        ) ??
        0;
    final presentToday = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(DISTINCT employee_id) FROM attendance_logs WHERE check_type = 'IN' AND timestamp BETWEEN ? AND ?",
            [start, end],
          ),
        ) ??
        0;
    final lateToday = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(DISTINCT employee_id) FROM attendance_logs WHERE check_type = 'IN' AND status = 'Terlambat' AND timestamp BETWEEN ? AND ?",
            [start, end],
          ),
        ) ??
        0;

    return {
      'totalEmployees': totalEmp,
      'registeredFaces': registeredFace,
      'presentToday': presentToday,
      'lateToday': lateToday,
    };
  }
}
