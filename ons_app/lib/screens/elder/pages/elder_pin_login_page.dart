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

  static const int _pinLength = 4; // ✅ DB PIN = 4 digits
  String _pin = '';

  bool _loading = false;
  String? _error;

  void _addDigit(String d) {
    if (_loading) return;
    if (_pin.length >= _pinLength) return;

    setState(() {
      _pin += d;
      _error = null;
    });

    // optional auto-login when 4 digits complete
    if (_pin.length == _pinLength) {
      _login();
    }
  }

  void _backspace() {
    if (_loading) return;
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _clearPin() {
    if (_loading) return;
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _login() async {
    final elderId = int.tryParse(_elderIdCtrl.text.trim());

    if (elderId == null) {
      setState(() => _error = 'Please enter a valid Elder ID');
      return;
    }
    if (_pin.length != _pinLength) {
      setState(() => _error = 'PIN must be $_pinLength digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await ElderAuthService().pinLogin(elderId: elderId, pin: _pin);
      if (!mounted) return;

      if (!ok) {
        setState(() => _error = 'Invalid Elder ID or PIN');
        _clearPin();
        return;
      }

      Navigator.of(context).pushReplacementNamed(ElderRoutes.home);
    } catch (e) {
      setState(() => _error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _pinDots(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final filled = i < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: filled ? cs.primary : cs.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant),
          ),
        );
      }),
    );
  }

  Widget _key(BuildContext context, String label, {VoidCallback? onTap, bool primary = false}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _loading ? null : (onTap ?? () => _addDigit(label)),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: _loading && label == 'OK'
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3))
            : Text(
                label,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primary ? cs.onPrimary : cs.onSurface,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _elderIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Elder Login')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Enter Elder ID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _elderIdCtrl,
                    enabled: !_loading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 4',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Enter 4-digit PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _pinDots(context),
                  const SizedBox(height: 10),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 18),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                for (final d in ['1','2','3','4','5','6','7','8','9']) _key(context, d),
                _key(context, '⌫', onTap: _backspace),
                _key(context, '0'),
                _key(context, 'OK', onTap: _login, primary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
