import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'payment_details_page.dart';

class RetirementPaymentsPage extends StatefulWidget {
  const RetirementPaymentsPage({super.key});

  @override
  State<RetirementPaymentsPage> createState() => _RetirementPaymentsPageState();
}

class _RetirementPaymentsPageState extends State<RetirementPaymentsPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;

  String _status = 'all';
  List<Map<String, dynamic>> _payments = [];

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
      final list = await _api.getPayments(status: _status);
      setState(() {
        _payments = list;
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text('Payments', style: Theme.of(context).textTheme.titleLarge)),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('all')),
                  DropdownMenuItem(value: 'pending', child: Text('pending')),
                  DropdownMenuItem(value: 'paid', child: Text('paid')),
                  DropdownMenuItem(value: 'failed', child: Text('failed')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _status = v);
                  await _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_payments.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No payments found.')))
          else
            ..._payments.map((p) {
              final id = (p['payment_id'] ?? 0) as num;
              final family = (p['family_name'] ?? '—').toString();
              final amount = (p['amount'] ?? '—').toString();
              final status = (p['status'] ?? '—').toString();
              final purpose = (p['purpose'] ?? '').toString();
              final created = (p['created_at'] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text('Payment #${id.toInt()} • $amount • $status'),
                  subtitle: Text('Family: $family\nPurpose: $purpose\nCreated: $created'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RetirementPaymentDetailsPage(paymentId: id.toInt())),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
