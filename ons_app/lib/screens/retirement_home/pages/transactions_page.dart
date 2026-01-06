import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class RetirementTransactionsPage extends StatefulWidget {
  const RetirementTransactionsPage({super.key});

  @override
  State<RetirementTransactionsPage> createState() => _RetirementTransactionsPageState();
}

class _RetirementTransactionsPageState extends State<RetirementTransactionsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

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
      final list = await _api.getTransactions(limit: 100);
      setState(() {
        _tx = list;
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tx.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final t = _tx[i];
          return Card(
            child: ListTile(
              title: Text('TX #${t['transaction_id']} • ${t['amount']} • ${t['type']}'),
              subtitle: Text('Payment: ${t['payment_id']}\n'
                  'From: ${t['from_role']} (${t['from_id']}) → To: ${t['to_role']} (${t['to_id']})\n'
                  '${t['created_at']}'),
            ),
          );
        },
      ),
    );
  }
}
