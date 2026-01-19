import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/screens/admin/caregiver_cv_viewer_page.dart';
import 'package:ons_app/services/admin_api.dart';

class ApproveCaregiversPage extends StatefulWidget {
  const ApproveCaregiversPage({super.key});

  @override
  State<ApproveCaregiversPage> createState() => _ApproveCaregiversPageState();
}

class _ApproveCaregiversPageState extends State<ApproveCaregiversPage> {
  final AdminApi _api = AdminApi();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _pendingCaregivers = [];

  // ✅ track per-caregiver analyze loading
  final Map<String, bool> _analyzing = {};

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pending = await _api.getApprovals();

      final caregivers = pending
          .where((u) => (u['role']?.toString() ?? '') == 'caregiver')
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _pendingCaregivers = caregivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 🎨 Visual badge for the caregiver type (Freelance vs Internal)
  Widget _buildTypeBadge(String type) {
    final bool isFreelance = type == 'freelance';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFreelance ? Colors.blue.shade50 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFreelance ? Colors.blue : Colors.purple),
      ),
      child: Text(
        isFreelance ? "FREELANCE" : "INTERNAL STAFF",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isFreelance ? Colors.blue.shade900 : Colors.purple.shade900,
        ),
      ),
    );
  }

  // ✅ Analyze CV => calls backend, updates caregiver map (ai_score/ai_feedback)
  Future<void> _handleAnalyze(Map<String, dynamic> caregiver) async {
    final id = caregiver['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() => _analyzing[id] = true);

    try {
      // Make sure you added this method in AdminApi:
      // Future<Map<String,dynamic>> analyzeCaregiverCv(String caregiverId)
      final result = await _api.analyzeCaregiverCv(id);

      // backend returns: { ai_score: ..., ai_feedback: ... }
      final score = result['ai_score'];
      final feedback = result['ai_feedback'];

      setState(() {
        caregiver['ai_score'] = score;
        caregiver['ai_feedback'] = feedback;
        _analyzing.remove(id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV analyzed and saved ✅')),
      );
    } catch (e) {
      setState(() => _analyzing.remove(id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analyze failed: $e')),
      );
    }
  }

  Widget _buildActionButtons(Map<String, dynamic> caregiver) {
    final id = caregiver['id']?.toString() ?? '';
    final bool isAnalyzing = _analyzing[id] == true;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'Approve',
          onPressed: () => _handleApprove(caregiver),
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          tooltip: 'Reject',
          onPressed: () => _handleReject(caregiver),
        ),
       IconButton(
  icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
  tooltip: 'View CV',
  onPressed: () {
    // 🛠️ FIX 3: Robust ID passing
    final idString = caregiver['id']?.toString() ?? '';
    if (idString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Caregiver ID is missing')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaregiverCvViewerPage(
          caregiverId: idString, // This matches the backend :id param
          caregiverName: caregiver['name']?.toString() ?? 'Caregiver',
        ),
      ),
    );
  },
),

        // ✅ Analyze CV button
        IconButton(
          icon: isAnalyzing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, color: Colors.deepPurple),
          tooltip: caregiver['ai_score'] == null ? 'Analyze CV' : 'Re-analyze CV',
          onPressed: isAnalyzing ? null : () => _handleAnalyze(caregiver),
        ),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Center(
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
            onPressed: _loadCaregivers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(Map<String, dynamic> caregiver) async {
    final id = caregiver['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      await _api.approveUser('caregiver', id);
      if (!mounted) return;
      setState(() {
        _pendingCaregivers.removeWhere((c) => c['id'].toString() == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${caregiver['name'] ?? 'caregiver'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> _handleReject(Map<String, dynamic> caregiver) async {
    final id = caregiver['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      await _api.rejectUser('caregiver', id);
      if (!mounted) return;
      setState(() {
        _pendingCaregivers.removeWhere((c) => c['id'].toString() == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${caregiver['name'] ?? 'caregiver'}')),
      );
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
      title: 'Approve Caregivers',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _buildErrorUI()
              : _pendingCaregivers.isEmpty
                  ? const Center(child: Text('No caregivers waiting for approval.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingCaregivers.length,
                      itemBuilder: (context, index) {
                        final caregiver = _pendingCaregivers[index];
                        final name = caregiver['name']?.toString() ?? 'Unknown';
                        final email = caregiver['email']?.toString() ?? '';
                        final phone = caregiver['phone']?.toString() ?? '';

                        final type = (caregiver['employment_type']?.toString() ?? 'internal')
                            .toLowerCase()
                            .trim();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: type == 'freelance'
                                  ? Colors.blue.shade100
                                  : Colors.purple.shade100,
                              child: Icon(
                                type == 'freelance' ? Icons.person : Icons.business,
                                color: type == 'freelance' ? Colors.blue : Colors.purple,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                _buildTypeBadge(type),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (email.isNotEmpty) 'Email: $email',
                                    if (phone.isNotEmpty) 'Phone: $phone',
                                  ].join('\n'),
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                                const SizedBox(height: 12),

                                // 🤖 AI EVALUATION BOX (shows if already analyzed)
                                if (caregiver['ai_score'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade100),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                                            const SizedBox(width: 6),
                                            Text(
                                              "AI SCORE: ${caregiver['ai_score']}%",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          caregiver['ai_feedback'] ?? "",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: _buildActionButtons(caregiver),
                          ),
                        );
                      },
                    ),
    );
  }
}
