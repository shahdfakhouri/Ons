import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/models/elder_models.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/labeled_switch.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class ConsentPage extends StatefulWidget {
  final void Function(int index)? onBack;
  const ConsentPage({super.key, this.onBack});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  final api = ElderApi();
  ElderConsent? consent;
  bool loading = true;
  String? error;

  void _triggerBack() {
    if (widget.onBack != null) widget.onBack!(0);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await api.getConsent();
      setState(() {
        consent = ElderConsent.fromJson(data);
        loading = false;
      });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _save() async {
    if (consent == null) return;
    setState(() { loading = true; });
    try {
      await api.updateConsent(consent!.toJson());
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Settings Updated ✅')));
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text('Error: $error')));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F4),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _triggerBack),
          title: const Text('Privacy & Consent', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Who can see what?',
              child: Column(
                children: [
                  _buildSwitch('Share location', 'Allow family to see my location', consent!.shareLocation, (v) => _updateConsent(location: v)),
                  _buildSwitch('Share health', 'Allow health logs / alerts', consent!.shareHealth, (v) => _updateConsent(health: v)),
                  _buildSwitch('Share gallery', 'Allow viewing photos', consent!.shareMedia, (v) => _updateConsent(media: v)),
                  _buildSwitch('Daily summary', 'Share AI wellness reports', consent!.shareSummary, (v) => _updateConsent(summary: v)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(icon: const Icon(Icons.save), label: const Text('Save Settings'), onPressed: _save),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateConsent({bool? location, bool? health, bool? media, bool? summary}) {
    setState(() {
      consent = ElderConsent(
        shareLocation: location ?? consent!.shareLocation,
        shareHealth: health ?? consent!.shareHealth,
        shareMedia: media ?? consent!.shareMedia,
        shareSummary: summary ?? consent!.shareSummary,
      );
    });
  }

  Widget _buildSwitch(String t, String s, bool v, Function(bool) onChanged) {
    return LabeledSwitch(title: t, subtitle: s, value: v, onChanged: onChanged);
  }
}