// lib/presentation/screens/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/network/ai_service.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../state/ai_config_state.dart';
import 'helper_results_screen.dart';

// ── Design tokens ──
const _bg = Color(0xFFF7F8FA);
const _ink = Color(0xFF14181F);
const _muted = Color(0xFF6B7280);
const _line = Color(0xFFE6E8EC);
const _blue = Color(0xFF2563EB);
const _brand = Color(0xFF7C5CFC); // AI accent (brain)
const _green = Color(0xFF1A9E5C);

/// One quick-pick roadside issue + the structured diagnosis it shows.
class _Issue {
  final String id;
  final String label;
  final IconData icon;
  final Color tile;
  final _Diagnosis diagnosis;
  const _Issue(this.id, this.label, this.icon, this.tile, this.diagnosis);
}

class _Diagnosis {
  final String severity; // low | medium | high
  final String title;
  final List<String> steps;
  final String action;
  final Color actionColor;
  final String categoryKey; // maps to a backend service category
  const _Diagnosis({
    required this.severity,
    required this.title,
    required this.steps,
    required this.action,
    required this.actionColor,
    required this.categoryKey,
  });
}

/// An inline "find help" action attached to a free-text AI reply (from a
/// [SUGGEST_BOOKING] marker).
class _Action {
  final String label;
  final String categoryKey;
  final Color color;
  const _Action(this.label, this.categoryKey, this.color);
}

class _Msg {
  final bool isUser;
  final String? text;
  final _Diagnosis? diagnosis;
  final _Action? action;
  const _Msg.user(this.text)
      : isUser = true,
        diagnosis = null,
        action = null;
  const _Msg.aiText(this.text, {this.action})
      : isUser = false,
        diagnosis = null;
  const _Msg.aiDiagnosis(this.diagnosis)
      : isUser = false,
        text = null,
        action = null;
}

const _quickIssues = <_Issue>[
  _Issue('tyre', 'Flat Tyre', Icons.tire_repair, _blue, _Diagnosis(
    severity: 'low',
    title: 'Flat tyre',
    steps: [
      'Pull over fully onto the shoulder, away from traffic.',
      'Turn on hazard lights before stepping out.',
      'Check if your spare tyre and jack are accessible.',
    ],
    action: 'Find Puncture Fix near me',
    actionColor: _blue,
    categoryKey: 'puncture',
  )),
  _Issue('overheat', 'Engine Overheating', Icons.thermostat, Color(0xFFE5484D), _Diagnosis(
    severity: 'high',
    title: 'Engine overheating',
    steps: [
      'Pull over and turn off the engine immediately.',
      'Do not open the radiator cap while hot.',
      'Wait 20-30 min before checking coolant level.',
    ],
    action: 'Find Mechanic near me',
    actionColor: _brand,
    categoryKey: 'breakdown',
  )),
  _Issue('battery', 'Dead Battery', Icons.battery_alert, _green, _Diagnosis(
    severity: 'medium',
    title: 'Dead battery',
    steps: [
      'Switch off all electronics and lights.',
      'Check if cables look corroded or loose.',
      'A jump start can usually get you moving again.',
    ],
    action: 'Find Jump Start near me',
    actionColor: _green,
    categoryKey: 'battery',
  )),
  _Issue('fuel', 'Out of Fuel', Icons.local_gas_station, Color(0xFFF5A623), _Diagnosis(
    severity: 'low',
    title: 'Out of fuel',
    steps: [
      'Move to the left shoulder and turn on hazards.',
      'Note your exact location for the delivery rider.',
      'Fuel delivery usually arrives within 15-20 min.',
    ],
    action: 'Order Fuel Delivery',
    actionColor: Color(0xFFF5A623),
    categoryKey: 'fuel',
  )),
];

({Color bg, Color fg, String label, IconData icon}) _severityStyle(String s) {
  switch (s) {
    case 'high':
      return (bg: const Color(0xFFFDECEC), fg: const Color(0xFFE5484D), label: 'Pull over now', icon: Icons.warning_amber_rounded);
    case 'medium':
      return (bg: const Color(0xFFFFF6E5), fg: const Color(0xFFB07A0E), label: 'Moderate — act soon', icon: Icons.warning_amber_rounded);
    case 'low':
    default:
      return (bg: const Color(0xFFEAFBF1), fg: _green, label: 'Low risk — safe to wait', icon: Icons.check_circle_rounded);
  }
}

({String label, Color color}) _actionFor(String key) {
  switch (key) {
    case 'puncture':
      return (label: 'Find Puncture Fix near me', color: _blue);
    case 'fuel':
      return (label: 'Order Fuel Delivery', color: const Color(0xFFF5A623));
    case 'battery':
      return (label: 'Find Jump Start near me', color: _green);
    case 'towing':
      return (label: 'Find Towing near me', color: const Color(0xFFE5484D));
    case 'breakdown':
    default:
      return (label: 'Find Mechanic near me', color: _brand);
  }
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<_Msg> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final AiService _ai = AiService();
  final DiscoveryApi _discovery = DiscoveryApi();

  List<ServiceCategory> _categories = [];
  bool _thinking = false;

  static const String _systemPrompt = '''
You are the AI Roadside Mechanic for "Roadside SOS".
1. Be a helpful, general assistant: answer general/non-vehicle questions directly and fully. Do NOT refuse general queries.
2. For vehicle, roadside, or mechanical issues:
   a. Prioritize safety: remind the user to pull over safely, switch on hazard lights, and stand in a safe place.
   b. Give clear diagnostic steps or ask troubleshooting questions.
   c. Suggest one of these categories at the end when relevant: puncture, fuel, battery, breakdown, towing.
      Put it on a new line at the very end like:
      [SUGGEST_BOOKING: category_name | brief description]
''';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _messages.add(const _Msg.aiText(
      "Hi, I'm your AI Roadside Mechanic. Tell me what's wrong with your vehicle, "
      "or pick an issue below — I'll help diagnose it, share safety tips, and find the right help nearby.",
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _discovery.categories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg.user(text));
      _thinking = true;
    });
    _scrollToBottom();

    final config = context.read<AiConfigState>();
    final history = <ChatMessage>[
      ChatMessage(role: 'system', content: _systemPrompt),
      ..._messages.where((m) => m.text != null).map(
            (m) => ChatMessage(role: m.isUser ? 'user' : 'assistant', content: m.text!),
          ),
    ];

    try {
      final response = await _ai.chat(history, config);
      final match = RegExp(r'\[SUGGEST_BOOKING:\s*(.*?)\s*\|\s*(.*?)\]').firstMatch(response);
      var clean = response;
      _Action? action;
      if (match != null) {
        final key = (match.group(1) ?? '').trim().toLowerCase();
        clean = response.replaceAll(RegExp(r'\[SUGGEST_BOOKING:.*?\]'), '').trim();
        final a = _actionFor(key);
        action = _Action(a.label, key, a.color);
      }
      if (!mounted) return;
      setState(() => _messages.add(_Msg.aiText(clean.isEmpty ? '…' : clean, action: action)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(const _Msg.aiText(
          "Sorry, I couldn't reach the AI service. Please check your connection or AI settings and try again.")));
    } finally {
      if (mounted) setState(() => _thinking = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendQuickIssue(_Issue issue) async {
    if (_thinking) return;
    setState(() {
      _messages.add(_Msg.user(issue.label));
      _thinking = true;
    });
    _scrollToBottom();
    // Brief, faithful "thinking" beat before the structured diagnosis.
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg.aiDiagnosis(issue.diagnosis));
      _thinking = false;
    });
    _scrollToBottom();
  }

  Future<void> _findHelp(String categoryKey) async {
    ServiceCategory? cat;
    for (final c in _categories) {
      if (c.key.toLowerCase() == categoryKey.toLowerCase()) {
        cat = c;
        break;
      }
    }
    cat ??= _categories.isEmpty
        ? null
        : _categories.firstWhere((c) => c.key == 'breakdown', orElse: () => _categories.first);
    if (cat == null) return;

    double lat = 17.4239, lng = 78.4738;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HelperResultsScreen(category: cat!, lat: lat, lng: lng),
    ));
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
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.psychology_rounded, size: 18, color: _brand),
            ),
            const SizedBox(width: 12),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Roadside Mechanic',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _ink)),
                Row(children: [
                  _Dot(),
                  SizedBox(width: 5),
                  Text('Online · responds instantly',
                      style: TextStyle(fontSize: 11.5, color: _green, fontWeight: FontWeight.w500)),
                ]),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (_thinking && i == _messages.length) return const _TypingRow();
                return _MessageRow(msg: _messages[i], onFindHelp: _findHelp);
              },
            ),
          ),

          // Quick issue cards (2x2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 4.2,
              children:
                  _quickIssues.map((q) => _QuickIssueCard(issue: q, onTap: () => _sendQuickIssue(q))).toList(),
            ),
          ),

          // Input bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  _SquareButton(
                    icon: Icons.mic_none_rounded,
                    iconColor: _muted,
                    bg: Colors.white,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice input coming soon')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendText,
                        style: const TextStyle(fontSize: 13.5, color: _ink),
                        decoration: const InputDecoration(
                          hintText: 'Describe your issue...',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SquareButton(
                    icon: Icons.send_rounded,
                    iconColor: Colors.white,
                    bg: _blue,
                    onTap: () => _sendText(_input.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) =>
      Container(width: 6, height: 6, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle));
}

/// One message row: AI (brain avatar + bubble/diagnosis) or user (blue bubble).
class _MessageRow extends StatelessWidget {
  final _Msg msg;
  final void Function(String categoryKey) onFindHelp;
  const _MessageRow({required this.msg, required this.onFindHelp});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _brand.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.psychology_rounded, size: 14, color: _brand),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: msg.diagnosis != null
                ? _DiagnosisCard(diag: msg.diagnosis!, onFindHelp: onFindHelp)
                : _Bubble(text: msg.text ?? '', isUser: isUser, action: msg.action, onFindHelp: onFindHelp),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final _Action? action;
  final void Function(String categoryKey) onFindHelp;
  const _Bubble({required this.text, required this.isUser, this.action, required this.onFindHelp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? _blue : Colors.white,
            border: isUser ? null : Border.all(color: _line),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUser ? 14 : 4),
              topRight: Radius.circular(isUser ? 4 : 14),
              bottomLeft: const Radius.circular(14),
              bottomRight: const Radius.circular(14),
            ),
          ),
          child: Text(text,
              style: TextStyle(
                  color: isUser ? Colors.white : _ink, fontSize: 13.5, height: 1.5)),
        ),
        if (action != null) ...[
          const SizedBox(height: 8),
          _ActionButton(label: action!.label, color: action!.color, onTap: () => onFindHelp(action!.categoryKey)),
        ],
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final _Diagnosis diag;
  final void Function(String categoryKey) onFindHelp;
  const _DiagnosisCard({required this.diag, required this.onFindHelp});

  @override
  Widget build(BuildContext context) {
    final sev = _severityStyle(diag.severity);
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: sev.bg, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(sev.icon, size: 13, color: sev.fg),
              const SizedBox(width: 6),
              Text(sev.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sev.fg)),
            ]),
          ),
          const SizedBox(height: 10),
          Text(diag.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _ink)),
          const SizedBox(height: 8),
          ...List.generate(diag.steps.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _muted)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(diag.steps[i],
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.4)),
                  ),
                ]),
              )),
          const SizedBox(height: 6),
          _ActionButton(label: diag.action, color: diag.actionColor, onTap: () => onFindHelp(diag.categoryKey)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _QuickIssueCard extends StatelessWidget {
  final _Issue issue;
  final VoidCallback onTap;
  const _QuickIssueCard({required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: issue.tile.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(9)),
              child: Icon(issue.icon, size: 16, color: issue.tile),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(issue.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.iconColor, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: bg == Colors.white ? Border.all(color: _line) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _brand.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: const Icon(Icons.psychology_rounded, size: 14, color: _brand),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _line),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: _TypingDots(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_c.value - i * 0.15) % 1.0);
            final lift = (t < 0.3) ? (t / 0.3) : (t < 0.6 ? (1 - (t - 0.3) / 0.3) : 0.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -3 * lift),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9CA3AF).withValues(alpha: 0.4 + 0.6 * lift),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
