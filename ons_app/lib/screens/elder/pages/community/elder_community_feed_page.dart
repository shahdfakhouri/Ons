import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_community_api.dart.dart';
import 'elder_create_post_page.dart';
import 'elder_post_detail_page.dart';

class ElderCommunityFeedPage extends StatefulWidget {
  const ElderCommunityFeedPage({super.key});

  @override
  State<ElderCommunityFeedPage> createState() => _ElderCommunityFeedPageState();
}

class _ElderCommunityFeedPageState extends State<ElderCommunityFeedPage> {
  final _svc = ElderCommunityService();
  String _category = 'All';

  Future<void> _refresh() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bigTitle = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900);

    return Scaffold(
      appBar: AppBar(
        title: Text('Community', style: bigTitle),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ElderCreatePostPage()),
          );
          if (!mounted) return;
          _refresh();
        },
        icon: const Icon(Icons.edit),
        label: const Text('New Post'),
      ),
      body: Column(
        children: [
          // category filter (simple)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 10),
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Health', child: Text('Health')),
                        DropdownMenuItem(value: 'Friends', child: Text('Friends')),
                        DropdownMenuItem(value: 'Fun', child: Text('Fun')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder(
              future: _svc.getPosts(category: _category == 'All' ? null : _category),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final posts = snap.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = posts[i];
                    final title = (p['title'] ?? '').toString();
                    final author = (p['author_name'] ?? '').toString();
                    final category = (p['category'] ?? 'Other').toString();
                    final createdAt = (p['created_at'] ?? '').toString();

                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Chip(label: Text(category)),
                              Chip(label: Text(author.isEmpty ? 'Elder' : author)),
                              if (createdAt.isNotEmpty) Chip(label: Text(createdAt)),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final id = (p['post_id'] as num).toInt();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ElderPostDetailPage(postId: id)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
