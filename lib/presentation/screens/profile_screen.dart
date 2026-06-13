import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/strings.dart';

import '../state/auth_state.dart';
import '../utils/helper_actions.dart';
import 'auth/email_auth_screen.dart';
import 'history_screen.dart';
import 'provider/provider_inbox_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Design tokens from HTML ──
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFECEEF4);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryLight = Color(0xFFEEF3FF);
  static const Color _green = Color(0xFF16A34A);
  static const Color _greenLight = Color(0xFFDCFCE7);
  static const Color _text = Color(0xFF0F172A);
  static const Color _sub = Color(0xFF64748B);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _red = Color(0xFFDC2626);

  // Dynamic lists to make profile options fully functional
  final List<String> _vehicles = [
    'Maruti Suzuki Swift (White) - MH-12-AB-1234',
    'Royal Enfield Classic 350 (Black) - MH-12-CD-5678',
  ];

  final List<Map<String, String>> _payments = [
    {'type': 'UPI', 'detail': 'arunn@okaxis', 'name': 'Google Pay'},
    {'type': 'Card', 'detail': 'Visa ending in 4321', 'name': 'HDFC Bank'},
  ];

  final List<Map<String, String>> _contacts = [
    {'name': 'Dad', 'phone': '+91 98765 43210'},
    {'name': 'Spouse', 'phone': '+91 98765 43211'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    final vehiclesList = prefs.getStringList('profile_vehicles');
    if (vehiclesList != null) {
      _vehicles.clear();
      _vehicles.addAll(vehiclesList);
    }
    final paymentsJson = prefs.getString('profile_payments');
    if (paymentsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(paymentsJson);
        _payments.clear();
        for (final item in decoded) {
          _payments.add(Map<String, String>.from(item as Map));
        }
      } catch (_) {}
    }
    final contactsJson = prefs.getString('profile_contacts');
    if (contactsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        _contacts.clear();
        for (final item in decoded) {
          _contacts.add(Map<String, String>.from(item as Map));
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('profile_vehicles', _vehicles);
  }

  Future<void> _savePayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_payments', jsonEncode(_payments));
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_contacts', jsonEncode(_contacts));
  }

  void _showVehiclesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'My Vehicles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_vehicles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No vehicles added yet.',
                          style: TextStyle(color: _sub, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._vehicles.map((v) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _border, width: 1.5),
                        ),
                        child: ListTile(
                          leading: const Text('🚗', style: TextStyle(fontSize: 20)),
                          title: Text(
                            v,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _text,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: _red),
                            onPressed: () {
                              setSheetState(() => _vehicles.remove(v));
                              _saveVehicles();
                              setState(() {}); // refresh profile count
                            },
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showAddVehicleDialog(setSheetState),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add Vehicle',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddVehicleDialog(StateSetter setSheetState) {
    final modelController = TextEditingController();
    final plateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add New Vehicle',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model (e.g. Swift White)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'License Plate (e.g. MH-12-AB-1234)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                final model = modelController.text.trim();
                final plate = plateController.text.trim();
                if (model.isNotEmpty && plate.isNotEmpty) {
                  final vehicleStr = '$model - $plate';
                  setSheetState(() => _vehicles.add(vehicleStr));
                  _saveVehicles();
                  setState(() {}); // refresh profile count
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No payment methods linked.',
                          style: TextStyle(color: _sub, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._payments.map((p) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _border, width: 1.5),
                        ),
                        child: ListTile(
                          leading: Text(p['type'] == 'UPI' ? '📱' : '💳', style: const TextStyle(fontSize: 20)),
                          title: Text(
                            p['name']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _text,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          subtitle: Text(
                            p['detail']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _sub,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.link_off, color: _red),
                            onPressed: () {
                              setSheetState(() => _payments.remove(p));
                              _savePayments();
                              setState(() {}); // refresh subtitle/state
                            },
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primary, width: 1.5),
                        foregroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showAddPaymentDialog(setSheetState),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Link New Payment Method',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTransactionItem('Puncture Service', '₹450.00', '12 Jun 2026', 'Success'),
                  _buildTransactionItem('Petrol Delivery (5L)', '₹680.00', '08 Jun 2026', 'Success'),
                  _buildTransactionItem('Towing (12 km)', '₹1,500.00', '28 May 2026', 'Success'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(String title, String amount, String date, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: _muted, fontFamily: 'Outfit'),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _text, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _green, fontFamily: 'Outfit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(StateSetter setSheetState) {
    final upiController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Link UPI Address',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: upiController,
            decoration: const InputDecoration(
              labelText: 'UPI ID (e.g. name@okaxis)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                final upi = upiController.text.trim();
                if (upi.isNotEmpty) {
                  setSheetState(() => _payments.add({
                    'type': 'UPI',
                    'detail': upi,
                    'name': 'Linked UPI Payment',
                  }));
                  _savePayments();
                  setState(() {}); // refresh subtitle/state
                  Navigator.pop(context);
                }
              },
              child: const Text('Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showContactsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'In case of emergency, these contacts can be notified instantly with your location.',
                    style: TextStyle(fontSize: 11.5, color: _sub, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  if (_contacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No contacts added.',
                          style: TextStyle(color: _sub, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._contacts.map((c) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _border, width: 1.5),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: _primaryLight,
                            child: Icon(Icons.person, color: _primary, size: 20),
                          ),
                          title: Text(
                            c['name']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _text,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          subtitle: Text(
                            c['phone']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _sub,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.phone, color: _green),
                                onPressed: () => HelperActions.call(c['phone']!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: _red),
                                onPressed: () {
                                  setSheetState(() => _contacts.remove(c));
                                  _saveContacts();
                                  setState(() {}); // refresh profile count
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _showAddContactDialog(setSheetState),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add Emergency Contact',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddContactDialog(StateSetter setSheetState) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. Dad)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  setSheetState(() => _contacts.add({'name': name, 'phone': phone}));
                  _saveContacts();
                  setState(() {}); // refresh profile count
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSafetySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Roadside Safety Guidelines',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSafetyTipCard('🚨 1. Turn on Hazard Lights', 'Immediately turn on your hazard lights (double-indicator) to warn other highway traffic.'),
                  _buildSafetyTipCard('🚗 2. Pull Over Safely', 'Move your vehicle to the left-most hard shoulder or emergency lane, away from moving traffic streams.'),
                  _buildSafetyTipCard('🦺 3. Wear High-Visibility Gear', 'If you have a reflective vest, put it on before exiting the vehicle.'),
                  _buildSafetyTipCard('🚧 4. Place Warning Triangle', 'Place your reflective warning triangle 50 meters behind your vehicle to alert incoming motorists.'),
                  _buildSafetyTipCard('🌳 5. Wait in a Safe Area', 'Exit the vehicle from the passenger side (away from traffic) and stand behind the safety barrier or guardrail.'),
                  const SizedBox(height: 20),
                  const Text(
                    'Emergency Helplines',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: _border, width: 1.5),
                    ),
                    child: ListTile(
                      title: const Text('National Highway Helpline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit')),
                      subtitle: const Text('1033', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                      trailing: const Icon(Icons.phone, color: _green),
                      onTap: () => HelperActions.call('1033'),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: _border, width: 1.5),
                    ),
                    child: ListTile(
                      title: const Text('National Emergency Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit')),
                      subtitle: const Text('112', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                      trailing: const Icon(Icons.phone, color: _green),
                      onTap: () => HelperActions.call('112'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSafetyTipCard(String title, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: _text, fontFamily: 'Outfit')),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 11.5, color: _sub, height: 1.3, fontFamily: 'Outfit')),
          ],
        ),
      ),
    );
  }

  void _showReferEarnSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Refer & Earn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share the safety. Invite your friends to Roadside SOS and both of you will receive ₹50 in wallet credits on their first completed emergency booking.',
                style: TextStyle(fontSize: 12.5, color: _sub, height: 1.35, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Referral Code', style: TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                        SizedBox(height: 3),
                        Text(
                          'SOS-REF-8849',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text, letterSpacing: 0.5, fontFamily: 'Outfit'),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'SOS-REF-8849'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Referral code copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showHelpSupportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Help & Customer Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: _border, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Text('📞', style: TextStyle(fontSize: 18)),
                          title: const Text('Call Helpline support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                          subtitle: const Text('24/7 dedicated telephone support lines', style: TextStyle(fontSize: 10.5, color: _sub, fontFamily: 'Outfit')),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => HelperActions.call('1033'),
                        ),
                        const Divider(height: 1, color: _border),
                        ListTile(
                          leading: const Text('✉️', style: TextStyle(fontSize: 18)),
                          title: const Text('Email Support Desk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                          subtitle: const Text('support@roadsidesos.in', style: TextStyle(fontSize: 10.5, color: _sub, fontFamily: 'Outfit')),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Frequently Asked Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _text, fontFamily: 'Outfit')),
                  const SizedBox(height: 10),
                  _buildFaqItem('How fast will a mechanic arrive?', 'Usually within 15 to 30 minutes depending on your distance from the nearest active shop. You can track their moving location in real-time.'),
                  _buildFaqItem('How is pricing calculated?', 'Emergency service call-outs have flat rates set by mechanics depending on the service category. Any replacement parts or extra repairs will be charged separately.'),
                  _buildFaqItem('What if there is no internet connection?', 'Roadside SOS works offline. The app automatically lists locally cached shops from your database and allows you to submit direct call or SMS assistance requests.'),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border, width: 1.5),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _text, fontFamily: 'Outfit')),
        childrenPadding: const EdgeInsets.all(14),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(answer, style: const TextStyle(fontSize: 12, color: _sub, height: 1.35, fontFamily: 'Outfit')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _sub,
          letterSpacing: 0.4,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildItem({
    required String emoji,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isLast = false,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? _text,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _muted,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  const Text(
                    '›',
                    style: TextStyle(
                      fontSize: 18,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              thickness: 1,
              color: _border,
              indent: 0,
              endIndent: 0,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAuthenticated) {
      return const _GuestPrompt();
    }

    final user = auth.user!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // Header (c2-top)
            Container(
              color: _white,
              padding: const EdgeInsets.only(top: 30, bottom: 20, left: 20, right: 20),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primary,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '👤',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : 'Arunn Reddy',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? user.phone ?? 'demo.user@gmail.com',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _muted,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _greenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              '4.8 Rating',
                              style: TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🚗', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              '${_vehicles.length} Vehicles',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _border),

            // Account Section
            _AnimatedCard(
              delay: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account'),
                  _buildSectionCard([
                    _buildItem(
                      emoji: '🚗',
                      title: context.tr('saved_vehicles'),
                      subtitle: '${_vehicles.length} ${context.tr('vehicles_suffix')}',
                      onTap: _showVehiclesSheet,
                    ),
                    _buildItem(
                      emoji: '💳',
                      title: context.tr('payments'),
                      subtitle: '${_payments.length} linked',
                      onTap: _showPaymentsSheet,
                    ),
                    _buildItem(
                      emoji: '🕐',
                      title: context.tr('my_sos'),
                      isLast: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Safety Section
            _AnimatedCard(
              delay: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Safety'),
                  _buildSectionCard([
                    _buildItem(
                      emoji: '🛡️',
                      title: context.tr('safety'),
                      onTap: _showSafetySheet,
                    ),
                    _buildItem(
                      emoji: '📞',
                      title: context.tr('emergency_contacts'),
                      subtitle: '${_contacts.length} ${context.tr('added_suffix')}',
                      isLast: true,
                      onTap: _showContactsSheet,
                    ),
                  ]),
                ],
              ),
            ),

            // More Section
            _AnimatedCard(
              delay: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('More'),
                  _buildSectionCard([
                    _buildItem(
                      emoji: '🎁',
                      title: context.tr('refer_earn'),
                      subtitle: context.tr('get_50'),
                      onTap: _showReferEarnSheet,
                    ),
                    _buildItem(
                      emoji: '🌐',
                      title: context.tr('app_language'),
                      subtitle: AppStrings.languageNames[context.watch<LocaleController>().code],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    _buildItem(
                      emoji: '❓',
                      title: context.tr('help_support'),
                      onTap: _showHelpSupportSheet,
                    ),
                    _buildItem(
                      emoji: '🛠️',
                      title: context.tr('provider_mode'),
                      subtitle: context.tr('provider_sub'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProviderInboxScreen()),
                      ),
                    ),
                    _buildItem(
                      emoji: '🚪',
                      title: context.tr('sign_out'),
                      titleColor: _red,
                      trailing: const Text(
                        '›',
                        style: TextStyle(
                          fontSize: 18,
                          color: _red,
                        ),
                      ),
                      isLast: true,
                      onTap: () async {
                        await context.read<AuthState>().logout();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Version text
            const Center(
              child: Text(
                'Roadside SOS · v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Animated card wrapper ────────────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          return Transform.translate(
            offset: _slide.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// ── Guest prompt ─────────────────────────────────────────────────────────────
class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.colorScheme.surface;
    final text = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.tertiary;
    final green = theme.colorScheme.primary;
    final greenSoft = isDark ? const Color(0xFF143022) : const Color(0xFFE7F6EE);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(Icons.person_outline_rounded,
                        size: 36, color: green),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('sign_in_continue'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('sign_in_profile_prompt'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.colorScheme.secondary, theme.colorScheme.primary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: green.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EmailAuthScreen()),
                        ),
                        child: Center(
                          child: Text(
                            context.tr('login'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
