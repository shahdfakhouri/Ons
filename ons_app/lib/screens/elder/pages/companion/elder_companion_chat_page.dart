import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_companion_api.dart.dart';

class ElderCompanionChatPage extends StatefulWidget {
  const ElderCompanionChatPage({super.key});

  @override
  State<ElderCompanionChatPage> createState() => _ElderCompanionChatPageState();
}

class _ElderCompanionChatPageState extends State<ElderCompanionChatPage> {
  final _svc = CompanionService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  String? _conversationId;
  bool _sending = false;

  final List<_ChatMsg> _messages = [
    _ChatMsg(role: 'assistant', text: 'Hello 🌿 I’m here with you. How are you feeling today?'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMsg(role: 'user', text: text));
      _ctrl.clear();
    });

    _jumpToBottom();

    try {
      final data = await _svc.chat(
        message: text,
        conversationId: _conversationId,
      );

      final reply = (data['reply'] ?? '').toString();
      final convId = (data['conversationId'] ?? '').toString();

      setState(() {
        _conversationId = convId.isEmpty ? _conversationId : convId;
        _messages.add(_ChatMsg(role: 'assistant', text: reply.isEmpty ? 'I’m here with you.' : reply));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg(role: 'assistant', text: 'Sorry, I couldn’t reply. Please try again.'));
      });
    } finally {
      setState(() => _sending = false);
      _jumpToBottom();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;               // ✅ add
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Companion'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isMe = m.role == 'user';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: isMe ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        color: isMe ? cs.onPrimary : cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // later: speech-to-text
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice input coming soon 🎤')),
                      );
                    },
                    icon: const Icon(Icons.mic),
                    iconSize: 28,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type here…',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Icon(Icons.send),
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

class _ChatMsg {
  final String role; // 'user' or 'assistant'
  final String text;
  _ChatMsg({required this.role, required this.text});
}
