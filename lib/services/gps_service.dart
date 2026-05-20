import 'dart:math';
import 'package:geolocator/geolocator.dart';

class GpsService {
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns distance in meters between two coords
  static double distanceBetween(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if position is within allowed radius of site
  static GeoFenceResult checkGeoFence({
    required double userLat,
    required double userLon,
    required double siteLat,
    required double siteLon,
    required double allowedRadius,
  }) {
    final distance = distanceBetween(userLat, userLon, siteLat, siteLon);
    return GeoFenceResult(
      isInside: distance <= allowedRadius,
      distance: distance,
      allowedRadius: allowedRadius,
    );
  }

  /// Detect mock/fake GPS (basic check)
  static Future<bool> isMockLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return pos.isMocked;
    } catch (_) {
      return false;
    }
  }
}

class GeoFenceResult {
  final bool isInside;
  final double distance;
  final double allowedRadius;

  GeoFenceResult({
    required this.isInside,
    required this.distance,
    required this.allowedRadius,
  });

  String get message {
    if (isInside) {
      return 'Within range (${distance.toStringAsFixed(0)}m from site)';
    }
    return '${(distance - allowedRadius).toStringAsFixed(0)}m outside allowed zone';
  }
}
