// lib/presentation/screens/ai_assistant_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/network/ai_service.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../state/ai_config_state.dart';
import 'helper_results_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final DiscoveryApi _discoveryApi = DiscoveryApi();

  List<ServiceCategory> _categories = [];
  bool _loading = false;
  String? _suggestedCategory;
  String? _suggestedDesc;

  static const String _systemPrompt = '''
You are the AI Roadside Mechanic for "Roadside SOS".
Your job is to:
1. Prioritize user safety: if they are on the road, remind them to pull over safely, turn on hazard lights, and stand in a safe place.
2. Ask questions or give diagnostic steps to help them troubleshoot their vehicle issue.
3. Be helpful, concise, and professional.

At the very end of your diagnoses, or if the user asks you to create a booking request, identify the most suitable roadside help category from these five:
- puncture
- fuel
- battery
- breakdown
- towing

Output your suggestion in this exact format on a new line at the end:
[SUGGEST_BOOKING: category_name | brief description of the issue]
Example: [SUGGEST_BOOKING: puncture | Left rear tyre has a flat due to a nail]
''';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Add default welcoming message
    _messages.add(
      ChatMessage(
        role: 'assistant',
        content: 'Hello! I am your AI Roadside Mechanic. Tell me what\'s wrong with your vehicle, and I will help you diagnose the issue, provide safety tips, and guide you to find the right help.',
      ),
    );
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _discoveryApi.categories();
      setState(() {
        _categories = cats;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPrompt(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMsg = ChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    final config = context.read<AiConfigState>();
    final fullHistory = [
      ChatMessage(role: 'system', content: _systemPrompt),
      ..._messages,
    ];

    try {
      final responseText = await _aiService.chat(fullHistory, config);
      
      // Parse suggested booking from response
      final bookingMatch = RegExp(r'\[SUGGEST_BOOKING:\s*(.*?)\s*\|\s*(.*?)\]').firstMatch(responseText);
      String cleanResponse = responseText;
      String? matchedCat;
      String? matchedDesc;
      
      if (bookingMatch != null) {
        matchedCat = bookingMatch.group(1)?.trim();
        matchedDesc = bookingMatch.group(2)?.trim();
        cleanResponse = responseText.replaceAll(RegExp(r'\[SUGGEST_BOOKING:.*?\]'), '').trim();
      }

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: cleanResponse));
        if (matchedCat != null) {
          _suggestedCategory = matchedCat;
          _suggestedDesc = matchedDesc;
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: 'Sorry, I encountered an error communicating with the AI client: $e.\nPlease verify your settings or endpoint configuration.',
          ),
        );
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _onQuickPrompt(String prompt) {
    _sendPrompt(prompt);
  }

  void _navigateToBooking() async {
    if (_suggestedCategory == null) return;
    
    // Attempt to map string to actual category
    ServiceCategory? matchedCategory;
    for (final cat in _categories) {
      if (cat.key.toLowerCase() == _suggestedCategory!.toLowerCase()) {
        matchedCategory = cat;
        break;
      }
    }
    
    // Fallback if no match
    if (matchedCategory == null && _categories.isNotEmpty) {
      matchedCategory = _categories.firstWhere(
        (c) => c.key == 'breakdown', 
        orElse: () => _categories.first,
      );
    }

    if (matchedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No categories available yet. Please check your internet connection.')),
      );
      return;
    }

    // Fetch user location
    double lat = 17.4239;
    double lng = 78.4738;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HelperResultsScreen(
            category: matchedCategory!,
            lat: lat,
            lng: lng,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0E7C52).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, color: Color(0xFF0E7C52), size: 20),
            ),
            const SizedBox(width: 8),
            Text(context.tr('ai_assistant')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggested Category Notification Panel
          if (_suggestedCategory != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF18B26B), Color(0xFF0E7C52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x280E7C52), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Text('🔧', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diagnostic Match: ${_suggestedCategory!.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (_suggestedDesc != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _suggestedDesc!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0E7C52),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      context.tr('ai_suggest_prefill'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),

          // Messages View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0E7C52)
                          : (isDark ? Colors.grey[900] : const Color(0xFFEBEFEF)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0E7C52)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Mechanic is typing...',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.tertiary),
                  ),
                ],
              ),
            ),

          // Quick Starter chips when no conversation is active
          if (_messages.length == 1 && !_loading)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickPromptChip(
                    label: '🛞 Flat Tyre',
                    onTap: () => _onQuickPrompt('I have a tyre puncture and need assistance changing it.'),
                  ),
                  _QuickPromptChip(
                    label: '🌡️ Overheating Engine',
                    onTap: () => _onQuickPrompt('My engine temperature indicator is in the red. What should I do?'),
                  ),
                  _QuickPromptChip(
                    label: '🔋 Dead Battery',
                    onTap: () => _onQuickPrompt('My car battery is dead and I need a jump start.'),
                  ),
                  _QuickPromptChip(
                    label: '⛽ Out of Fuel',
                    onTap: () => _onQuickPrompt('I have run out of fuel on the highway and need refuel assistance.'),
                  ),
                ],
              ),
            ),

          // Message Input Field
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                elevation: 0,
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: const InputDecoration(
                            hintText: 'Describe your issue...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: _sendPrompt,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF0E7C52)),
                        onPressed: () => _sendPrompt(_inputController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickPromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE7ECEA), width: 1.5),
      ),
    );
  }
}
