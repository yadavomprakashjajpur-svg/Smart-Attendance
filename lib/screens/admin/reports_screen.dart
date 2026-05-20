import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/attendance_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _logs = [];
  String _filter = 'All';
  String _typeFilter = 'All';
  bool _loading = true;
  List<Map<String, dynamic>> _sites = [];
  int? _selectedSite;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await AttendanceService.getAllLogs(siteId: _selectedSite);
    final sites = await AttendanceService.getAllSites();
    setState(() {
      _logs = logs;
      _sites = sites;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _logs;
    if (_filter == 'Failed') list = list.where((l) => l['status'] == 'failed').toList();
    if (_filter == 'Success') list = list.where((l) => l['status'] == 'success').toList();
    if (_typeFilter == 'In') list = list.where((l) => l['type'] == 'in').toList();
    if (_typeFilter == 'Out') list = list.where((l) => l['type'] == 'out').toList();
    return list;
  }

  String _formatDt(String iso) {
    try {
      return DateFormat('MMM d · hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export Report',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Connect to your backend API to enable exports.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            ...[
              ('📊 Export as Excel (.xlsx)', AppTheme.success),
              ('📄 Export as CSV', AppTheme.accent),
              ('🖨 Export as PDF', AppTheme.warning),
            ].map((item) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.$1.split(' ').last} export ready — connect backend to download'),
                        backgroundColor: AppTheme.card,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Text(item.$1, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.download, color: item.$2, size: 18),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Status:',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(width: 8),
                      ...['All', 'Success', 'Failed'].map((f) => _filterChip(
                            f,
                            _filter == f,
                            () => setState(() => _filter = f),
                            _filter == f ? AppTheme.accent : AppTheme.card,
                          )),
                      const SizedBox(width: 16),
                      const Text('Type:',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(width: 8),
                      ...['All', 'In', 'Out'].map((f) => _filterChip(
                            f,
                            _typeFilter == f,
                            () => setState(() => _typeFilter = f),
                            _typeFilter == f ? AppTheme.accentBlue : AppTheme.card,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Site filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Site:',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      const SizedBox(width: 8),
                      _filterChip(
                        'All Sites',
                        _selectedSite == null,
                        () => setState(() {
                          _selectedSite = null;
                          _load();
                        }),
                        _selectedSite == null ? AppTheme.success : AppTheme.card,
                      ),
                      ..._sites.map((s) => _filterChip(
                            s['name'] as String,
                            _selectedSite == s['id'],
                            () => setState(() {
                              _selectedSite = s['id'] as int;
                              _load();
                            }),
                            _selectedSite == s['id'] ? AppTheme.success : AppTheme.card,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),

          // Summary strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _summaryChip('Total', _logs.length.toString(), AppTheme.accent),
                const SizedBox(width: 8),
                _summaryChip(
                    'Success',
                    _logs.where((l) => l['status'] == 'success').length.toString(),
                    AppTheme.success),
                const SizedBox(width: 8),
                _summaryChip(
                    'Failed',
                    _logs.where((l) => l['status'] == 'failed').length.toString(),
                    AppTheme.error),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showExportDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.download, color: AppTheme.accent, size: 16),
                        SizedBox(width: 4),
                        Text('Export',
                            style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart, size: 48, color: AppTheme.textMuted),
                            SizedBox(height: 12),
                            Text('No records found',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final log = _filtered[i];
                          final isSuccess = log['status'] == 'success';
                          final isIn = log['type'] == 'in';
                          final color = isSuccess
                              ? (isIn ? AppTheme.success : AppTheme.accent)
                              : AppTheme.error;

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
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                      isIn ? Icons.login : Icons.logout,
                                      color: color,
                                      size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['employee_name'] as String? ?? '',
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${log['site_name']} · ${_formatDt(log['timestamp'] as String? ?? '')}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                      if (log['failure_reason'] != null)
                                        Text(
                                          log['failure_reason'] as String,
                                          style: const TextStyle(
                                              color: AppTheme.error, fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isSuccess ? 'OK' : 'FAIL',
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      log['face_verified'] == 1 ? '✓ Face' : '✗ Face',
                                      style: TextStyle(
                                        color: log['face_verified'] == 1
                                            ? AppTheme.success
                                            : AppTheme.error,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap, Color bg) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? bg : AppTheme.card,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: active ? bg : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
