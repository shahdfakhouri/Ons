// ======================
// CAREGIVER: EldersPage (with Chat button per elder)
// ======================
import 'package:flutter/material.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'elder_detail_page.dart';

import 'package:ons_app/services/chat_h2h_api.dart';
import 'package:ons_app/screens/chat_h2h/chat_page.dart';
import 'package:ons_app/services/auth_service.dart';


class EldersPage extends StatefulWidget {
  const EldersPage({super.key});

  @override
  State<EldersPage> createState() => _EldersPageState();
}

class _EldersPageState extends State<EldersPage> {
  final _api = CaregiverApi();
  final _chatApi = ChatH2HApi();

  bool _loading = true;
  bool _chatBusy = false;

  String? _error;
  List<Map<String, dynamic>> _elders = [];
  String _q = '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final elders = await _api.getAssignedElders();
      setState(() {
        _elders = elders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openChatForElder(Map<String, dynamic> e) async {
    if (_chatBusy) return;

    final elderId = int.tryParse((e['elder_id'] ?? '').toString());
    if (elderId == null) return;

    // IMPORTANT:
    // This requires backend to return family_id in getAssignedElders(),
    // OR you add an endpoint to fetch family_id for this elder.
    final familyId = int.tryParse((e['family_id'] ?? '').toString());
    if (familyId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing family_id for this elder. Add it to /caregiver/elders response.')),
      );
      return;
    }

    // caregiver id comes from JWT on backend, but your API expects it in body too.
    // You can either:
    // 1) decode it from token, or
    // 2) modify backend to ignore caregiverId and use req.user.id
    //
    // For now we assume token already has id and you can pass it by decoding the JWT
    // OR you already added caregiver_id in each elder row.
final caregiverId = AuthService().myId;
if (caregiverId == null) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Missing caregiver id (login again).')),
  );
  return;
}




    setState(() => _chatBusy = true);

    try {
      final res = await _chatApi.createOrGetConversation(
        elderId: elderId,
        caregiverId: caregiverId,
        familyId: familyId,
      );

      final convId = (res['conversationId'] ?? '').toString();
      if (convId.isEmpty) throw Exception('No conversationId returned');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatH2HPage(conversationId: convId)),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat failed: $err')),
      );
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load elders', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_error!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = _elders.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      return name.contains(_q.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
                hintText: 'Search elders by name...',
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No elders found.', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        for (final e in filtered)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                foregroundColor: cs.onSecondaryContainer,
                child: Text(((e['name'] ?? 'E').toString()).substring(0, 1).toUpperCase()),
              ),
              title: Text((e['name'] ?? 'Unknown').toString()),
              subtitle: Text(
                'Age: ${e['age'] ?? '-'} • Gender: ${e['gender'] ?? '-'}\nLast check-in: ${e['last_check_in'] ?? '-'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Chat with family',
                    onPressed: _chatBusy ? null : () => _openChatForElder(e),
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                final id = int.tryParse(e['elder_id'].toString());
                if (id == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ElderDetailPage(elderId: id)),
                );
              },
            ),
          ),
      ],
    );
  }
}
