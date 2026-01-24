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

  String _myRole() => AuthService().currentUser?.role.name ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final raw = await api.listConversations();
      convs = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() => loading = false);
    } catch (e) {
      setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = _myRole(); // ✅ 'me' is defined here

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _buildBody(cs, me), // ✅ 'me' is passed to the builder
    );
  }

  Widget _buildBody(ColorScheme cs, String me) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));
    if (convs.isEmpty) return _buildEmptyState(cs);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: convs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final c = convs[i];
          final id = c['_id']?.toString() ?? '';
          final elderName = c['elderName']?.toString() ?? 'Resident';
          final lastMsg = c['lastMessageText']?.toString() ?? 'No messages yet';
          
          final peerName = (me == 'caregiver') 
              ? (c['familyName'] ?? 'Family').toString() 
              : (c['caregiverName'] ?? 'Caregiver').toString();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatH2HPage(conversationId: id))),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: cs.primaryContainer,
                      child: Text(elderName.isNotEmpty ? elderName[0] : '?', 
                        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(elderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                            'Chatting with $peerName',
                            style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: cs.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("No conversations found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}