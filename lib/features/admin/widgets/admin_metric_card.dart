import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_dashboard_models.dart';

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({super.key, required this.metric});

  final AdminOverviewMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF8)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10233C7F),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(metric.icon, color: metric.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C2340),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF626D89),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
