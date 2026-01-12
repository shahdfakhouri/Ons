import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_community_api.dart.dart';

class ElderCreatePostPage extends StatefulWidget {
  const ElderCreatePostPage({super.key});

  @override
  State<ElderCreatePostPage> createState() => _ElderCreatePostPageState();
}

class _ElderCreatePostPageState extends State<ElderCreatePostPage> {
  final _svc = ElderCommunityService();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'Other';

  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = 'Please enter title and content');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _svc.createPost(title: title, content: content, category: _category);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created (pending approval) ✅')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),

          TextField(
            controller: _titleCtrl,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _category,
            items: const [
              DropdownMenuItem(value: 'Health', child: Text('Health')),
              DropdownMenuItem(value: 'Friends', child: Text('Friends')),
              DropdownMenuItem(value: 'Fun', child: Text('Fun')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: _loading ? null : (v) => setState(() => _category = v ?? 'Other'),
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _contentCtrl,
            enabled: !_loading,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Write your post',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
              ),
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 3))
                  : const Icon(Icons.send),
              label: Text(_loading ? 'Posting...' : 'Post', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
