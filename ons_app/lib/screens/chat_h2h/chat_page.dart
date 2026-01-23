import 'package:flutter/material.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/services/chat_h2h_api.dart';

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
  DateTime? oldestCreatedAt;
  List<Map<String, dynamic>> messages = [];

  String get myRole {
    final r = AuthService().currentUser?.role;
    if (r == null) return '';
    // enum name in your code is admin/family/caregiver/retirementHome
    if (r.name == 'retirementHome') return 'retirement_home';
    return r.name;
  }

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() => loading = true);

    final raw = await api.getMessages(widget.conversationId, limit: 30);
    final parsed = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    setState(() {
      messages = parsed;
      loading = false;
      if (messages.isNotEmpty) {
        oldestCreatedAt = DateTime.tryParse(messages.first['createdAt'] ?? '');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadOlder() async {
    if (oldestCreatedAt == null) return;

    final raw = await api.getMessages(
      widget.conversationId,
      limit: 30,
      before: oldestCreatedAt,
    );
    final parsed = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (parsed.isEmpty) return;

    setState(() {
      messages = [...parsed, ...messages];
      oldestCreatedAt = DateTime.tryParse(messages.first['createdAt'] ?? '');
    });
  }

  Future<void> _send() async {
    final text = ctrl.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);
    ctrl.clear();

    try {
      final res = await api.sendMessage(widget.conversationId, text);
      final msg = Map<String, dynamic>.from(res['message'] as Map);

      setState(() {
        messages.add(msg);
        sending = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels <= 40) _loadOlder();
                      return false;
                    },
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final senderRole = (m['senderRole'] ?? '').toString(); // caregiver/family
                        final text = (m['text'] ?? '').toString();

                        final isMe = senderRole == myRole;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(text),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: sending ? null : _send,
                    icon: const Icon(Icons.send),
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
