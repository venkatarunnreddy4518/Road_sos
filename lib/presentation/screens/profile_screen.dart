import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/profile_api.dart';
import '../state/auth_state.dart';
import 'auth/email_auth_screen.dart';
import 'provider/provider_inbox_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ProfileApi();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _vehicle = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _api.update(
        displayName: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        vehicleInfo: _vehicle.text.trim(),
      );
      if (!mounted) return;
      context.read<AuthState>().setUser(updated);
      setState(() => _editing = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAuthenticated) {
      return _GuestPrompt();
    }

    final user = auth.user!;
    if (!_editing) {
      _name.text = user.displayName;
      _phone.text = user.phone ?? '';
      _vehicle.text = user.vehicleInfo ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFDF6E3),
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            enabled: _editing,
            decoration: InputDecoration(labelText: context.tr('name'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: _editing,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: context.tr('phone'), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicle,
            enabled: _editing,
            decoration: const InputDecoration(labelText: 'Vehicle (e.g. Honda Activa)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          if (_editing)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('submit')),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit),
              label: const Text('Edit profile'),
            ),
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.handyman),
            title: Text(context.tr('provider_mode')),
            subtitle: const Text('Receive and accept roadside requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProviderInboxScreen())),
          ),
        ],
      ),
    );
  }
}

class _GuestPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 56, color: Colors.black38),
              const SizedBox(height: 12),
              const Text('Sign in to manage your profile and history',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmailAuthScreen())),
                child: Text(context.tr('login')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
