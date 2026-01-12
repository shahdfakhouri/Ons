import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder(
        future: api.getPayments(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final list = (data['payments'] as List?) ?? const [];

          if (list.isEmpty) return const EmptyState(title: 'No payments yet');

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = list[i] as Map;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.payments),
                  title: Text('Amount: ${p['amount'] ?? p['total'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Status: ${p['status'] ?? '-'} • ${p['created_at'] ?? ''}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
