import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/attendance_service.dart';

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});
  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logs = await AttendanceService.getAllLogs(date: today);
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.success.withOpacity(0.15),
                AppTheme.success.withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success,
                    boxShadow: [BoxShadow(color: AppTheme.success.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live · Today\'s Activity (${_logs.length} punches)',
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _load,
                  child: const Icon(Icons.refresh, color: AppTheme.success, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.monitor_heart_outlined, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 12),
                    Text('No punches recorded today',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ..._logs.map((log) {
              final isIn = log['type'] == 'in';
              final isSuccess = log['status'] == 'success';
              final color = isSuccess
                  ? (isIn ? AppTheme.success : AppTheme.accent)
                  : AppTheme.error;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.15)),
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
                      child: Icon(isIn ? Icons.login : Icons.logout, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                log['employee_name'] as String? ?? '',
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                log['employee_id'] as String? ?? '',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                          Text(
                            '${log['site_name']} · ${isIn ? "Punch In" : "Punch Out"}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          if (log['latitude'] != null)
                            Text(
                              '📍 ${(log['latitude'] as num).toStringAsFixed(4)}, ${(log['longitude'] as num).toStringAsFixed(4)} · ${(log['geo_distance'] as num?)?.toStringAsFixed(0) ?? "?"}m from site',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          Row(
                            children: [
                              _badge(
                                log['face_verified'] == 1 ? '✓ Face' : '✗ Face',
                                log['face_verified'] == 1 ? AppTheme.success : AppTheme.error,
                              ),
                              const SizedBox(width: 4),
                              _badge(isSuccess ? 'OK' : 'FAIL', color),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(log['timestamp'] as String? ?? ''),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}
