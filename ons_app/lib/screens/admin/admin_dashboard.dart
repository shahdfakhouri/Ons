import 'package:flutter/material.dart';
import 'package:ons_app/core/theme/app_theme.dart';
import 'package:ons_app/screens/admin/admin_layout.dart';
import 'package:ons_app/screens/admin/approve_caregivers.dart';
import 'package:ons_app/screens/admin/approve_retirement_homes.dart';
import 'package:ons_app/screens/admin/health_logs_page.dart';
import 'package:ons_app/screens/admin/matching_overview_page.dart';
import 'package:ons_app/screens/admin/notifications_page.dart';
import 'package:ons_app/screens/admin/payments_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AdminLayout(
      title: 'Dashboard',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Monitor the platform, approve partners, and keep Ons running smoothly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 20),

            // small status chips
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: const [
                _StatusChip(label: 'Pending caregivers', value: '8'),
                _StatusChip(label: 'Pending homes', value: '3'),
                _StatusChip(label: 'Open complaints', value: '2'),
              ],
            ),
            const SizedBox(height: 32),

            // main grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final crossAxisCount = isWide ? 2 : 1;

                final tiles = <_AdminTile>[
                  _AdminTile(
                    icon: Icons.badge_outlined,
                    title: 'Approve Caregivers',
                    subtitle: 'Review CVs & approve new caregivers.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApproveCaregiversPage(),
                        ),
                      );
                    },
                  ),
                  _AdminTile(
                    icon: Icons.home_work_outlined,
                    title: 'Approve Retirement Homes',
                    subtitle:
                        'Check partner homes, documents & permissions.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ApproveRetirementHomesPage(),
                        ),
                      );
                    },
                  ),
                  _AdminTile(
                    icon: Icons.payments_outlined,
                    title: 'Payments & Payouts',
                    subtitle: 'Monitor subscriptions & caregiver payouts.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentsPage(),
                        ),
                      );
                    },
                  ),
                  _AdminTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications & Reports',
                    subtitle: 'System alerts, complaints, and flags.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  _AdminTile(
                    icon: Icons.groups_3_outlined,
                    title: 'Matching Overview',
                    subtitle: 'Monitor AI matches & override decisions.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchingOverviewPage(),
                        ),
                      );
                    },
                  ),
                  _AdminTile(
                    icon: Icons.favorite_border,
                    title: 'Health Logs',
                    subtitle: 'View elders’ health logs & visit history.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HealthLogsPage(),
                        ),
                      );
                    },
                  ),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isWide ? 2.5 : 2.2,
                  ),
                  itemCount: tiles.length,
                  itemBuilder: (_, i) => tiles[i],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: AppTheme.sage.withOpacity(0.16),
      side: BorderSide.none,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.denim,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.deepNavy.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends State<_AdminTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform:
            _hovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  )
                ]
              : [
                  BoxShadow(
                    color: colors.onSurface.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.sage.withOpacity(0.35),
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: AppTheme.denim,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepNavy,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: colors.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
