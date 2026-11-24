import 'package:flutter/material.dart';
import 'db/database_helper.dart';
import 'screens/attendance_log_screen.dart';
import 'screens/face_attendance_screen.dart';
import 'screens/master_data_screen.dart';
import 'screens/report_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolItAbsensiApp());
}

class SolItAbsensiApp extends StatelessWidget {
  const SolItAbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sol-IT Absensi Wajah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D6FE2)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAFD),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  Map<String, int> _summary = {
    'totalEmployees': 0,
    'registeredFaces': 0,
    'presentToday': 0,
    'lateToday': 0,
  };

  @override
  void initState() {
    super.initState();
    _refreshSummary();
  }

  Future<void> _refreshSummary() async {
    final s = await DatabaseHelper.instance.getTodaySummary();
    if (mounted) setState(() => _summary = s);
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Sol-IT Absensi Wajah',
      'Scan Absensi Wajah',
      'Log Absensi',
      'Laporan Kehadiran',
      'Master Data & CRUD',
    ];

    final pages = [
      _buildDashboard(),
      FaceAttendanceScreen(onSuccess: _refreshSummary),
      const AttendanceLogScreen(),
      const ReportScreen(),
      const MasterDataScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 0) _refreshSummary();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.face_outlined), selectedIcon: Icon(Icons.face), label: 'Absen'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Master'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _refreshSummary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1D6FE2), Color(0xFF124EAF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('sol.it · PT SIT Global Systems', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                const Text(
                  'Absensi Sensor Wajah & GPS',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1D6FE2)),
                  onPressed: () => setState(() => _tab = 1),
                  icon: const Icon(Icons.camera_front),
                  label: const Text('Mulai Absen Wajah Sekarang'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _kpiCard('Total Karyawan', '${_summary['totalEmployees']}', Icons.people, const Color(0xFF1D6FE2)),
              _kpiCard('Wajah Terdaftar', '${_summary['registeredFaces']}', Icons.face, const Color(0xFF0EA5E9)),
              _kpiCard('Hadir Hari Ini', '${_summary['presentToday']}', Icons.check_circle, const Color(0xFF10B981)),
              _kpiCard('Terlambat', '${_summary['lateToday']}', Icons.schedule, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFF1D6FE2)),
              title: const Text('Langkah Awal: Tambah Karyawan & Daftar Wajah'),
              subtitle: const Text('Buka menu Master -> Karyawan & Wajah untuk CRUD dan registrasi sensor wajah.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _tab = 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
        ],
      ),
    );
  }
}
