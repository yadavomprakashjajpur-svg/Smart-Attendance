import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/attendance_service.dart';

class HistoryScreen extends StatefulWidget {
  final String employeeId;
  const HistoryScreen({super.key, required this.employeeId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final logs = await AttendanceService.getEmployeeLogs(widget.employeeId);
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text('No attendance records yet',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      const Text('Punch in to see your history',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  color: AppTheme.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) => _logCard(_logs[i]),
                  ),
                ),
    );
  }

  Widget _logCard(Map<String, dynamic> log) {
    final isIn = log['type'] == 'in';
    final isSuccess = log['status'] == 'success';
    final color = isSuccess
        ? (isIn ? AppTheme.success : AppTheme.accent)
        : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIn ? Icons.login : Icons.logout,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isIn ? 'Punch In' : 'Punch Out',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSuccess ? 'Success' : 'Failed',
                        style: TextStyle(
                            color: color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(log['timestamp'] ?? ''),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (log['failure_reason'] != null)
                  Text(
                    log['failure_reason']!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(log['timestamp'] ?? ''),
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
        ],
      ),
    );
  }
}
