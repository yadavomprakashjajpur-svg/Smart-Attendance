import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AddUserScreen extends StatefulWidget {
  final Map<String, dynamic>? existingUser;
  const AddUserScreen({super.key, this.existingUser});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'employee';
  String _shift = 'Morning';
  int _siteId = 1;
  bool _saving = false;

  final _sites = [
    {'id': 1, 'name': 'Jindal Stainless – Unit A'},
    {'id': 2, 'name': 'Plant – Steel Rolling'},
    {'id': 3, 'name': 'Corporate HQ'},
    {'id': 4, 'name': 'Warehouse – North Depot'},
  ];

  final _shifts = ['Morning', 'Day', 'Night', '24/7'];

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    if (u != null) {
      _nameCtrl.text = u['name'] ?? '';
      _emailCtrl.text = u['email'] ?? '';
      _empIdCtrl.text = u['employeeId'] ?? '';
      _role = u['role'] ?? 'employee';
      _shift = u['shift'] ?? 'Morning';
      _siteId = u['siteId'] ?? 1;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _empIdCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800)); // simulate API
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingUser == null
            ? 'User created successfully'
            : 'User updated'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingUser != null;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(isEdit ? 'Edit Employee' : 'Add Employee',
            style: const TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accent))
                : const Text('Save',
                    style: TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar placeholder
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.card,
                    child: const Icon(Icons.person, size: 40, color: AppTheme.textMuted),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Tap to register face photo',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 24),

            _label('Full Name'),
            _field(_nameCtrl, 'e.g. Rajesh Kumar', Icons.person_outline),
            const SizedBox(height: 16),

            _label('Email Address'),
            _field(_emailCtrl, 'e.g. rajesh@plant.com', Icons.email_outlined,
                type: TextInputType.emailAddress),
            const SizedBox(height: 16),

            _label('Employee ID'),
            _field(_empIdCtrl, 'e.g. EMP-001', Icons.badge_outlined),
            const SizedBox(height: 16),

            if (!isEdit) ...[
              _label('Password'),
              _field(_passCtrl, 'Min 8 characters', Icons.lock_outline,
                  obscure: true),
              const SizedBox(height: 16),
            ],

            _label('Role'),
            _dropdown<String>(
              value: _role,
              items: const ['employee', 'admin'],
              labels: const ['Employee', 'Admin'],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 16),

            _label('Assigned Site'),
            _dropdown<int>(
              value: _siteId,
              items: _sites.map((s) => s['id'] as int).toList(),
              labels: _sites.map((s) => s['name'] as String).toList(),
              onChanged: (v) => setState(() => _siteId = v!),
            ),
            const SizedBox(height: 16),

            _label('Shift'),
            _dropdown<String>(
              value: _shift,
              items: _shifts,
              labels: _shifts,
              onChanged: (v) => setState(() => _shift = v!),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: Icon(isEdit ? Icons.save : Icons.person_add),
                label: Text(isEdit ? 'Update Employee' : 'Create Employee'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required List<String> labels,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: AppTheme.card,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: const InputDecoration(),
      items: List.generate(items.length, (i) {
        return DropdownMenuItem<T>(
          value: items[i],
          child: Text(labels[i]),
        );
      }),
      onChanged: onChanged,
    );
  }
}
