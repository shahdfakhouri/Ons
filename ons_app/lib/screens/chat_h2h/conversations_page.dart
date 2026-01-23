import 'package:flutter/material.dart';
import 'package:ons_app/services/auth_service.dart';
import 'package:ons_app/services/chat_h2h_api.dart';
import 'chat_page.dart';

class ChatH2HConversationsPage extends StatefulWidget {
  const ChatH2HConversationsPage({super.key});

  @override
  State<ChatH2HConversationsPage> createState() => _ChatH2HConversationsPageState();
}

class _ChatH2HConversationsPageState extends State<ChatH2HConversationsPage> {
  final api = ChatH2HApi();

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> convs = [];

  String _myRole() {
    final r = AuthService().currentUser?.role;
    if (r == null) return '';
    // your enum names: admin/family/caregiver/retirementHome
    // we only care about family/caregiver here
    return r.name; // 'family' or 'caregiver'
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final raw = await api.listConversations();
      convs = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _myRole();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : convs.isEmpty
                  ? const Center(child: Text('No conversations yet.'))
                  : ListView.separated(
                      itemCount: convs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = convs[i];

                        final id = (c['_id'] ?? '').toString();
                        final last = (c['lastMessageText'] ?? '').toString();

                        final elderId = c['elderId'];
                        final elderName = (c['elderName'] ?? '').toString();
                        final title = elderName.isNotEmpty ? elderName : 'Elder #$elderId';

                        final peerName = (me == 'caregiver')
                            ? (c['familyName'] ?? 'Family').toString()
                            : (c['caregiverName'] ?? 'Caregiver').toString();

                        return ListTile(
                          title: Text(title),
                          subtitle: Text(
                            'Chat with $peerName • ${last.isEmpty ? 'No messages yet' : last}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatH2HPage(conversationId: id),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
