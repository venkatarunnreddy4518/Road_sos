import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../data/api/auth_api.dart';
import '../../state/auth_state.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _api = AuthApi();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _devCode;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phone.text.trim().length < 6) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final dev = await _api.requestOtp(_phone.text.trim());
      setState(() {
        _codeSent = true;
        _devCode = dev;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await _api.verifyOtp(_phone.text.trim(), _code.text.trim(), name: _name.text.trim());
      if (!mounted) return;
      context.read<AuthState>().onSignedIn(user);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('continue_phone'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _phone,
                enabled: !_codeSent,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: context.tr('phone'),
                    hintText: '+91 98765 43210',
                    border: const OutlineInputBorder()),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                      labelText: '${context.tr('name')} (optional)', border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: context.tr('enter_code'), border: const OutlineInputBorder()),
                ),
                 if (_devCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFFF2F2F7)
                              : const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Dev mode: your code is $_devCode',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary),
                onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                child: _busy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                    : Text(_codeSent ? context.tr('verify') : context.tr('send_code')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
