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

  // 🎨 Ons Signature Theme Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  // Submit Logic State
  String _selectedRole = 'caregiver';
  int? _selectedTargetId;
  String? _selectedTargetName;
  
  final _ratingController = TextEditingController(text: '5');
  final _commentController = TextEditingController();

  // Public Lookup State
  String lookupRole = 'caregiver';
  final lookupId = TextEditingController();
  bool lookupLoading = false;
  String? lookupError;
  Map<String, dynamic>? lookupData;

  @override
  void dispose() {
    _ratingController.dispose();
    _commentController.dispose();
    lookupId.dispose();
    super.dispose();
  }

  Future<void> _reload() async => setState(() {});

  Future<void> _submitReview() async {
    final r = int.tryParse(_ratingController.text.trim());
    if (_selectedTargetId == null || r == null) {
      showSnack(context, 'Please select a provider and rating', isError: true);
      return;
    }

    try {
      await api.createReview({
        'target_role': _selectedRole,
        'target_id': _selectedTargetId,
        'rating': r,
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      });
      
      if (!mounted) return;
      showSnack(context, 'Review for $_selectedTargetName submitted ✅');
      
      // Reset form
      _commentController.clear();
      setState(() {
        _selectedTargetId = null;
        _selectedTargetName = null;
      });
      _reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _fetchPublic() async {
    final id = int.tryParse(lookupId.text.trim());
    if (id == null) {
      showSnack(context, 'Enter a valid ID', isError: true);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < r.floor() ? Icons.star_rounded : (index < r ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: 18,
          color: _sage,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Feedback Center', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _deepNavy,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildContextualReviewHeader(),
          const SizedBox(height: 32),
          const SectionTitle('Your Past Feedback'),
          _buildMyReviewsHistory(),
          const SizedBox(height: 32),
          const SectionTitle('Public Reputation Lookup'),
          _buildPublicLookupSection(),
          const SizedBox(height: 8),
          _publicResult(),
        ],
      ),
    );
  }

  // ✅ NEW: Automatic Provider Detection Logic
  // ✅ Full Enhanced Review Selection (Names instead of IDs)
Widget _buildContextualReviewHeader() {
  return FutureBuilder(
    future: api.getMyProfile(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: LinearProgressIndicator());
      
      final data = snap.data as Map<String, dynamic>;
      
      // These names are pulled from your updated Node.js controller
      final caregiverName = data['assigned_caregiver_name'];
      final caregiverId = data['assigned_caregiver_id'];
      final homeName = data['retirement_home_name'];
      final homeId = data['retirement_home_id'];

      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: const Color(0xFF313647).withOpacity(0.05), blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share Your Experience", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                if (caregiverId != null)
                  _providerChip(caregiverName ?? "Assigned Caregiver", 'caregiver', caregiverId),
                if (homeId != null)
                  _providerChip(homeName ?? "Facility", 'retirement_home', homeId),
              ],
            ),
            if (_selectedTargetId != null) ...[
              const Divider(height: 48),
              // ✅ UI now shows NAME instead of ID
              Text("Reviewing: $_selectedTargetName", style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFA3B087))),
              const SizedBox(height: 16),
              AppTextField(controller: _ratingController, label: 'Rating (1-5)', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(controller: _commentController, label: 'Your feedback...', maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitReview,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF313647)),
                  child: const Text("Submit Feedback"),
                ),
              ),
            ]
          ],
        ),
      );
    },
  );
}

  Widget _providerChip(String name, String role, int id) {
    bool selected = _selectedTargetId == id;
    return ChoiceChip(
      label: Text(name),
      selected: selected,
      onSelected: (val) => setState(() {
        _selectedRole = role;
        _selectedTargetId = val ? id : null;
        _selectedTargetName = val ? name : null;
      }),
      selectedColor: _sage,
      backgroundColor: _cream,
      labelStyle: TextStyle(color: selected ? Colors.white : _deepNavy, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMyReviewsHistory() {
    return FutureBuilder(
      future: api.getMyReviews(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const SizedBox();
        final data = (snap.data as Map<String, dynamic>? ?? {});
        final list = (data['reviews'] as List?) ?? [];

        if (list.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text("You haven't posted any reviews yet.")));
        }

        return Column(
          children: list.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: _cream, child: const Icon(Icons.star_rounded, color: _sage)),
              title: Text('${r['target_role'].toString().replaceAll('_', ' ')} #${r['target_id']}'),
              subtitle: Text(r['comment'] ?? 'No comment provided.'),
              trailing: _stars(r['rating']),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildPublicLookupSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: lookupRole,
            decoration: InputDecoration(
              labelText: 'Target Type',
              filled: true,
              fillColor: _cream.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'caregiver', child: Text('Caregivers')),
              DropdownMenuItem(value: 'retirement_home', child: Text('Facilities')),
            ],
            onChanged: (v) => setState(() => lookupRole = v!),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: lookupId, label: 'Search by ID', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchPublic,
              icon: const Icon(Icons.search_rounded),
              label: const Text("Check Reputation"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: _denim),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _publicResult() {
    if (lookupLoading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    if (lookupError != null) return Text("Error: $lookupError", style: const TextStyle(color: Colors.red));
    if (lookupData == null) return const SizedBox();

    final summary = (lookupData!['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final latest = (lookupData!['latest_reviews'] as List?) ?? const [];
    final avg = summary['avg_rating'];

    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined, color: _deepNavy),
            title: Text('Average Rating: ${avg ?? 'N/A'}'),
            subtitle: _stars(avg),
          ),
        ),
        const SizedBox(height: 8),
        ...latest.map((r) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: _stars(r['rating']),
            subtitle: Text(r['comment'] ?? ''),
          ),
        )),
      ],
    );
  }
}