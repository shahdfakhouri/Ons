import 'package:flutter/material.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late final RetirementHomeApi api;
  String paymentsFilter = 'all';

  @override
  void initState() {
    super.initState();
    api = RetirementHomeApi(DioFactory.create());
  }

  Future<void> _openPayment(int paymentId) async {
    final details = await api.getPaymentDetails(paymentId);
    if (!mounted) return;

    final payment = details['payment'] as Map?;
    final tx = (details['transactions'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Payment #$paymentId'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: ListView(
            children: [
              Text('Amount: ${payment?['amount'] ?? '-'}'),
              Text('Status: ${payment?['status'] ?? '-'}'),
              Text('Method: ${payment?['method'] ?? '-'}'),
              Text('Purpose: ${payment?['purpose'] ?? '-'}'),
              const Divider(),
              const Text('Transactions'),
              ...tx.map((t) => ListTile(
                    title: Text('Amount: ${t['amount']}'),
                    subtitle: Text('${t['from_role']} -> ${t['to_role']}\n${t['created_at']}'),
                    isThreeLine: true,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RetirementHomeLayout(
      title: 'Finance',
      child: Column(
        children: [
          Row(
            children: [
              const Text('Payments filter:  '),
              DropdownButton<String>(
                value: paymentsFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                ],
                onChanged: (v) => setState(() => paymentsFilter = v ?? 'all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: api.getPayments(status: paymentsFilter),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

                      final payments = (snap.data as List<Map<String, dynamic>>?) ?? [];
                      if (payments.isEmpty) return const Center(child: Text('No payments.'));

                      return ListView.separated(
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = payments[i];
                          final id = int.tryParse(p['payment_id'].toString()) ?? 0;
                          return ListTile(
                            title: Text('Payment #$id - ${p['amount'] ?? '-'}'),
                            subtitle: Text('Status: ${p['status'] ?? '-'} | ${p['created_at'] ?? ''}'),
                            onTap: () => _openPayment(id),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder(
                    future: api.getTransactions(limit: 100),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

                      final tx = (snap.data as List<Map<String, dynamic>>?) ?? [];
                      if (tx.isEmpty) return const Center(child: Text('No transactions.'));

                      return ListView.separated(
                        itemCount: tx.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = tx[i];
                          return ListTile(
                            title: Text('Amount: ${t['amount'] ?? '-'}'),
                            subtitle: Text('${t['from_role']} -> ${t['to_role']}\n${t['created_at'] ?? ''}'),
                            isThreeLine: true,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
