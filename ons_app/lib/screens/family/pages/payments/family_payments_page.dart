import 'package:flutter/material.dart';
import 'package:ons_app/services/family_api.dart';
import 'package:ons_app/services/transaction_api.dart';
import 'package:ons_app/services/payment_api.dart';
import 'package:url_launcher/url_launcher.dart';

class FamilyPaymentsPage extends StatefulWidget {
  const FamilyPaymentsPage({super.key});

  @override
  State<FamilyPaymentsPage> createState() => _FamilyPaymentsPageState();
}

class _FamilyPaymentsPageState extends State<FamilyPaymentsPage> with TickerProviderStateMixin {
  final FamilyApi _familyApi = FamilyApi();
  final TransactionApi _txApi = TransactionApi();
  final PaymentApi _payApi = PaymentApi();

  late final TabController _tabs;
  String _method = 'paypal';

  // 🎨 Ons Signature Palette
  static const _deepNavy = Color(0xFF313647);
  static const _denim = Color(0xFF435663);
  static const _sage = Color(0xFFA3B087);
  static const _cream = Color(0xFFFFF8D4);

  final _caregiverId = TextEditingController();
  final _homeId = TextEditingController();
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
    _amount.dispose();
    super.dispose();
  }

  // --- 🛠️ FUNCTIONALITY (RETAINED FROM YOUR CODE) ---

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: error ? Colors.redAccent : _sage,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  num? _parseAmount() => num.tryParse(_amount.text.trim());

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw Exception('Could not open PayPal checkout');
  }

  Future<bool> _confirmAfterPayment() async {
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Complete payment', style: TextStyle(fontWeight: FontWeight.w900, color: _deepNavy)),
            content: const Text('After you finish the PayPal payment in the browser, come back here and press "I Paid".'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _denim))),
              FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: _sage), child: const Text('I Paid')),
            ],
          ),
        )) ?? false;
  }

  Future<void> _payWithPaypal({required int paymentId, required num amount}) async {
    final orderRes = await _payApi.createPayPalOrder(paymentId: paymentId, amount: amount);
    final approveUrl = (orderRes['approveUrl'] ?? '').toString();
    final orderId = (orderRes['orderId'] ?? '').toString();
    if (approveUrl.isEmpty || orderId.isEmpty) throw Exception('PayPal order failed');

    await _openUrl(approveUrl);
    final paid = await _confirmAfterPayment();
    if (!paid) { _snack('Payment cancelled', error: true); return; }
    await _payApi.capturePayPal(orderId: orderId, paymentId: paymentId);
  }

  Future<void> _payFreelancer() async {
    final caregiverId = int.tryParse(_caregiverId.text.trim());
    final amount = _parseAmount();
    if (caregiverId == null || amount == null || amount <= 0) {
      _snack('Enter valid caregiver_id and amount', error: true);
      return;
    }
    setState(() => _loadingPay = true);
    try {
      final txRes = await _txApi.payFreelancer(caregiverId: caregiverId, amount: amount, method: _method);
      if (_method == 'paypal') {
        final pId = _asInt(txRes['paymentId'] ?? txRes['payment_id']);
        await _payWithPaypal(paymentId: pId, amount: amount);
        _snack('PayPal payment completed ✅');
      } else { _snack('Payment recorded ✅ (${_method})'); }
      _amount.clear(); _caregiverId.clear();
      setState(() {});
    } catch (e) { _snack(e.toString(), error: true); }
    finally { if (mounted) setState(() => _loadingPay = false); }
  }

  Future<void> _payHome() async {
    final homeId = int.tryParse(_homeId.text.trim());
    final caregiverId = int.tryParse(_caregiverId.text.trim());
    final amount = _parseAmount();
    if (homeId == null || caregiverId == null || amount == null || amount <= 0) {
      _snack('Enter valid IDs and amount', error: true); return;
    }
    if (_method == 'paypal') {
      _snack('PayPal for homes not supported yet. Use on_arrival.', error: true); return;
    }
    setState(() => _loadingPay = true);
    try {
      await _txApi.payHome(homeId: homeId, caregiverId: caregiverId, amount: amount, method: _method);
      _snack('Payment recorded ✅');
      _amount.clear(); _homeId.clear(); _caregiverId.clear();
      setState(() {});
    } catch (e) { _snack(e.toString(), error: true); }
    finally { if (mounted) setState(() => _loadingPay = false); }
  }

  // --- 🎨 UI ENHANCEMENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Financial Center', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _deepNavy,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _deepNavy,
          unselectedLabelColor: _denim,
          indicatorColor: _sage,
          indicatorWeight: 4,
          tabs: const [Tab(text: 'Caregiver'), Tab(text: 'Home'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildForm(
            title: "Independent Caregiver",
            btn: "Settle Payment",
            onPay: _payFreelancer,
            children: [_buildField(_caregiverId, "Caregiver ID", Icons.badge_outlined)],
          ),
          _buildForm(
            title: "Retirement Facility",
            btn: "Authorize Transfer",
            onPay: _payHome,
            children: [
              _buildField(_homeId, "Facility ID", Icons.apartment_rounded),
              const SizedBox(height: 12),
              _buildField(_caregiverId, "Assigned Staff ID", Icons.assignment_ind_outlined),
            ],
          ),
          _historyTab(),
        ],
      ),
    );
  }

  Widget _buildForm({required String title, required String btn, required VoidCallback onPay, required List<Widget> children}) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _deepNavy)),
              const SizedBox(height: 24),
              _methodPicker(),
              const SizedBox(height: 12),
              _buildField(_amount, "Amount (\$)", Icons.monetization_on_outlined, isNum: true),
              const SizedBox(height: 12),
              ...children,
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _loadingPay ? null : onPay,
                  style: FilledButton.styleFrom(backgroundColor: _deepNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _loadingPay 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(btn, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {bool isNum = false}) {
    return TextField(
      controller: c,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _denim, size: 20),
        filled: true,
        fillColor: _cream.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _methodPicker() {
    return DropdownButtonFormField<String>(
      value: _method,
      decoration: InputDecoration(
        labelText: 'Payment Method',
        filled: true,
        fillColor: _cream.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: const [
        DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
        DropdownMenuItem(value: 'on_arrival', child: Text('On Arrival')),
        DropdownMenuItem(value: 'cash', child: Text('Cash')),
      ],
      onChanged: (v) => setState(() => _method = v ?? 'paypal'),
    );
  }

  Widget _historyTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("Ledger History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _deepNavy)),
        const SizedBox(height: 16),
        _buildHistorySection("Payments", _familyApi.getPayments(), 'payments'),
        const SizedBox(height: 32),
        _buildHistorySection("Transactions", _familyApi.getTransactions(), 'transactions'),
      ],
    );
  }

  Widget _buildHistorySection(String title, Future<dynamic> future, String key) {
    return FutureBuilder(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(color: _sage);
        final list = _extractList(snap.data, key: key);
        if (list.isEmpty) return Text("No $title found.", style: const TextStyle(color: _denim, fontStyle: FontStyle.italic));
        
        return Column(
          children: list.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: Icon(key == 'payments' ? Icons.receipt_long : Icons.swap_horiz, color: _sage),
              title: Text("${item['amount']} • ${item['status'] ?? item['type']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['created_at'] ?? ''),
            ),
          )).toList(),
        );
      },
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic res, {required String key}) {
    if (res is Map<String, dynamic>) {
      final v = res[key] ?? res['data'];
      if (v is List) return v.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}