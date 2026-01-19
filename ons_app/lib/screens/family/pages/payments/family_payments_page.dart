import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/services/transaction_api.dart';

class FamilyPaymentsPage extends StatefulWidget {
  const FamilyPaymentsPage({super.key});

  @override
  State<FamilyPaymentsPage> createState() => _FamilyPaymentsPageState();
}

class _FamilyPaymentsPageState extends State<FamilyPaymentsPage> with TickerProviderStateMixin {
  final FamilyApi _familyApi = FamilyApi();
  final TransactionApi _txApi = TransactionApi();

  late final TabController _tabs;

  // forms
  String _method = 'paypal';

  final _caregiverId = TextEditingController();
  final _homeId = TextEditingController();
  final _medicineId = TextEditingController();
  final _amount = TextEditingController();

  bool _loadingPay = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _caregiverId.dispose();
    _homeId.dispose();
    _medicineId.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  num? _parseAmount() => num.tryParse(_amount.text.trim());

  Future<void> _payFreelancer() async {
    final caregiverId = int.tryParse(_caregiverId.text.trim());
    final amount = _parseAmount();
    if (caregiverId == null || amount == null || amount <= 0) {
      _snack('Enter valid caregiver_id and amount', error: true);
      return;
    }

    setState(() => _loadingPay = true);
    try {
      await _txApi.payFreelancer(caregiverId: caregiverId, amount: amount, method: _method);
      _snack('Payment completed ✅');
      _amount.clear();
      _caregiverId.clear();
      setState(() {}); // refresh history builders
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loadingPay = false);
    }
  }

  Future<void> _payHome() async {
    final homeId = int.tryParse(_homeId.text.trim());
    final caregiverId = int.tryParse(_caregiverId.text.trim());
    final amount = _parseAmount();
    if (homeId == null || caregiverId == null || amount == null || amount <= 0) {
      _snack('Enter valid home_id, caregiver_id and amount', error: true);
      return;
    }

    setState(() => _loadingPay = true);
    try {
      await _txApi.payHome(homeId: homeId, caregiverId: caregiverId, amount: amount, method: _method);
      _snack('Payment completed ✅');
      _amount.clear();
      _homeId.clear();
      _caregiverId.clear();
      setState(() {});
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loadingPay = false);
    }
  }

  Future<void> _payMedicine() async {
    final medicineId = int.tryParse(_medicineId.text.trim());
    final amount = _parseAmount();
    if (medicineId == null || amount == null || amount <= 0) {
      _snack('Enter valid medicine_id and amount', error: true);
      return;
    }

    setState(() => _loadingPay = true);
    try {
      await _txApi.payMedicine(medicineId: medicineId, amount: amount, method: _method);
      _snack('Payment completed ✅');
      _amount.clear();
      _medicineId.clear();
      setState(() {});
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loadingPay = false);
    }
  }

  Widget _methodPicker() {
    return DropdownButtonFormField<String>(
      value: _method,
      decoration: const InputDecoration(
        labelText: 'Method',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'paypal', child: Text('paypal')),
        DropdownMenuItem(value: 'on_arrival', child: Text('on_arrival')),
        DropdownMenuItem(value: 'cash', child: Text('cash')),
      ],
      onChanged: (v) => setState(() => _method = v ?? 'paypal'),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _payTab({required Widget child, required VoidCallback onPay, required String btn}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _methodPicker(),
                const SizedBox(height: 10),
                _numField(_amount, 'Amount'),
                const SizedBox(height: 12),
                child,
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadingPay ? null : onPay,
                    icon: _loadingPay
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.payments),
                    label: Text(btn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic res, {required String key}) {
    if (res is Map<String, dynamic>) {
      final v = res[key];
      if (v is List) return v.map((e) => Map<String, dynamic>.from(e)).toList();
      final data = res['data'];
      if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Widget _historyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Payment history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder(
          future: _familyApi.getPayments(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
            }
            if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

            final list = _extractList(snap.data, key: 'payments');
            if (list.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No payments yet.')));
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = list[i];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Payment #${p['payment_id'] ?? '-'} • ${p['status'] ?? '-'}'),
                    subtitle: Text(
                      'Target: ${p['target_type'] ?? '-'} #${p['target_id'] ?? '-'}\n'
                      'Amount: ${p['amount'] ?? '-'} • Method: ${p['method'] ?? '-'}\n'
                      '${p['created_at'] ?? ''}',
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text('Transaction history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder(
          future: _familyApi.getTransactions(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
            }
            if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}')));

            final list = _extractList(snap.data, key: 'transactions');
            if (list.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No transactions yet.')));
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = list[i];
                  return ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text('${t['type'] ?? '-'} • ${t['amount'] ?? '-'}'),
                    subtitle: Text(
                      'From: ${t['from_role'] ?? '-'} #${t['from_id'] ?? '-'} → To: ${t['to_role'] ?? '-'} #${t['to_id'] ?? '-'}\n'
                      'Payment: ${t['payment_id'] ?? '-'}\n'
                      '${t['created_at'] ?? ''}',
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pay Caregiver'),
            Tab(text: 'Pay Home'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _payTab(
            btn: 'Pay freelancer caregiver',
            onPay: _payFreelancer,
            child: Column(
              children: [
                _numField(_caregiverId, 'Caregiver ID'),
              ],
            ),
          ),
          _payTab(
            btn: 'Pay retirement home',
            onPay: _payHome,
            child: Column(
              children: [
                _numField(_homeId, 'Home ID'),
                const SizedBox(height: 10),
                _numField(_caregiverId, 'Caregiver ID (employee)'),
              ],
            ),
          ),
          _historyTab(),
        ],
      ),
    );
  }
}
