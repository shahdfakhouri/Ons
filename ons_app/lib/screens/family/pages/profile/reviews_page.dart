import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/services/public_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final api = FamilyApi();
  final publicApi = PublicApi();

  Future<void> _reload() async => setState(() {});

  // submit review (family)
  String role = 'caregiver';
  final targetId = TextEditingController();
  final rating = TextEditingController(text: '5');
  final comment = TextEditingController();

  // public lookup
  String lookupRole = 'caregiver';
  final lookupId = TextEditingController();
  bool lookupLoading = false;
  String? lookupError;
  Map<String, dynamic>? lookupData;

  @override
  void dispose() {
    targetId.dispose();
    rating.dispose();
    comment.dispose();
    lookupId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = int.tryParse(targetId.text.trim());
    final r = int.tryParse(rating.text.trim());
    if (id == null || r == null) {
      showSnack(context, 'target_id and rating required', isError: true);
      return;
    }
    if (r < 1 || r > 5) {
      showSnack(context, 'rating must be 1..5', isError: true);
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

  Future<void> _fetchPublic() async {
    final id = int.tryParse(lookupId.text.trim());
    if (id == null) {
      showSnack(context, 'Enter a valid id', isError: true);
      return;
    }

    setState(() {
      lookupLoading = true;
      lookupError = null;
      lookupData = null;
    });

    try {
      final data = lookupRole == 'caregiver'
          ? await publicApi.getCaregiverReviews(id)
          : await publicApi.getRetirementHomeReviews(id);

      if (!mounted) return;
      setState(() {
        lookupData = data;
        lookupLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        lookupError = e.toString();
        lookupLoading = false;
      });
    }
  }

  Widget _stars(dynamic rating) {
    final r = (rating is num) ? rating.toDouble() : double.tryParse('$rating') ?? 0.0;
    final full = r.floor().clamp(0, 5);
    final half = (r - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < full; i++) const Icon(Icons.star, size: 18),
        for (int i = 0; i < half; i++) const Icon(Icons.star_half, size: 18),
        for (int i = 0; i < empty; i++) const Icon(Icons.star_border, size: 18),
      ],
    );
  }

  Widget _publicResult() {
    if (lookupLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      );
    }
    if (lookupError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $lookupError'),
        ),
      );
    }
    if (lookupData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Fetch public reviews for a caregiver/home id.'),
        ),
      );
    }

    final summary = (lookupData!['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final latest = (lookupData!['latest_reviews'] as List?) ?? const [];

    final total = summary['total_reviews'] ?? 0;
    final avg = summary['avg_rating'];

    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.reviews_outlined),
            title: Text('Total reviews: $total'),
            subtitle: Row(
              children: [
                Text('Avg: ${avg ?? '-'}  '),
                _stars(avg),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Latest reviews', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (latest.isEmpty)
                  const Text('No reviews yet.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: latest.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = (latest[i] as Map).cast<String, dynamic>();
                      return ListTile(
                        leading: const Icon(Icons.star),
                        title: Row(
                          children: [
                            Text('Rating: ${r['rating'] ?? '-'}  '),
                            _stars(r['rating']),
                          ],
                        ),
                        subtitle: Text('${r['comment'] ?? ''}\n${r['created_at'] ?? ''}'),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ---------------- PUBLIC LOOKUP ----------------
          const SectionTitle('Public reviews lookup'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: lookupRole,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'target_role',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'caregiver', child: Text('caregiver')),
                      DropdownMenuItem(value: 'retirement_home', child: Text('retirement_home')),
                    ],
                    onChanged: (v) => setState(() => lookupRole = v ?? 'caregiver'),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: lookupId,
                    label: lookupRole == 'caregiver' ? 'caregiver_id' : 'home_id',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _fetchPublic,
                      icon: const Icon(Icons.search),
                      label: const Text('Fetch public reviews'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _publicResult(),

          const SizedBox(height: 16),

          // ---------------- FAMILY: SUBMIT ----------------
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _submit, child: const Text('Submit')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ---------------- FAMILY: MY REVIEWS ----------------
          const SectionTitle('My reviews'),
          FutureBuilder(
            future: api.getMyReviews(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
              }
              if (snap.hasError) {
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));
              }

              final data = (snap.data as Map<String, dynamic>? ?? {});
              final list = (data['reviews'] as List?) ?? const [];

              if (list.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No reviews yet.')));
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = (list[i] as Map).cast<String, dynamic>();
                    return ListTile(
                      leading: const Icon(Icons.star),
                      title: Text(
                        '${r['target_role']} #${r['target_id']} • Rating: ${r['rating']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
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
