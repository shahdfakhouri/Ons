import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/models/elder.dart';
import 'package:ons_app/screens/retirement_home/retirement_home_layout.dart';
import 'package:ons_app/services/elder_service.dart';

class ResidentsPage extends StatefulWidget {
  const ResidentsPage({super.key});

  @override
  State<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends State<ResidentsPage> {
  final ElderService _elderService = ElderService();
  late Future<List<Elder>> _futureResidents;

  @override
  void initState() {
    super.initState();
    // later: real homeId from auth/user
    _futureResidents = _loadResidentsForHome('home1');
  }

  Future<List<Elder>> _loadResidentsForHome(String homeId) async {
    final all = await _elderService.getAllElders();
    return all
        .where((e) =>
            e.livingType == 'retirement_home' &&
            e.retirementHomeId == homeId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RetirementHomeLayout(
      title: 'Residents',
      child: FutureBuilder<List<Elder>>(
        future: _futureResidents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load residents',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
            );
          }

          final residents = snapshot.data ?? [];

          if (residents.isEmpty) {
            return Center(
              child: Text(
                'No residents found for this home.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.7),
                    ),
              ),
            );
          }

          return ListView.separated(
            itemCount: residents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = residents[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.onSurface.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.sage.withOpacity(0.4),
                      child: Text(
                        r.name[0],
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: AppTheme.deepNavy,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.deepNavy,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r.age} years',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colors.onSurface.withOpacity(0.7),
                                ),
                          ),
                          if (r.medicalCondition != null &&
                              r.medicalCondition!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              r.medicalCondition!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors
                                        .onSurface
                                        .withOpacity(0.8),
                                  ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            r.caregiverId != null
                                ? 'Primary caregiver: ${r.caregiverId}'
                                : 'No caregiver assigned yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.denim,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
