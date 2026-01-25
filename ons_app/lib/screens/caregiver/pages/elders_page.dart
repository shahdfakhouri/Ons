import 'package:flutter/material.dart';
import 'package:ons_app/services/caregiver_api.dart';
import 'package:ons_app/services/chat_h2h_api.dart';
import 'package:ons_app/screens/chat_h2h/chat_page.dart';
import 'package:ons_app/services/auth_service.dart';
import 'elder_detail_page.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final elders = await _api.getAssignedElders();
      if (mounted) {
        setState(() {
          _elders = elders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openChatForElder(Map<String, dynamic> e) async {
    if (_chatBusy) return;

    final elderId = int.tryParse((e['elder_id'] ?? '').toString());
    final familyId = int.tryParse((e['family_id'] ?? '').toString());
    final caregiverId = AuthService().myId;

    if (elderId == null || familyId == null) {
      _showSnack('Information missing for chat initialization.');
      return;
    }

    if (caregiverId == null) {
      _showSnack('Session expired. Please login again.');
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
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatH2HPage(conversationId: convId)),
      );
    } catch (err) {
      _showSnack('Chat failed: $err');
    } finally {
      if (mounted) setState(() => _chatBusy = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState(cs, tt);

    final filtered = _elders.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      return name.contains(_q.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4), // Signature Ons Cream
      body: Column(
        children: [
          _buildSearchHeader(cs, isMobile),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: filtered.isEmpty
                  ? _buildEmptyState(cs, tt)
                  : ListView.separated(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildElderCard(filtered[index], cs, tt, isMobile),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ColorScheme cs, bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 10, isMobile ? 16 : 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _q = v),
        decoration: InputDecoration(
          hintText: 'Search residents...',
          prefixIcon: Icon(Icons.search, color: cs.primary),
          filled: true,
          fillColor: const Color(0xFFF4F4F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildElderCard(Map<String, dynamic> e, ColorScheme cs, TextTheme tt, bool isMobile) {
    final name = (e['name'] ?? 'Resident').toString();
    final gender = (e['gender'] ?? 'Other').toString();
    final lastCheck = (e['last_check_in'] ?? 'No data').toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          final id = int.tryParse(e['elder_id'].toString());
          if (id != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ElderDetailPage(elderId: id)));
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 28,
                backgroundColor: cs.primaryContainer,
                child: Text(name[0].toUpperCase(), 
                  style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, 
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Age: ${e['age'] ?? '-'} • $gender', 
                      style: tt.bodySmall?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.history, size: 12, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('Check-in: $lastCheck', 
                            style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: "Chat with elder's family",
                child: IconButton.filledTonal(
                  onPressed: _chatBusy ? null : () => _openChatForElder(e),
                  icon: _chatBusy 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chat_bubble_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded, size: 64, color: cs.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_q.isEmpty ? 'No residents assigned yet.' : 'No matches found.', 
            style: tt.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text('Failed to load residents', style: tt.titleMedium),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Retry Connection')),
        ],
      ),
    );
  }
}