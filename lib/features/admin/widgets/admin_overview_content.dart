import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/admin_dashboard_data.dart';
import 'package:mana_poster/features/admin/models/admin_dashboard_models.dart';
import 'package:mana_poster/features/admin/widgets/admin_metric_card.dart';
import 'package:mana_poster/features/admin/widgets/admin_quick_action_tile.dart';
import 'package:mana_poster/features/admin/widgets/admin_section_status_tile.dart';

class AdminOverviewContent extends StatelessWidget {
  const AdminOverviewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final int visibleCount = AdminDashboardData.sectionStatuses
        .where((AdminSectionStatus item) => item.visible)
        .length;
    final int totalSections = AdminDashboardData.sectionStatuses.length;

    return ListView(
      children: <Widget>[
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: AdminDashboardData.metrics
              .map(
                (AdminOverviewMetric metric) => SizedBox(
                  width: _metricWidth(context),
                  child: AdminMetricCard(metric: metric),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        _LandingStatusAndActionsCard(
          visibleCount: visibleCount,
          totalSections: totalSections,
        ),
        const SizedBox(height: 18),
        _SectionStatusCard(),
      ],
    );
  }

  double _metricWidth(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width < 700) {
      return double.infinity;
    }
    if (width < 1150) {
      return (width - 64) / 2;
    }
    return (width - 420) / 3;
  }
}

class _LandingStatusAndActionsCard extends StatelessWidget {
  const _LandingStatusAndActionsCard({
    required this.visibleCount,
    required this.totalSections,
  });

  final int visibleCount;
  final int totalSections;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Landing Sections Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2543),
                  ),
                ),
              ),
              Icon(Icons.web_asset_rounded, color: Color(0xFF5A32DE)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$visibleCount / $totalSections sections visible on public landing page.',
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF62708F)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2950),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AdminDashboardData.quickActions
                .map(
                  (AdminQuickAction action) =>
                      AdminQuickActionTile(action: action),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Landing Management Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2444),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Current visibility and status summary for key landing page sections.',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF63708C)),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth < 760 ? 1 : 2;
              final double tileWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AdminDashboardData.sectionStatuses
                    .map(
                      (AdminSectionStatus status) => SizedBox(
                        width: tileWidth,
                        child: AdminSectionStatusTile(section: status),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE7EBF8)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x12213A80), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );
}
