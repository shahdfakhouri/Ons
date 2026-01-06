import 'package:flutter/material.dart';
import 'package:ons_app/services/retirement_home_api.dart';
import 'elder_details_page.dart';

class RetirementEldersPage extends StatefulWidget {
  const RetirementEldersPage({super.key});

  @override
  State<RetirementEldersPage> createState() => _RetirementEldersPageState();
}

class _RetirementEldersPageState extends State<RetirementEldersPage> {
  final _api = RetirementHomeApi();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _elders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getEldersMonitoring();
      setState(() {
        _elders = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _elders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = _elders[i];
          final id = (e['elder_id'] ?? 0) as num;
          final name = (e['elder_name'] ?? e['name'] ?? 'Elder').toString();
          final age = (e['age'] ?? '').toString();
          final caregiver = (e['caregiver_name'] ?? '—').toString();
          final lastCheckIn = (e['last_check_in'] ?? '—').toString();

          return Card(
            child: ListTile(
              title: Text('$name (ID: ${id.toInt()})'),
              subtitle: Text('Age: $age • Caregiver: $caregiver • Last check-in: $lastCheckIn'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RetirementElderDetailsPage(elderId: id.toInt())),
                );
                // refresh after returning
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}
