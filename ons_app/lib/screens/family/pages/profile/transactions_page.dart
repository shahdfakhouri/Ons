import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/screens/family/widgets/family_ui.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final api = FamilyApi();
  Future<void> _reload() async => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
      body: FutureBuilder(
        future: api.getTransactions(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final data = (snap.data as Map<String, dynamic>? ?? {});
          final list = (data['transactions'] as List?) ?? const [];

          if (list.isEmpty) return const EmptyState(title: 'No transactions yet');

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = list[i] as Map;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('To: ${t['to_role'] ?? '-'} #${t['to_id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Amount: ${t['amount'] ?? '-'} • ${t['created_at'] ?? ''}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
