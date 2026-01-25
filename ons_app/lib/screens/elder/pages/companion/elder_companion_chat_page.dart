import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_companion_api.dart.dart';

class ElderCompanionChatPage extends StatefulWidget {
  final void Function(int index)? onBack;
  const ElderCompanionChatPage({super.key, this.onBack});

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

  void _triggerBack() {
    if (widget.onBack != null) widget.onBack!(0);
  }

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
      final data = await _svc.chat(message: text, conversationId: _conversationId);
      final reply = (data['reply'] ?? '').toString();
      final convId = (data['conversationId'] ?? '').toString();

      setState(() {
        _conversationId = convId.isEmpty ? _conversationId : convId;
        _messages.add(_ChatMsg(role: 'assistant', text: reply.isEmpty ? 'I’m here with you.' : reply));
      });
    } catch (e) {
      setState(() => _messages.add(_ChatMsg(role: 'assistant', text: 'Sorry, please try again.')));
    } finally {
      setState(() => _sending = false);
      _jumpToBottom();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _triggerBack),
          title: const Text('AI Companion'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isMe = m.role == 'user';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF313647) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(fontSize: 18, color: isMe ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.mic), iconSize: 32, onPressed: () {}),
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: !_sending,
                decoration: const InputDecoration(hintText: 'Type here…', border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _sending ? null : _send, child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final String role;
  final String text;
  _ChatMsg({required this.role, required this.text});
}