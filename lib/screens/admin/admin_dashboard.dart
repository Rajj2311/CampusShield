import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/tenant.dart';
import '../../widgets/ui.dart';
import '../role_select_screen.dart';
import 'admin_hostels_tab.dart';
import 'admin_access_tab.dart';
import 'admin_settings_tab.dart';

/// Home screen for a college administrator.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const _OverviewTab(),
      const AdminHostelsTab(),
      const AdminAccessTab(),
      const AdminSettingsTab(),
    ];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: Text(Tenant.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.home_work_outlined), label: 'Hostels'),
          NavigationDestination(icon: Icon(Icons.key_outlined), label: 'Access'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  Future<int> _count(String col) async {
    final snap = await Tenant.col(col).count().get();
    return snap.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, MapEntry<String, IconData>>>[
      const MapEntry('students', MapEntry('Students', Icons.school)),
      const MapEntry('wardens', MapEntry('Wardens', Icons.admin_panel_settings)),
      const MapEntry('guards', MapEntry('Guards', Icons.shield)),
      const MapEntry('workers', MapEntry('Workers', Icons.engineering)),
      const MapEntry('complaints', MapEntry('Complaints', Icons.report_problem_outlined)),
      const MapEntry('leaveRequests', MapEntry('Leave requests', Icons.exit_to_app)),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionCard(
        child: Row(children: [
          const Icon(Icons.apartment, color: kNavy, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Tenant.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 4),
              Text('College code: ${Tenant.id}',
                  style: const TextStyle(color: Colors.black54)),
              Text('${Tenant.hostels.length} hostel(s)',
                  style: const TextStyle(color: Colors.black54)),
            ]),
          ),
        ]),
      ),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: items.map((e) {
          return FutureBuilder<int>(
            future: _count(e.key),
            builder: (context, snap) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(e.value.value, color: kAmber),
                  const SizedBox(height: 6),
                  Text(snap.hasData ? '${snap.data}' : '...',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: kNavy)),
                  Text(e.value.key,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      const Text(
          'Next steps: add your hostels, then share the access codes with your wardens, guards and workers.',
          style: TextStyle(color: Colors.black54, height: 1.4)),
    ]);
  }
}
