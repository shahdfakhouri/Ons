import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
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

  Future<void> _handleAnalyze(Map<String, dynamic> caregiver) async {
    final id = caregiver['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _analyzing[id] = true);
    try {
      final result = await _api.analyzeCaregiverCv(id);
      setState(() {
        caregiver['ai_score'] = result['ai_score'];
        caregiver['ai_feedback'] = result['ai_feedback'];
        _analyzing.remove(id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CV analyzed ✅')));
    } catch (e) {
      setState(() => _analyzing.remove(id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analyze failed: $e')));
    }
  }

  Future<void> _handleApprove(Map<String, dynamic> caregiver) async {
    final id = caregiver['id']?.toString() ?? '';
    try {
      await _api.approveUser('caregiver', id);
      setState(() => _pendingCaregivers.removeWhere((c) => c['id'].toString() == id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved ${caregiver['name']}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _handleReject(Map<String, dynamic> caregiver) async {
    final id = caregiver['id']?.toString() ?? '';
    try {
      await _api.rejectUser('caregiver', id);
      setState(() => _pendingCaregivers.removeWhere((c) => c['id'].toString() == id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected ${caregiver['name']}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return AdminLayout(
      title: 'Approve Caregivers',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorUI()
              : _pendingCaregivers.isEmpty
                  ? const Center(child: Text('No caregivers waiting for approval.'))
                  : ListView.builder(
                      itemCount: _pendingCaregivers.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        return _CaregiverCard(
                          caregiver: _pendingCaregivers[index],
                          isMobile: isMobile,
                          isAnalyzing: _analyzing[_pendingCaregivers[index]['id'].toString()] == true,
                          onAnalyze: () => _handleAnalyze(_pendingCaregivers[index]),
                          onApprove: () => _handleApprove(_pendingCaregivers[index]),
                          onReject: () => _handleReject(_pendingCaregivers[index]),
                        );
                      },
                    ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: _loadCaregivers, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  final Map<String, dynamic> caregiver;
  final bool isMobile;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _CaregiverCard({
    required this.caregiver,
    required this.isMobile,
    required this.isAnalyzing,
    required this.onAnalyze,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final type = (caregiver['employment_type']?.toString() ?? 'internal').toLowerCase();
    final bool isFreelance = type == 'freelance';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isFreelance ? Colors.blue.shade50 : Colors.purple.shade50,
                  child: Icon(isFreelance ? Icons.person : Icons.business, 
                         color: isFreelance ? Colors.blue : Colors.purple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caregiver['name'] ?? 'Unknown', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      _TypeBadge(isFreelance: isFreelance),
                    ],
                  ),
                ),
                // Only show side-by-side actions on Desktop
                if (!isMobile) _DesktopActions(
                  caregiver: caregiver, 
                  isAnalyzing: isAnalyzing, 
                  onAnalyze: onAnalyze, 
                  onApprove: onApprove, 
                  onReject: onReject
                ),
              ],
            ),
            const Divider(height: 32),
            _InfoRow(icon: Icons.email_outlined, text: caregiver['email'] ?? 'No email'),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone_outlined, text: caregiver['phone'] ?? 'No phone'),
            
            if (caregiver['ai_score'] != null) ...[
              const SizedBox(height: 16),
              _AiEvaluationBox(score: caregiver['ai_score'], feedback: caregiver['ai_feedback']),
            ],

            // Mobile view puts primary actions at the bottom for better reach
            if (isMobile) ...[
              const SizedBox(height: 20),
              _MobileActions(
                caregiver: caregiver, 
                isAnalyzing: isAnalyzing, 
                onAnalyze: onAnalyze, 
                onApprove: onApprove, 
                onReject: onReject
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- UI Sub-Components ---

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }
}

class _AiEvaluationBox extends StatelessWidget {
  final dynamic score;
  final dynamic feedback;
  const _AiEvaluationBox({this.score, this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
              const SizedBox(width: 6),
              Text("AI FIT SCORE: $score%", 
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
            ],
          ),
          if (feedback != null) ...[
            const SizedBox(height: 6),
            Text(feedback, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isFreelance;
  const _TypeBadge({required this.isFreelance});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFreelance ? Colors.blue.shade50 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(isFreelance ? "FREELANCE" : "INTERNAL STAFF", 
             style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isFreelance ? Colors.blue : Colors.purple)),
    );
  }
}

class _DesktopActions extends StatelessWidget {
  final Map<String, dynamic> caregiver;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DesktopActions({required this.caregiver, required this.isAnalyzing, required this.onAnalyze, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaregiverCvViewerPage(
                caregiverId: caregiver['id'].toString(),
                caregiverName: caregiver['name'] ?? 'Caregiver',
          ))),
        ),
        IconButton(
          icon: isAnalyzing 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.auto_awesome, color: Colors.deepPurple),
          onPressed: isAnalyzing ? null : onAnalyze,
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: onApprove, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('Approve')),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onReject, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject')),
      ],
    );
  }
}

class _MobileActions extends StatelessWidget {
  final Map<String, dynamic> caregiver;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _MobileActions({required this.caregiver, required this.isAnalyzing, required this.onAnalyze, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaregiverCvViewerPage(
                      caregiverId: caregiver['id'].toString(),
                      caregiverName: caregiver['name'] ?? 'Caregiver',
                ))),
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text("View CV"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isAnalyzing ? null : onAnalyze,
                icon: isAnalyzing 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.auto_awesome, size: 18),
                label: const Text("AI Analyze"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onApprove, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Approve"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onReject, 
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Reject"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}