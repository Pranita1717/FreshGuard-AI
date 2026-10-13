import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/api_config.dart';
import '../services/session.dart';
import '../widgets/app_shell.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _serverIpCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _healthStatus;
  bool _isTestingHealth = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final session = Session();
    _nameCtrl.text = session.name ?? '';
    _storeNameCtrl.text = session.storeName ?? '';
    _serverIpCtrl.text = ApiConfig.activeBaseUrl;

    try {
      final profile = await ApiService().getProfile();
      if (mounted) {
        setState(() {
          _nameCtrl.text = profile['name'] ?? session.name ?? '';
          _phoneCtrl.text = profile['phone'] ?? '';
          _storeNameCtrl.text = profile['storeName'] ?? session.storeName ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        // Store assignment is fixed by the account and is not editable here.
      );
      final session = Session();
      await session.saveSession(
        token: session.token ?? '',
        id: session.id ?? '',
        name: _nameCtrl.text.trim(),
        email: session.email ?? '',
        role: session.role ?? '',
        storeName: session.storeName ?? '',
        // Store assignment is fixed by the account and is not editable here.
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details updated successfully!'), backgroundColor: Color(0xFF168B45)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _testHealth() async {
    setState(() {
      _isTestingHealth = true;
      _healthStatus = null;
    });

    try {
      final res = await ApiService().get('/health');
      if (!mounted) return;
      setState(() {
        _healthStatus = 'Active & Connected • Database Status: ${res['database'] ?? "Synced"}';
        _isTestingHealth = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthStatus = 'Service Offline: Check network connection';
        _isTestingHealth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Session();
    final role = session.role;
    int navIndex = 6;
    if (role == 'ADMIN') {
      navIndex = -1;
    } else if (role == 'STORE_MANAGER') {
      navIndex = 10;
    }

    return AppShell(
      title: role == 'ADMIN' ? 'System Infrastructure & Settings' : 'User Profile',
      selectedIndex: navIndex,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF168B45)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role == 'ADMIN' ? 'System Infrastructure & Service Settings' : 'User Profile Details',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == 'ADMIN'
                            ? 'Manage enterprise cluster connection, gateway routing, and platform infrastructure.'
                            : 'View and update your staff contact credentials and store branch assignment.',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Staff Account Information',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFF168B45).withAlpha(30),
                                  child: Text(
                                    (_nameCtrl.text.isNotEmpty) ? _nameCtrl.text[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF168B45)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_nameCtrl.text.isEmpty ? 'Staff User' : _nameCtrl.text,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Email: ${session.email ?? "user@freshguard.local"}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF168B45).withAlpha(20),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          session.role ?? 'USER',
                                          style: const TextStyle(
                                              color: Color(0xFF168B45), fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 600;

                                if (isWide) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _nameCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Full Name',
                                                prefixIcon: Icon(Icons.person_outline),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: TextField(
                                              controller: _phoneCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Contact Phone',
                                                prefixIcon: Icon(Icons.phone_outlined),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _storeNameCtrl,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Store Branch Name',
                                          prefixIcon: Icon(Icons.storefront_outlined),
                                          helperText: 'Store assignment is controlled by the account.',
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    TextField(
                                      controller: _nameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _phoneCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Contact Phone',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _storeNameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Store Branch Name',
                                        prefixIcon: Icon(Icons.storefront_outlined),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF168B45),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.save),
                                label: Text(_isSaving ? 'Saving...' : 'Save Profile Changes'),
                                onPressed: _isSaving ? null : _saveProfile,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (role == 'ADMIN') ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Enterprise Gateway Connection',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _serverIpCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Enterprise Gateway URL',
                                  prefixIcon: Icon(Icons.lan_outlined),
                                  helperText: 'Configure active gateway endpoint for remote network connectivity.',
                                ),
                                onChanged: (v) {
                                  if (v.trim().isNotEmpty) {
                                    ApiConfig.setCustomBaseUrl(v.trim());
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth >= 500;

                                  if (isWide) {
                                    return Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0284C7),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: _isTestingHealth
                                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Icon(Icons.network_check, size: 18),
                                          label: const Text('Test Gateway Health'),
                                          onPressed: _isTestingHealth ? null : _testHealth,
                                        ),
                                        const SizedBox(width: 16),
                                        if (_healthStatus != null)
                                          Expanded(
                                            child: Text(
                                              _healthStatus!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: _healthStatus!.startsWith('Active') ? const Color(0xFF168B45) : Colors.red,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0284C7),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: _isTestingHealth
                                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.network_check, size: 18),
                                        label: const Text('Test Gateway Health'),
                                        onPressed: _isTestingHealth ? null : _testHealth,
                                      ),
                                      if (_healthStatus != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _healthStatus!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _healthStatus!.startsWith('Active') ? const Color(0xFF168B45) : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
