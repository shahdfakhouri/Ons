import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/models/elder.dart';
import 'package:ons_app/screens/family/family_layout.dart';
import 'package:ons_app/services/elder_service.dart';

class FamilyEldersPage extends StatefulWidget {
  const FamilyEldersPage({super.key});

  @override
  State<FamilyEldersPage> createState() => _FamilyEldersPageState();
}

class _FamilyEldersPageState extends State<FamilyEldersPage> {
  final ElderService _elderService = ElderService();
  late Future<List<Elder>> _futureElders;

  @override
  void initState() {
    super.initState();
    // later: replace "fam1" with real familyId from auth
    _futureElders = _loadEldersForFamily('fam1');
  }

  Future<List<Elder>> _loadEldersForFamily(String familyId) async {
    final all = await _elderService.getAllElders();
    return all.where((e) => e.familyId == familyId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FamilyLayout(
      title: 'My elders',
      child: FutureBuilder<List<Elder>>(
        future: _futureElders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load elders',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
            );
          }

          final elders = snapshot.data ?? [];

          if (elders.isEmpty) {
            return Center(
              child: Text(
                'No elders linked to this family yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withOpacity(0.7),
                    ),
              ),
            );
          }

          return ListView.separated(
            itemCount: elders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final e = elders[index];
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
                        e.name[0],
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
                            e.name,
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
                            '${e.age} years • ${_formatLivingType(e.livingType)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colors.onSurface.withOpacity(0.7),
                                ),
                          ),
                          if (e.medicalCondition != null &&
                              e.medicalCondition!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              e.medicalCondition!,
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
                            e.caregiverId != null
                                ? 'Primary caregiver: ${e.caregiverId}'
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

  String _formatLivingType(String livingType) {
    if (livingType == 'home') return 'Lives at home';
    if (livingType == 'retirement_home') return 'Lives in retirement home';
    return livingType;
  }
}
