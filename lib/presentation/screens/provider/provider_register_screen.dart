// lib/presentation/screens/provider/provider_register_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/api/profile_api.dart';
import 'provider_inbox_screen.dart';

/// Provider onboarding: register a service (helper profile) so the user starts
/// receiving nearby roadside requests. Maps to ProfileApi.upsertHelper.
class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _Service {
  final String type; // backend helper_type
  final String label;
  final IconData icon;
  final Color color;
  const _Service(this.type, this.label, this.icon, this.color);
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _api = ProfileApi();
  String _type = 'mechanic';
  bool _submitting = false;

  static const _bg = Color(0xFFF7F8FA);
  static const _ink = Color(0xFF14181F);
  static const _line = Color(0xFFE6E8EC);
  static const _green = Color(0xFF1A9E5C);
  static const _muted = Color(0xFF9CA3AF);

  static const _services = <_Service>[
    _Service('mechanic', 'Mechanic', Icons.build_rounded, Color(0xFF7C5CFC)),
    _Service('puncture_shop', 'Puncture', Icons.tire_repair_rounded, Color(0xFF2563EB)),
    _Service('petrol_pump', 'Fuel', Icons.local_gas_station_rounded, Color(0xFFF5A623)),
    _Service('battery', 'Battery', Icons.battery_charging_full_rounded, _green),
    _Service('towing', 'Towing', Icons.local_shipping_rounded, Color(0xFFE5484D)),
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _register() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Please enter a service name');
      return;
    }
    setState(() => _submitting = true);
    double lat = 17.4239, lng = 78.4738;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}
    try {
      await _api.upsertHelper(
        name: name,
        helperType: _type,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        latitude: lat,
        longitude: lng,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You're online — requests will appear in your inbox.")));
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProviderInboxScreen()));
    } catch (e) {
      if (mounted) _snack('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _ink,
        title: const Text('Provider Mode',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'Outfit')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Intro banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFEAFBF1), borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.work_outline_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Register your service to receive nearby roadside requests and start earning on Roadside SOS.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF3B7A57), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Service name
          _label('Service name'),
          _field(_name, "e.g. Ravi's Auto Garage"),
          const SizedBox(height: 16),

          // Service type
          _label('Service type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((s) {
              final active = _type == s.type;
              return GestureDetector(
                onTap: () => setState(() => _type = s.type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? s.color.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? s.color : _line, width: active ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, size: 14, color: active ? s.color : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(s.label,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: active ? s.color : const Color(0xFF6B7280))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Contact phone
          _label('Contact phone'),
          _field(_phone, '+91 98765 43210', icon: Icons.phone_rounded, keyboard: TextInputType.phone),
          const SizedBox(height: 20),

          // CTA
          GestureDetector(
            onTap: _submitting ? null : _register,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded, size: 17, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Register & go online',
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "By registering, you agree to Roadside SOS's provider terms and background verification process.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: _muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      );

  Widget _field(TextEditingController c, String hint, {IconData? icon, TextInputType? keyboard}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          prefixIcon: icon != null ? Icon(icon, size: 18, color: _muted) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
