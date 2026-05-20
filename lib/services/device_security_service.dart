import 'dart:io';
import 'package:flutter/services.dart';

class DeviceSecurityService {
  static const _channel = MethodChannel('com.smartattendance.app/security');

  /// Check if device is rooted (Android)
  static Future<bool> isRooted() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isRooted');
      return result ?? false;
    } catch (_) {
      // Fallback: check common root indicators
      return _checkRootIndicators();
    }
  }

  static Future<bool> _checkRootIndicators() async {
    final paths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
    ];
    for (final p in paths) {
      if (await File(p).exists()) return true;
    }
    return false;
  }

  /// Check if developer mode is on (increases mock GPS risk)
  static Future<bool> isDeveloperModeOn() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeveloperMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Full device security check
  static Future<SecurityCheckResult> runSecurityCheck() async {
    final rooted = await isRooted();
    final devMode = await isDeveloperModeOn();

    return SecurityCheckResult(
      isRooted: rooted,
      isDeveloperMode: devMode,
      passed: !rooted,
      reason: rooted
          ? 'Rooted device detected. Attendance is blocked for security.'
          : devMode
              ? 'Developer mode is enabled. Mock GPS risk is elevated.'
              : 'Device security check passed.',
    );
  }
}

class SecurityCheckResult {
  final bool isRooted;
  final bool isDeveloperMode;
  final bool passed;
  final String reason;

  SecurityCheckResult({
    required this.isRooted,
    required this.isDeveloperMode,
    required this.passed,
    required this.reason,
  });
}
