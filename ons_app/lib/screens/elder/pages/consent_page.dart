import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/models/elder_models.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/labeled_switch.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  final api = ElderApi();
  ElderConsent? consent;

  bool loading = true;
  String? error;

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
    setState(() { loading = true; error = null; });
    try {
      await api.updateConsent(consent!.toJson());
      setState(() { loading = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated ✅')));
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    final c = consent!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy / Consent'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Who can see what?',
            child: Column(
              children: [
                LabeledSwitch(
                  title: 'Share location',
                  subtitle: 'Allow family/caregiver to see my location',
                  value: c.shareLocation,
                  onChanged: (v) => setState(() => consent = ElderConsent(
                    shareLocation: v,
                    shareHealth: c.shareHealth,
                    shareMedia: c.shareMedia,
                    shareSummary: c.shareSummary,
                  )),
                ),
                LabeledSwitch(
                  title: 'Share health',
                  subtitle: 'Allow health logs / alerts',
                  value: c.shareHealth,
                  onChanged: (v) => setState(() => consent = ElderConsent(
                    shareLocation: c.shareLocation,
                    shareHealth: v,
                    shareMedia: c.shareMedia,
                    shareSummary: c.shareSummary,
                  )),
                ),
                LabeledSwitch(
                  title: 'Share gallery',
                  subtitle: 'Allow viewing photos/videos',
                  value: c.shareMedia,
                  onChanged: (v) => setState(() => consent = ElderConsent(
                    shareLocation: c.shareLocation,
                    shareHealth: c.shareHealth,
                    shareMedia: v,
                    shareSummary: c.shareSummary,
                  )),
                ),
                LabeledSwitch(
                  title: 'Share summaries',
                  subtitle: 'Allow daily summaries to be shared',
                  value: c.shareSummary,
                  onChanged: (v) => setState(() => consent = ElderConsent(
                    shareLocation: c.shareLocation,
                    shareHealth: c.shareHealth,
                    shareMedia: c.shareMedia,
                    shareSummary: v,
                  )),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: _save,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
