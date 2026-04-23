import 'package:flutter/material.dart';

import 'package:mana_poster/features/admin/data/admin_dashboard_data.dart';
import 'package:mana_poster/features/admin/models/admin_dashboard_models.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selectedNavId,
    required this.onNavSelected,
  });

  final String selectedNavId;
  final ValueChanged<String> onNavSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      margin: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE6EAF5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14213B7A),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const _SidebarBrand(),
          const Divider(height: 1, color: Color(0xFFE8ECF7)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: AdminDashboardData.navItems.length,
              separatorBuilder: (_, int index) => const SizedBox(height: 4),
              itemBuilder: (BuildContext context, int index) {
                final AdminNavItem item = AdminDashboardData.navItems[index];
                final bool selected = item.id == selectedNavId;
                return _SidebarItem(
                  item: item,
                  selected: selected,
                  onTap: () => onNavSelected(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFFF8A00),
                  Color(0xFFE72E6A),
                  Color(0xFF6B46F8),
                ],
              ),
            ),
            child: const Icon(
              Icons.collections_bookmark_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mana Poster',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2040),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(fontSize: 12, color: Color(0xFF66708A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? const Color(0xFFF1EEFF) : Colors.transparent,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                item.icon,
                size: 20,
                color: selected
                    ? const Color(0xFF6A40F8)
                    : const Color(0xFF65708E),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF2A2354)
                        : const Color(0xFF2C3454),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
