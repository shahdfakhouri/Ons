import 'package:flutter/material.dart';
import 'package:ons_app/models/retirement_home.dart';
import 'package:ons_app/services/retirement_home_service.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';

class ApproveRetirementHomesPage extends StatefulWidget {
  const ApproveRetirementHomesPage({super.key});

  @override
  State<ApproveRetirementHomesPage> createState() =>
      _ApproveRetirementHomesPageState();
}

class _ApproveRetirementHomesPageState
    extends State<ApproveRetirementHomesPage> {
  final RetirementHomeService _service = RetirementHomeService();

  bool _isLoading = true;
  List<RetirementHome> _pendingHomes = [];

  @override
  void initState() {
    super.initState();
    _loadHomes();
  }

  Future<void> _loadHomes() async {
    final all = await _service.getAllHomes();
    setState(() {
      _pendingHomes = all.where((h) => !h.isApproved).toList();
      _isLoading = false;
    });
  }

  Future<void> _handleApprove(RetirementHome home) async {
    final ok = await _service.approveHome(home.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _pendingHomes.removeWhere((h) => h.id == home.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${home.name}')),
      );
    }
  }

  Future<void> _handleReject(RetirementHome home) async {
    final ok = await _service.rejectHome(home.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _pendingHomes.removeWhere((h) => h.id == home.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${home.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Approve Retirement Homes',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingHomes.isEmpty
              ? const Center(
                  child: Text('No retirement homes waiting for approval.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingHomes.length,
                  itemBuilder: (context, index) {
                    final home = _pendingHomes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(home.name),
                        subtitle: Text(
                          'Location: ${home.location}\n'
                          'Capacity: ${home.capacity} residents\n'
                          'Current elders: ${home.elders.length}',
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
