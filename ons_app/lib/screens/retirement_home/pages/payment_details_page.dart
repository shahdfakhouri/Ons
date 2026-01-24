import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementPaymentDetailsPage extends StatefulWidget {
  final int paymentId;
  const RetirementPaymentDetailsPage({super.key, required this.paymentId});

  @override
  State<RetirementPaymentDetailsPage> createState() => _RetirementPaymentDetailsPageState();
}

class _RetirementPaymentDetailsPageState extends State<RetirementPaymentDetailsPage> {
  final _api = RetirementHomeApi();

  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payment;
  List<Map<String, dynamic>> _tx = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final j = await _api.getPaymentById(widget.paymentId);
      final payment = (j['payment'] as Map?)?.cast<String, dynamic>() ?? {};
      final tx = (j['transactions'] as List?) ?? [];
      setState(() {
        _payment = payment;
        _tx = tx.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _cream, body: Center(child: CircularProgressIndicator(color: _deepNavy)));
    if (_error != null) return Scaffold(backgroundColor: _cream, appBar: AppBar(backgroundColor: Colors.white), body: Center(child: Text(_error!)));

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text('Invoice #${widget.paymentId}', style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: _deepNavy,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            _buildBentoSection("Payment Overview", [
              _row("Amount", "\$${_payment?['amount']}"),
              _row("Status", _payment?['status']?.toString().toUpperCase() ?? '-'),
              _row("Family", _payment?['family_name'] ?? '—'),
              _row("Purpose", _payment?['purpose'] ?? '-'),
              _row("Created", _payment?['created_at'] ?? '-'),
            ]),
            const SizedBox(height: 48),
            const Text('Transaction Ledger', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _deepNavy)),
            const SizedBox(height: 20),
            if (_tx.isEmpty)
              _buildEmptyState()
            else
              ..._tx.map((t) => _buildTxCard(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepNavy)),
          const Divider(height: 40),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _denim, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: _deepNavy, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTxCard(Map<String, dynamic> t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: _cream, child: Icon(Icons.sync_alt_rounded, color: _sage)),
        title: Text('${t['type']} Transfer', style: const TextStyle(fontWeight: FontWeight.bold, color: _deepNavy)),
        subtitle: Text('Amount: \$${t['amount']}\nDate: ${t['created_at']}'),
        trailing: Text('#${t['transaction_id']}', style: const TextStyle(fontSize: 10, color: _denim, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(24)),
      child: const Center(child: Text("No linked ledger entries.", style: TextStyle(color: _denim, fontStyle: FontStyle.italic))),
    );
  }
}