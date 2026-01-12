import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/elder_routes.dart';
import 'package:ons_app/services/elder_auth_service.dart';

class ElderLoginPage extends StatefulWidget {
  const ElderLoginPage({super.key});

  @override
  State<ElderLoginPage> createState() => _ElderLoginPageState();
}

class _ElderLoginPageState extends State<ElderLoginPage> {
  final _elderIdCtrl = TextEditingController();
  String _pin = '';
  bool _loading = false;
  String? _error;

  void _addDigit(String d) {
    if (_pin.length >= 6) return;
    setState(() => _pin += d);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _login() async {
    final elderId = int.tryParse(_elderIdCtrl.text.trim());
    if (elderId == null) {
      setState(() => _error = 'Please enter a valid Elder ID');
      return;
    }
    if (_pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = await ElderAuthService().pinLogin(elderId: elderId, pin: _pin);

    setState(() => _loading = false);

    if (!ok) {
      setState(() => _error = 'Invalid PIN');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(ElderRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget key(String label, {VoidCallback? onTap}) {
      return SizedBox(
        height: 72,
        child: FilledButton(
          onPressed: onTap ?? () => _addDigit(label),
          child: Text(label, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Elder Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _elderIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Elder ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('PIN: ${'*' * _pin.length}', style: t.headlineSmall),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  for (final d in ['1','2','3','4','5','6','7','8','9'])
                    key(d),
                  key('⌫', onTap: _backspace),
                  key('0'),
                  key(_loading ? '...' : 'OK', onTap: _loading ? null : _login),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
