import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ElderSummariesPage extends StatefulWidget {
  final int elderId;
  const ElderSummariesPage({super.key, required this.elderId});

  @override
  State<ElderSummariesPage> createState() => _ElderSummariesPageState();
}

class _ElderSummariesPageState extends State<ElderSummariesPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  final from = TextEditingController(text: '2000-01-01');
  final to = TextEditingController(text: '2100-01-01');

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    super.dispose();
  }

  Future<void> _addComment(int summaryId) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add comment'),
        content: AppTextField(controller: c, label: 'Comment', maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await api.addDailySummaryComment(widget.elderId, summaryId, c.text.trim());
      if (!mounted) return;
      showSnack(context, 'Comment added ✅');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _showComments(int summaryId) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Comments'),
        content: FutureBuilder(
          future: api.getDailySummaryComments(widget.elderId, summaryId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
            if (snap.hasError) return Text('Error: ${snap.error}');
            final data = (snap.data as Map<String, dynamic>? ?? {});
            final comments = (data['comments'] as List?) ?? const [];
            if (comments.isEmpty) return const Text('No comments yet.');
            return SizedBox(
              width: 420,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = comments[i] as Map;
                  return ListTile(
                    title: Text((c['comment_text'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text((c['created_at'] ?? '').toString()),
                  );
                },
              ),
            );
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elderId = widget.elderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summaries'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Today'),
          FutureBuilder(
            future: api.getTodaySummary(elderId),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final s = (data['summary'] as Map?) ?? {};

              if (s.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No summary today.')));

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.today),
                  title: Text((s['summary_text'] ?? s['notes'] ?? 'Summary').toString()),
                  subtitle: Text('Date: ${s['summary_date'] ?? ''}'),
                ),
              );
            },
          ),

          const SizedBox(height: 14),
          const SectionTitle('Range'),
          Row(
            children: [
              Expanded(child: AppTextField(controller: from, label: 'from')),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: to, label: 'to')),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _reload, child: const Text('Load')),
            ],
          ),

          const SizedBox(height: 10),
          FutureBuilder(
            future: api.getSummariesRange(elderId, from: from.text.trim(), to: to.text.trim()),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['summaries'] as List?) ?? const [];

              if (list.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No summaries in this range.')));

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = list[i] as Map;
                    final summaryId = (s['summary_id'] ?? 0) as int? ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.summarize),
                      title: Text((s['summary_date'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text((s['summary_text'] ?? s['notes'] ?? '').toString()),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'comment') _addComment(summaryId);
                          if (v == 'view') _showComments(summaryId);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'comment', child: Text('Add comment')),
                          PopupMenuItem(value: 'view', child: Text('View comments')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
