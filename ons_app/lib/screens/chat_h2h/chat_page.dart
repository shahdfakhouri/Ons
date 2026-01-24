import 'package:flutter/material.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/services/chat_h2h_api.dart';
import 'package:intl/intl.dart';

class ChatH2HPage extends StatefulWidget {
  final String conversationId;
  const ChatH2HPage({super.key, required this.conversationId});

  @override
  State<ChatH2HPage> createState() => _ChatH2HPageState();
}

class _ChatH2HPageState extends State<ChatH2HPage> {
  final api = ChatH2HApi();
  final ctrl = TextEditingController();
  final scrollCtrl = ScrollController();

  bool loading = true;
  bool sending = false;
  List<Map<String, dynamic>> messages = [];

  String get myRole {
    final r = AuthService().currentUser?.role.name;
    return r == 'retirementHome' ? 'retirement_home' : (r ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() => loading = true);
    final raw = await api.getMessages(widget.conversationId, limit: 30);
    setState(() {
      messages = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = ctrl.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);
    ctrl.clear();

    try {
      final res = await api.sendMessage(widget.conversationId, text);
      setState(() {
        messages.add(Map<String, dynamic>.from(res['message'] as Map));
        sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => sending = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F9),
      appBar: AppBar(
        title: const Text('Chat Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final isMe = m['senderRole'] == myRole;
                      return _buildChatBubble(m, isMe, cs);
                    },
                  ),
          ),
          _buildInputBar(cs),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> m, bool isMe, ColorScheme cs) {
    final text = m['text'] ?? '';
    final timeStr = m['createdAt'] != null 
        ? DateFormat('h:mm a').format(DateTime.parse(m['createdAt']).toLocal()) 
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? cs.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Text(
              text,
              style: TextStyle(color: isMe ? cs.onPrimary : Colors.black87, fontSize: 15, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Write your message...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : _send,
              child: CircleAvatar(
                backgroundColor: cs.primary,
                child: sending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}