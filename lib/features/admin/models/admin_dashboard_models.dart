import 'package:flutter/material.dart';

@immutable
class AdminNavItem {
  const AdminNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

@immutable
class AdminOverviewMetric {
  const AdminOverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

@immutable
class AdminQuickAction {
  const AdminQuickAction({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

@immutable
class AdminSectionStatus {
  const AdminSectionStatus({
    required this.sectionName,
    required this.statusText,
    required this.visible,
  });

  final String sectionName;
  final String statusText;
  final bool visible;
}
