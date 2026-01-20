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
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedMatches();
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  Future<void> _loadSelectedMatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _api.getSelectedMatches();
      final filtered = rows.where((m) {
        final selected = (m['selected_by_family'] == 1 || m['selected_by_family'] == true);
        final approved = (m['approved_by_admin'] == 1 || m['approved_by_admin'] == true);
        final status = (m['status'] ?? '').toString().toLowerCase();
        return selected && !approved && status != 'rejected' && status != 'approved';
      }).toList();

      setState(() {
        _matches = filtered;
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

  Future<void> _handleMatch(String matchId, bool approve) async {
    try {
      if (approve) {
        await _api.approveMatch(matchId);
      } else {
        await _api.rejectMatch(matchId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Match approved ✅' : 'Match rejected ❌')),
      );
      await _loadSelectedMatches();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

 // 🎨 Updated Style Helper to handle decimals
  Color _getScoreColor(String scoreStr) {
    // 🛠️ FIX: Use double.tryParse instead of int.tryParse
    final score = double.tryParse(scoreStr) ?? 0.0; 
    
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Matching Requests',
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.handshake_outlined, color: Colors.blueGrey),
                const SizedBox(width: 12),
                const Text(
                  "Review Family Selections",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: _loadSelectedMatches,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                    ? _buildErrorView()
                    : _matches.isEmpty
                        ? _buildEmptyView()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _matches.length,
                            itemBuilder: (context, index) {
                              final m = _matches[index];
                              final matchId = _v(m['match_id']);
                              final role = _v(m['matched_role']);
                              final score = _v(m['score'], fallback: '0');
                              final matchedName = _v(m['matched_name'], fallback: 'Unknown');
                              final familyName = _v(m['family_name'], fallback: 'Family');
                              final city = _v(m['city'], fallback: 'Unknown Location');

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: colors.outlineVariant),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // 1. Connection Logic UI
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _EntityCircle(label: "Family Member", name: familyName, icon: Icons.family_restroom, color: Colors.blue),
                                          const Icon(Icons.compare_arrows, color: Colors.grey),
                                          _EntityCircle(
                                            label: role.toUpperCase(),
                                            name: matchedName,
                                            icon: role == 'caregiver' ? Icons.badge : Icons.apartment,
                                            color: Colors.purple,
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 32),
                                      
                                      // 2. Details Row
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(city, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                          const Spacer(),
                                          // Score Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getScoreColor(score).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: _getScoreColor(score)),
                                            ),
                                            child: Text(
                                              "Compatibility: $score%",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getScoreColor(score),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // 3. Action Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () => _handleMatch(matchId, false),
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              label: const Text("Reject Connection", style: TextStyle(color: Colors.red)),
                                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _handleMatch(matchId, true),
                                              icon: const Icon(Icons.check, color: Colors.white),
                                              label: const Text("Finalize Match"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 64, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("All set!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("No pending match requests."),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(onPressed: _loadSelectedMatches, child: const Text("Retry")),
        ],
      ),
    );
  }
}

// 🏛️ Reusable Component for the Connection Logic Visual
class _EntityCircle extends StatelessWidget {
  final String label, name;
  final IconData icon;
  final Color color;

  const _EntityCircle({required this.label, required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}