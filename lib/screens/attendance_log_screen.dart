import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  List<AttendanceLog> _logs = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getAttendanceLogs(query: _search);
    if (mounted) setState(() => _logs = rows);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari log berdasarkan nama atau NIK...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              _search = v;
              _load();
            },
          ),
        ),
        Expanded(
          child: _logs.isEmpty
              ? const Center(child: Text('Belum ada riwayat absensi.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final l = _logs[i];
                      final isLate = l.status == 'Terlambat';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: l.checkType == 'IN'
                                ? (isLate ? Colors.orange : const Color(0xFF1D6FE2))
                                : const Color(0xFF10B981),
                            child: Text(
                              l.checkType,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${l.employeeName} (${l.employeeNik})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${fmt.format(l.timestamp)} · ${l.status}\n${l.locationName} · Wajah ${(l.similarityScore * 100).toStringAsFixed(0)}%',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteAttendanceLog(l.id!);
                              _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
