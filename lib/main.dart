import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/employee/employee_home.dart';
import 'screens/admin/admin_dashboard.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SmartAttendanceApp());
}

class SmartAttendanceApp extends StatefulWidget {
  const SmartAttendanceApp({super.key});

  @override
  State<SmartAttendanceApp> createState() => _SmartAttendanceAppState();
}

class _SmartAttendanceAppState extends State<SmartAttendanceApp> {
  Widget _startScreen = const SplashScreen();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final user = await AuthService.getStoredUser();
    if (!mounted) return;
    if (user == null) {
      setState(() => _startScreen = const LoginScreen());
    } else if (user['role'] == 'admin') {
      setState(() => _startScreen = const AdminDashboard());
    } else {
      setState(() => _startScreen = EmployeeHome(user: user));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _startScreen,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminDashboard(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0070F3), Color(0xFF00C2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'GEO · FACE · SECURE',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00C2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
