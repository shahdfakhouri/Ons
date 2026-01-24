import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementIncidentDetailsPage extends StatefulWidget {
  final int incidentId;
  const RetirementIncidentDetailsPage({super.key, required this.incidentId});

  @override
  State<RetirementIncidentDetailsPage> createState() => _RetirementIncidentDetailsPageState();
}

class _RetirementIncidentDetailsPageState extends State<RetirementIncidentDetailsPage> {
  final _api = RetirementHomeApi();
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _incident;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final inc = await _api.getIncidentById(widget.incidentId);
      setState(() {
        _incident = inc;
        _status = (inc['status'] ?? 'open').toString();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updateStatus(String s) async {
    try {
      await _api.updateIncidentStatus(widget.incidentId, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log Updated ✅'), behavior: SnackBarBehavior.floating));
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _cream, body: Center(child: CircularProgressIndicator(color: _deepNavy)));
    if (_error != null) return Scaffold(backgroundColor: _cream, appBar: AppBar(), body: Center(child: Text(_error!)));

    final i = _incident ?? {};

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text('Case Log #${widget.incidentId}', style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: _deepNavy,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          _buildInfoBento(i),
          const SizedBox(height: 32),
          _buildStatusUpdateBento(),
        ],
      ),
    );
  }

  Widget _buildInfoBento(Map<String, dynamic> i) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Case Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _deepNavy)),
          const Divider(height: 40),
          _detailRow("Type", i['type']),
          _detailRow("Severity", i['severity']?.toString().toUpperCase(), color: Colors.redAccent),
          _detailRow("Elder ID", i['elder_id'].toString()),
          _detailRow("Created", i['created_at']),
          const SizedBox(height: 24),
          const Text("Description", style: TextStyle(color: _denim, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(i['description'] ?? 'No description available', style: const TextStyle(color: _deepNavy, height: 1.5)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _denim, fontWeight: FontWeight.w600)),
          Text(value ?? '—', style: TextStyle(color: color ?? _deepNavy, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateBento() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Administrative Action", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepNavy)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              filled: true,
              fillColor: _cream.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
              DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => _updateStatus(_status),
              style: FilledButton.styleFrom(backgroundColor: _deepNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text("Commit Status Update", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}