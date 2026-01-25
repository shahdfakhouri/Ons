import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/safe_zones_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class LocationPage extends StatefulWidget {
  // ✅ 1. Accept the onBack navigation callback
  final void Function(int index)? onBack;
  const LocationPage({super.key, this.onBack});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  Map<String, dynamic>? loc;

  // ✅ 2. Define helper to return to Index 0 (Home)
  void _triggerBack() {
    if (widget.onBack != null) {
      widget.onBack!(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      loc = await api.locationCurrent();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _help() async {
    try {
      await api.requestHelp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Help request sent ✅'), behavior: SnackBarBehavior.floating)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(body: Center(child: Text('Error: $error')));

    final lat = loc?['latitude']?.toString() ?? loc?['lat']?.toString() ?? '-';
    final lng = loc?['longitude']?.toString() ?? loc?['lng']?.toString() ?? '-';
    final at = loc?['recorded_at']?.toString() ?? '';

    // ✅ 3. PopScope intercepts the device back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _triggerBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F4), // ONS Signature Cream
        appBar: AppBar(
          // ✅ 4. Manual back button navigation
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _triggerBack,
          ),
          title: const Text('My Location', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const SafeZonesPage())
              ),
              tooltip: 'Safe zones',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Where am I now?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Coordinates:', style: TextStyle(color: Color(0xFF8E9297), fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Latitude: $lat', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text('Longitude: $lng', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  if (at.isNotEmpty) 
                    Padding(
                      padding: const EdgeInsets.only(top: 12), 
                      child: Text('Last updated: $at', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // High-visibility Help Button
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assistant_direction, size: 32),
                label: const Text('I NEED HELP / I’M LOST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                onPressed: _help,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Don't worry. Your family and caregivers can see where you are and will come to help.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF435663), fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}