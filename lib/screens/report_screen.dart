import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();
  List<AttendanceLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getAttendanceLogs(startDate: _start, endDate: _end);
    if (mounted) setState(() => _logs = rows);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
      _load();
    }
  }

  Future<void> _exportCsv() async {
    final rows = <List<dynamic>>[
      ['Tanggal', 'Jam', 'NIK', 'Nama', 'Departemen', 'Tipe', 'Status', 'Lokasi', 'Kemiripan (%)'],
      ..._logs.map((l) => [
            DateFormat('yyyy-MM-dd').format(l.timestamp),
            DateFormat('HH:mm:ss').format(l.timestamp),
            l.employeeNik,
            l.employeeName,
            l.departmentName,
            l.checkType,
            l.status,
            l.locationName,
            (l.similarityScore * 100).toStringAsFixed(1),
          ]),
    ];
    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/laporan_absensi_sol_it.csv');
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'Laporan Absensi Sol-IT');
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final totalIn = _logs.where((l) => l.checkType == 'IN').length;
    final totalLate = _logs.where((l) => l.status == 'Terlambat').length;
    final totalOut = _logs.where((l) => l.checkType == 'OUT').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            label: Text('Periode: ${df.format(_start)} — ${df.format(_end)}'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBox('Masuk', '$totalIn', const Color(0xFF1D6FE2)),
              const SizedBox(width: 8),
              _statBox('Terlambat', '$totalLate', Colors.orange),
              const SizedBox(width: 8),
              _statBox('Pulang', '$totalOut', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _logs.isEmpty ? null : _exportCsv,
            icon: const Icon(Icons.download),
            label: const Text('Ekspor & Bagikan Laporan (CSV / Excel)'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('Tidak ada data absensi pada periode ini.'))
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final l = _logs[i];
                      return ListTile(
                        dense: true,
                        title: Text('${l.employeeName} (${l.checkType} · ${l.status})'),
                        subtitle: Text('${DateFormat('dd/MM HH:mm').format(l.timestamp)} · ${l.departmentName}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: col.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: col)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
