import 'package:flutter/material.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/services/admin_api.dart';

class ApproveRetirementHomesPage extends StatefulWidget {
  const ApproveRetirementHomesPage({super.key});

  @override
  State<ApproveRetirementHomesPage> createState() =>
      _ApproveRetirementHomesPageState();
}

class _ApproveRetirementHomesPageState extends State<ApproveRetirementHomesPage> {
  final AdminApi _api = AdminApi();

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _pendingHomes = [];

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  Future<void> _loadHomes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pending = await _api.getApprovals();

      final homes = pending
          .where((u) => (u['role']?.toString() ?? '') == 'retirement_home')
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _pendingHomes = homes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove(Map<String, dynamic> home) async {
    final id = home['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      await _api.approveUser('retirement_home', id);

      if (!mounted) return;
      setState(() {
        _pendingHomes.removeWhere((h) => h['id'].toString() == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${home['name'] ?? 'home'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> _handleReject(Map<String, dynamic> home) async {
    final id = home['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      await _api.rejectUser('retirement_home', id);

      if (!mounted) return;
      setState(() {
        _pendingHomes.removeWhere((h) => h['id'].toString() == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${home['name'] ?? 'home'}')),
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
      title: 'Approve Retirement Homes',
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
                        onPressed: _loadHomes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingHomes.isEmpty
                  ? const Center(
                      child: Text('No retirement homes waiting for approval.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingHomes.length,
                      itemBuilder: (context, index) {
                        final home = _pendingHomes[index];

                        final name = home['name']?.toString() ?? 'Unknown';
                        final email = home['email']?.toString() ?? '';
                        final phone = home['phone']?.toString() ?? '';
                        final id = home['id']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(
                              [
                                if (email.isNotEmpty) 'Email: $email',
                                if (phone.isNotEmpty) 'Phone: $phone',
                                'ID: $id',
                              ].join('\n'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  tooltip: 'Approve',
                                  onPressed: () => _handleApprove(home),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Reject',
                                  onPressed: () => _handleReject(home),
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
