import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../auth/login_screen.dart';
import 'geofence_screen.dart';
import 'user_management_screen.dart';
import 'live_monitor_screen.dart';
import 'reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;
  Map<String, int> _stats = {'present': 0, 'failed': 0};
  List<Map<String, dynamic>> _recentLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stats = await AttendanceService.getTodayStats();
    final logs = await AttendanceService.getAllLogs();
    setState(() {
      _stats = stats;
      _recentLogs = logs.take(10).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Admin Panel',
            style: TextStyle(color: AppTheme.textPrimary)),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0070F3), Color(0xFF00C2FF)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 18),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildHome(),
          const UserManagementScreen(),
          const GeoFenceScreen(),
          const LiveMonitorScreen(),
          const ReportsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          indicatorColor: AppTheme.accent.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.accent),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.people, color: AppTheme.accent),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.fence_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.fence, color: AppTheme.accent),
              label: 'Geofence',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.monitor_heart, color: AppTheme.accent),
              label: 'Live',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.bar_chart, color: AppTheme.accent),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Overview',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Stats grid
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _statCard('Present Today', _stats['present'].toString(),
                          Icons.check_circle_outline, AppTheme.success),
                      _statCard('Failed Punches', _stats['failed'].toString(),
                          Icons.cancel_outlined, AppTheme.error),
                      _statCard('Total Sites', '4',
                          Icons.location_city, AppTheme.accent),
                      _statCard('Active Users',
                          AuthService.getAllUsers().length.toString(),
                          Icons.people_outline, AppTheme.warning),
                    ],
                  ),

            const SizedBox(height: 24),
            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    Icons.fence,
                    'Manage Geofence',
                    'Set location radius per site',
                    AppTheme.accentBlue,
                    () => setState(() => _tab = 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionCard(
                    Icons.people,
                    'Manage Users',
                    'Add / edit employees',
                    AppTheme.warning,
                    () => setState(() => _tab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent logs
            const Text(
              'Recent Activity',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_recentLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: Text('No activity yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ...(_recentLogs.map((log) => _logRow(log)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w700)),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _logRow(Map<String, dynamic> log) {
    final isIn = log['type'] == 'in';
    final isSuccess = log['status'] == 'success';
    final color = isSuccess
        ? (isIn ? AppTheme.success : AppTheme.accent)
        : AppTheme.error;

    String timeStr = '';
    try {
      final dt = DateTime.parse(log['timestamp'] ?? '');
      timeStr = DateFormat('hh:mm a').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            isIn ? Icons.login : Icons.logout,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['employee_name'] ?? '',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
                Text(
                  '${log['site_name'] ?? ''} · ${isIn ? "In" : "Out"}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isSuccess ? 'OK' : 'FAIL',
                  style:
                      TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
