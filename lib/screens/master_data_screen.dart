import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import 'employee_crud_screen.dart';

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: const [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Karyawan & Wajah'),
              Tab(text: 'Departemen'),
              Tab(text: 'Shift Kerja'),
              Tab(text: 'Lokasi GPS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                EmployeeCrudScreen(),
                _DepartmentTab(),
                _ShiftTab(),
                _LocationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentTab extends StatefulWidget {
  const _DepartmentTab();
  @override
  State<_DepartmentTab> createState() => _DepartmentTabState();
}

class _DepartmentTabState extends State<_DepartmentTab> {
  List<Department> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getDepartments();
    if (mounted) setState(() => _items = rows);
  }

  Future<void> _openForm({Department? existing}) async {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Departemen' : 'Edit Departemen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Kode (mis. PROD)')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Departemen / Outlet')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Keterangan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              final d = Department(
                id: existing?.id,
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
              );
              if (existing == null) {
                await DatabaseHelper.instance.insertDepartment(d);
              } else {
                await DatabaseHelper.instance.updateDepartment(d);
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final d = _items[i];
          return ListTile(
            title: Text('${d.code} — ${d.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(d.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(existing: d)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteDepartment(d.id!);
                    _load();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}

class _ShiftTab extends StatefulWidget {
  const _ShiftTab();
  @override
  State<_ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends State<_ShiftTab> {
  List<WorkShift> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getShifts();
    if (mounted) setState(() => _items = rows);
  }

  Future<void> _openForm({WorkShift? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl = TextEditingController(text: existing?.startTime ?? '08:00');
    final endCtrl = TextEditingController(text: existing?.endTime ?? '17:00');
    final tolCtrl = TextEditingController(text: '${existing?.lateToleranceMinutes ?? 15}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Shift' : 'Edit Shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Shift')),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Jam Masuk (HH:mm)')),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Jam Pulang (HH:mm)')),
            TextField(
              controller: tolCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Toleransi Terlambat (menit)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final s = WorkShift(
                id: existing?.id,
                name: nameCtrl.text.trim(),
                startTime: startCtrl.text.trim(),
                endTime: endCtrl.text.trim(),
                lateToleranceMinutes: int.tryParse(tolCtrl.text.trim()) ?? 15,
              );
              if (existing == null) {
                await DatabaseHelper.instance.insertShift(s);
              } else {
                await DatabaseHelper.instance.updateShift(s);
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final s = _items[i];
          return ListTile(
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${s.startTime} - ${s.endTime} · Toleransi ${s.lateToleranceMinutes} menit'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(existing: s)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteShift(s.id!);
                    _load();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}

class _LocationTab extends StatefulWidget {
  const _LocationTab();
  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  List<OfficeLocation> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getLocations();
    if (mounted) setState(() => _items = rows);
  }

  Future<void> _openForm({OfficeLocation? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final latCtrl = TextEditingController(text: '${existing?.latitude ?? -6.2567}');
    final lngCtrl = TextEditingController(text: '${existing?.longitude ?? 106.8019}');
    final radCtrl = TextEditingController(text: '${existing?.radiusMeters ?? 150}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Lokasi Geofence' : 'Edit Lokasi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kantor / Pabrik / Outlet')),
              TextField(controller: latCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Latitude')),
              TextField(controller: lngCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Longitude')),
              TextField(controller: radCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Radius Diizinkan (meter)')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  var perm = await Geolocator.checkPermission();
                  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
                  final pos = await Geolocator.getCurrentPosition();
                  latCtrl.text = pos.latitude.toStringAsFixed(6);
                  lngCtrl.text = pos.longitude.toStringAsFixed(6);
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Ambil GPS Saat Ini'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final loc = OfficeLocation(
                id: existing?.id,
                name: nameCtrl.text.trim(),
                latitude: double.tryParse(latCtrl.text.trim()) ?? 0,
                longitude: double.tryParse(lngCtrl.text.trim()) ?? 0,
                radiusMeters: double.tryParse(radCtrl.text.trim()) ?? 150,
              );
              if (existing == null) {
                await DatabaseHelper.instance.insertLocation(loc);
              } else {
                await DatabaseHelper.instance.updateLocation(loc);
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final l = _items[i];
          return ListTile(
            title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('(${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}) · Radius ${l.radiusMeters.toStringAsFixed(0)} m'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(existing: l)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteLocation(l.id!);
                    _load();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}
