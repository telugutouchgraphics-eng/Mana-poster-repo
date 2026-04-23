import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/models/admin_dashboard_models.dart';

class AdminDashboardData {
  const AdminDashboardData._();

  static const String overviewTab = 'overview';
  static const String visualEditorTab = 'visual-editor';

  static const List<AdminNavItem> navItems = <AdminNavItem>[
    AdminNavItem(
      id: 'visual-editor',
      label: 'Visual Editor',
      icon: Icons.edit_note_rounded,
    ),
    AdminNavItem(
      id: 'overview',
      label: 'Overview',
      icon: Icons.grid_view_rounded,
    ),
    AdminNavItem(
      id: 'landing-page',
      label: 'Landing Page',
      icon: Icons.web_rounded,
    ),
    AdminNavItem(
      id: 'hero',
      label: 'Hero Section',
      icon: Icons.rocket_launch_rounded,
    ),
    AdminNavItem(
      id: 'features',
      label: 'Features',
      icon: Icons.auto_awesome_rounded,
    ),
    AdminNavItem(
      id: 'categories',
      label: 'Categories',
      icon: Icons.category_rounded,
    ),
    AdminNavItem(
      id: 'showcase-posters',
      label: 'Showcase Posters',
      icon: Icons.photo_library_rounded,
    ),
    AdminNavItem(id: 'faq', label: 'FAQ', icon: Icons.quiz_rounded),
    AdminNavItem(
      id: 'footer-contact',
      label: 'Footer / Contact',
      icon: Icons.contact_mail_rounded,
    ),
    AdminNavItem(id: 'app-links', label: 'App Links', icon: Icons.link_rounded),
    AdminNavItem(
      id: 'media-library',
      label: 'Media Library',
      icon: Icons.perm_media_rounded,
    ),
    AdminNavItem(
      id: 'version-history',
      label: 'Version History',
      icon: Icons.history_rounded,
    ),
    AdminNavItem(
      id: 'activity-history',
      label: 'Activity History',
      icon: Icons.manage_history_rounded,
    ),
    AdminNavItem(
      id: 'dynamic-events',
      label: 'Dynamic Events',
      icon: Icons.event_note_rounded,
    ),
    AdminNavItem(
      id: 'templates',
      label: 'Templates',
      icon: Icons.layers_rounded,
    ),
    AdminNavItem(id: 'users', label: 'Users', icon: Icons.groups_rounded),
    AdminNavItem(
      id: 'payments',
      label: 'Payments',
      icon: Icons.payments_rounded,
    ),
    AdminNavItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_rounded,
    ),
  ];

  static const List<AdminOverviewMetric> metrics = <AdminOverviewMetric>[
    AdminOverviewMetric(
      label: 'Total Templates',
      value: '128',
      icon: Icons.layers_rounded,
      color: Color(0xFF2563EB),
    ),
    AdminOverviewMetric(
      label: 'Free Templates',
      value: '76',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF16A34A),
    ),
    AdminOverviewMetric(
      label: 'Premium Templates',
      value: '52',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFF97316),
    ),
    AdminOverviewMetric(
      label: 'Total Categories',
      value: '18',
      icon: Icons.category_rounded,
      color: Color(0xFF8B5CF6),
    ),
    AdminOverviewMetric(
      label: 'Dynamic Events',
      value: '43',
      icon: Icons.event_available_rounded,
      color: Color(0xFF0EA5E9),
    ),
    AdminOverviewMetric(
      label: 'FAQ Count',
      value: '8',
      icon: Icons.quiz_rounded,
      color: Color(0xFFEC4899),
    ),
  ];

  static const List<AdminQuickAction> quickActions = <AdminQuickAction>[
    AdminQuickAction(label: 'Edit Hero', icon: Icons.mode_edit_rounded),
    AdminQuickAction(label: 'Manage Templates', icon: Icons.layers_rounded),
    AdminQuickAction(label: 'Update Categories', icon: Icons.category_rounded),
    AdminQuickAction(label: 'Update FAQ', icon: Icons.help_center_rounded),
    AdminQuickAction(
      label: 'Open Landing Preview',
      icon: Icons.open_in_new_rounded,
    ),
  ];

  static const List<AdminSectionStatus> sectionStatuses = <AdminSectionStatus>[
    AdminSectionStatus(
      sectionName: 'Hero Section',
      statusText: 'Headline and CTA updated for launch quality.',
      visible: true,
    ),
    AdminSectionStatus(
      sectionName: 'Features Section',
      statusText: 'Six app highlights currently visible.',
      visible: true,
    ),
    AdminSectionStatus(
      sectionName: 'Categories Section',
      statusText: 'Category cards aligned with app categories.',
      visible: true,
    ),
    AdminSectionStatus(
      sectionName: 'Showcase Section',
      statusText: 'Preview cards with free/premium labels.',
      visible: true,
    ),
    AdminSectionStatus(
      sectionName: 'FAQ Section',
      statusText: 'Accordion flow active with launch FAQs.',
      visible: true,
    ),
    AdminSectionStatus(
      sectionName: 'Footer Section',
      statusText: 'Support/legal/contact links visible.',
      visible: true,
    ),
  ];
}
