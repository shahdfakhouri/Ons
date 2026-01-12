import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  String role = 'caregiver';
  final targetId = TextEditingController();
  final rating = TextEditingController(text: '5');
  final comment = TextEditingController();

  @override
  void dispose() {
    targetId.dispose();
    rating.dispose();
    comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = int.tryParse(targetId.text.trim());
    final r = int.tryParse(rating.text.trim());
    if (id == null || r == null) {
      showSnack(context, 'target_id and rating required', isError: true);
      return;
    }
    try {
      await api.createReview({
        'target_role': role,
        'target_id': id,
        'rating': r,
        'comment': comment.text.trim().isEmpty ? null : comment.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Review submitted ✅');
      targetId.clear();
      comment.clear();
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SectionTitle('Submit review'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'target_role'),
                    items: const [
                      DropdownMenuItem(value: 'caregiver', child: Text('caregiver')),
                      DropdownMenuItem(value: 'retirement_home', child: Text('retirement_home')),
                    ],
                    onChanged: (v) => setState(() => role = v ?? 'caregiver'),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(controller: targetId, label: 'target_id', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  AppTextField(controller: rating, label: 'rating (1..5)', keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  AppTextField(controller: comment, label: 'comment (optional)', maxLines: 3),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submit, child: const Text('Submit'))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SectionTitle('My reviews'),
          FutureBuilder(
            future: api.getMyReviews(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['reviews'] as List?) ?? const [];

              if (list.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No reviews yet.')));

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = list[i] as Map;
                    return ListTile(
                      leading: const Icon(Icons.star),
                      title: Text('${r['target_role']} #${r['target_id']} • Rating: ${r['rating']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${r['comment'] ?? ''}\n${r['created_at'] ?? ''}'),
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
