import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ons_app/services/payment_api.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final PaymentApi _api = PaymentApi();
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _rev = {};
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
      final rev = await _api.getReceiverRevenue();
      final tx = await _api.getReceiverTransactions(limit: 100);

      setState(() {
        _rev = rev;
        _tx = tx;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _v(dynamic x, {String fallback = '-'}) {
    final s = (x ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _prettyDate(dynamic raw) {
    final s = _v(raw, fallback: '');
    if (s.isEmpty || s == '-') return '-';

    // handles: 2026-01-19T14:20:07.000Z
    DateTime? dt = DateTime.tryParse(s);

    // fallback for MySQL style: 2026-01-19 15:19:50
    dt ??= DateTime.tryParse(s.replaceFirst(' ', 'T'));

    if (dt == null) return s;

    // show in local time
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateFormat('MMM d, yyyy • h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final total =
        _rev['receiver_revenue'] ?? _rev['totalRevenue'] ?? _rev['total_revenue'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Total earnings'),
              trailing: Text('$total', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          const SizedBox(height: 12),
          Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_tx.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No transactions yet.'),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tx.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = _tx[i];

                  final fromLabel =
                      (t['from_name']?.toString().trim().isNotEmpty == true)
                          ? t['from_name']
                          : '${t['from_role'] ?? '-'}';

                  return ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text('${_v(t['type'])} • ${_v(t['amount'])}'),
                    subtitle: Text(
                      'From: $fromLabel\n'
                      '${_prettyDate(t['created_at'])}',
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
