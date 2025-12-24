import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
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

      // pending contains caregivers + retirement_homes
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
                        onPressed: _loadCaregivers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingCaregivers.isEmpty
                  ? const Center(
                      child: Text('No caregivers waiting for approval.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingCaregivers.length,
                      itemBuilder: (context, index) {
                        final caregiver = _pendingCaregivers[index];
                        final name = caregiver['name']?.toString() ?? 'Unknown';
                        final email = caregiver['email']?.toString() ?? '';
                        final phone = caregiver['phone']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(
                              [
                                if (email.isNotEmpty) 'Email: $email',
                                if (phone.isNotEmpty) 'Phone: $phone',
                                'ID: ${caregiver['id']}',
                              ].join('\n'),
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
