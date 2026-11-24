import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import 'face_register_screen.dart';

class EmployeeCrudScreen extends StatefulWidget {
  const EmployeeCrudScreen({super.key});

  @override
  State<EmployeeCrudScreen> createState() => _EmployeeCrudScreenState();
}

class _EmployeeCrudScreenState extends State<EmployeeCrudScreen> {
  List<Employee> _employees = [];
  List<Department> _departments = [];
  List<WorkShift> _shifts = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final emps = await DatabaseHelper.instance.getEmployees(query: _search);
    final depts = await DatabaseHelper.instance.getDepartments();
    final shifts = await DatabaseHelper.instance.getShifts();
    if (!mounted) return;
    setState(() {
      _employees = emps;
      _departments = depts;
      _shifts = shifts;
    });
  }

  Future<void> _openForm({Employee? existing}) async {
    final nikCtrl = TextEditingController(text: existing?.nik ?? '');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final posCtrl = TextEditingController(text: existing?.position ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    int? deptId = existing?.departmentId ?? (_departments.isNotEmpty ? _departments.first.id : null);
    int? shiftId = existing?.shiftId ?? (_shifts.isNotEmpty ? _shifts.first.id : null);
    bool isActive = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Tambah Karyawan' : 'Edit Karyawan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nikCtrl, decoration: const InputDecoration(labelText: 'NIK / ID Karyawan')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Jabatan')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. HP / WhatsApp')),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: deptId,
                  decoration: const InputDecoration(labelText: 'Departemen / Outlet'),
                  items: _departments
                      .map((d) => DropdownMenuItem<int?>(value: d.id, child: Text('${d.code} - ${d.name}')))
                      .toList(),
                  onChanged: (v) => setS(() => deptId = v),
                ),
                DropdownButtonFormField<int?>(
                  value: shiftId,
                  decoration: const InputDecoration(labelText: 'Shift Kerja'),
                  items: _shifts
                      .map((s) => DropdownMenuItem<int?>(value: s.id, child: Text('${s.name} (${s.startTime}-${s.endTime})')))
                      .toList(),
                  onChanged: (v) => setS(() => shiftId = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Status Aktif'),
                  value: isActive,
                  onChanged: (v) => setS(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (nikCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                final emp = Employee(
                  id: existing?.id,
                  nik: nikCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  position: posCtrl.text.trim(),
                  departmentId: deptId,
                  shiftId: shiftId,
                  phone: phoneCtrl.text.trim(),
                  isActive: isActive,
                  faceVector: existing?.faceVector,
                );
                if (existing == null) {
                  await DatabaseHelper.instance.insertEmployee(emp);
                } else {
                  await DatabaseHelper.instance.updateEmployee(emp);
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama, NIK, atau jabatan...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _search = v;
                _loadData();
              },
            ),
          ),
          Expanded(
            child: _employees.isEmpty
                ? const Center(child: Text('Belum ada data karyawan. Tekan tombol + untuk menambah.'))
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (_, i) {
                      final e = _employees[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: e.hasFaceRegistered ? const Color(0xFF1D6FE2) : Colors.grey.shade400,
                            child: Icon(e.hasFaceRegistered ? Icons.face : Icons.person_outline, color: Colors.white),
                          ),
                          title: Text('${e.fullName} (${e.nik})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${e.position} · ${e.departmentName ?? "-"}\nShift: ${e.shiftName ?? "-"} · ${e.hasFaceRegistered ? "Wajah Terdaftar" : "Belum Daftar Wajah"}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'face') {
                                final ok = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => FaceRegisterScreen(employee: e)),
                                );
                                if (ok == true) _loadData();
                              } else if (val == 'edit') {
                                _openForm(existing: e);
                              } else if (val == 'delete') {
                                await DatabaseHelper.instance.deleteEmployee(e.id!);
                                _loadData();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'face', child: Text('Registrasi / Update Wajah')),
                              PopupMenuItem(value: 'edit', child: Text('Edit Data')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Karyawan'),
      ),
    );
  }
}
