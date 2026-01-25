import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_community_service.dart';

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

  // (Imports remain the same)
// Inside _ElderCreatePostPageState build method:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D4), // Signature Cream
      appBar: AppBar(
        title: const Text('Share with Community', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInputLabel("What's on your mind?"),
          TextField(
            controller: _titleCtrl,
            decoration: _inputDecoration("Title of your post"),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInputLabel("Category"),
          DropdownButtonFormField<String>(
            value: _category,
            items: ['Health', 'Friends', 'Fun', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Other'),
            decoration: _inputDecoration("Select a category"),
          ),
          const SizedBox(height: 20),
          _buildInputLabel("Details"),
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            decoration: _inputDecoration("Write your thoughts here..."),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF313647), // Deep Navy
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _loading ? null : _submit,
              child: _loading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Post to Community', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(18),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF313647))),
    );
  }
}
