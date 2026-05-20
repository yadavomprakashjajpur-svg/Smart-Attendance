import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/gps_service.dart';
import '../../services/face_service.dart';
import '../../services/attendance_service.dart';
import '../auth/login_screen.dart';
import 'history_screen.dart';

class EmployeeHome extends StatefulWidget {
  final Map<String, dynamic> user;
  const EmployeeHome({super.key, required this.user});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome>
    with TickerProviderStateMixin {
  int _tab = 0;
  bool _isPunchedIn = false;
  String? _lastPunchTime;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user['name'] ?? 'Employee',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              widget.user['employeeId'] ?? '',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(
            backgroundColor: AppTheme.accentBlue.withOpacity(0.2),
            child: Text(
              (widget.user['name'] as String? ?? 'E')[0].toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
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
          _buildPunchTab(),
          HistoryScreen(employeeId: widget.user['id'] ?? ''),
          _buildProfileTab(),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fingerprint, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.fingerprint, color: AppTheme.accent),
              label: 'Punch',
            ),
            NavigationDestination(
              icon: Icon(Icons.history, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.history, color: AppTheme.accent),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.person, color: AppTheme.accent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunchTab() {
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMM d yyyy').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentBlue.withOpacity(0.15),
                  AppTheme.accent.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isPunchedIn
                    ? AppTheme.success.withOpacity(0.4)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPunchedIn ? AppTheme.success : AppTheme.textMuted,
                    boxShadow: _isPunchedIn
                        ? [
                            BoxShadow(
                              color: AppTheme.success.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPunchedIn ? 'Currently Punched In' : 'Not Punched In',
                      style: TextStyle(
                        color: _isPunchedIn
                            ? AppTheme.success
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (_lastPunchTime != null)
                      Text(
                        'Last: $_lastPunchTime',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Site info
          _infoRow(Icons.location_on_outlined,
              widget.user['site'] ?? 'N/A', 'Work Site'),
          const SizedBox(height: 12),
          _infoRow(Icons.schedule, widget.user['shift'] ?? 'Day', 'Shift'),
          const SizedBox(height: 32),

          // Big punch button
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: GestureDetector(
              onTap: () => _startPunchFlow(),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isPunchedIn
                        ? [
                            const Color(0xFFEF4444),
                            const Color(0xFFDC2626),
                          ]
                        : [
                            AppTheme.accent,
                            AppTheme.accentBlue,
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPunchedIn
                              ? AppTheme.error
                              : AppTheme.accent)
                          .withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPunchedIn
                          ? Icons.logout
                          : Icons.fingerprint,
                      color: Colors.white,
                      size: 52,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap to punch — face scan + GPS will be verified',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  void _startPunchFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PunchScreen(
          user: widget.user,
          punchType: _isPunchedIn ? 'out' : 'in',
          onPunchSuccess: () {
            setState(() {
              _isPunchedIn = !_isPunchedIn;
              _lastPunchTime = DateFormat('hh:mm a').format(DateTime.now());
            });
          },
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = widget.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.accentBlue.withOpacity(0.2),
            child: Text(
              (user['name'] as String? ?? 'E')[0].toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user['name'] ?? '',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(user['email'] ?? '',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          _profileCard([
            {'label': 'Employee ID', 'value': user['employeeId'] ?? 'N/A'},
            {'label': 'Site', 'value': user['site'] ?? 'N/A'},
            {'label': 'Shift', 'value': user['shift'] ?? 'N/A'},
            {'label': 'Role', 'value': 'Employee'},
          ]),
        ],
      ),
    );
  }

  Widget _profileCard(List<Map<String, String>> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['label']!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                Text(item['value']!,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
