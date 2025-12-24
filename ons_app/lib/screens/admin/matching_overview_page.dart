import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class MatchingOverviewPage extends StatefulWidget {
  const MatchingOverviewPage({super.key});

  @override
  State<MatchingOverviewPage> createState() => _MatchingOverviewPageState();
}

class _MatchingOverviewPageState extends State<MatchingOverviewPage> {
  final AdminApi _api = AdminApi();
  final TextEditingController _familyIdCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  String? _loadedFamilyId;
  List _matches = [];

  @override
  void dispose() {
    _familyIdCtrl.dispose();
    super.dispose();
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _loadMatches() async {
    final familyId = _familyIdCtrl.text.trim();
    if (familyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a family ID')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _loadedFamilyId = familyId;
    });

    try {
      final rows = await _api.getMatches(familyId);
      setState(() {
        _matches = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _matches = [];
        _loading = false;
      });
    }
  }

  Future<void> _approveMatch(String matchId) async {
    try {
      await _api.approveMatch(matchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match approved')),
      );
      if (_loadedFamilyId != null) {
        await _loadMatches();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> _rejectMatch(String matchId) async {
    try {
      await _api.rejectMatch(matchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match rejected')),
      );
      if (_loadedFamilyId != null) {
        await _loadMatches();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Matching Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _familyIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Family ID',
                        hintText: 'e.g. 12',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _loadMatches,
                    icon: const Icon(Icons.search),
                    label: const Text('Load matches'),
                  ),
                  if (_loadedFamilyId != null)
                    Text(
                      'Loaded for family: $_loadedFamilyId',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadMatches,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : (_loadedFamilyId == null)
                        ? const Center(
                            child: Text('Enter a family ID to view matches.'),
                          )
                        : (_matches.isEmpty)
                            ? const Center(
                                child: Text('No matches found for this family.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _matches.length,
                                itemBuilder: (context, index) {
                                  final m = _matches[index] as Map;

                                  final matchId = _v(m['match_id']);
                                  final role = _v(m['matched_role']);
                                  final score = _v(m['score']);
                                  final status = _v(m['status'], fallback: 'pending');

                                  final matchedName = _v(m['matched_name'], fallback: 'Unknown');
                                  final city = _v(m['city'], fallback: '-');

                                  final selectedByFamily = (m['selected_by_family'] == 1 ||
                                      m['selected_by_family'] == true);
                                  final approvedByAdmin = (m['approved_by_admin'] == 1 ||
                                      m['approved_by_admin'] == true);

                                  final canReview = status.toLowerCase() == 'pending' ||
                                      status.toLowerCase() == 'selected';

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      leading: Icon(
                                        role == 'caregiver'
                                            ? Icons.badge_outlined
                                            : Icons.home_work_outlined,
                                      ),
                                      title: Text('$matchedName ($role)'),
                                      subtitle: Text(
                                        [
                                          'Match ID: $matchId',
                                          'Score: $score',
                                          'City: $city',
                                          'Selected by family: ${selectedByFamily ? "Yes" : "No"}',
                                          'Approved by admin: ${approvedByAdmin ? "Yes" : "No"}',
                                          'Status: $status',
                                        ].join('\n'),
                                      ),
                                      isThreeLine: true,
                                      trailing: canReview
                                          ? Wrap(
                                              spacing: 8,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _approveMatch(matchId),
                                                  child: const Text('Approve'),
                                                ),
                                                TextButton(
                                                  onPressed: () => _rejectMatch(matchId),
                                                  child: const Text('Reject'),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              status,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}
