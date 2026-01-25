import 'package:flutter/material.dart';
import 'package:ons_app/screens/elder/pages/medication_history_page.dart';
import 'package:ons_app/services/elder_api.dart';
import 'package:ons_app/screens/elder/widgets/section_card.dart';

class MedicationTodayPage extends StatefulWidget {
  // 1. Correctly define the callback in the Widget class
  final void Function(int index)? onBack; 
  const MedicationTodayPage({super.key, this.onBack});

  @override
  State<MedicationTodayPage> createState() => _MedicationTodayPageState();
}

class _MedicationTodayPageState extends State<MedicationTodayPage> {
  final api = ElderApi();
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final list = await api.medsToday();
      setState(() { items = list; loading = false; });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _confirm(dynamic item) async {
    final Map<String, dynamic> body = {};
    final id = item['medication_id'] ?? item['id'] ?? item['schedule_id'] ?? item['log_id'];
    if (id != null) body['medication_id'] = id;

    final scheduled = item['scheduled_time'] ?? item['time'];
    if (scheduled != null && scheduled.toString().trim().isNotEmpty) {
      body['scheduled_time'] = scheduled;
    }

    try {
      await api.confirmMedTaken(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as taken ✅')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Confirm failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text('Error: $error'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines Today'),
        // 2. Access the callback using 'widget.onBack'
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!(0); // Navigates back to Home (Index 0)
            }
          },
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationHistoryPage())),
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Today Schedule',
            child: items.isEmpty
                ? const Text('No medicines for today ✅')
                : Column(
                    children: items.map((e) {
                      final name = (e['name'] ?? e['medicine_name'] ?? 'Medicine').toString();
                      final dose = (e['dosage'] ?? e['dose'] ?? '').toString();
                      final time = (e['time'] ?? e['scheduled_time'] ?? e['at'] ?? '').toString();
                      final status = (e['status'] ?? e['taken'] ?? '').toString();

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.medication),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text([
                            if (dose.isNotEmpty) 'Dose: $dose', 
                            if (time.isNotEmpty) 'Time: $time', 
                            if (status.isNotEmpty) 'Status: $status'
                          ].join(' • ')),
                          trailing: FilledButton(
                            onPressed: () => _confirm(e),
                            child: const Text('Taken'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}