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
    setState(() {
      _loading = true;
      _error = null;
    });

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
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));

    final p = _payment ?? {};

    return Scaffold(
      appBar: AppBar(title: Text('Payment #${widget.paymentId}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Amount: ${p['amount']}\n'
                  'Status: ${p['status']}\n'
                  'Method: ${p['method']}\n'
                  'Purpose: ${p['purpose']}\n'
                  'Family: ${p['family_name'] ?? '—'}\n'
                  'Created: ${p['created_at']}\n',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_tx.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No transactions found.')))
            else
              ..._tx.map((t) {
                return Card(
                  child: ListTile(
                    title: Text('TX #${t['transaction_id']} • ${t['amount']} • ${t['type']}'),
                    subtitle: Text('From: ${t['from_role']} (${t['from_id']}) → To: ${t['to_role']} (${t['to_id']})\n${t['created_at']}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
