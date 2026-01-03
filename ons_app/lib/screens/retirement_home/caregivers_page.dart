import 'package:flutter/material.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/services/dio_factory.dart';
import 'package:ons_app/services/retirement_home_api.dart';

class CaregiversPage extends StatefulWidget {
  const CaregiversPage({super.key});

  @override
  State<CaregiversPage> createState() => _CaregiversPageState();
}

class _CaregiversPageState extends State<CaregiversPage> {
  late final RetirementHomeApi api;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> caregivers = [];

  @override
  void initState() {
    super.initState();
    api = RetirementHomeApi(DioFactory.create());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      caregivers = await api.getHomeCaregivers();
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    try {
      final available = await api.getAvailableCaregivers();
      if (!mounted) return;

      final picked = await showDialog<int>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Add caregiver'),
          content: SizedBox(
            width: 420,
            height: 400,
            child: ListView.builder(
              itemCount: available.length,
              itemBuilder: (context, i) {
                final c = available[i];
                final id = int.tryParse(c['caregiver_id'].toString()) ?? 0;
                return ListTile(
                  title: Text('${c['name'] ?? '-'}'),
                  subtitle: Text('${c['phone'] ?? ''}  ${c['email'] ?? ''}'),
                  onTap: () => Navigator.pop(context, id),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      );

      if (picked != null) {
        await api.addCaregiverToHome(picked);
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _remove(int caregiverId) async {
    await api.removeCaregiverFromHome(caregiverId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RetirementHomeLayout(
      title: 'Caregivers',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add caregiver'),
            ),
          ),
          const SizedBox(height: 12),
          if (loading) const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error != null) Expanded(child: Center(child: Text('Error: $error')))
          else if (caregivers.isEmpty) const Expanded(child: Center(child: Text('No caregivers in this home.')))
          else
            Expanded(
              child: ListView.separated(
                itemCount: caregivers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = caregivers[i];
                  final id = int.tryParse(c['caregiver_id'].toString()) ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text('${c['name'] ?? '-'}'),
                      subtitle: Text('${c['phone'] ?? ''}\n${c['email'] ?? ''}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(id),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
