import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  static const _userKey = 'current_user';
  static const _tokenKey = 'auth_token';

  // Demo users — replace with real API calls in production
  static final List<Map<String, dynamic>> _demoUsers = [
    {
      'id': 'emp001',
      'name': 'Rajesh Kumar',
      'email': 'rajesh@plant.com',
      'password': _hash('emp123'),
      'role': 'employee',
      'employeeId': 'EMP-001',
      'site': 'Jindal Stainless – Unit A',
      'siteId': 1,
      'shift': 'Morning',
      'photoUrl': '',
      'deviceBound': false,
    },
    {
      'id': 'emp002',
      'name': 'Priya Sharma',
      'email': 'priya@plant.com',
      'password': _hash('emp123'),
      'role': 'employee',
      'employeeId': 'EMP-002',
      'site': 'Corporate HQ',
      'siteId': 3,
      'shift': 'Day',
      'photoUrl': '',
      'deviceBound': false,
    },
    {
      'id': 'adm001',
      'name': 'Admin Manager',
      'email': 'admin@plant.com',
      'password': _hash('admin123'),
      'role': 'admin',
      'employeeId': 'ADM-001',
      'site': 'All Sites',
      'siteId': 0,
      'shift': 'N/A',
      'photoUrl': '',
      'deviceBound': false,
    },
  ];

  static String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800)); // simulate API

    final user = _demoUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == _hash(password),
      orElse: () => {},
    );

    if (user.isEmpty) return null;

    // Generate simple token
    final token = _hash('${user['id']}_${DateTime.now().millisecondsSinceEpoch}');
    final userCopy = Map<String, dynamic>.from(user)..remove('password');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userCopy));
    await prefs.setString(_tokenKey, token);

    return userCopy;
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Admin: get all users
  static List<Map<String, dynamic>> getAllUsers() {
    return _demoUsers
        .map((u) => Map<String, dynamic>.from(u)..remove('password'))
        .toList();
  }
}
