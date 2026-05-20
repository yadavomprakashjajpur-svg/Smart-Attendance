import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../services/gps_service.dart';
import '../../services/face_service.dart';
import '../../services/attendance_service.dart';

enum PunchStep { camera, verifying, result }

class PunchScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String punchType; // 'in' or 'out'
  final VoidCallback onPunchSuccess;

  const PunchScreen({
    super.key,
    required this.user,
    required this.punchType,
    required this.onPunchSuccess,
  });

  @override
  State<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends State<PunchScreen> {
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  PunchStep _step = PunchStep.camera;
  String _statusMsg = 'Position your face in the frame';
  bool _success = false;
  String? _imagePath;
  Position? _position;
  bool _cameraReady = false;

  // Verification states
  bool _gpsOk = false;
  bool _faceOk = false;
  bool _geoFenceOk = false;
  bool _mockGpsDetected = false;
  String _gpsMsg = 'Checking location...';
  String _faceMsg = 'Waiting for face scan...';
  String _geoMsg = 'Checking geofence...';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Prefer front camera for selfie
    final front = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraCtrl = CameraController(front, ResolutionPreset.high);
    await _cameraCtrl!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    _cameraCtrl?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) return;

    setState(() {
      _step = PunchStep.verifying;
      _statusMsg = 'Verifying face and location...';
    });

    // 1. Capture photo
    final XFile photo = await _cameraCtrl!.takePicture();
    _imagePath = photo.path;

    // 2. Check mock GPS first
    setState(() => _gpsMsg = 'Checking for fake GPS...');
    _mockGpsDetected = await GpsService.isMockLocation();
    if (_mockGpsDetected) {
      _finish(false, 'Fake/Mock GPS detected. Punch denied.');
      return;
    }

    // 3. Get GPS position
    setState(() => _gpsMsg = 'Getting your location...');
    _position = await GpsService.getCurrentPosition();

    if (_position == null) {
      _finish(false, 'Could not get GPS location. Enable location services.');
      return;
    }

    setState(() {
      _gpsOk = true;
      _gpsMsg = 'GPS: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
    });

    // 4. Check geofence
    setState(() => _geoMsg = 'Verifying site boundaries...');
    final site = await AttendanceService.getSite(widget.user['siteId'] as int? ?? 1);
    double geoDistance = 0;

    if (site != null) {
      final geoResult = GpsService.checkGeoFence(
        userLat: _position!.latitude,
        userLon: _position!.longitude,
        siteLat: site['latitude'] as double,
        siteLon: site['longitude'] as double,
        allowedRadius: site['radius'] as double,
      );
      geoDistance = geoResult.distance;
      _geoFenceOk = geoResult.isInside;
      setState(() => _geoMsg = geoResult.message);

      if (!_geoFenceOk) {
        _finish(
          false,
          'Outside allowed zone. You are ${(geoResult.distance - geoResult.allowedRadius).toStringAsFixed(0)}m away from ${site['name']}.',
        );
        return;
      }
    } else {
      _geoFenceOk = true;
      setState(() => _geoMsg = 'Geofence: Site data unavailable, bypassed');
      geoDistance = 0;
    }

    setState(() => _geoFenceOk = true);

    // 5. Face verification
    setState(() => _faceMsg = 'Analyzing face...');
    final faceResult = await FaceService.checkFace(_imagePath!);
    _faceOk = faceResult.success;
    setState(() => _faceMsg = faceResult.message);

    if (!_faceOk) {
      _finish(false, faceResult.message);
      return;
    }

    // 6. Record punch
    final punchResult = await AttendanceService.punch(
      employeeId: widget.user['id'] ?? '',
      employeeName: widget.user['name'] ?? '',
      siteId: widget.user['siteId'] as int? ?? 1,
      siteName: widget.user['site'] ?? '',
      type: widget.punchType,
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      geoDistance: geoDistance,
      faceVerified: _faceOk,
      geoVerified: _geoFenceOk,
      faceImagePath: _imagePath,
    );

    _finish(punchResult.success, 'Attendance recorded successfully!');
  }

  void _finish(bool success, String message) {
    setState(() {
      _step = PunchStep.result;
      _success = success;
      _statusMsg = message;
    });
    if (success) widget.onPunchSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(
          widget.punchType == 'in' ? 'Punch In' : 'Punch Out',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case PunchStep.camera:
        return _buildCamera();
      case PunchStep.verifying:
        return _buildVerifying();
      case PunchStep.result:
        return _buildResult();
    }
  }

  Widget _buildCamera() {
    return Column(
      children: [
        Expanded(
          child: _cameraReady && _cameraCtrl != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_cameraCtrl!),
                    // Face oval guide
                    Center(
                      child: Container(
                        width: 220,
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.accent, width: 2),
                          borderRadius: BorderRadius.circular(110),
                        ),
                      ),
                    ),
                    // Instructions overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Text(
                          'Look directly at the camera\nKeep your eyes open',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text('Initializing camera...',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          color: AppTheme.surface,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _requirement(Icons.face, 'Face Scan'),
                  _requirement(Icons.location_on, 'GPS'),
                  _requirement(Icons.fence, 'Geofence'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cameraReady ? _capture : null,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    widget.punchType == 'in' ? 'Capture & Punch In' : 'Capture & Punch Out',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.punchType == 'in'
                        ? AppTheme.accent
                        : AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _requirement(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildVerifying() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.accent),
          const SizedBox(height: 32),
          const Text('Verifying...',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          _verifyStep(Icons.gps_fixed, 'GPS', _gpsMsg, _gpsOk),
          _verifyStep(Icons.fence, 'Geofence', _geoMsg, _geoFenceOk),
          _verifyStep(Icons.face, 'Face Detection', _faceMsg, _faceOk),
        ],
      ),
    );
  }

  Widget _verifyStep(IconData icon, String label, String msg, bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: done ? AppTheme.success : AppTheme.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(msg,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (done)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_success ? AppTheme.success : AppTheme.error)
                  .withOpacity(0.15),
            ),
            child: Icon(
              _success ? Icons.check_circle : Icons.cancel,
              color: _success ? AppTheme.success : AppTheme.error,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _success
                ? (widget.punchType == 'in' ? 'Punched In!' : 'Punched Out!')
                : 'Punch Failed',
            style: TextStyle(
              color: _success ? AppTheme.success : AppTheme.error,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _statusMsg,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (_success) ...[
            const SizedBox(height: 12),
            Text(
              DateFormat('hh:mm:ss a · MMM d, yyyy').format(DateTime.now()),
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.card,
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.border),
              ),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }
}
