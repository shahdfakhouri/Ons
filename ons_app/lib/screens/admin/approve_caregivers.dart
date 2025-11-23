import 'package:flutter/material.dart';
import 'package:ons_app/models/caregiver.dart';
import 'package:ons_app/services/caregiver_service.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

class ApproveCaregiversPage extends StatefulWidget {
  const ApproveCaregiversPage({super.key});

  @override
  State<ApproveCaregiversPage> createState() => _ApproveCaregiversPageState();
}

class _ApproveCaregiversPageState extends State<ApproveCaregiversPage> {
  final CaregiverService _service = CaregiverService();

  bool _isLoading = true;
  List<Caregiver> _pendingCaregivers = [];

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    final all = await _service.getAllCaregivers();
    setState(() {
      _pendingCaregivers = all.where((c) => !c.isApproved).toList();
      _isLoading = false;
    });
  }

  Future<void> _handleApprove(Caregiver caregiver) async {
    final ok = await _service.approveCaregiver(caregiver.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _pendingCaregivers.removeWhere((c) => c.id == caregiver.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${caregiver.name}')),
      );
    }
  }

  Future<void> _handleReject(Caregiver caregiver) async {
    final ok = await _service.rejectCaregiver(caregiver.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _pendingCaregivers.removeWhere((c) => c.id == caregiver.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${caregiver.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Approve Caregivers',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingCaregivers.isEmpty
              ? const Center(
                  child: Text('No caregivers waiting for approval.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingCaregivers.length,
                  itemBuilder: (context, index) {
                    final caregiver = _pendingCaregivers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(caregiver.name),
                        subtitle: Text(
                          'Experience: ${caregiver.experienceYears} years\n'
                          'Skills: ${caregiver.skills.join(', ')}\n'
                          'Rating: ${caregiver.rating.toStringAsFixed(1)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check),
                              tooltip: 'Approve',
                              onPressed: () => _handleApprove(caregiver),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Reject',
                              onPressed: () => _handleReject(caregiver),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
