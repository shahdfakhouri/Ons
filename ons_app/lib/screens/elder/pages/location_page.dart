import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/safe_zones_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  Map<String, dynamic>? loc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      loc = await api.locationCurrent();
      setState(() => loading = false);
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _help() async {
    try {
      await api.requestHelp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help request sent ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    final lat = loc?['latitude']?.toString() ?? loc?['lat']?.toString() ?? '-';
    final lng = loc?['longitude']?.toString() ?? loc?['lng']?.toString() ?? '-';
    final at = loc?['recorded_at']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.shield),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeZonesPage())),
            tooltip: 'Safe zones',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Where am I?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latitude: $lat', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Longitude: $lng', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (at.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Updated: $at')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 72,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.assistant),
              label: const Text('I need help / I’m lost'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: _help,
            ),
          ),
        ],
      ),
    );
  }
}
