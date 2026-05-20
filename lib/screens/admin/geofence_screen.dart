import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/attendance_service.dart';

class GeoFenceScreen extends StatefulWidget {
  const GeoFenceScreen({super.key});

  @override
  State<GeoFenceScreen> createState() => _GeoFenceScreenState();
}

class _GeoFenceScreenState extends State<GeoFenceScreen> {
  List<Map<String, dynamic>> _sites = [];
  Map<String, dynamic>? _selected;
  double _editRadius = 200;
  bool _loading = true;
  bool _saved = false;

  final List<double> _presets = [50, 100, 150, 200, 300, 500, 1000];
  final List<Color> _siteColors = [
    const Color(0xFF00C2FF),
    const Color(0xFFFF6B35),
    const Color(0xFF7C3AED),
    const Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final sites = await AttendanceService.getAllSites();
    setState(() {
      _sites = sites;
      if (sites.isNotEmpty) {
        _selected = sites.first;
        _editRadius = (sites.first['radius'] as num).toDouble();
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_selected == null) return;
    await AttendanceService.updateSiteRadius(_selected!['id'] as int, _editRadius);
    setState(() {
      _saved = true;
      // update local list
      final idx = _sites.indexWhere((s) => s['id'] == _selected!['id']);
      if (idx >= 0) {
        _sites[idx] = Map.from(_sites[idx])..['radius'] = _editRadius;
        _selected = _sites[idx];
      }
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _toggleActive(Map<String, dynamic> site) async {
    final newActive = !((site['active'] as int) == 1);
    await AttendanceService.toggleSiteActive(site['id'] as int, newActive);
    setState(() {
      final idx = _sites.indexWhere((s) => s['id'] == site['id']);
      if (idx >= 0) {
        _sites[idx] = Map.from(_sites[idx])..['active'] = newActive ? 1 : 0;
        if (_selected?['id'] == site['id']) _selected = _sites[idx];
      }
    });
  }

  Color _colorFor(int index) => _siteColors[index % _siteColors.length];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Row(
      children: [
        // Site list sidebar
        Container(
          width: 140,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(right: BorderSide(color: AppTheme.border)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _sites.length,
            itemBuilder: (_, i) {
              final site = _sites[i];
              final isSelected = _selected?['id'] == site['id'];
              final color = _colorFor(i);
              final isActive = (site['active'] as int) == 1;

              return GestureDetector(
                onTap: () => setState(() {
                  _selected = site;
                  _editRadius = (site['radius'] as num).toDouble();
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentBlue.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentBlue.withOpacity(0.4) : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? color : AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(site['radius'] as num).toInt()}m',
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        site['name'] as String,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Detail panel
        Expanded(
          child: _selected == null
              ? const Center(
                  child: Text('Select a site',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : _buildDetail(),
        ),
      ],
    );
  }

  Widget _buildDetail() {
    final site = _selected!;
    final idx = _sites.indexOf(_selected!);
    final color = _colorFor(idx < 0 ? 0 : idx);
    final isActive = (site['active'] as int) == 1;
    final coverage =
        (3.14159 * _editRadius * _editRadius).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site['name'] as String,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      site['address'] as String? ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleActive(site),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? color : AppTheme.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment:
                        isActive ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Map visualizer
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              children: [
                // Grid lines
                CustomPaint(
                  painter: GridPainter(),
                  child: const SizedBox.expand(),
                ),
                // Radius ring
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: (_editRadius / 1000 * 180).clamp(40.0, 180.0),
                    height: (_editRadius / 1000 * 120).clamp(30.0, 120.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                          color: color.withOpacity(0.6), width: 1.5, style: BorderStyle.solid),
                      color: color.withOpacity(0.07),
                    ),
                  ),
                ),
                // Center dot
                Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Text(
                    '⌀ ${(_editRadius * 2).toStringAsFixed(0)}m span',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Radius control
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Geo-Fence Radius',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_editRadius.toInt()}m',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: AppTheme.border,
                    thumbColor: Colors.white,
                    overlayColor: color.withOpacity(0.2),
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _editRadius,
                    min: 20,
                    max: 1000,
                    divisions: 98,
                    onChanged: (v) => setState(() => _editRadius = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('20m', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('500m', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('1000m', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Quick Presets',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _presets.map((r) {
                    final selected = _editRadius == r;
                    return GestureDetector(
                      onTap: () => setState(() => _editRadius = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected ? color : AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: selected ? color : AppTheme.border),
                        ),
                        child: Text(
                          '${r.toInt()}m',
                          style: TextStyle(
                            color:
                                selected ? Colors.white : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _miniStat('Coverage', '$coverage m²', Icons.crop_square,
                    AppTheme.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                    'Coordinates',
                    '${(site['latitude'] as num).toStringAsFixed(3)}, ${(site['longitude'] as num).toStringAsFixed(3)}',
                    Icons.gps_fixed,
                    AppTheme.accent),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(_saved ? Icons.check : Icons.save),
              label: Text(_saved ? 'Saved!' : 'Save Geo-Fence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? AppTheme.success : color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10)),
                Text(value,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2533).withOpacity(0.5)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 6; i++) {
      final x = size.width / 6 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = 1; i < 4; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
