import 'package:flutter/material.dart';
import 'package:ons_app/services/elder_community_service.dart';
import 'elder_create_post_page.dart';
import 'elder_post_detail_page.dart';

class ElderCommunityFeedPage extends StatefulWidget {
  final void Function(int index)? onBack;
  const ElderCommunityFeedPage({super.key, this.onBack});

  @override
  State<ElderCommunityFeedPage> createState() => _ElderCommunityFeedPageState();
}

class _ElderCommunityFeedPageState extends State<ElderCommunityFeedPage> {
  final _svc = ElderCommunityService();
  String _category = 'All';

  static const _deepNavy = Color(0xFF313647);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFF9F9F4);

  void _triggerBack() {
    if (widget.onBack != null) widget.onBack!(0);
  }

  Future<void> _refresh() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _deepNavy),
            onPressed: _triggerBack,
          ),
          title: const Text('Community', style: TextStyle(fontWeight: FontWeight.w900, color: _deepNavy)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded, color: _deepNavy))],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ElderCreatePostPage()));
            _refresh();
          },
          backgroundColor: _deepNavy,
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
          label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            _buildCategoryFilter(),
            Expanded(
              child: FutureBuilder(
                future: _svc.getPosts(category: _category == 'All' ? null : _category),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: _sage));
                  }
                  final posts = snap.data ?? [];
                  if (posts.isEmpty) return const Center(child: Text("No posts found in this category."));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: posts.length,
                    itemBuilder: (_, i) => _buildPostCard(posts[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Health', 'Friends', 'Fun', 'Other'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _category == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat),
              onSelected: (v) => setState(() => _category = cat),
              backgroundColor: Colors.white,
              selectedColor: _sage,
              labelStyle: TextStyle(color: isSelected ? Colors.white : _deepNavy, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Map p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _deepNavy.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(p['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepNavy)),
        subtitle: Text('by ${p['author_name'] ?? 'Elder'} • ${p['category'] ?? 'Other'}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: _sage),
        onTap: () {
          final id = (p['post_id'] as num).toInt();
          Navigator.push(context, MaterialPageRoute(builder: (_) => ElderPostDetailPage(postId: id)));
        },
      ),
    );
  }
}