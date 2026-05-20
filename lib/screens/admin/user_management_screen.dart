import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'add_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late List<Map<String, dynamic>> _users;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _users = AuthService.getAllUsers();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      return (u['name'] as String).toLowerCase().contains(q) ||
          (u['email'] as String).toLowerCase().contains(q) ||
          (u['employeeId'] as String).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
          if (result == true) setState(() => _users = AuthService.getAllUsers());
        },
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by name, email, or ID...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _statPill('${_users.where((u) => u['role'] == 'employee').length} Employees', AppTheme.accent),
                const SizedBox(width: 8),
                _statPill('${_users.where((u) => u['role'] == 'admin').length} Admins', AppTheme.warning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No users found', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _userCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final isAdmin = user['role'] == 'admin';
    final color = isAdmin ? AppTheme.warning : AppTheme.accentBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Text((user['name'] as String)[0].toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(user['name'] as String,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(isAdmin ? 'ADMIN' : 'EMP',
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ]),
                Text(user['email'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text('${user['employeeId']} · ${user['site']} · ${user['shift']} shift',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppTheme.card,
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: AppTheme.accent, size: 16), SizedBox(width: 8), Text('Edit', style: TextStyle(color: AppTheme.textPrimary))])),
              const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.lock_reset, color: AppTheme.warning, size: 16), SizedBox(width: 8), Text('Reset Password', style: TextStyle(color: AppTheme.textPrimary))])),
              const PopupMenuItem(value: 'deactivate', child: Row(children: [Icon(Icons.block, color: AppTheme.error, size: 16), SizedBox(width: 8), Text('Deactivate', style: TextStyle(color: AppTheme.error))])),
            ],
            onSelected: (action) async {
              if (action == 'edit') {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddUserScreen(existingUser: user)));
              }
            },
          ),
        ],
      ),
    );
  }
}
