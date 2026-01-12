import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_community_api.dart.dart';

class ElderPostDetailPage extends StatefulWidget {
  final int postId;
  const ElderPostDetailPage({super.key, required this.postId});

  @override
  State<ElderPostDetailPage> createState() => _ElderPostDetailPageState();
}

class _ElderPostDetailPageState extends State<ElderPostDetailPage> {
  final _svc = ElderCommunityService();
  final _commentCtrl = TextEditingController();

  Future<void> _reload() async => setState(() {});

  Future<void> _askReportPost() async {
    final reason = await _reasonDialog(title: 'Report post');
    if (reason == null) return;

    try {
      await _svc.reportPost(postId: widget.postId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report failed: $e')));
    }
  }

  Future<void> _askReportComment(int commentId) async {
    final reason = await _reasonDialog(title: 'Report comment');
    if (reason == null) return;

    try {
      await _svc.reportComment(commentId: commentId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report failed: $e')));
    }
  }

  Future<String?> _reasonDialog({required String title}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Send')),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    try {
      await _svc.addComment(postId: widget.postId, text: text);
      _commentCtrl.clear();
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deletePost() async {
    try {
      await _svc.deletePost(widget.postId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _svc.deleteComment(commentId);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _askReportPost, icon: const Icon(Icons.flag_outlined)),
          IconButton(onPressed: _deletePost, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: FutureBuilder(
        future: _svc.getPostById(widget.postId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = snap.data as Map<String, dynamic>;
          final post = Map<String, dynamic>.from(data['post'] as Map);
          final comments = (data['comments'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                color: cs.surfaceContainerLow,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (post['title'] ?? '').toString(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(label: Text((post['category'] ?? 'Other').toString())),
                          if ((post['created_at'] ?? '').toString().isNotEmpty)
                            Chip(label: Text((post['created_at']).toString())),
                          Chip(label: Text((post['is_approved'] ?? 0).toString() == '1' ? 'Approved' : 'Pending')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (post['content'] ?? '').toString(),
                        style: const TextStyle(fontSize: 18, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Text('Comments (${comments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),

              for (final c in comments)
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  child: ListTile(
                    title: Text((c['comment'] ?? '').toString(), style: const TextStyle(fontSize: 17)),
                    subtitle: Text((c['created_at'] ?? '').toString()),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        final id = (c['comment_id'] as num).toInt();
                        if (v == 'report') _askReportComment(id);
                        if (v == 'delete') _deleteComment(id);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'report', child: Text('Report')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Write a comment',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _sendComment,
                          icon: const Icon(Icons.send),
                          label: const Text('Send', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
