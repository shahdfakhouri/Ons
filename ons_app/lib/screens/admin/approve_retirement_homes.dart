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

      // Filter for retirement homes and map the results
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
              ? _buildErrorUI()
              : _pendingHomes.isEmpty
                  ? const Center(child: Text('No retirement homes waiting for approval.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingHomes.length,
                      itemBuilder: (context, index) {
                        final home = _pendingHomes[index];
                        final name = home['name']?.toString() ?? 'Unknown Facility';
                        final email = home['email']?.toString() ?? '';
                        final phone = home['phone']?.toString() ?? '';
                        final city = home['city']?.toString() ?? 'Palestine';
                        
                        // Handle comma-separated services from DB
                        final String servicesRaw = home['services']?.toString() ?? 'General Care';
                        final List<String> servicesList = servicesRaw.split(',');

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Icon(Icons.business, color: Colors.white),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    if (email.isNotEmpty) 'Contact: $email',
                                    if (phone.isNotEmpty) 'Phone: $phone',
                                    'Location: $city',
                                  ].join('\n'),
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                                const SizedBox(height: 12),
                                
                                // 🏥 FACILITY SERVICES CHIPS
                                const Text(
                                  "OFFERED SERVICES:",
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.grey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: servicesList.map((service) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.purple.shade100),
                                    ),
                                    child: Text(
                                      service.trim().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade900,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: _buildActionButtons(home),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> home) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'Approve',
          onPressed: () => _handleApprove(home),
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          tooltip: 'Reject',
          onPressed: () => _handleReject(home),
        ),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadHomes,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}